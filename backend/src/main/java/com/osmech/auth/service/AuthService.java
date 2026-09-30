package com.osmech.auth.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.auth.entity.Desafio2fa;
import com.osmech.auth.repository.Desafio2faRepository;
import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.rbac.PermissionService;
import com.osmech.security.JwtUtil;
import com.osmech.sessao.service.SessaoService;
import com.osmech.sessao.service.SessaoService.SessaoEmitida;
import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Serviço responsável por autenticação, cadastro e recuperação de senha.
 * Integra RBAC para permissões granulares, 2FA, tenant e sessões rotativas.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    /** Validade do token de recuperação de senha */
    private static final Duration RESET_TOKEN_TTL = Duration.ofHours(1);

    /** Validade do código 2FA enviado por e-mail */
    private static final Duration DESAFIO_2FA_TTL = Duration.ofMinutes(10);

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final Desafio2faRepository desafio2faRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final EmailService emailService;
    private final SessaoService sessaoService;
    private final AuditoriaService auditoria;
    private final PermissionService permissionService;

    /**
     * Quando true, exige e-mail verificado no login.
     * Default false para não quebrar contas legadas criadas antes da verificação.
     */
    @Value("${app.auth.require-verified-email:false}")
    private boolean requireVerifiedEmail;

    /**
     * Realiza o cadastro de um novo usuário e dispara o e-mail de verificação.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().toLowerCase().trim();

        if (email.length() < 5) {
            throw new IllegalArgumentException("Por favor, utilize um e-mail válido.");
        }

        if (usuarioRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Este e-mail já está em uso.");
        }

        // Fase 1: todo cadastro cria a OFICINA (tenant) e vincula o usuário a ela
        String nomeOficina = request.getNomeOficina() != null && !request.getNomeOficina().isBlank()
                ? request.getNomeOficina().trim()
                : "Oficina de " + request.getNome().trim();
        Oficina oficina = oficinaRepository.save(Oficina.builder()
                .nome(nomeOficina)
                .email(email)
                .telefone(request.getTelefone())
                .plano("FREE")
                .build());

        Usuario usuario = Usuario.builder()
                .nome(request.getNome())
                .email(email)
                .senha(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone())
                .nomeOficina(request.getNomeOficina())
                .role(Papel.DONO.name())
                .oficinaId(oficina.getId())
                .emailVerificado(false)
                .verificationToken(UUID.randomUUID().toString())
                .build();

        usuarioRepository.save(usuario);

        // Em dev (SMTP desabilitado) o EmailService apenas loga — não bloqueia o cadastro
        emailService.enviarEmailVerificacao(usuario.getEmail(), usuario.getVerificationToken());

        return AuthResponse.builder()
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(usuario.getRole())
                .plano(usuario.getPlano())
                .message("Cadastro realizado! Enviamos um link de verificação para o seu e-mail.")
                .build();
    }

    /**
     * Realiza o login do usuário.
     */
    @Transactional
    public AuthResponse login(LoginRequest request, String userAgent) {
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail().toLowerCase().trim())
                .orElse(null);

        if (usuario == null || !passwordEncoder.matches(request.getSenha(), usuario.getSenha())) {
            auditoria.registrar(usuario == null ? null : usuario.getOficinaId(),
                    usuario == null ? null : usuario.getId(),
                    request.getEmail(), LogAuditoria.LOGIN_RECUSADO, "Senha incorreta ou conta inexistente");
            throw new BadCredentialsException("E-mail ou senha incorretos.");
        }

        // Conta desativada não entra
        if (!Boolean.TRUE.equals(usuario.getAtivo())) {
            auditoria.registrar(usuario, LogAuditoria.LOGIN_RECUSADO, "Conta desativada");
            throw new DisabledException("Sua conta está desativada. Fale com o suporte.");
        }

        if (requireVerifiedEmail && !Boolean.TRUE.equals(usuario.getEmailVerificado())) {
            auditoria.registrar(usuario, LogAuditoria.LOGIN_RECUSADO, "E-mail não verificado");
            throw new DisabledException("Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.");
        }

        // 2FA: emite desafio em vez de tokens
        if (Boolean.TRUE.equals(usuario.getDoisFaAtivo())) {
            return iniciarDesafio2fa(usuario);
        }

        auditoria.registrar(usuario, LogAuditoria.LOGIN, "Login com senha");
        return emitirRespostaAutenticada(usuario, userAgent);
    }

    /**
     * Verifica o código 2FA e conclui o login emitindo os tokens.
     */
    @Transactional
    public AuthResponse verificar2fa(Long desafioId, String codigo, String userAgent) {
        Desafio2fa desafio = desafio2faRepository.findById(desafioId)
                .orElseThrow(() -> new IllegalArgumentException("Código inválido ou expirado. Faça login novamente."));

        Usuario usuario = usuarioRepository.findById(desafio.getUsuarioId())
                .orElseThrow(() -> new IllegalArgumentException("Sessão inválida. Faça login novamente."));

        if (desafio.isExpirado()) {
            desafio2faRepository.deleteByUsuarioId(usuario.getId());
            auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_RECUSADO, "Código expirado");
            throw new IllegalArgumentException("O código expirou. Faça login novamente.");
        }

        if (desafio.getTentativas() >= Desafio2fa.MAX_TENTATIVAS) {
            desafio2faRepository.deleteByUsuarioId(usuario.getId());
            auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_RECUSADO, "Tentativas esgotadas");
            throw new IllegalArgumentException("Tentativas esgotadas. Faça login novamente.");
        }

        if (!SessaoService.hash(codigo.trim()).equals(desafio.getCodigoHash())) {
            desafio.setTentativas(desafio.getTentativas() + 1);
            desafio2faRepository.save(desafio);
            auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_RECUSADO, "Código incorreto");
            throw new IllegalArgumentException("Código incorreto. "
                    + (Desafio2fa.MAX_TENTATIVAS - desafio.getTentativas()) + " tentativa(s) restante(s).");
        }

        // Sucesso: descarta o desafio e emite tokens
        desafio2faRepository.deleteByUsuarioId(usuario.getId());
        auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_OK, "Login com 2FA");
        return emitirRespostaAutenticada(usuario, userAgent);
    }

    /**
     * Reenvia o código 2FA de um desafio pendente (mesmo id, código novo).
     */
    @Transactional
    public void reenviar2fa(Long desafioId) {
        Desafio2fa desafio = desafio2faRepository.findById(desafioId)
                .orElseThrow(() -> new IllegalArgumentException("Sessão de verificação expirada. Faça login."));

        Usuario usuario = usuarioRepository.findById(desafio.getUsuarioId())
                .orElseThrow(() -> new IllegalArgumentException("Sessão inválida."));

        String codigo = gerarCodigo6();
        desafio.setCodigoHash(SessaoService.hash(codigo));
        desafio.setTentativas(0);
        desafio.setExpiraEm(LocalDateTime.now().plus(DESAFIO_2FA_TTL));
        desafio2faRepository.save(desafio);

        emailService.enviarCodigo2fa(usuario.getEmail(), codigo);
        auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_SOLICITADO, "Código reenviado");
    }

    /**
     * Renova a sessão: valida o refresh token, rotaciona e devolve
     * novo access token JWT + novo refresh token.
     */
    @Transactional
    public AuthResponse refresh(String refreshToken, String userAgent) {
        String raw = refreshToken == null ? "" : refreshToken.trim();
        if (raw.isEmpty()) {
            throw new IllegalArgumentException("Sessão inválida. Faça login novamente.");
        }

        Usuario donoSessao = null;
        var sessao = sessaoService.buscarPorToken(raw);
        if (sessao != null) {
            donoSessao = usuarioRepository.findById(sessao.getUsuarioId()).orElse(null);
            if (donoSessao != null && !Boolean.TRUE.equals(donoSessao.getAtivo())) {
                sessaoService.revogarTodas(donoSessao.getId(), SessaoService.MOTIVO_CONTA_DESATIVADA);
                donoSessao = null;
            }
        }
        if (donoSessao == null) {
            throw new IllegalArgumentException("Sessão inválida. Faça login novamente.");
        }

        SessaoEmitida nova = sessaoService.rotacionar(raw, userAgent, donoSessao);
        auditoria.registrar(donoSessao, LogAuditoria.SESSAO_RENOVADA, "Refresh token rotacionado");

        String papel = Papel.from(donoSessao.getRole()).name();
        List<String> permissions = permissionService.getPermissionsForUser(donoSessao);
        String token = (permissions != null && !permissions.isEmpty())
                ? jwtUtil.generateToken(donoSessao.getEmail(), papel, permissions, donoSessao.getId(), donoSessao.getOficinaId())
                : jwtUtil.generateToken(donoSessao.getEmail(), papel, donoSessao.getId(), donoSessao.getOficinaId());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(nova.refreshToken())
                .email(donoSessao.getEmail())
                .nome(donoSessao.getNome())
                .role(papel)
                .permissions(permissions)
                .plano(donoSessao.getPlano())
                .build();
    }

    /**
     * Logout: revoga a sessão do refresh token informado.
     */
    @Transactional
    public void logout(String refreshToken) {
        sessaoService.revogar(refreshToken);
    }

    /**
     * Confirma o e-mail do usuário a partir do token de verificação.
     */
    @Transactional
    public void verifyEmail(String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Token de verificação inválido.");
        }

        Usuario usuario = usuarioRepository.findByVerificationToken(token.trim())
                .orElseThrow(() -> new IllegalArgumentException("Token de verificação inválido ou já utilizado."));

        usuario.setEmailVerificado(true);
        usuario.setVerificationToken(null);
        usuarioRepository.save(usuario);

        log.info("E-mail verificado com sucesso: {}", usuario.getEmail());
    }

    /**
     * Inicia o fluxo de recuperação de senha.
     */
    @Transactional
    public void forgotPassword(String rawEmail) {
        String email = rawEmail == null ? "" : rawEmail.toLowerCase().trim();

        usuarioRepository.findByEmail(email).ifPresentOrElse(usuario -> {
            String token = UUID.randomUUID().toString();
            usuario.setResetPasswordToken(token);
            usuario.setResetPasswordTokenExpiry(LocalDateTime.now().plus(RESET_TOKEN_TTL));
            usuarioRepository.save(usuario);

            emailService.enviarEmailRecuperacaoSenha(usuario.getEmail(), token);
            log.info("Solicitação de recuperação de senha registrada para {}", usuario.getEmail());
        }, () -> log.info("Recuperação de senha solicitada para e-mail não cadastrado (ignorado): {}", email));
    }

    /**
     * Reenvia o e-mail de verificação de cadastro.
     */
    @Transactional
    public void reenviarVerificacao(String rawEmail) {
        String email = rawEmail == null ? "" : rawEmail.toLowerCase().trim();

        usuarioRepository.findByEmail(email).ifPresentOrElse(usuario -> {
            if (Boolean.TRUE.equals(usuario.getEmailVerificado())) {
                log.info("Reenvio de verificação ignorado (já verificado): {}", email);
                return;
            }
            if (usuario.getVerificationToken() == null || usuario.getVerificationToken().isBlank()) {
                usuario.setVerificationToken(UUID.randomUUID().toString());
                usuarioRepository.save(usuario);
            }
            emailService.enviarEmailVerificacao(usuario.getEmail(), usuario.getVerificationToken());
            auditoria.registrar(usuario, LogAuditoria.EMAIL_VERIFICACAO_REENVIADO, null);
            log.info("E-mail de verificação reenviado para {}", email);
        }, () -> log.info("Reenvio de verificação para e-mail não cadastrado (ignorado): {}", email));
    }

    /**
     * Redefine a senha a partir do token de recuperação.
     */
    @Transactional
    public void resetPassword(String token, String novaSenha) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Token de redefinição inválido.");
        }
        if (novaSenha == null || novaSenha.length() < 8) {
            throw new IllegalArgumentException("A senha deve ter pelo menos 8 caracteres.");
        }

        Usuario usuario = usuarioRepository.findByResetPasswordToken(token.trim())
                .orElseThrow(() -> new IllegalArgumentException("Token de redefinição inválido ou já utilizado."));

        if (usuario.getResetPasswordTokenExpiry() == null
                || usuario.getResetPasswordTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("Token de redefinição expirado. Solicite uma nova recuperação de senha.");
        }

        usuario.setSenha(passwordEncoder.encode(novaSenha));
        usuario.setResetPasswordToken(null);
        usuario.setResetPasswordTokenExpiry(null);
        usuarioRepository.save(usuario);

        sessaoService.revogarTodas(usuario.getId(), SessaoService.MOTIVO_SENHA_ALTERADA);
        auditoria.registrar(usuario, LogAuditoria.SENHA_REDEFINIDA, "Senha redefinida por e-mail — sessões encerradas");

        log.info("Senha redefinida com sucesso para {}", usuario.getEmail());
    }

    // ==================== helpers internos ====================

    /**
     * Emite access token JWT + sessão com refresh token rotativo.
     */
    private AuthResponse emitirRespostaAutenticada(Usuario usuario, String userAgent) {
        String papel = Papel.from(usuario.getRole()).name();
        List<String> permissions = permissionService.getPermissionsForUser(usuario);
        String token = (permissions != null && !permissions.isEmpty())
                ? jwtUtil.generateToken(usuario.getEmail(), papel, permissions, usuario.getId(), usuario.getOficinaId())
                : jwtUtil.generateToken(usuario.getEmail(), papel, usuario.getId(), usuario.getOficinaId());
        SessaoEmitida sessao = sessaoService.criar(usuario, userAgent);

        return AuthResponse.builder()
                .token(token)
                .refreshToken(sessao.refreshToken())
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(papel)
                .permissions(permissions)
                .plano(usuario.getPlano())
                .build();
    }

    /**
     * Cria desafio 2FA e envia o código por e-mail (nenhum token emitido).
     */
    private AuthResponse iniciarDesafio2fa(Usuario usuario) {
        desafio2faRepository.deleteByUsuarioId(usuario.getId());

        String codigo = gerarCodigo6();
        Desafio2fa desafio = desafio2faRepository.save(Desafio2fa.builder()
                .usuarioId(usuario.getId())
                .codigoHash(SessaoService.hash(codigo))
                .expiraEm(LocalDateTime.now().plus(DESAFIO_2FA_TTL))
                .build());

        emailService.enviarCodigo2fa(usuario.getEmail(), codigo);
        auditoria.registrar(usuario, LogAuditoria.LOGIN_2FA_SOLICITADO, "Senha correta — código 2FA enviado");

        return AuthResponse.builder()
                .requer2fa(true)
                .sessao(desafio.getId())
                .email(usuario.getEmail())
                .message("Enviamos um código de verificação para o seu e-mail.")
                .build();
    }

    private String gerarCodigo6() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }
}
