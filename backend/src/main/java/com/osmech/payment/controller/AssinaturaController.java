package com.osmech.payment.controller;

import com.osmech.payment.dto.AssinaturaRequest;
import com.osmech.payment.dto.AssinaturaResponse;
import com.osmech.payment.service.AssinaturaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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

    /**
     * POST /api/assinatura - Criar/atualizar assinatura (assinar plano)
     */
    @PostMapping
    public ResponseEntity<?> assinar(Authentication auth, @Valid @RequestBody AssinaturaRequest request) {
        try {
            AssinaturaResponse response = assinaturaService.assinar(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/assinatura - Buscar assinatura ativa
     */
    @GetMapping
    public ResponseEntity<?> buscarAtiva(Authentication auth) {
        try {
            AssinaturaResponse response = assinaturaService.buscarAtiva(auth.getName());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/assinatura/historico - Histórico de assinaturas
     */
    @GetMapping("/historico")
    public ResponseEntity<List<AssinaturaResponse>> historico(Authentication auth) {
        return ResponseEntity.ok(assinaturaService.listarHistorico(auth.getName()));
    }

    /**
     * DELETE /api/assinatura - Cancelar assinatura
     */
    @DeleteMapping
    public ResponseEntity<?> cancelar(Authentication auth) {
        try {
            AssinaturaResponse response = assinaturaService.cancelar(auth.getName());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/assinatura/status - Verifica se assinatura está ativa
     */
    @GetMapping("/status")
    public ResponseEntity<?> verificarStatus(Authentication auth) {
        boolean ativa = assinaturaService.isAssinaturaAtiva(auth.getName());
        return ResponseEntity.ok(Map.of("ativa", ativa));
    }

    /**
     * POST /api/assinatura/verificar-inadimplencia - Verifica e aplica regras de inadimplência
     * (Rota administrativa - em produção deveria ser protegida por role ADMIN)
     */
    @PostMapping("/verificar-inadimplencia")
    public ResponseEntity<?> verificarInadimplencia() {
        assinaturaService.verificarInadimplencia();
        return ResponseEntity.ok(Map.of("message", "Verificação de inadimplência executada"));
    }
}
