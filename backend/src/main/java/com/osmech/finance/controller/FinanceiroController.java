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
    public ResponseEntity<TransacaoResponse> criarTransacao(Authentication auth,
                                                              @Valid @RequestBody TransacaoRequest request) {
        return ResponseEntity.ok(financeiroService.criarTransacao(auth.getName(), request));
    }

    /** GET /api/finance/transaction - Listar transações (com filtros opcionais) */
    @GetMapping("/transaction")
    public ResponseEntity<List<TransacaoResponse>> listarTransacoes(
            Authentication auth,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim,
            @RequestParam(required = false) String tipo) {
        return ResponseEntity.ok(financeiroService.listarTransacoes(auth.getName(), dataInicio, dataFim, tipo));
    }

    /** POST /api/finance/transaction/{id}/estorno - Estornar transação */
    @PostMapping("/transaction/{id}/estorno")
    public ResponseEntity<TransacaoResponse> estornarTransacao(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(financeiroService.estornarTransacao(auth.getName(), id));
    }

    // ==========================================
    // FLUXO DE CAIXA
    // ==========================================

    /** GET /api/finance/cashflow - Fluxo de caixa por período */
    @GetMapping("/cashflow")
    public ResponseEntity<List<FluxoCaixaResponse>> getFluxoCaixa(
            Authentication auth,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        return ResponseEntity.ok(financeiroService.getFluxoCaixa(auth.getName(), inicio, fim));
    }

    // ==========================================
    // RESUMO FINANCEIRO
    // ==========================================

    /** GET /api/finance/summary - Resumo financeiro para dashboard */
    @GetMapping("/summary")
    public ResponseEntity<ResumoFinanceiroDTO> getResumoFinanceiro(Authentication auth) {
        return ResponseEntity.ok(financeiroService.getResumoFinanceiro(auth.getName()));
    }
}
