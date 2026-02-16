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

/**
 * Controller REST para Pagamentos.
 */
@RestController
@RequestMapping("/api/pagamento")
@RequiredArgsConstructor
public class PagamentoController {

    private final PagamentoService pagamentoService;

    /** POST /api/pagamento - Registrar novo pagamento */
    @PostMapping
    public ResponseEntity<PagamentoResponse> criar(Authentication auth,
                                                     @Valid @RequestBody PagamentoRequest request) {
        return ResponseEntity.ok(pagamentoService.criar(auth.getName(), request));
    }

    /** PUT /api/pagamento/{id}/confirmar - Confirmar pagamento */
    @PutMapping("/{id}/confirmar")
    public ResponseEntity<PagamentoResponse> confirmar(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(pagamentoService.confirmar(auth.getName(), id));
    }

    /** PUT /api/pagamento/{id}/cancelar - Cancelar pagamento pendente */
    @PutMapping("/{id}/cancelar")
    public ResponseEntity<PagamentoResponse> cancelar(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(pagamentoService.cancelar(auth.getName(), id));
    }

    /** GET /api/pagamento - Listar todos os pagamentos */
    @GetMapping
    public ResponseEntity<List<PagamentoResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(pagamentoService.listar(auth.getName()));
    }

    /** GET /api/pagamento/tipo/{tipo} - Listar por tipo (ASSINATURA ou OS) */
    @GetMapping("/tipo/{tipo}")
    public ResponseEntity<List<PagamentoResponse>> listarPorTipo(Authentication auth, @PathVariable String tipo) {
        return ResponseEntity.ok(pagamentoService.listarPorTipo(auth.getName(), tipo.toUpperCase()));
    }

    /** GET /api/pagamento/{id} - Buscar pagamento por ID */
    @GetMapping("/{id}")
    public ResponseEntity<PagamentoResponse> buscarPorId(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(pagamentoService.buscarPorId(auth.getName(), id));
    }

    /** GET /api/pagamento/resumo - Resumo financeiro */
    @GetMapping("/resumo")
    public ResponseEntity<ResumoFinanceiroResponse> resumoFinanceiro(Authentication auth) {
        return ResponseEntity.ok(pagamentoService.getResumoFinanceiro(auth.getName()));
    }
}
