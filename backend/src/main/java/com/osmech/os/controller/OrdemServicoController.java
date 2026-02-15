package com.osmech.os.controller;

import com.osmech.os.dto.OrdemServicoRequest;
import com.osmech.os.dto.OrdemServicoResponse;
import com.osmech.os.service.OrdemServicoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST das Ordens de Serviço.
 * Todas as rotas exigem JWT.
 */
@RestController
@RequestMapping("/api/os")
@RequiredArgsConstructor
public class OrdemServicoController {

    private final OrdemServicoService osService;

    /**
     * POST /api/os - Criar nova OS
     */
    @PostMapping
    public ResponseEntity<?> criar(Authentication auth, @Valid @RequestBody OrdemServicoRequest request) {
        try {
            OrdemServicoResponse response = osService.criar(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/os - Listar todas as OS do usuário
     */
    @GetMapping
    public ResponseEntity<List<OrdemServicoResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(osService.listarPorUsuario(auth.getName()));
    }

    /**
     * GET /api/os/{id} - Buscar OS por ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> buscarPorId(Authentication auth, @PathVariable Long id) {
        try {
            return ResponseEntity.ok(osService.buscarPorId(auth.getName(), id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/os/{id} - Atualizar OS
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> atualizar(Authentication auth,
                                        @PathVariable Long id,
                                        @Valid @RequestBody OrdemServicoRequest request) {
        try {
            return ResponseEntity.ok(osService.atualizar(auth.getName(), id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * DELETE /api/os/{id} - Excluir OS
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> excluir(Authentication auth, @PathVariable Long id) {
        try {
            osService.excluir(auth.getName(), id);
            return ResponseEntity.ok(Map.of("message", "Ordem de Serviço excluída com sucesso"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/os/dashboard - Estatísticas do dashboard
     */
    @GetMapping("/dashboard")
    public ResponseEntity<?> dashboard(Authentication auth) {
        return ResponseEntity.ok(osService.getDashboardStats(auth.getName()));
    }
}
