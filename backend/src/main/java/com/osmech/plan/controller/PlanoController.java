package com.osmech.plan.controller;

import com.osmech.plan.dto.PlanoResponse;
import com.osmech.plan.service.PlanoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST dos Planos.
 * Rotas públicas (não exigem JWT) — para exibir na tela de pricing.
 */
@RestController
@RequestMapping("/api/planos")
@RequiredArgsConstructor
public class PlanoController {

    private final PlanoService planoService;

    /**
     * GET /api/planos - Lista todos os planos ativos
     */
    @GetMapping
    public ResponseEntity<List<PlanoResponse>> listar() {
        return ResponseEntity.ok(planoService.listarAtivos());
    }

    /**
     * GET /api/planos/{codigo} - Busca plano por código
     */
    @GetMapping("/{codigo}")
    public ResponseEntity<?> buscarPorCodigo(@PathVariable String codigo) {
        try {
            return ResponseEntity.ok(planoService.buscarPorCodigo(codigo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
