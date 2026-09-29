package com.osmech.user.controller;

import com.osmech.user.dto.AdminDtos;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import com.osmech.user.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller para operações administrativas restritas aos administradores do sistema.
 * O papel é referenciado via enum Papel (fonte única de verdade) em vez de String solta.
 */
@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@PreAuthorize(com.osmech.security.PapeisSeguranca.SOMENTE_ADMIN)
public class AdminController {

    private final UsuarioRepository usuarioRepository;
    private final AdminService adminService;

    /**
     * GET /api/admin/dashboard
     * Dados consolidados dos usuários (compatibilidade — dump completo sem paginação).
     * Mantido para não quebrar clientes antigos; prefira {@code GET /admin/usuarios}.
     */
    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardData() {
        long totalUsuarios = usuarioRepository.count();
        List<Usuario> list = usuarioRepository.findAll();

        List<Map<String, Object>> usuariosData = list.stream().map(u -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", u.getId());
            map.put("nome", u.getNome());
            map.put("email", u.getEmail());
            map.put("telefone", u.getTelefone());
            map.put("nomeOficina", u.getNomeOficina());
            map.put("role", u.getRole());
            map.put("plano", u.getPlano());
            map.put("ativo", u.getAtivo());
            map.put("criadoEm", u.getCriadoEm());
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("totalUsuarios", totalUsuarios);
        response.put("usuarios", usuariosData);

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/admin/usuarios?termo=&pagina=0&tamanho=25
     * Listagem paginada com busca por nome/e-mail/oficina + agregados dos cards.
     */
    @GetMapping("/usuarios")
    public ResponseEntity<AdminDtos.PaginaUsuarios> listarUsuarios(
            @RequestParam(required = false) String termo,
            @RequestParam(defaultValue = "0") int pagina,
            @RequestParam(defaultValue = "25") int tamanho) {
        return ResponseEntity.ok(adminService.listar(termo, pagina, tamanho));
    }

    /** PUT /api/admin/usuarios/{id}/ativo - Ativa/inativa uma conta. */
    @PutMapping("/usuarios/{id}/ativo")
    public ResponseEntity<AdminDtos.UsuarioAdmin> definirAtivo(
            Authentication auth, @PathVariable Long id,
            @Valid @RequestBody AdminDtos.AtivoRequest request) {
        return ResponseEntity.ok(
                adminService.definirAtivo(auth.getName(), id, request.getAtivo()));
    }

    /** PUT /api/admin/usuarios/{id}/plano - Altera o plano (espelhado na oficina). */
    @PutMapping("/usuarios/{id}/plano")
    public ResponseEntity<AdminDtos.UsuarioAdmin> definirPlano(
            Authentication auth, @PathVariable Long id,
            @Valid @RequestBody AdminDtos.PlanoRequest request) {
        return ResponseEntity.ok(
                adminService.definirPlano(auth.getName(), id, request.getPlano()));
    }

    /** PUT /api/admin/usuarios/{id}/role - Altera o papel (GERENTE/ATENDENTE/MECANICO). */
    @PutMapping("/usuarios/{id}/role")
    public ResponseEntity<AdminDtos.UsuarioAdmin> definirPapel(
            Authentication auth, @PathVariable Long id,
            @Valid @RequestBody AdminDtos.PapelRequest request) {
        return ResponseEntity.ok(
                adminService.definirPapel(auth.getName(), id, request.getRole()));
    }
}
