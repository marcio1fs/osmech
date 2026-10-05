package com.osmech.equipe.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.config.ResourceNotFoundException;
import com.osmech.equipe.dto.EquipeDtos.*;
import com.osmech.equipe.entity.ConviteEquipe;
import com.osmech.equipe.repository.ConviteEquipeRepository;
import com.osmech.mecanico.entity.Mecanico;
import com.osmech.mecanico.repository.MecanicoRepository;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.security.JwtUtil;
import com.osmech.sessao.service.SessaoService;
import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Gestão da equipe da oficina (Fase 3 do plano de controle de usuários).
 *
 * Regras principais:
 *  - Somente DONO (endpoint protegido) convida, altera papéis e ativa/desativa;
 *  - Limite de usuários do plano cobrado no convite E no aceite (defesa em
 *    profundidade) — considerando usuários ativos + convites pendentes;
 *  - Um e-mail pertence a UMA oficina: convidado já vinculado a outra é rejeitado;
 *  - A oficina precisa manter ao menos um DONO ativo;
 *  - Tokens de convite são de uso único e expiram em 7 dias.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EquipeService {

    private static final Duration CONVITE_TTL = Duration.ofDays(7);

    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final ConviteEquipeRepository conviteRepository;
    private final PlanoRepository planoRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final JwtUtil jwtUtil;
    private final SessaoService sessaoService;
    private final AuditoriaService auditoria;
    private final MecanicoRepository mecanicoRepository;

    // ==================== visão consolidada (tela Equipe) ====================

    @Transactional
    public EquipeResponse getEquipe(String emailDono) {
        Usuario dono = getUsuario(emailDono);
        Long oid = dono.getOficinaId();

        List<Usuario> membros = usuarioRepository.findAllByOficinaId(oid);
        List<ConviteEquipe> convites = conviteRepository
                .findByOficinaIdAndStatusOrderByCriadoEmDesc(oid, ConviteEquipe.STATUS_PENDENTE);

        // Expiração preguiçosa: marca vencidos sem depender de job agendado
        LocalDateTime agora = LocalDateTime.now();
        convites.stream()
                .filter(c -> c.marcarExpiradoSeVencido(agora))
                .forEach(conviteRepository::save);

        Integer limite = limiteUsuariosDaOficina(oid);
        long ativos = membros.stream().filter(m -> Boolean.TRUE.equals(m.getAtivo())).count();
        long pendentes = convites.stream()
                .filter(c -> ConviteEquipe.STATUS_PENDENTE.equals(c.getStatus())).count();
        long emUso = ativos + pendentes;

        return EquipeResponse.builder()
                .limiteUsuarios(limite)
                .usuariosEmUso(emUso)
                .limiteAtingido(limiteAtingido(limite, emUso))
                .membros(membros.stream().map(this::toMembroResponse).collect(Collectors.toList()))
                .convites(convites.stream().map(this::toConviteResponse).collect(Collectors.toList()))
                .build();
    }

    @Transactional(readOnly = true)
    public java.util.List<com.osmech.auditoria.entity.LogAuditoria> getAuditoria(String emailSolicitante) {
        Long oid = getUsuario(emailSolicitante).getOficinaId();
        return auditoria.ultimasDaOficina(oid);
    }

    // ==================== convites (área do DONO) ====================

    @Transactional
    public ConviteEquipeResponse convidar(String emailDono, ConvidarUsuarioRequest request) {
        Usuario dono = getUsuario(emailDono);
        Long oid = dono.getOficinaId();

        Papel papel = Papel.from(request.getPapel());
        if (!papel.convidavel()) {
            throw new IllegalArgumentException(
                    "Papel inválido para convite. Use GERENTE, ATENDENTE, VENDEDOR ou MECANICO.");
        }

        String emailConvidado = request.getEmail().toLowerCase().trim();

        if (emailConvidado.equals(dono.getEmail())) {
            throw new IllegalArgumentException("Você já é o dono desta oficina.");
        }

        usuarioRepository.findByEmail(emailConvidado).ifPresent(existente -> {
            if (oid.equals(existente.getOficinaId())) {
                throw new IllegalArgumentException("Este e-mail já faz parte da sua equipe.");
            }
            throw new IllegalArgumentException("Este e-mail já está vinculado a outra oficina no OSMECH.");
        });

        if (conviteRepository.existsByOficinaIdAndEmailAndStatus(
                oid, emailConvidado, ConviteEquipe.STATUS_PENDENTE)) {
            throw new IllegalArgumentException("Já existe um convite pendente para este e-mail.");
        }

        cobrarLimiteDoPlano(oid);

        Oficina oficina = getOficina(oid);
        ConviteEquipe convite = conviteRepository.save(ConviteEquipe.builder()
                .oficinaId(oid)
                .email(emailConvidado)
                .papel(papel.name())
                .token(UUID.randomUUID().toString())
                .status(ConviteEquipe.STATUS_PENDENTE)
                .criadoPorUsuarioId(dono.getId())
                .expiraEm(LocalDateTime.now().plus(CONVITE_TTL))
                .build());

        emailService.enviarEmailConvite(emailConvidado, oficina.getNome(), papel.name(), convite.getToken());
        auditoria.registrar(dono, LogAuditoria.CONVITE_CRIADO,
                "Convite para " + emailConvidado + " como " + papel);
        log.info("Convite criado: oficina {} → {} ({})", oid, emailConvidado, papel);

        return toConviteResponse(convite);
    }

    @Transactional
    public void revogarConvite(String emailDono, Long conviteId) {
        Long oid = getUsuario(emailDono).getOficinaId();
        ConviteEquipe convite = conviteRepository.findByIdAndOficinaId(conviteId, oid)
                .orElseThrow(() -> new ResourceNotFoundException("Convite não encontrado"));

        if (!ConviteEquipe.STATUS_PENDENTE.equals(convite.getStatus())) {
            throw new IllegalArgumentException("Somente convites pendentes podem ser revogados.");
        }

        convite.setStatus(ConviteEquipe.STATUS_REVOGADO);
        conviteRepository.save(convite);
        auditoria.registrar(getUsuario(emailDono), LogAuditoria.CONVITE_REVOGADO,
                "Convite de " + convite.getEmail() + " revogado");
        log.info("Convite {} revogado (oficina {})", conviteId, oid);
    }

    @Transactional
    public ConviteEquipeResponse reenviarConvite(String emailDono, Long conviteId) {
        Long oid = getUsuario(emailDono).getOficinaId();
        ConviteEquipe convite = conviteRepository.findByIdAndOficinaId(conviteId, oid)
                .orElseThrow(() -> new ResourceNotFoundException("Convite não encontrado"));

        // Novo token invalida o link antigo
        convite.setToken(UUID.randomUUID().toString());
        convite.setStatus(ConviteEquipe.STATUS_PENDENTE);
        convite.setExpiraEm(LocalDateTime.now().plus(CONVITE_TTL));
        conviteRepository.save(convite);

        Oficina oficina = getOficina(oid);
        emailService.enviarEmailConvite(convite.getEmail(), oficina.getNome(), convite.getPapel(), convite.getToken());
        auditoria.registrar(getUsuario(emailDono), LogAuditoria.CONVITE_REENVIADO,
                "Convite de " + convite.getEmail() + " reenviado");
        log.info("Convite {} reenviado para {}", conviteId, convite.getEmail());

        return toConviteResponse(convite);
    }

    // ==================== gestão de membros (área do DONO) ====================

    @Transactional
    public MembroEquipeResponse alterarPapel(String emailDono, Long usuarioId, AlterarPapelRequest request) {
        Usuario dono = getUsuario(emailDono);
        if (dono.getId().equals(usuarioId)) {
            throw new IllegalArgumentException("Você não pode alterar seu próprio papel.");
        }

        Usuario alvo = usuarioRepository.findByIdAndOficinaId(usuarioId, dono.getOficinaId())
                .orElseThrow(() -> new ResourceNotFoundException("Membro não encontrado nesta oficina"));

        if (Papel.from(alvo.getRole()) == Papel.DONO) {
            throw new IllegalArgumentException("O papel do DONO não pode ser alterado.");
        }

        Papel novo = Papel.from(request.getPapel());
        if (!novo.convidavel()) {
            throw new IllegalArgumentException("Papel inválido. Use GERENTE, ATENDENTE, VENDEDOR ou MECANICO.");
        }

        alvo.setRole(novo.name());
        usuarioRepository.save(alvo);
        auditoria.registrar(dono, LogAuditoria.MEMBRO_PAPEL_ALTERADO,
                "Papel de " + alvo.getEmail() + " alterado para " + novo);
        log.info("Papel do usuário {} alterado para {} (oficina {})", usuarioId, novo, dono.getOficinaId());
        return toMembroResponse(alvo);
    }

    @Transactional
    public MembroEquipeResponse alterarStatus(String emailDono, Long usuarioId, AlterarStatusRequest request) {
        Usuario dono = getUsuario(emailDono);
        if (dono.getId().equals(usuarioId)) {
            throw new IllegalArgumentException("Você não pode desativar a própria conta por aqui.");
        }

        Usuario alvo = usuarioRepository.findByIdAndOficinaId(usuarioId, dono.getOficinaId())
                .orElseThrow(() -> new ResourceNotFoundException("Membro não encontrado nesta oficina"));

        boolean vaiDesativar = !Boolean.TRUE.equals(request.getAtivo());
        if (vaiDesativar && Papel.from(alvo.getRole()) == Papel.DONO) {
            long donosAtivos = usuarioRepository.findAllByOficinaId(dono.getOficinaId()).stream()
                    .filter(u -> Boolean.TRUE.equals(u.getAtivo()))
                    .filter(u -> Papel.from(u.getRole()) == Papel.DONO)
                    .count();
            if (donosAtivos <= 1) {
                throw new IllegalArgumentException("A oficina precisa manter ao menos um DONO ativo.");
            }
        }

        boolean reativando = Boolean.TRUE.equals(request.getAtivo());
        alvo.setAtivo(request.getAtivo());
        usuarioRepository.save(alvo);

        // Fase 4: desativar encerra todas as sessões do membro na hora
        if (!reativando) {
            sessaoService.revogarTodas(alvo.getId(), SessaoService.MOTIVO_CONTA_DESATIVADA);
        }
        auditoria.registrar(dono, reativando ? LogAuditoria.MEMBRO_ATIVADO : LogAuditoria.MEMBRO_DESATIVADO,
                "Conta de " + alvo.getEmail() + (reativando ? " reativada" : " desativada — sessões encerradas"));
        log.info("Usuário {} {} (oficina {})",
                usuarioId, reativando ? "ativado" : "desativado", dono.getOficinaId());
        return toMembroResponse(alvo);
    }

    // ==================== aceite (área pública) ====================

    @Transactional(readOnly = true)
    public ConviteInfoResponse conviteInfo(String token) {
        ConviteEquipe convite = conviteRepository.findByToken(token == null ? "" : token.trim())
                .orElseThrow(() -> new IllegalArgumentException("Convite inválido ou já utilizado."));

        if (!ConviteEquipe.STATUS_PENDENTE.equals(convite.getStatus())) {
            throw new IllegalArgumentException("Convite inválido ou já utilizado.");
        }
        if (convite.getExpiraEm() != null && convite.getExpiraEm().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("Este convite expirou. Peça um novo reenvio ao dono da oficina.");
        }

        Oficina oficina = getOficina(convite.getOficinaId());
        return ConviteInfoResponse.builder()
                .email(convite.getEmail())
                .nomeOficina(oficina.getNome())
                .papel(convite.getPapel())
                .expiraEm(convite.getExpiraEm())
                .build();
    }

    @Transactional
    public AuthResponse aceitarConvite(AceitarConviteRequest request) {
        ConviteEquipe convite = conviteRepository.findByToken(request.getToken().trim())
                .orElseThrow(() -> new IllegalArgumentException("Convite inválido ou já utilizado."));

        LocalDateTime agora = LocalDateTime.now();
        if (convite.marcarExpiradoSeVencido(agora)) {
            conviteRepository.save(convite);
            throw new IllegalArgumentException("Este convite expirou. Peça um novo reenvio ao dono da oficina.");
        }
        if (!ConviteEquipe.STATUS_PENDENTE.equals(convite.getStatus())) {
            throw new IllegalArgumentException("Convite inválido ou já utilizado.");
        }

        Long oid = convite.getOficinaId();
        String email = convite.getEmail();

        usuarioRepository.findByEmail(email).ifPresent(existente -> {
            if (oid.equals(existente.getOficinaId())) {
                throw new IllegalArgumentException("Este e-mail já faz parte da equipe. Faça login.");
            }
            throw new IllegalArgumentException("Este e-mail já está vinculado a outra oficina no OSMECH.");
        });

        // Defesa em profundidade: limite cobrado também no aceite
        cobrarLimiteDoPlano(oid);

        Oficina oficina = getOficina(oid);
        Papel papel = Papel.from(convite.getPapel());

        Usuario usuario = usuarioRepository.save(Usuario.builder()
                .nome(request.getNome().trim())
                .email(email)
                .senha(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone())
                .nomeOficina(oficina.getNome())
                .role(papel.name())
                .oficinaId(oid)
                .ativo(true)
                .emailVerificado(true) // o convite foi enviado para este e-mail
                .build());

        convite.setStatus(ConviteEquipe.STATUS_ACEITO);
        convite.setAceitoEm(agora);
        conviteRepository.save(convite);
        auditoria.registrar(usuario, LogAuditoria.CONVITE_ACEITO,
                email + " entrou na equipe como " + papel);
        log.info("Convite aceito: {} entrou na oficina {} como {}", email, oid, papel);

        // Integração Equipe ↔ Mecânicos: quem entra como MECANICO ganha (ou
        // assume) uma ficha no módulo de mecânicos, para que as comissões das
        // OS fiquem vinculadas à pessoa.
        if (papel == Papel.MECANICO) {
            vincularFichaMecanico(usuario, oid);
        }

        // Auto-login: JWT de acesso + refresh token (Fase 4)
        String token = jwtUtil.generateToken(usuario.getEmail(), papel.name(), usuario.getId(), oid);
        var sessao = sessaoService.criar(usuario, null);
        return AuthResponse.builder()
                .token(token)
                .refreshToken(sessao.refreshToken())
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(papel.name())
                .plano(oficina.getPlano())
                .message("Bem-vindo(a) à equipe da " + oficina.getNome() + "!")
                .build();
    }

    // ==================== integração com módulo de mecânicos ====================

    /**
     * Garante que o novo membro MECANICO tenha uma ficha no módulo de mecânicos:
     * - se existir uma ficha SEM vínculo com o mesmo nome na oficina, assume ela
     *   (caso do mecânico que já era cadastrado antes de ganhar login);
     * - senão, cria uma ficha nova com comissão 0% (o gestor ajusta depois).
     * Falha aqui NUNCA quebra o aceite do convite — é melhor entrar sem ficha
     * (vinculável manualmente depois) do que perder o cadastro.
     */
    private void vincularFichaMecanico(Usuario usuario, Long oficinaId) {
        try {
            var existente = mecanicoRepository
                    .findFirstByUsuarioIdAndNomeIgnoreCaseAndUsuarioContaIdIsNull(
                            oficinaId, usuario.getNome().trim());
            if (existente.isPresent()) {
                Mecanico ficha = existente.get();
                ficha.setUsuarioContaId(usuario.getId());
                mecanicoRepository.save(ficha);
                log.info("[Equipe→Mecânicos] {} assumiu a ficha de mecânico existente #{} ({})",
                        usuario.getEmail(), ficha.getId(), ficha.getNome());
                return;
            }
            Mecanico nova = mecanicoRepository.save(Mecanico.builder()
                    .usuarioId(oficinaId)
                    .usuarioContaId(usuario.getId())
                    .nome(usuario.getNome().trim())
                    .telefone(usuario.getTelefone())
                    .percentualComissao(java.math.BigDecimal.ZERO)
                    .ativo(true)
                    .build());
            log.info("[Equipe→Mecânicos] Ficha de mecânico #{} criada para {} (comissão 0%, ajuste em Mecânicos)",
                    nova.getId(), usuario.getEmail());
        } catch (Exception e) {
            log.warn("[Equipe→Mecânicos] Não foi possível vincular ficha de mecânico para {}: {}",
                    usuario.getEmail(), e.getMessage());
        }
    }

    // ==================== regras de limite do plano ====================

    /**
     * Lança LimiteEquipeException se a oficina atingiu o limite de usuários
     * do plano (ativos + convites pendentes). Limite 0/null = ilimitado.
     */
    private void cobrarLimiteDoPlano(Long oficinaId) {
        Integer limite = limiteUsuariosDaOficina(oficinaId);
        if (limite == null || limite <= 0) {
            return; // ilimitado
        }

        long ativos = usuarioRepository.countByOficinaIdAndAtivoTrue(oficinaId);
        long pendentes = conviteRepository.countByOficinaIdAndStatus(
                oficinaId, ConviteEquipe.STATUS_PENDENTE);
        long emUso = ativos + pendentes;

        if (emUso >= limite) {
            String planoCodigo = oficinaRepository.findById(oficinaId)
                    .map(Oficina::getPlano).orElse("atual");
            throw new LimiteEquipeException(
                    "Limite de " + limite + " usuário(s) do plano " + planoCodigo
                            + " atingido (" + ativos + " ativos, " + pendentes
                            + " convite(s) pendente(s)). Faça upgrade do plano para adicionar mais membros.");
        }
    }

    private Integer limiteUsuariosDaOficina(Long oficinaId) {
        String planoCodigo = oficinaRepository.findById(oficinaId).map(Oficina::getPlano).orElse("FREE");
        Plano plano = planoRepository.findByCodigo(planoCodigo).orElse(null);
        if (plano == null || plano.getLimiteUsuarios() == null) {
            return null; // desconhecido → não bloqueia
        }
        return plano.getLimiteUsuarios();
    }

    private boolean limiteAtingido(Integer limite, long emUso) {
        return limite != null && limite > 0 && emUso >= limite;
    }

    // ==================== helpers ====================

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    private Oficina getOficina(Long id) {
        return oficinaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Oficina não encontrada"));
    }

    private MembroEquipeResponse toMembroResponse(Usuario u) {
        return MembroEquipeResponse.builder()
                .id(u.getId())
                .nome(u.getNome())
                .email(u.getEmail())
                .papel(Papel.from(u.getRole()).name())
                .ativo(u.getAtivo())
                .criadoEm(u.getCriadoEm())
                .build();
    }

    private ConviteEquipeResponse toConviteResponse(ConviteEquipe c) {
        return ConviteEquipeResponse.builder()
                .id(c.getId())
                .email(c.getEmail())
                .papel(c.getPapel())
                .status(c.getStatus())
                .criadoEm(c.getCriadoEm())
                .expiraEm(c.getExpiraEm())
                .build();
    }
}
