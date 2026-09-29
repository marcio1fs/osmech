package com.osmech.auth.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.security.JwtUtil;
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
                .role("OFICINA")
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
        assertThat(salvo.getRole()).isEqualTo("OFICINA");
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
        when(jwtUtil.generateToken("dono@oficina.com", "OFICINA", 42L, 7L)).thenReturn("jwt-token");

        AuthResponse resp = authService.login(req);

        assertThat(resp.getToken()).isEqualTo("jwt-token");
        assertThat(resp.getRole()).isEqualTo("OFICINA");
        assertThat(resp.getPlano()).isEqualTo("FREE");
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

        assertThatThrownBy(() -> authService.login(req))
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

        assertThatThrownBy(() -> authService.login(req))
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
}
