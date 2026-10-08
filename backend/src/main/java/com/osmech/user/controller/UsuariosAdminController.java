package com.osmech.user.controller;

import com.osmech.rbac.PermissionService;
import com.osmech.user.dto.AlterarRoleRequest;
import com.osmech.user.dto.UsuarioAdminRequest;
import com.osmech.user.dto.UsuarioAdminResponse;
import com.osmech.user.service.UsuarioAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST para gerenciamento administrativo de usuários.
 *
 * Permissões necessárias (backend):
 * - Listar/consultar: hasAuthority('PERM_usuarios.visualizar')
 * - Criar: hasAuthority('PERM_usuarios.criar')
 * - Editar: hasAuthority('PERM_usuarios.editar')
 * - Bloquear: hasAuthority('PERM_usuarios.bloquear')
 * - Alterar perfil: hasAuthority('PERM_usuarios.alterar_perfil')
 *
 * Rotas:
 *   GET    /api/admin/usuarios          - lista paginada
 *   POST   /api/admin/usuarios          - cria usuário
 *   GET    /api/admin/usuarios/{id}     - detalhe
 *   PUT    /api/admin/usuarios/{id}     - edita dados
 *   PATCH  /api/admin/usuarios/{id}/role   - altera perfil/role
 *   PATCH  /api/admin/usuarios/{id}/status - bloquear/desbloquear
 *   POST   /api/admin/usuarios/{id}/reset-senha - reseta senha temporária
 *   GET    /api/admin/roles             - lista roles e permissões disponíveis
 */
@RestController
@RequestMapping("/admin/usuarios")
@RequiredArgsConstructor
public class UsuariosAdminController {

    private final UsuarioAdminService usuarioAdminService;
    private final PermissionService permissionService;

    // ─── Listagem ────────────────────────────────────────────────────────────

    @GetMapping
    @PreAuthorize("hasAuthority('PERM_usuarios.visualizar')")
    public ResponseEntity<Page<UsuarioAdminResponse>> listar(
            Authentication auth,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Pageable pageable = PageRequest.of(page, size);
        String role = extrairRole(auth);
        return ResponseEntity.ok(usuarioAdminService.listar(auth.getName(), role, pageable));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('PERM_usuarios.visualizar')")
    public ResponseEntity<UsuarioAdminResponse> buscarPorId(
            @PathVariable Long id, Authentication auth) {
        return ResponseEntity.ok(usuarioAdminService.buscarPorId(id, auth.getName(), extrairRole(auth)));
    }

    // ─── Criação ─────────────────────────────────────────────────────────────

    @PostMapping
    @PreAuthorize("hasAuthority('PERM_usuarios.criar')")
    public ResponseEntity<UsuarioAdminResponse> criar(
            @Valid @RequestBody UsuarioAdminRequest request, Authentication auth) {
        return ResponseEntity.ok(usuarioAdminService.criar(request, auth.getName(), extrairRole(auth)));
    }

    // ─── Edição ──────────────────────────────────────────────────────────────

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('PERM_usuarios.editar')")
    public ResponseEntity<UsuarioAdminResponse> editar(
            @PathVariable Long id,
            @Valid @RequestBody com.osmech.user.dto.UsuarioAdminUpdateRequest request,
            Authentication auth) {
        return ResponseEntity.ok(usuarioAdminService.editar(id, request, auth.getName(), extrairRole(auth)));
    }

    // ─── Alteração de Role ────────────────────────────────────────────────────

    @PatchMapping("/{id}/role")
    @PreAuthorize("hasAuthority('PERM_usuarios.alterar_perfil')")
    public ResponseEntity<UsuarioAdminResponse> alterarRole(
            @PathVariable Long id,
            @Valid @RequestBody AlterarRoleRequest request,
            Authentication auth) {
        return ResponseEntity.ok(
                usuarioAdminService.alterarRole(id, request.getNovaRole(), auth.getName(), extrairRole(auth)));
    }

    // ─── Bloqueio / Desbloqueio ───────────────────────────────────────────────

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAuthority('PERM_usuarios.bloquear')")
    public ResponseEntity<UsuarioAdminResponse> alterarStatus(
            @PathVariable Long id,
            @RequestParam boolean ativo,
            Authentication auth) {
        return ResponseEntity.ok(
                usuarioAdminService.alterarStatus(id, ativo, auth.getName(), extrairRole(auth)));
    }

    // ─── Reset de senha ───────────────────────────────────────────────────────

    @PostMapping("/{id}/reset-senha")
    @PreAuthorize("hasAuthority('PERM_usuarios.editar')")
    public ResponseEntity<Map<String, String>> resetarSenha(
            @PathVariable Long id, Authentication auth) {
        String senhaTemp = usuarioAdminService.resetarSenha(id, auth.getName(), extrairRole(auth));
        return ResponseEntity.ok(Map.of(
                "message", "Senha temporária gerada com sucesso.",
                "senhaTemporaria", senhaTemp
        ));
    }

    // ─── Exclusão ─────────────────────────────────────────────────────────────

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('PERM_usuarios.bloquear')")
    public ResponseEntity<Map<String, String>> excluir(
            @PathVariable Long id, Authentication auth) {
        usuarioAdminService.excluir(id, auth.getName(), extrairRole(auth));
        return ResponseEntity.ok(Map.of("message", "Usuário excluído com sucesso."));
    }

    // ─── Permissões customizadas ──────────────────────────────────────────────

    @GetMapping("/{id}/permissoes")
    @PreAuthorize("hasAuthority('PERM_usuarios.visualizar')")
    public ResponseEntity<Map<String, Object>> buscarPermissoes(
            @PathVariable Long id, Authentication auth) {
        return ResponseEntity.ok(usuarioAdminService.buscarPermissoesUsuario(id, auth.getName(), extrairRole(auth)));
    }

    @PutMapping("/{id}/permissoes")
    @PreAuthorize("hasAuthority('PERM_usuarios.alterar_perfil')")
    public ResponseEntity<Map<String, Object>> atualizarPermissoes(
            @PathVariable Long id,
            @RequestBody List<String> permissoes,
            Authentication auth) {
        List<String> efetivas = usuarioAdminService.atualizarPermissoesUsuario(
                id, permissoes, auth.getName(), extrairRole(auth));
        return ResponseEntity.ok(Map.of(
                "message", "Permissões atualizadas com sucesso.",
                "effectivePermissions", efetivas
        ));
    }

    // ─── Roles disponíveis ────────────────────────────────────────────────────

    /**
     * Retorna todas as roles e suas permissões (para popular dropdowns no frontend).
     */
    @GetMapping("/roles")
    @PreAuthorize("hasAuthority('PERM_usuarios.visualizar')")
    public ResponseEntity<Object> listarRoles() {
        return ResponseEntity.ok(permissionService.getAllRolesWithPermissions());
    }

    // ─── Helper ────────────────────────────────────────────────────────────────

    /**
     * Extrai a role do usuário autenticado a partir das authorities do JWT.
     * Busca a authority com prefixo "ROLE_".
     */
    private String extrairRole(Authentication auth) {
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith("ROLE_"))
                .map(a -> a.substring(5))
                .findFirst()
                .orElse("DESCONHECIDA");
    }
}
