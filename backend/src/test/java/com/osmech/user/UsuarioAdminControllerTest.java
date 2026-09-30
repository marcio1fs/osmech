package com.osmech.user;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.osmech.audit.AuditService;
import com.osmech.rbac.PermissionService;
import com.osmech.security.JwtUtil;
import com.osmech.user.controller.UsuariosAdminController;
import com.osmech.user.dto.UsuarioAdminRequest;
import com.osmech.user.dto.UsuarioAdminResponse;
import com.osmech.user.repository.UsuarioRepository;
import com.osmech.user.service.UsuarioAdminService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.osmech.config.RateLimitFilter;
import com.osmech.config.SecurityConfig;
import org.springframework.context.annotation.Import;

/**
 * Testes de integração para UsuariosAdminController.
 * Valida controle de acesso granular via @PreAuthorize + PERM_ authorities.
 */
@WebMvcTest(controllers = UsuariosAdminController.class, properties = "server.servlet.context-path=")
@Import(SecurityConfig.class)
class UsuarioAdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private RateLimitFilter rateLimitFilter;

    @MockBean
    private UsuarioAdminService usuarioAdminService;

    @MockBean
    private UsuarioRepository usuarioRepository;

    @MockBean
    private PermissionService permissionService;

    @MockBean
    private JwtUtil jwtUtil;

    @MockBean
    private AuditService auditService;

    private UsuarioAdminResponse usuarioMock;

    @BeforeEach
    void setUp() throws Exception {
        doAnswer(invocation -> {
            jakarta.servlet.FilterChain chain = invocation.getArgument(2);
            chain.doFilter(invocation.getArgument(0), invocation.getArgument(1));
            return null;
        }).when(rateLimitFilter).doFilter(any(), any(), any());

        usuarioMock = UsuarioAdminResponse.builder()
                .id(1L)
                .nome("João Teste")
                .email("joao@test.com")
                .role("ATENDENTE")
                .ativo(true)
                .build();

        when(permissionService.getAllRolesWithPermissions())
                .thenReturn(Map.of("ADMIN", List.of("os.criar"), "ATENDENTE", List.of("os.visualizar")));
    }

    // ─── Listagem ─────────────────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_ADMIN", "PERM_usuarios.visualizar"})
    @DisplayName("ADMIN com permissão pode listar usuários")
    void adminComPermissaoListaUsuarios() throws Exception {
        var page = new PageImpl<>(List.of(usuarioMock), PageRequest.of(0, 20), 1);
        when(usuarioAdminService.listar(any(), any(), any())).thenReturn(page);

        mockMvc.perform(get("/admin/usuarios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].email").value("joao@test.com"));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_MECANICO"})
    @DisplayName("MECANICO sem permissão recebe 403 ao listar usuários")
    void mecanicoSemPermissaoNaoListaUsuarios() throws Exception {
        mockMvc.perform(get("/admin/usuarios"))
                .andExpect(status().isForbidden());
    }

    // ─── Criação ──────────────────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.criar"})
    @DisplayName("GERENTE com permissão pode criar usuário")
    void gerenteComPermissaoCriaUsuario() throws Exception {
        when(usuarioAdminService.criar(any(), any(), any())).thenReturn(usuarioMock);

        UsuarioAdminRequest request = new UsuarioAdminRequest();
        request.setNome("Novo Atendente");
        request.setEmail("atendente@oficina.com");
        request.setSenha("senha1234");
        request.setRole("ATENDENTE");

        mockMvc.perform(post("/admin/usuarios")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("ATENDENTE"));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_ATENDENTE", "PERM_usuarios.visualizar"})
    @DisplayName("ATENDENTE sem permissão de criar recebe 403")
    void atendenteNaoPodeCriarUsuario() throws Exception {
        UsuarioAdminRequest request = new UsuarioAdminRequest();
        request.setNome("Teste");
        request.setEmail("x@x.com");
        request.setSenha("senha1234");
        request.setRole("MECANICO");

        mockMvc.perform(post("/admin/usuarios")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    // ─── Alteração de Role ────────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.alterar_perfil"})
    @DisplayName("GERENTE com permissão pode alterar role")
    void gerenteComPermissaoAlteraRole() throws Exception {
        when(usuarioAdminService.alterarRole(anyLong(), any(), any(), any()))
                .thenReturn(usuarioMock);

        mockMvc.perform(patch("/admin/usuarios/1/role")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"novaRole\":\"ESTOQUISTA\"}"))
                .andExpect(status().isOk());
    }

    // ─── Bloqueio ─────────────────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.bloquear"})
    @DisplayName("GERENTE com permissão pode bloquear usuário")
    void gerenteComPermissaoBloqueiaUsuario() throws Exception {
        var bloqueado = UsuarioAdminResponse.builder()
                .id(1L).nome("João").email("joao@test.com")
                .role("ATENDENTE").ativo(false).build();
        when(usuarioAdminService.alterarStatus(anyLong(), anyBoolean(), any(), any()))
                .thenReturn(bloqueado);

        mockMvc.perform(patch("/admin/usuarios/1/status")
                        .with(csrf())
                        .param("ativo", "false"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ativo").value(false));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_ATENDENTE"})
    @DisplayName("ATENDENTE sem permissão não pode bloquear usuário")
    void atendenteNaoPodeBloqueiarUsuario() throws Exception {
        mockMvc.perform(patch("/admin/usuarios/1/status")
                        .with(csrf())
                        .param("ativo", "false"))
                .andExpect(status().isForbidden());
    }

    // ─── Proteção contra auto-escalação (testado via service) ────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.alterar_perfil"})
    @DisplayName("Tentativa de escalação de privilégio retorna 403")
    void escalacaoDePrivilegioRetorna403() throws Exception {
        when(usuarioAdminService.alterarRole(anyLong(), any(), any(), any()))
                .thenThrow(new AccessDeniedException("Apenas administradores podem atribuir a role ADMIN."));

        mockMvc.perform(patch("/admin/usuarios/1/role")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"novaRole\":\"ADMIN\"}"))
                .andExpect(status().isForbidden());
    }

    // ─── Reset de Senha ───────────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.editar"})
    @DisplayName("GERENTE pode resetar senha de sub-usuário")
    void gerentePodeResetarSenha() throws Exception {
        when(usuarioAdminService.resetarSenha(anyLong(), any(), any()))
                .thenReturn("senhaTemp123!");

        mockMvc.perform(post("/admin/usuarios/1/reset-senha")
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.senhaTemporaria").value("senhaTemp123!"));
    }

    // ─── Exclusão de Usuário ──────────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.bloquear"})
    @DisplayName("GERENTE com permissão pode excluir usuário")
    void gerentePodeExcluirUsuario() throws Exception {
        doNothing().when(usuarioAdminService).excluir(anyLong(), any(), any());

        mockMvc.perform(delete("/admin/usuarios/1")
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Usuário excluído com sucesso."));
    }

    // ─── Permissões Customizadas ──────────────────────────────────────────────

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.visualizar"})
    @DisplayName("GERENTE pode buscar permissões do usuário")
    void gerentePodeBuscarPermissoesUsuario() throws Exception {
        when(usuarioAdminService.buscarPermissoesUsuario(anyLong(), any(), any()))
                .thenReturn(Map.of("usuarioId", 1L, "email", "teste@oficina.com"));

        mockMvc.perform(get("/admin/usuarios/1/permissoes"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("teste@oficina.com"));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_GERENTE", "PERM_usuarios.alterar_perfil"})
    @DisplayName("GERENTE pode atualizar permissões customizadas do usuário")
    void gerentePodeAtualizarPermissoesUsuario() throws Exception {
        when(usuarioAdminService.atualizarPermissoesUsuario(anyLong(), any(), any(), any()))
                .thenReturn(List.of("os.visualizar", "estoque.entrada"));

        mockMvc.perform(put("/admin/usuarios/1/permissoes")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("[\"estoque.entrada\"]"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Permissões atualizadas com sucesso."));
    }
}
