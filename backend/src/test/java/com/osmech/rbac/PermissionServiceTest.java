package com.osmech.rbac;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Testes unitários para PermissionService.
 * Valida carregamento de cache, consulta por role e invalidação.
 */
@ExtendWith(MockitoExtension.class)
class PermissionServiceTest {

    @Mock
    private PermissionRepository permissionRepository;

    @InjectMocks
    private PermissionService permissionService;

    @BeforeEach
    void setUp() {
        // Simula dados para cada role ao carregar o cache
        when(permissionRepository.findPermissionCodesByRole("ADMIN"))
                .thenReturn(List.of("os.criar", "os.visualizar", "financeiro.visualizar",
                        "usuarios.criar", "usuarios.bloquear"));
        when(permissionRepository.findPermissionCodesByRole("GERENTE"))
                .thenReturn(List.of("os.criar", "os.visualizar", "financeiro.visualizar",
                        "usuarios.criar"));
        when(permissionRepository.findPermissionCodesByRole("OFICINA"))
                .thenReturn(List.of("os.criar", "os.visualizar", "financeiro.visualizar"));
        when(permissionRepository.findPermissionCodesByRole("VENDEDOR"))
                .thenReturn(List.of("os.criar", "os.visualizar", "estoque.visualizar"));
        when(permissionRepository.findPermissionCodesByRole("ATENDENTE"))
                .thenReturn(List.of("os.criar", "os.visualizar", "mecanicos.visualizar"));
        when(permissionRepository.findPermissionCodesByRole("MECANICO"))
                .thenReturn(List.of("os.visualizar", "os.editar"));
        when(permissionRepository.findPermissionCodesByRole("ESTOQUISTA"))
                .thenReturn(List.of("estoque.visualizar", "estoque.entrada"));
        when(permissionRepository.findPermissionCodesByRole("FINANCEIRO"))
                .thenReturn(List.of("financeiro.visualizar", "financeiro.criar"));
        permissionService.carregarCache();
    }

    @Test
    @DisplayName("ADMIN deve ter permissão usuarios.bloquear")
    void adminDeveSerBloqueadorDeUsuarios() {
        List<String> perms = permissionService.getPermissionsForRole("ADMIN");
        assertThat(perms).contains("usuarios.bloquear");
    }

    @Test
    @DisplayName("ATENDENTE não deve ter permissão financeiro.visualizar")
    void atendenteNaoDeveAcessarFinanceiro() {
        List<String> perms = permissionService.getPermissionsForRole("ATENDENTE");
        assertThat(perms).doesNotContain("financeiro.visualizar");
    }

    @Test
    @DisplayName("MECANICO não deve ter permissão os.criar")
    void mecanicoNaoDeveCriarOS() {
        List<String> perms = permissionService.getPermissionsForRole("MECANICO");
        assertThat(perms).doesNotContain("os.criar");
    }

    @Test
    @DisplayName("ESTOQUISTA deve ter permissão estoque.entrada")
    void estoquistaDeveRegistrarEntrada() {
        List<String> perms = permissionService.getPermissionsForRole("ESTOQUISTA");
        assertThat(perms).contains("estoque.entrada");
    }

    @Test
    @DisplayName("Role desconhecida retorna lista vazia")
    void roleDesconhecidaRetornaListaVazia() {
        List<String> perms = permissionService.getPermissionsForRole("ROLE_INEXISTENTE");
        assertThat(perms).isEmpty();
    }

    @Test
    @DisplayName("Role null retorna lista vazia sem exceção")
    void roleNullRetornaListaVazia() {
        List<String> perms = permissionService.getPermissionsForRole(null);
        assertThat(perms).isEmpty();
    }

    @Test
    @DisplayName("Invalidação de cache recarrega do repositório")
    void invalidacaoDeCacheRecarrega() {
        // Reseta mock para retornar nova lista após invalidação
        when(permissionRepository.findPermissionCodesByRole("ADMIN"))
                .thenReturn(List.of("os.criar", "financeiro.visualizar", "nova.permissao"));

        permissionService.invalidarCache();

        List<String> perms = permissionService.getPermissionsForRole("ADMIN");
        assertThat(perms).contains("nova.permissao");
    }

    @Test
    @DisplayName("GERENTE não deve ter permissão usuarios.bloquear (somente ADMIN tem)")
    void gerenteNaoPodeBloquearUsuarios() {
        List<String> perms = permissionService.getPermissionsForRole("GERENTE");
        // Na seed real, GERENTE tem usuarios.criar mas não usuarios.bloquear
        // Aqui testamos que o mock está correto
        assertThat(perms).doesNotContain("usuarios.bloquear");
    }

    @Test
    @DisplayName("getAllRolesWithPermissions retorna todas as roles")
    void getAllRolesRetornaTodasRoles() {
        var all = permissionService.getAllRolesWithPermissions();
        assertThat(all).containsKeys("ADMIN", "GERENTE", "ATENDENTE", "MECANICO");
    }
}
