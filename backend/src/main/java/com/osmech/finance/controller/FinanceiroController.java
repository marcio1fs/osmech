package com.osmech.finance.controller;

import com.osmech.finance.dto.*;
import com.osmech.finance.service.FinanceiroService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Controller REST do módulo financeiro.
 * Gerencia transações, fluxo de caixa e resumo financeiro.
 */
@RestController
@RequestMapping("/api/finance")
@RequiredArgsConstructor
public class FinanceiroController {

    private final FinanceiroService financeiroService;

    // ==========================================
    // TRANSAÇÕES
    // ==========================================

    /** POST /api/finance/transaction - Criar nova transação */
    @PostMapping("/transaction")
    public ResponseEntity<?> criarTransacao(Authentication auth,
                                             @Valid @RequestBody TransacaoRequest request) {
        try {
            TransacaoResponse response = financeiroService.criarTransacao(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/finance/transaction - Listar transações (com filtros opcionais) */
    @GetMapping("/transaction")
    public ResponseEntity<?> listarTransacoes(
            Authentication auth,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim,
            @RequestParam(required = false) String tipo) {
        try {
            List<TransacaoResponse> lista = financeiroService.listarTransacoes(
                    auth.getName(), dataInicio, dataFim, tipo);
            return ResponseEntity.ok(lista);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** POST /api/finance/transaction/{id}/estorno - Estornar transação */
    @PostMapping("/transaction/{id}/estorno")
    public ResponseEntity<?> estornarTransacao(Authentication auth, @PathVariable Long id) {
        try {
            TransacaoResponse response = financeiroService.estornarTransacao(auth.getName(), id);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==========================================
    // FLUXO DE CAIXA
    // ==========================================

    /** GET /api/finance/cashflow - Fluxo de caixa por período */
    @GetMapping("/cashflow")
    public ResponseEntity<?> getFluxoCaixa(
            Authentication auth,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        try {
            List<FluxoCaixaResponse> fluxo = financeiroService.getFluxoCaixa(
                    auth.getName(), inicio, fim);
            return ResponseEntity.ok(fluxo);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==========================================
    // RESUMO FINANCEIRO
    // ==========================================

    /** GET /api/finance/summary - Resumo financeiro para dashboard */
    @GetMapping("/summary")
    public ResponseEntity<?> getResumoFinanceiro(Authentication auth) {
        try {
            ResumoFinanceiroDTO resumo = financeiroService.getResumoFinanceiro(auth.getName());
            return ResponseEntity.ok(resumo);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
