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
    public ResponseEntity<StockItemResponse> criarItem(Authentication auth,
                                                         @Valid @RequestBody StockItemRequest request) {
        return ResponseEntity.ok(stockService.criarItem(auth.getName(), request));
    }

    /** GET /api/stock - Listar itens (com filtros opcionais) */
    @GetMapping
    public ResponseEntity<List<StockItemResponse>> listarItens(Authentication auth,
                                                                 @RequestParam(required = false) String categoria,
                                                                 @RequestParam(required = false) String busca) {
        return ResponseEntity.ok(stockService.listarItens(auth.getName(), categoria, busca));
    }

    /** GET /api/stock/{id} - Buscar item por ID */
    @GetMapping("/{id}")
    public ResponseEntity<StockItemResponse> buscarItem(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(stockService.buscarItem(auth.getName(), id));
    }

    /** PUT /api/stock/{id} - Atualizar item */
    @PutMapping("/{id}")
    public ResponseEntity<StockItemResponse> atualizarItem(Authentication auth, @PathVariable Long id,
                                                              @Valid @RequestBody StockItemRequest request) {
        return ResponseEntity.ok(stockService.atualizarItem(auth.getName(), id, request));
    }

    /** DELETE /api/stock/{id} - Desativar item (soft delete) */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> desativarItem(Authentication auth, @PathVariable Long id) {
        stockService.desativarItem(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Item desativado com sucesso"));
    }

    // ==========================================
    // MOVIMENTAÇÕES
    // ==========================================

    /** POST /api/stock/move - Registrar movimentação */
    @PostMapping("/move")
    public ResponseEntity<StockMovementResponse> registrarMovimentacao(Authentication auth,
                                                                         @Valid @RequestBody StockMovementRequest request) {
        return ResponseEntity.ok(stockService.registrarMovimentacaoManual(auth.getName(), request));
    }

    /** GET /api/stock/movements - Listar todas as movimentações */
    @GetMapping("/movements")
    public ResponseEntity<List<StockMovementResponse>> listarMovimentacoes(Authentication auth) {
        return ResponseEntity.ok(stockService.listarTodasMovimentacoes(auth.getName()));
    }

    /** GET /api/stock/{id}/movements - Movimentações de um item específico */
    @GetMapping("/{id}/movements")
    public ResponseEntity<List<StockMovementResponse>> listarMovimentacoesItem(Authentication auth,
                                                                                 @PathVariable Long id) {
        return ResponseEntity.ok(stockService.listarMovimentacoes(auth.getName(), id));
    }

    // ==========================================
    // ALERTAS
    // ==========================================

    /** GET /api/stock/alerts - Alertas de estoque baixo/zerado */
    @GetMapping("/alerts")
    public ResponseEntity<List<StockAlertResponse>> getAlertas(Authentication auth) {
        return ResponseEntity.ok(stockService.getAlertas(auth.getName()));
    }
}
