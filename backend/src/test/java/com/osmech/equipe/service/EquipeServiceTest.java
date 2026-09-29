package com.osmech.equipe.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.equipe.dto.EquipeDtos.AceitarConviteRequest;
import com.osmech.equipe.dto.EquipeDtos.ConvidarUsuarioRequest;
import com.osmech.equipe.entity.ConviteEquipe;
import com.osmech.equipe.repository.ConviteEquipeRepository;
import com.osmech.notification.service.EmailService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.security.JwtUtil;
import com.osmech.sessao.service.SessaoService;
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
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes do EquipeService: convites (regras + limite do plano) e aceite.
 */
@ExtendWith(MockitoExtension.class)
class EquipeServiceTest {

    @Mock private UsuarioRepository usuarioRepository;
    @Mock private OficinaRepository oficinaRepository;
    @Mock private ConviteEquipeRepository conviteRepository;
    @Mock private PlanoRepository planoRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private EmailService emailService;
    @Mock private JwtUtil jwtUtil;
    @Mock private SessaoService sessaoService;
    @Mock private AuditoriaService auditoria;

    @InjectMocks
    private EquipeService equipeService;

    private Usuario dono;
    private Oficina oficina;

    @BeforeEach
    void setUp() {
        dono = Usuario.builder()
                .id(1L).nome("Dono").email("dono@oficina.com").senha("hash")
                .telefone("11999998888").role("DONO").plano("PRO").ativo(true)
                .oficinaId(7L).build();
        oficina = Oficina.builder()
                .id(7L).nome("Oficina do Zé").plano("PRO").build();
    }

    private ConvidarUsuarioRequest novoConvite(String email, String papel) {
        ConvidarUsuarioRequest req = new ConvidarUsuarioRequest();
        req.setEmail(email);
        req.setPapel(papel);
        return req;
    }

    @Test
    @DisplayName("convidar cria token, vincula à oficina e envia e-mail")
    void convidarSucesso() {
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(dono));
        when(usuarioRepository.findByEmail("ana@email.com")).thenReturn(Optional.empty());
        when(conviteRepository.existsByOficinaIdAndEmailAndStatus(7L, "ana@email.com", "PENDENTE"))
                .thenReturn(false);
        when(oficinaRepository.findById(7L)).thenReturn(Optional.of(oficina));
        when(planoRepository.findByCodigo("PRO"))
                .thenReturn(Optional.of(Plano.builder().codigo("PRO").limiteUsuarios(6).build()));
        when(usuarioRepository.countByOficinaIdAndAtivoTrue(7L)).thenReturn(1L);
        when(conviteRepository.countByOficinaIdAndStatus(7L, "PENDENTE")).thenReturn(0L);
        when(conviteRepository.save(any(ConviteEquipe.class))).thenAnswer(inv -> inv.getArgument(0));

        var resp = equipeService.convidar("dono@oficina.com", novoConvite("Ana@Email.com ", "gerente"));

        ArgumentCaptor<ConviteEquipe> captor = ArgumentCaptor.forClass(ConviteEquipe.class);
        verify(conviteRepository).save(captor.capture());
        ConviteEquipe salvo = captor.getValue();
        assertThat(salvo.getEmail()).isEqualTo("ana@email.com");
        assertThat(salvo.getPapel()).isEqualTo("GERENTE");
        assertThat(salvo.getOficinaId()).isEqualTo(7L);
        assertThat(salvo.getToken()).isNotBlank();
        assertThat(salvo.getExpiraEm()).isAfter(LocalDateTime.now().plusDays(6));

        verify(emailService).enviarEmailConvite(anyString(), anyString(), anyString(), anyString());
        assertThat(resp.getId()).isEqualTo(salvo.getId());
    }

    @Test
    @DisplayName("convidar deve rejeitar papel não convidável (DONO/ADMIN)")
    void convidarPapelInvalido() {
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(dono));

        assertThatThrownBy(() -> equipeService.convidar("dono@oficina.com", novoConvite("a@b.com", "ADMIN")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Papel inválido");

        verify(conviteRepository, never()).save(any());
    }

    @Test
    @DisplayName("convidar deve rejeitar e-mail já vinculado a OUTRA oficina")
    void convidarEmailDeOutraOficina() {
        Usuario deOutra = Usuario.builder().id(9L).email("jose@email.com").oficinaId(99L).build();
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(dono));
        when(usuarioRepository.findByEmail("jose@email.com")).thenReturn(Optional.of(deOutra));

        assertThatThrownBy(() -> equipeService.convidar("dono@oficina.com", novoConvite("jose@email.com", "MECANICO")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("outra oficina");
    }

    @Test
    @DisplayName("convidar deve cobrar o limite de usuários do plano (ativos + pendentes >= limite)")
    void convidarLimitePlano() {
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(dono));
        when(usuarioRepository.findByEmail("ana@email.com")).thenReturn(Optional.empty());
        when(conviteRepository.existsByOficinaIdAndEmailAndStatus(7L, "ana@email.com", "PENDENTE"))
                .thenReturn(false);
        when(oficinaRepository.findById(7L)).thenReturn(Optional.of(oficina));
        when(planoRepository.findByCodigo("PRO"))
                .thenReturn(Optional.of(Plano.builder().codigo("PRO").limiteUsuarios(2).build()));
        when(usuarioRepository.countByOficinaIdAndAtivoTrue(7L)).thenReturn(1L);
        when(conviteRepository.countByOficinaIdAndStatus(7L, "PENDENTE")).thenReturn(1L);

        assertThatThrownBy(() -> equipeService.convidar("dono@oficina.com", novoConvite("ana@email.com", "ATENDENTE")))
                .isInstanceOf(LimiteEquipeException.class)
                .hasMessageContaining("Limite de 2 usuário(s)");

        verify(conviteRepository, never()).save(any());
    }

    @Test
    @DisplayName("aceitarConvite cria usuário vinculado, marca ACEITO e devolve JWT")
    void aceitarSucesso() {
        ConviteEquipe convite = ConviteEquipe.builder()
                .id(5L).oficinaId(7L).email("ana@email.com").papel("MECANICO")
                .token("tok").status(ConviteEquipe.STATUS_PENDENTE)
                .expiraEm(LocalDateTime.now().plusDays(3)).build();

        AceitarConviteRequest req = new AceitarConviteRequest();
        req.setToken("tok");
        req.setNome("Ana");
        req.setTelefone("11977776666");
        req.setSenha("senhaForte1");

        when(conviteRepository.findByToken("tok")).thenReturn(Optional.of(convite));
        when(usuarioRepository.findByEmail("ana@email.com")).thenReturn(Optional.empty());
        when(oficinaRepository.findById(7L)).thenReturn(Optional.of(oficina));
        when(planoRepository.findByCodigo("PRO"))
                .thenReturn(Optional.of(Plano.builder().codigo("PRO").limiteUsuarios(6).build()));
        when(usuarioRepository.countByOficinaIdAndAtivoTrue(7L)).thenReturn(1L);
        when(conviteRepository.countByOficinaIdAndStatus(7L, "PENDENTE")).thenReturn(0L);
        when(passwordEncoder.encode("senhaForte1")).thenReturn("hash-novo");
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> {
            Usuario u = inv.getArgument(0);
            u.setId(50L);
            return u;
        });
        when(jwtUtil.generateToken("ana@email.com", "MECANICO", 50L, 7L)).thenReturn("jwt-novo");
        when(sessaoService.criar(any(Usuario.class), any()))
                .thenReturn(new SessaoService.SessaoEmitida("refresh-novo", null));

        AuthResponse resp = equipeService.aceitarConvite(req);

        assertThat(resp.getToken()).isEqualTo("jwt-novo");
        assertThat(resp.getRefreshToken()).isEqualTo("refresh-novo");
        assertThat(resp.getRole()).isEqualTo("MECANICO");
        assertThat(convite.getStatus()).isEqualTo(ConviteEquipe.STATUS_ACEITO);
        assertThat(convite.getAceitoEm()).isNotNull();

        ArgumentCaptor<Usuario> captor = ArgumentCaptor.forClass(Usuario.class);
        verify(usuarioRepository).save(captor.capture());
        assertThat(captor.getValue().getOficinaId()).isEqualTo(7L);
        assertThat(captor.getValue().getEmailVerificado()).isTrue();
    }

    @Test
    @DisplayName("aceitarConvite deve rejeitar token expirado (marca EXPIRADO)")
    void aceitarExpirado() {
        ConviteEquipe convite = ConviteEquipe.builder()
                .oficinaId(7L).email("ana@email.com").papel("MECANICO")
                .token("tok").status(ConviteEquipe.STATUS_PENDENTE)
                .expiraEm(LocalDateTime.now().minusDays(1)).build();

        AceitarConviteRequest req = new AceitarConviteRequest();
        req.setToken("tok");
        req.setNome("Ana");
        req.setTelefone("11977776666");
        req.setSenha("senhaForte1");

        when(conviteRepository.findByToken("tok")).thenReturn(Optional.of(convite));

        assertThatThrownBy(() -> equipeService.aceitarConvite(req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expirou");
        assertThat(convite.getStatus()).isEqualTo(ConviteEquipe.STATUS_EXPIRADO);
    }

    @Test
    @DisplayName("alterarStatus não pode desativar o último DONO ativo")
    void ultimoDonoProtegido() {
        when(usuarioRepository.findByEmail("dono@oficina.com")).thenReturn(Optional.of(dono));
        Usuario outro = Usuario.builder().id(2L).email("x@x.com").role("GERENTE")
                .oficinaId(7L).ativo(true).build();
        // alvo é outro DONO (id 3) da mesma oficina; dono (id 1) também é DONO ativo
        Usuario alvoDono = Usuario.builder().id(3L).email("y@y.com").role("DONO")
                .oficinaId(7L).ativo(true).build();
        when(usuarioRepository.findByIdAndOficinaId(3L, 7L)).thenReturn(Optional.of(alvoDono));
        when(usuarioRepository.findAllByOficinaId(7L)).thenReturn(List.of(alvoDono));

        var req = new com.osmech.equipe.dto.EquipeDtos.AlterarStatusRequest();
        req.setAtivo(false);

        assertThatThrownBy(() -> equipeService.alterarStatus("dono@oficina.com", 3L, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ao menos um DONO ativo");

        verify(usuarioRepository, never()).save(any());
    }
}
