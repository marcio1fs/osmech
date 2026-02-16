package com.osmech.payment.controller;

import com.osmech.payment.dto.AssinaturaRequest;
import com.osmech.payment.dto.AssinaturaResponse;
import com.osmech.payment.service.AssinaturaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST para Assinaturas.
 */
@RestController
@RequestMapping("/api/assinatura")
@RequiredArgsConstructor
public class AssinaturaController {

    private final AssinaturaService assinaturaService;

    /** POST /api/assinatura - Criar/atualizar assinatura (assinar plano) */
    @PostMapping
    public ResponseEntity<AssinaturaResponse> assinar(Authentication auth,
                                                        @Valid @RequestBody AssinaturaRequest request) {
        return ResponseEntity.ok(assinaturaService.assinar(auth.getName(), request));
    }

    /** GET /api/assinatura - Buscar assinatura ativa */
    @GetMapping
    public ResponseEntity<AssinaturaResponse> buscarAtiva(Authentication auth) {
        return ResponseEntity.ok(assinaturaService.buscarAtiva(auth.getName()));
    }

    /** GET /api/assinatura/historico - Histórico de assinaturas */
    @GetMapping("/historico")
    public ResponseEntity<List<AssinaturaResponse>> historico(Authentication auth) {
        return ResponseEntity.ok(assinaturaService.listarHistorico(auth.getName()));
    }

    /** DELETE /api/assinatura - Cancelar assinatura */
    @DeleteMapping
    public ResponseEntity<AssinaturaResponse> cancelar(Authentication auth) {
        return ResponseEntity.ok(assinaturaService.cancelar(auth.getName()));
    }

    /** GET /api/assinatura/status - Verifica se assinatura está ativa */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Boolean>> verificarStatus(Authentication auth) {
        boolean ativa = assinaturaService.isAssinaturaAtiva(auth.getName());
        return ResponseEntity.ok(Map.of("ativa", ativa));
    }

    /** POST /api/assinatura/verificar-inadimplencia - Verificar inadimplência (ADMIN) */
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/verificar-inadimplencia")
    public ResponseEntity<Map<String, String>> verificarInadimplencia() {
        assinaturaService.verificarInadimplencia();
        return ResponseEntity.ok(Map.of("message", "Verificação de inadimplência executada"));
    }
}
