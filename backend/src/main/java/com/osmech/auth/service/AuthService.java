package com.osmech.auth.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.security.JwtUtil;
import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Serviço responsável por autenticação e cadastro de usuários.
 *
 * Fluxos suportados:
 *  - Cadastro com verificação de e-mail (token UUID enviado via EmailService);
 *  - Login com checagem de senha + conta ativa (+ e-mail verificado quando
 *    app.auth.require-verified-email=true);
 *  - Recuperação de senha com token de 1 hora, sem vazar se o e-mail existe;
 *  - Redefinição de senha com invalidação do token após o uso.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    /** Validade do token de recuperação de senha */
    private static final Duration RESET_TOKEN_TTL = Duration.ofHours(1);

    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final EmailService emailService;

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

        // Validação básica de tamanho de e-mail
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

        // Cria o usuário com senha criptografada e aguardando verificação de e-mail
        Usuario usuario = Usuario.builder()
                .nome(request.getNome())
                .email(email)
                .senha(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone())
                .nomeOficina(request.getNomeOficina())
                .role(Papel.OFICINA.name())
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
                .message("Cadastro realizado! Enviamos um link de verificação para o seu e-mail.")
                .build();
    }

    /**
     * Realiza o login do usuário.
     */
    public AuthResponse login(LoginRequest request) {
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail().toLowerCase().trim())
                .orElse(null);

        if (usuario == null || !passwordEncoder.matches(request.getSenha(), usuario.getSenha())) {
            throw new BadCredentialsException("E-mail ou senha incorretos.");
        }

        // Conta desativada não entra (antes, só falhava no filtro após emitir o token)
        if (!Boolean.TRUE.equals(usuario.getAtivo())) {
            throw new DisabledException("Sua conta está desativada. Fale com o suporte.");
        }

        if (requireVerifiedEmail && !Boolean.TRUE.equals(usuario.getEmailVerificado())) {
            throw new DisabledException("Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.");
        }

        String papel = Papel.from(usuario.getRole()).name();

        // Gera token JWT com claims "uid" (usuário) e "oid" (oficina/tenant)
        String token = jwtUtil.generateToken(usuario.getEmail(), papel, usuario.getId(), usuario.getOficinaId());

        return AuthResponse.builder()
                .token(token)
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(papel)
                .plano(usuario.getPlano())
                .build();
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
     * Responde com sucesso MESMO quando o e-mail não existe (não vaza contas).
     * Quem envia failure responses diferentes por conta existente facilita enumeração.
     */
    @Transactional
    public void forgotPassword(String rawEmail) {
        String email = rawEmail == null ? "" : rawEmail.toLowerCase().trim();

        usuarioRepository.findByEmail(email).ifPresentOrElse(usuario -> {
            usuario.setResetPasswordToken(UUID.randomUUID().toString());
            usuario.setResetPasswordTokenExpiry(LocalDateTime.now().plus(RESET_TOKEN_TTL));
            usuarioRepository.save(usuario);

            emailService.enviarEmailRecuperacaoSenha(usuario.getEmail(), usuario.getResetPasswordToken());
            log.info("Solicitação de recuperação de senha registrada para {}", usuario.getEmail());
        }, () -> log.info("Recuperação de senha solicitada para e-mail não cadastrado (ignorado): {}", email));
    }

    /**
     * Redefine a senha a partir do token de recuperação.
     * O token é de uso único e expira em 1 hora.
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

        log.info("Senha redefinida com sucesso para {}", usuario.getEmail());
    }
}
