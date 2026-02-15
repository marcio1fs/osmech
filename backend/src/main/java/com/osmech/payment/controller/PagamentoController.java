package com.osmech.payment.controller;

import com.osmech.payment.dto.PagamentoRequest;
import com.osmech.payment.dto.PagamentoResponse;
import com.osmech.payment.dto.ResumoFinanceiroResponse;
import com.osmech.payment.service.PagamentoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST para Pagamentos.
 */
@RestController
@RequestMapping("/api/pagamento")
@RequiredArgsConstructor
public class PagamentoController {

    private final PagamentoService pagamentoService;

    /**
     * POST /api/pagamento - Registrar novo pagamento
     */
    @PostMapping
    public ResponseEntity<?> criar(Authentication auth, @Valid @RequestBody PagamentoRequest request) {
        try {
            PagamentoResponse response = pagamentoService.criar(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/pagamento/{id}/confirmar - Confirmar pagamento
     */
    @PutMapping("/{id}/confirmar")
    public ResponseEntity<?> confirmar(Authentication auth, @PathVariable Long id) {
        try {
            PagamentoResponse response = pagamentoService.confirmar(auth.getName(), id);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/pagamento/{id}/cancelar - Cancelar pagamento pendente
     */
    @PutMapping("/{id}/cancelar")
    public ResponseEntity<?> cancelar(Authentication auth, @PathVariable Long id) {
        try {
            PagamentoResponse response = pagamentoService.cancelar(auth.getName(), id);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/pagamento - Listar todos os pagamentos
     */
    @GetMapping
    public ResponseEntity<List<PagamentoResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(pagamentoService.listar(auth.getName()));
    }

    /**
     * GET /api/pagamento/tipo/{tipo} - Listar por tipo (ASSINATURA ou OS)
     */
    @GetMapping("/tipo/{tipo}")
    public ResponseEntity<List<PagamentoResponse>> listarPorTipo(Authentication auth, @PathVariable String tipo) {
        return ResponseEntity.ok(pagamentoService.listarPorTipo(auth.getName(), tipo.toUpperCase()));
    }

    /**
     * GET /api/pagamento/{id} - Buscar pagamento por ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> buscarPorId(Authentication auth, @PathVariable Long id) {
        try {
            return ResponseEntity.ok(pagamentoService.buscarPorId(auth.getName(), id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/pagamento/resumo - Resumo financeiro
     */
    @GetMapping("/resumo")
    public ResponseEntity<?> resumoFinanceiro(Authentication auth) {
        try {
            ResumoFinanceiroResponse resumo = pagamentoService.getResumoFinanceiro(auth.getName());
            return ResponseEntity.ok(resumo);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
