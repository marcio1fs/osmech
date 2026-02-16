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

    /** POST /api/os - Criar nova OS */
    @PostMapping
    public ResponseEntity<OrdemServicoResponse> criar(Authentication auth,
                                                       @Valid @RequestBody OrdemServicoRequest request) {
        return ResponseEntity.ok(osService.criar(auth.getName(), request));
    }

    /** GET /api/os - Listar todas as OS do usuário */
    @GetMapping
    public ResponseEntity<List<OrdemServicoResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(osService.listarPorUsuario(auth.getName()));
    }

    /** GET /api/os/{id} - Buscar OS por ID */
    @GetMapping("/{id}")
    public ResponseEntity<OrdemServicoResponse> buscarPorId(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(osService.buscarPorId(auth.getName(), id));
    }

    /** PUT /api/os/{id} - Atualizar OS */
    @PutMapping("/{id}")
    public ResponseEntity<OrdemServicoResponse> atualizar(Authentication auth,
                                                           @PathVariable Long id,
                                                           @Valid @RequestBody OrdemServicoRequest request) {
        return ResponseEntity.ok(osService.atualizar(auth.getName(), id, request));
    }

    /** DELETE /api/os/{id} - Excluir OS */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> excluir(Authentication auth, @PathVariable Long id) {
        osService.excluir(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Ordem de Serviço excluída com sucesso"));
    }

    /** GET /api/os/dashboard - Estatísticas do dashboard */
    @GetMapping("/dashboard")
    public ResponseEntity<OrdemServicoService.DashboardStats> dashboard(Authentication auth) {
        return ResponseEntity.ok(osService.getDashboardStats(auth.getName()));
    }
}
