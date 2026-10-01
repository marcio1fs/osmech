package com.osmech.sessao.service;

import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.sessao.entity.SessaoUsuario;
import com.osmech.sessao.repository.SessaoUsuarioRepository;
import com.osmech.user.entity.Usuario;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes do SessaoService (Fase 4): criação, rotação, reuse detection,
 * expiração e revogação de sessões com refresh token.
 */
@ExtendWith(MockitoExtension.class)
class SessaoServiceTest {

    @Mock
    private SessaoUsuarioRepository repository;

    @Mock
    private AuditoriaService auditoria;

    @InjectMocks
    private SessaoService sessaoService;

    private Usuario usuario;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(sessaoService, "refreshDias", 30);
        usuario = Usuario.builder()
                .id(42L).nome("Dono").email("dono@oficina.com")
                .senha("hash").telefone("11999998888")
                .role("DONO").plano("FREE").ativo(true)
                .oficinaId(7L).build();
    }

    @Test
    @DisplayName("criar deve gravar APENAS o hash SHA-256 e expiração de ~30 dias")
    void criarGravaHash() {
        when(repository.save(any(SessaoUsuario.class))).thenAnswer(inv -> inv.getArgument(0));

        var emitida = sessaoService.criar(usuario, "Mozilla/5.0");

        assertThat(emitida.refreshToken()).hasSize(64);
        assertThat(emitida.usuario()).isSameAs(usuario);

        ArgumentCaptor<SessaoUsuario> captor = ArgumentCaptor.forClass(SessaoUsuario.class);
        verify(repository).save(captor.capture());
        SessaoUsuario salva = captor.getValue();
        assertThat(salva.getRefreshTokenHash())
                .isEqualTo(SessaoService.hash(emitida.refreshToken()))
                .hasSize(64);
        assertThat(salva.getRefreshTokenHash()).isNotEqualTo(emitida.refreshToken());
        assertThat(salva.getExpiraEm()).isAfter(LocalDateTime.now().plusDays(29));
        assertThat(salva.getUserAgent()).isEqualTo("Mozilla/5.0");

        // Higiene de sessões velhas roda junto
        verify(repository).deleteByUsuarioIdAndExpiraEmBefore(eq(42L), any(LocalDateTime.class));
    }

    @Test
    @DisplayName("rotacionar deve revogar o token antigo (ROTACAO) e emitir um novo")
    void rotacionarSucesso() {
        String tokenAntigo = "a".repeat(64);
        SessaoUsuario sessao = SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash(SessaoService.hash(tokenAntigo))
                .expiraEm(LocalDateTime.now().plusDays(10))
                .build();
        when(repository.findByRefreshTokenHash(SessaoService.hash(tokenAntigo)))
                .thenReturn(Optional.of(sessao));
        when(repository.save(any(SessaoUsuario.class))).thenAnswer(inv -> inv.getArgument(0));

        var nova = sessaoService.rotacionar(tokenAntigo, "agente", usuario);

        assertThat(nova.refreshToken()).isNotEqualTo(tokenAntigo);
        assertThat(sessao.getRevogadoEm()).isNotNull();
        assertThat(sessao.getMotivoRevogacao()).isEqualTo(SessaoUsuario.MOTIVO_ROTACAO);
    }

    @Test
    @DisplayName("reapresentar token já rotacionado revoga TODAS as sessões (reuse detection)")
    void rotacionarReusoDetectado() {
        String tokenMorto = "b".repeat(64);
        SessaoUsuario sessaoMorta = SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash(SessaoService.hash(tokenMorto))
                .expiraEm(LocalDateTime.now().plusDays(10))
                .revogadoEm(LocalDateTime.now().minusMinutes(5))
                .motivoRevogacao(SessaoUsuario.MOTIVO_ROTACAO)
                .build();
        SessaoUsuario outraAtiva = SessaoUsuario.builder()
                .id(2L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash("outro")
                .expiraEm(LocalDateTime.now().plusDays(10))
                .build();

        when(repository.findByRefreshTokenHash(SessaoService.hash(tokenMorto)))
                .thenReturn(Optional.of(sessaoMorta));
        when(repository.findByUsuarioIdAndRevogadoEmIsNull(42L))
                .thenReturn(List.of(outraAtiva));
        when(repository.save(any(SessaoUsuario.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThatThrownBy(() -> sessaoService.rotacionar(tokenMorto, "agente", usuario))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("reutilizada");

        // A outra sessão ativa também foi encerrada por segurança
        assertThat(outraAtiva.getRevogadoEm()).isNotNull();
        assertThat(outraAtiva.getMotivoRevogacao()).isEqualTo(SessaoUsuario.MOTIVO_REUSO_DETECTADO);

        ArgumentCaptor<String> acaoCaptor = ArgumentCaptor.forClass(String.class);
        verify(auditoria).registrar(eq(usuario), acaoCaptor.capture(), any());
        assertThat(acaoCaptor.getValue()).isEqualTo(LogAuditoria.SESSAO_REUSO_DETECTADO);
    }

    @Test
    @DisplayName("token apenas EXPIRADO rejeita sem derrubar as outras sessões")
    void rotacionarExpiradaSemCarvarGuilhotina() {
        String tokenVelho = "c".repeat(64);
        SessaoUsuario sessaoVelha = SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash(SessaoService.hash(tokenVelho))
                .expiraEm(LocalDateTime.now().minusDays(1)) // expirada, nunca revogada
                .build();
        when(repository.findByRefreshTokenHash(SessaoService.hash(tokenVelho)))
                .thenReturn(Optional.of(sessaoVelha));
        when(repository.save(any(SessaoUsuario.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThatThrownBy(() -> sessaoService.rotacionar(tokenVelho, "agente", usuario))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expirada");

        assertThat(sessaoVelha.getMotivoRevogacao()).isEqualTo(SessaoUsuario.MOTIVO_EXPIRADA);
        verify(repository, never()).findByUsuarioIdAndRevogadoEmIsNull(any());
    }

    @Test
    @DisplayName("token desconhecido ou de outro usuário → sessão inválida")
    void rotacionarTokenDesconhecido() {
        when(repository.findByRefreshTokenHash(any(String.class))).thenReturn(Optional.empty());

        assertThatThrownBy(() -> sessaoService.rotacionar("x".repeat(64), null, usuario))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Sessão inválida");
    }

    @Test
    @DisplayName("revogar (logout) marca a sessão como LOGOUT")
    void revogarLogout() {
        String token = "d".repeat(64);
        SessaoUsuario sessao = SessaoUsuario.builder()
                .id(1L).usuarioId(42L).oficinaId(7L)
                .refreshTokenHash(SessaoService.hash(token))
                .expiraEm(LocalDateTime.now().plusDays(10))
                .build();
        when(repository.findByRefreshTokenHash(SessaoService.hash(token)))
                .thenReturn(Optional.of(sessao));

        sessaoService.revogar(token);

        assertThat(sessao.getRevogadoEm()).isNotNull();
        assertThat(sessao.getMotivoRevogacao()).isEqualTo(SessaoUsuario.MOTIVO_LOGOUT);
    }

    @Test
    @DisplayName("hash deve ser determinístico, 64 hex chars")
    void hashDeterministico() {
        String h1 = SessaoService.hash("token-abc");
        String h2 = SessaoService.hash("token-abc");
        assertThat(h1).isEqualTo(h2).hasSize(64);
        assertThat(SessaoService.hash("token-abc")).isNotEqualTo(SessaoService.hash("token-abd"));
    }
}
