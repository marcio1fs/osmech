package com.osmech.user.controller;

import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
@PreAuthorize("hasRole(T(com.osmech.user.entity.Papel).ADMIN.name())")
public class AdminController {

    private final UsuarioRepository usuarioRepository;

    /**
     * Retorna dados consolidados sobre os usuários e assinaturas.
     * Acesso restrito a usuários com role 'ADMIN' (ROLE_ADMIN).
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
}
