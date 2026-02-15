package com.osmech.stock.controller;

import com.osmech.stock.dto.*;
import com.osmech.stock.service.StockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST do módulo de estoque.
 * Gerencia itens, movimentações e alertas.
 */
@RestController
@RequestMapping("/api/stock")
@RequiredArgsConstructor
public class StockController {

    private final StockService stockService;

    // ==========================================
    // ITENS DE ESTOQUE
    // ==========================================

    /** POST /api/stock - Criar novo item */
    @PostMapping
    public ResponseEntity<?> criarItem(Authentication auth,
                                        @Valid @RequestBody StockItemRequest request) {
        try {
            StockItemResponse response = stockService.criarItem(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/stock - Listar itens (com filtros opcionais) */
    @GetMapping
    public ResponseEntity<?> listarItens(Authentication auth,
                                          @RequestParam(required = false) String categoria,
                                          @RequestParam(required = false) String busca) {
        try {
            List<StockItemResponse> lista = stockService.listarItens(auth.getName(), categoria, busca);
            return ResponseEntity.ok(lista);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/stock/{id} - Buscar item por ID */
    @GetMapping("/{id}")
    public ResponseEntity<?> buscarItem(Authentication auth, @PathVariable Long id) {
        try {
            StockItemResponse response = stockService.buscarItem(auth.getName(), id);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** PUT /api/stock/{id} - Atualizar item */
    @PutMapping("/{id}")
    public ResponseEntity<?> atualizarItem(Authentication auth, @PathVariable Long id,
                                            @Valid @RequestBody StockItemRequest request) {
        try {
            StockItemResponse response = stockService.atualizarItem(auth.getName(), id, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** DELETE /api/stock/{id} - Desativar item (soft delete) */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> desativarItem(Authentication auth, @PathVariable Long id) {
        try {
            stockService.desativarItem(auth.getName(), id);
            return ResponseEntity.ok(Map.of("message", "Item desativado com sucesso"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==========================================
    // MOVIMENTAÇÕES
    // ==========================================

    /** POST /api/stock/move - Registrar movimentação */
    @PostMapping("/move")
    public ResponseEntity<?> registrarMovimentacao(Authentication auth,
                                                     @Valid @RequestBody StockMovementRequest request) {
        try {
            StockMovementResponse response = stockService.registrarMovimentacaoManual(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/stock/movements - Listar todas as movimentações */
    @GetMapping("/movements")
    public ResponseEntity<?> listarMovimentacoes(Authentication auth) {
        try {
            List<StockMovementResponse> lista = stockService.listarTodasMovimentacoes(auth.getName());
            return ResponseEntity.ok(lista);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/stock/{id}/movements - Movimentações de um item específico */
    @GetMapping("/{id}/movements")
    public ResponseEntity<?> listarMovimentacoesItem(Authentication auth, @PathVariable Long id) {
        try {
            List<StockMovementResponse> lista = stockService.listarMovimentacoes(auth.getName(), id);
            return ResponseEntity.ok(lista);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==========================================
    // ALERTAS
    // ==========================================

    /** GET /api/stock/alerts - Alertas de estoque baixo/zerado */
    @GetMapping("/alerts")
    public ResponseEntity<?> getAlertas(Authentication auth) {
        try {
            List<StockAlertResponse> alertas = stockService.getAlertas(auth.getName());
            return ResponseEntity.ok(alertas);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
