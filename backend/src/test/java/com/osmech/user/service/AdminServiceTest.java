package com.osmech.user.service;

import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.sessao.service.SessaoService;
import com.osmech.user.dto.AdminDtos;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes das ações administrativas da plataforma (gap #8 da auditoria):
 * salvaguardas de ativação, alteração de plano e de papel.
 */
@ExtendWith(MockitoExtension.class)
class AdminServiceTest {

    @Mock private UsuarioRepository usuarioRepository;
    @Mock private OficinaRepository oficinaRepository;
    @Mock private SessaoService sessaoService;
    @Mock private AuditoriaService auditoria;

    @InjectMocks private AdminService adminService;

    private Usuario admin;

    @BeforeEach
    void setUp() {
        admin = Usuario.builder()
                .id(1L).nome("Admin").email("admin@osmech.com")
                .role("ADMIN").plano("PREMIUM").ativo(true).oficinaId(1L).build();
        lenientAdmin();
    }

    private void lenientAdmin() {
        when(usuarioRepository.findByEmail("admin@osmech.com")).thenReturn(Optional.of(admin));
    }

    private Usuario membro(Long id, String role, String plano, boolean ativo, Long oficinaId) {
        return Usuario.builder()
                .id(id).nome("User" + id).email("user" + id + "@x.com")
                .role(role).plano(plano).ativo(ativo).oficinaId(oficinaId).build();
    }

    // ---------- definirAtivo ----------

    @Test
    @DisplayName("inativar usuário comum revoga sessões e audita")
    void inativarComum() {
        Usuario alvo = membro(5L, "GERENTE", "PRO", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(alvo));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(i -> i.getArgument(0));

        AdminDtos.UsuarioAdmin dto = adminService.definirAtivo("admin@osmech.com", 5L, false);

        assertThat(dto.getAtivo()).isFalse();
        verify(sessaoService).revogarTodas(eq(5L), anyString());
        verify(auditoria).registrar(eq(admin), anyString(), anyString());
    }

    @Test
    @DisplayName("admin não pode inativar a própria conta")
    void naoInativaSiMesmo() {
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(admin));

        assertThatThrownBy(() -> adminService.definirAtivo("admin@osmech.com", 1L, false))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("própria conta");
        verify(sessaoService, never()).revogarTodas(any(), anyString());
    }

    @Test
    @DisplayName("não é permitido inativar outro ADMIN")
    void naoInativaOutroAdmin() {
        Usuario outroAdmin = membro(2L, "ADMIN", "PREMIUM", true, 2L);
        when(usuarioRepository.findById(2L)).thenReturn(Optional.of(outroAdmin));

        assertThatThrownBy(() -> adminService.definirAtivo("admin@osmech.com", 2L, false))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("administrador");
    }

    // ---------- definirPlano ----------

    @Test
    @DisplayName("alterar plano espelha para a oficina e todos os membros")
    void alterarPlanoEspelha() {
        Usuario alvo = membro(5L, "DONO", "FREE", true, 9L);
        Usuario colega = membro(6L, "MECANICO", "FREE", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(alvo));
        when(usuarioRepository.findAllByOficinaId(9L)).thenReturn(List.of(alvo, colega));
        when(oficinaRepository.findById(9L)).thenReturn(Optional.empty());
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(i -> i.getArgument(0));

        AdminDtos.UsuarioAdmin dto = adminService.definirPlano("admin@osmech.com", 5L, "pro_plus");

        assertThat(dto.getPlano()).isEqualTo("PRO_PLUS");
        assertThat(colega.getPlano()).isEqualTo("PRO_PLUS");
        verify(auditoria).registrar(eq(admin), anyString(), anyString());
    }

    @Test
    @DisplayName("plano inválido é rejeitado")
    void planoInvalido() {
        Usuario alvo = membro(5L, "DONO", "FREE", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(alvo));

        assertThatThrownBy(() -> adminService.definirPlano("admin@osmech.com", 5L, "OURO"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("inválido");
    }

    // ---------- definirPapel ----------

    @Test
    @DisplayName("alterar papel de membro comum funciona")
    void alterarPapelOk() {
        Usuario alvo = membro(5L, "MECANICO", "PRO", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(alvo));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(i -> i.getArgument(0));

        AdminDtos.UsuarioAdmin dto = adminService.definirPapel("admin@osmech.com", 5L, "GERENTE");

        assertThat(dto.getRole()).isEqualTo("GERENTE");
    }

    @Test
    @DisplayName("não é possível rebaixar o DONO da oficina")
    void naoAlteraDono() {
        Usuario dono = membro(5L, "DONO", "PRO", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(dono));

        assertThatThrownBy(() -> adminService.definirPapel("admin@osmech.com", 5L, "MECANICO"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("DONO");
    }

    @Test
    @DisplayName("não é possível promover ninguém a ADMIN ou DONO")
    void naoPromoveAdmin() {
        Usuario alvo = membro(5L, "MECANICO", "PRO", true, 9L);
        when(usuarioRepository.findById(5L)).thenReturn(Optional.of(alvo));

        assertThatThrownBy(() -> adminService.definirPapel("admin@osmech.com", 5L, "ADMIN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("não atribuível");
    }
}
