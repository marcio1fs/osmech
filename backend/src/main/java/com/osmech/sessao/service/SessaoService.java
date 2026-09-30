package com.osmech.sessao.service;

import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.sessao.entity.SessaoUsuario;
import com.osmech.sessao.repository.SessaoUsuarioRepository;
import com.osmech.user.entity.Usuario;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HexFormat;

/**
 * Sessões com refresh token rotativo (Fase 4).
 *
 * - Token opaco de 256 bits; no banco fica só o hash SHA-256;
 * - Cada refresh ROTACIONA o token (o antigo é revogado com motivo ROTACAO);
 * - Apresentação de um token já revogado/expirado = sinal de roubo:
 *   TODAS as sessões do usuário são revogadas (reuse detection) e o
 *   incidente vai para a trilha de auditoria.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SessaoService {

    private static final SecureRandom RANDOM = new SecureRandom();

    /** Aliases dos motivos de revogação (definidos na entidade) */
    public static final String MOTIVO_SENHA_ALTERADA = SessaoUsuario.MOTIVO_SENHA_ALTERADA;
    public static final String MOTIVO_CONTA_DESATIVADA = SessaoUsuario.MOTIVO_CONTA_DESATIVADA;

    private final SessaoUsuarioRepository repository;
    private final AuditoriaService auditoria;

    @Value("${app.session.refresh-days:30}")
    private int refreshDias;

    /** Resultado da criação/rotação: token em claro (vai ao cliente) + dono da sessão */
    public record SessaoEmitida(String refreshToken, Usuario usuario) {
    }

    /**
     * Cria uma sessão nova e devolve o refresh token em claro
     * (único momento em que ele existe fora do cliente).
     */
    @Transactional
    public SessaoEmitida criar(Usuario usuario, String userAgent) {
        // Higiene oportunista: some com sessões expiradas há mais de 7 dias
        repository.deleteByUsuarioIdAndExpiraEmBefore(
                usuario.getId(), LocalDateTime.now().minusDays(7));

        String token = gerarToken();
        repository.save(SessaoUsuario.builder()
                .usuarioId(usuario.getId())
                .oficinaId(usuario.getOficinaId())
                .refreshTokenHash(hash(token))
                .userAgent(userAgent == null || userAgent.length() <= 300
                        ? userAgent : userAgent.substring(0, 300))
                .expiraEm(LocalDateTime.now().plus(Duration.ofDays(refreshDias)))
                .build());
        return new SessaoEmitida(token, usuario);
    }

    /** Localiza a sessão pelo refresh token em claro (null se não existir). */
    @Transactional(readOnly = true)
    public SessaoUsuario buscarPorToken(String refreshToken) {
        return repository.findByRefreshTokenHash(hash(refreshToken)).orElse(null);
    }

    /**
     * Troca um refresh token válido por um novo (rotação).
     * Lança IllegalArgumentException em token inválido/expirado/revogado.
     */
    @Transactional
    public SessaoEmitida rotacionar(String refreshToken, String userAgent, Usuario usuario) {
        SessaoUsuario sessao = repository.findByRefreshTokenHash(hash(refreshToken))
                .orElse(null);

        // Token desconhecido: apenas rejeita (pode ser lixo de cliente antigo)
        if (sessao == null || !sessao.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Sessão inválida. Faça login novamente.");
        }

        if (sessao.getRevogadoEm() != null) {
            // Reuso de token já rotacionado/revogado = provável roubo:
            // revoga TUDO do usuário e registra alerta.
            revogarTodasInterno(usuario.getId(), SessaoUsuario.MOTIVO_REUSO_DETECTADO);
            auditoria.registrar(usuario, com.osmech.auditoria.entity.LogAuditoria.SESSAO_REUSO_DETECTADO,
                    "Refresh token já revogado (" + sessao.getMotivoRevogacao()
                            + ") apresentado novamente — sessões encerradas por segurança.");
            log.warn("[Sessao] Reuso de refresh token detectado (usuario {})", usuario.getEmail());
            throw new IllegalArgumentException("Sessão reutilizada após rotação — faça login novamente.");
        }

        if (!sessao.isAtiva()) {
            // Apenas expirada por inatividade (ex.: dispositivo parado):
            // marca e rejeita — NÃO encerra as demais sessões do usuário.
            sessao.setRevogadoEm(LocalDateTime.now());
            sessao.setMotivoRevogacao(SessaoUsuario.MOTIVO_EXPIRADA);
            repository.save(sessao);
            throw new IllegalArgumentException("Sessão expirada. Faça login novamente.");
        }

        sessao.setRevogadoEm(LocalDateTime.now());
        sessao.setMotivoRevogacao(SessaoUsuario.MOTIVO_ROTACAO);
        repository.save(sessao);

        return criar(usuario, userAgent);
    }

    /** Logout: revoga a sessão identificada pelo refresh token (best effort). */
    @Transactional
    public void revogar(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank()) {
            return;
        }
        repository.findByRefreshTokenHash(hash(refreshToken.trim())).ifPresent(sessao -> {
            sessao.setRevogadoEm(LocalDateTime.now());
            sessao.setMotivoRevogacao(SessaoUsuario.MOTIVO_LOGOUT);
            repository.save(sessao);
        });
    }

    /** Revoga todas as sessões do usuário (senha alterada, conta desativada etc.). */
    @Transactional
    public void revogarTodas(Long usuarioId, String motivo) {
        revogarTodasInterno(usuarioId, motivo);
    }

    private void revogarTodasInterno(Long usuarioId, String motivo) {
        LocalDateTime agora = LocalDateTime.now();
        for (SessaoUsuario s : repository.findByUsuarioIdAndRevogadoEmIsNull(usuarioId)) {
            s.setRevogadoEm(agora);
            s.setMotivoRevogacao(motivo);
            repository.save(s);
        }
    }

    /** Token opaco de 256 bits em hex (64 chars). */
    private String gerarToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    /** SHA-256 hex — helper estático para comparar tokens recebidos. */
    public static String hash(String token) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponível", e);
        }
    }
}
