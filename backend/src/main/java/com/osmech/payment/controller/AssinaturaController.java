package com.osmech.payment.controller;

import com.osmech.payment.dto.AssinaturaRequest;
import com.osmech.payment.dto.AssinaturaResponse;
import com.osmech.payment.service.AssinaturaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/assinaturas")
@RequiredArgsConstructor
public class AssinaturaController {

    private final AssinaturaService assinaturaService;

    @PostMapping("/iniciar")
    public ResponseEntity<AssinaturaResponse> iniciarAssinatura(Authentication authentication,
                                                                @Valid @RequestBody AssinaturaRequest request) {
        AssinaturaResponse response = assinaturaService.iniciarAssinatura(
                authentication.getName(),
                request.getPlanoCodigo()
        );

        return ResponseEntity.ok(response);
    }

    @GetMapping("/ativa")
    public ResponseEntity<AssinaturaResponse> getAssinaturaAtiva(Authentication authentication) {
        return ResponseEntity.ok(assinaturaService.buscarAssinaturaAtiva(authentication.getName()));
    }

    @DeleteMapping("/cancelar")
    public ResponseEntity<AssinaturaResponse> cancelar(Authentication authentication) {
        return ResponseEntity.ok(assinaturaService.cancelarAssinatura(authentication.getName()));
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Boolean>> status(Authentication authentication) {
        boolean ativa = assinaturaService.isAssinaturaAtiva(authentication.getName());
        return ResponseEntity.ok(Map.of("ativa", ativa));
    }

    @GetMapping("/historico")
    public ResponseEntity<List<AssinaturaResponse>> historico(Authentication authentication) {
        return ResponseEntity.ok(assinaturaService.listarHistorico(authentication.getName()));
    }
}
