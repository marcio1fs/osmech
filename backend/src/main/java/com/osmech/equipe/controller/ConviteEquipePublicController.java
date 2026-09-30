package com.osmech.equipe.controller;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.equipe.dto.EquipeDtos.AceitarConviteRequest;
import com.osmech.equipe.dto.EquipeDtos.ConviteInfoResponse;
import com.osmech.equipe.service.EquipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Endpoints PÚBLICOS do fluxo de convite (não exigem JWT — rota /auth/**).
 */
@RestController
@RequestMapping("/auth/convites")
@RequiredArgsConstructor
public class ConviteEquipePublicController {

    private final EquipeService equipeService;

    /** GET /api/auth/convites/{token} — dados do convite para a tela de aceite */
    @GetMapping("/{token}")
    public ResponseEntity<ConviteInfoResponse> info(@PathVariable String token) {
        return ResponseEntity.ok(equipeService.conviteInfo(token));
    }

    /** POST /api/auth/convites/aceitar — cria a conta vinculada e retorna JWT */
    @PostMapping("/aceitar")
    public ResponseEntity<AuthResponse> aceitar(@Valid @RequestBody AceitarConviteRequest request) {
        return ResponseEntity.ok(equipeService.aceitarConvite(request));
    }
}
