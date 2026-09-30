package com.osmech.auth.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.auth.repository.Desafio2faRepository;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.security.JwtUtil;
import com.osmech.sessao.service.SessaoService;
import com.osmech.sessao.service.SessaoService.SessaoEmitida;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes unitários dos fluxos de autenticação implementados na Fase 0:
 * verificação de e-mail, recuperação/redefinição de senha e bloqueios de login.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private OficinaRepository oficinaRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private EmailService emailService;

    @Mock
    private Desafio2faRepository desafio2faRepository;

    @Mock
    private SessaoService sessaoService;

    @Mock
    private AuditoriaService auditoria;

    @InjectMocks
    private AuthService authService;

    private Usuario usuarioAtivo;

    @BeforeEach
    void setUp() {
        usuarioAtivo = Usuario.builder()
                .id(42L)
                .nome("Oficina Teste")
                .email("dono@oficina.com")
                .senha("hash-bcrypt")
                .telefone("11999998888")
                .role("DONO")
                .plano("FREE")
                .ativo(true)
                .emailVerificado(false)
                .oficinaId(7L)
                .build();
    }

    // ---------- register ----------

    @Test
    @DisplayName("register deve criar a oficina (tenant), gravar token de verificação e disparar o e-mail")
    void registerEnviaVerificacao() {
        RegisterRequest req = new RegisterRequest();
        req.setNome("Dono");
        req.setEmail("NOVO@Oficina.com ");
        req.setSenha("senha123");
        req.setTelefone("11999998888");
        req.setNomeOficina("Oficina do Zé");

        when(usuarioRepository.existsByEmail("novo@oficina.com")).thenReturn(false);
        when(passwordEncoder.encode("senha123")).thenReturn("hash-bcrypt");
        when(oficinaRepository.save(any(Oficina.class))).thenAnswer(inv -> {
            Oficina o = inv.getArgument(0);
            o.setId(7L);
            return o;
        });

        AuthResponse resp = authService.register(req);

        ArgumentCaptor<Oficina> oficinaCaptor = ArgumentCaptor.forClass(Oficina.class);
        verify(oficinaRepository).save(oficinaCaptor.capture());
        Oficina oficinaSalva = oficinaCaptor.getValue();
        assertThat(oficinaSalva.getNome()).isEqualTo("Oficina do Zé");
        assertThat(oficinaSalva.getEmail()).isEqualTo("novo@oficina.com");
        assertThat(oficinaSalva.getPlano()).isEqualTo("FREE");

        ArgumentCaptor<Usuario> captor = ArgumentCaptor.forClass(Usuario.class);
        verify(usuarioRepository).save(captor.capture());
        Usuario salvo = captor.getValue();

        assertThat(salvo.getEmail()).isEqualTo("novo@oficina.com");
        assertThat(salvo.getRole()).isEqualTo("DONO");
        assertThat(salvo.getOficinaId()).isEqualTo(7L);
        assertThat(salvo.getEmailVerificado()).isFalse();
        assertThat(salvo.getVerificationToken()).isNotBlank();

        verify(emailService).enviarEmailVerificacao(anyString(), anyString());
        assertThat(resp.getToken()).isNull();
        assertThat(resp.getEmail()).isEqualTo("novo@oficina.com");
    }

    // ---------- login ----------

    @Test
    @DisplayName("login deve gerar token com claims uid e oid quando credenciais válidas")
    void loginSucesso() {
        LoginRequest req = new LoginRequest();
        req.setEmail("dono@oficina.com");
        req.setSenha("senha123");

        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));
        when(passwordEncoder.matches("senha123", "hash-bcrypt")).thenReturn(true);
        when(jwtUtil.generateToken("dono@oficina.com", "DONO", 42L, 7L)).thenReturn("jwt-token");
        when(sessaoService.criar(any(Usuario.class), any()))
                .thenReturn(new SessaoEmitida("refresh-token", usuarioAtivo));

        AuthResponse resp = authService.login(req, "agente-teste");

        assertThat(resp.getToken()).isEqualTo("jwt-token");
        assertThat(resp.getRefreshToken()).isEqualTo("refresh-token");
        assertThat(resp.getRole()).isEqualTo("DONO");
        assertThat(resp.getPlano()).isEqualTo("FREE");
        verify(auditoria).registrar(any(Usuario.class),
                org.mockito.ArgumentMatchers.eq(com.osmech.auditoria.entity.LogAuditoria.LOGIN), any());
    }

    @Test
    @DisplayName("login com 2FA ativo deve emitir desafio e enviar código, SEM tokens")
    void loginRequer2fa() {
        usuarioAtivo.setDoisFaAtivo(true);
        LoginRequest req = new LoginRequest();
        req.setEmail("dono@oficina.com");
        req.setSenha("senha123");

        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));
        when(passwordEncoder.matches("senha123", "hash-bcrypt")).thenReturn(true);
        when(desafio2faRepository.save(any(com.osmech.auth.entity.Desafio2fa.class))).thenAnswer(inv -> {
            var d = inv.getArgument(0, com.osmech.auth.entity.Desafio2fa.class);
            d.setId(99L);
            return d;
        });

        AuthResponse resp = authService.login(req, null);

        assertThat(resp.getToken()).isNull();
        assertThat(resp.getRequer2fa()).isTrue();
        assertThat(resp.getSessao()).isEqualTo(99L);
        verify(emailService).enviarCodigo2fa(anyString(), anyString());
        verify(sessaoService, never()).criar(any(), any());
    }

    @Test
    @DisplayName("refresh deve rotacionar o refresh token e devolver novo JWT")
    void refreshSucesso() {
        var sessao = com.osmech.sessao.entity.SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash("h").expiraEm(LocalDateTime.now().plusDays(30)).build();

        when(sessaoService.buscarPorToken("tok-antigo")).thenReturn(sessao);
        when(usuarioRepository.findById(42L)).thenReturn(Optional.of(usuarioAtivo));
        when(sessaoService.rotacionar(org.mockito.ArgumentMatchers.eq("tok-antigo"), any(), any(Usuario.class)))
                .thenReturn(new SessaoEmitida("tok-novo", usuarioAtivo));
        when(jwtUtil.generateToken("dono@oficina.com", "DONO", 42L, 7L)).thenReturn("jwt-novo");

        AuthResponse resp = authService.refresh("tok-antigo", "agente");

        assertThat(resp.getToken()).isEqualTo("jwt-novo");
        assertThat(resp.getRefreshToken()).isEqualTo("tok-novo");
    }

    @Test
    @DisplayName("refresh deve rejeitar sessão de usuário desativado (revoga tudo)")
    void refreshUsuarioDesativado() {
        usuarioAtivo.setAtivo(false);
        var sessao = com.osmech.sessao.entity.SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash("h").expiraEm(LocalDateTime.now().plusDays(30)).build();

        when(sessaoService.buscarPorToken("tok-antigo")).thenReturn(sessao);
        when(usuarioRepository.findById(42L)).thenReturn(Optional.of(usuarioAtivo));

        assertThatThrownBy(() -> authService.refresh("tok-antigo", null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Sessão inválida");

        verify(sessaoService).revogarTodas(42L, "CONTA_DESATIVADA");
        verify(sessaoService, never()).rotacionar(anyString(), any(), any());
    }

    @Test
    @DisplayName("login deve rejeitar conta desativada (mesmo com senha correta)")
    void loginContaDesativada() {
        usuarioAtivo.setAtivo(false);
        LoginRequest req = new LoginRequest();
        req.setEmail("dono@oficina.com");
        req.setSenha("senha123");

        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));
        when(passwordEncoder.matches("senha123", "hash-bcrypt")).thenReturn(true);

        assertThatThrownBy(() -> authService.login(req, null))
                .isInstanceOf(DisabledException.class)
                .hasMessageContaining("desativada");
    }

    @Test
    @DisplayName("login deve rejeitar senha incorreta com BadCredentials")
    void loginSenhaIncorreta() {
        LoginRequest req = new LoginRequest();
        req.setEmail("dono@oficina.com");
        req.setSenha("errada");

        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));
        when(passwordEncoder.matches("errada", "hash-bcrypt")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(req, null))
                .isInstanceOf(BadCredentialsException.class);
    }

    // ---------- verifyEmail ----------

    @Test
    @DisplayName("verifyEmail deve marcar emailVerificado e limpar o token")
    void verifyEmailSucesso() {
        usuarioAtivo.setVerificationToken("tok-123");
        when(usuarioRepository.findByVerificationToken("tok-123")).thenReturn(Optional.of(usuarioAtivo));

        authService.verifyEmail("tok-123");

        assertThat(usuarioAtivo.getEmailVerificado()).isTrue();
        assertThat(usuarioAtivo.getVerificationToken()).isNull();
        verify(usuarioRepository).save(usuarioAtivo);
    }

    @Test
    @DisplayName("verifyEmail deve rejeitar token desconhecido")
    void verifyEmailTokenInvalido() {
        when(usuarioRepository.findByVerificationToken("zzz")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.verifyEmail("zzz"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("inválido");
    }

    // ---------- forgotPassword ----------

    @Test
    @DisplayName("forgotPassword com e-mail desconhecido não deve falhar nem enviar e-mail (anti-enumeração)")
    void forgotPasswordEmailDesconhecido() {
        when(usuarioRepository.findByEmail("ghost@oficina.com")).thenReturn(Optional.empty());

        authService.forgotPassword("Ghost@Oficina.com ");

        verify(usuarioRepository, never()).save(any());
        verify(emailService, never()).enviarEmailRecuperacaoSenha(anyString(), anyString());
    }

    @Test
    @DisplayName("forgotPassword deve gerar token com expiração de ~1h e enviar e-mail")
    void forgotPasswordGeraToken() {
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));

        authService.forgotPassword("dono@oficina.com");

        assertThat(usuarioAtivo.getResetPasswordToken()).isNotBlank();
        assertThat(usuarioAtivo.getResetPasswordTokenExpiry())
                .isAfter(LocalDateTime.now().plusMinutes(50))
                .isBefore(LocalDateTime.now().plusMinutes(70));
        verify(usuarioRepository).save(usuarioAtivo);
        verify(emailService).enviarEmailRecuperacaoSenha(
                org.mockito.ArgumentMatchers.eq("dono@oficina.com"), anyString());
    }

    // ---------- resetPassword ----------

    @Test
    @DisplayName("resetPassword deve trocar a senha e invalidar o token (uso único)")
    void resetPasswordSucesso() {
        usuarioAtivo.setResetPasswordToken("tok-reset");
        usuarioAtivo.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(30));

        when(usuarioRepository.findByResetPasswordToken("tok-reset")).thenReturn(Optional.of(usuarioAtivo));
        when(passwordEncoder.encode("novaSenha8")).thenReturn("hash-novo");

        authService.resetPassword("tok-reset", "novaSenha8");

        assertThat(usuarioAtivo.getSenha()).isEqualTo("hash-novo");
        assertThat(usuarioAtivo.getResetPasswordToken()).isNull();
        assertThat(usuarioAtivo.getResetPasswordTokenExpiry()).isNull();
        verify(usuarioRepository).save(usuarioAtivo);
        verify(sessaoService).revogarTodas(42L, "SENHA_ALTERADA");
    }

    @Test
    @DisplayName("resetPassword deve rejeitar token expirado")
    void resetPasswordExpirado() {
        usuarioAtivo.setResetPasswordToken("tok-reset");
        usuarioAtivo.setResetPasswordTokenExpiry(LocalDateTime.now().minusMinutes(5));

        when(usuarioRepository.findByResetPasswordToken("tok-reset")).thenReturn(Optional.of(usuarioAtivo));

        assertThatThrownBy(() -> authService.resetPassword("tok-reset", "novaSenha8"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expirado");

        verify(usuarioRepository, never()).save(any());
    }

    @Test
    @DisplayName("resetPassword deve rejeitar senha curta mesmo com token válido")
    void resetPasswordSenhaCurta() {
        assertThatThrownBy(() -> authService.resetPassword("tok-reset", "123"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("8 caracteres");
    }

    // ---------- reenviarVerificacao ----------

    @Test
    @DisplayName("reenviarVerificacao deve mandar novo e-mail para conta NÃO verificada")
    void reenviarVerificacaoContaNaoVerificada() {
        usuarioAtivo.setEmailVerificado(false);
        usuarioAtivo.setVerificationToken(null);
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));

        authService.reenviarVerificacao("Dono@Oficina.com ");

        // Token novo gerado (era null) e e-mail reenviado
        assertThat(usuarioAtivo.getVerificationToken()).isNotBlank();
        verify(usuarioRepository).save(usuarioAtivo);
        verify(emailService).enviarEmailVerificacao(anyString(), anyString());
    }

    @Test
    @DisplayName("reenviarVerificacao ignora conta já verificada (sem e-mail)")
    void reenviarVerificacaoContaJaVerificada() {
        usuarioAtivo.setEmailVerificado(true);
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(usuarioAtivo));

        authService.reenviarVerificacao("dono@oficina.com");

        verify(emailService, never()).enviarEmailVerificacao(anyString(), anyString());
    }

    @Test
    @DisplayName("reenviarVerificacao com e-mail desconhecido não falha (anti-enumeração)")
    void reenviarVerificacaoEmailDesconhecido() {
        when(usuarioRepository.findByEmail("ghost@oficina.com")).thenReturn(Optional.empty());

        authService.reenviarVerificacao("ghost@oficina.com");

        verify(emailService, never()).enviarEmailVerificacao(anyString(), anyString());
    }
}
