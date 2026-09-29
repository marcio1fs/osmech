package com.osmech.equipe.controller;

import com.osmech.equipe.dto.EquipeDtos.AlterarPapelRequest;
import com.osmech.equipe.dto.EquipeDtos.AlterarStatusRequest;
import com.osmech.equipe.dto.EquipeDtos.ConvidarUsuarioRequest;
import com.osmech.equipe.dto.EquipeDtos.ConviteEquipeResponse;
import com.osmech.equipe.dto.EquipeDtos.EquipeResponse;
import com.osmech.equipe.dto.EquipeDtos.MembroEquipeResponse;
import com.osmech.equipe.service.EquipeService;
import com.osmech.security.PapeisSeguranca;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Gestão da equipe da oficina — exclusivo do DONO (ADMIN herda).
 * Convites, mudança de papel e ativação/desativação de membros.
 */
@RestController
@RequestMapping("/oficina/equipe")
@RequiredArgsConstructor
@PreAuthorize(PapeisSeguranca.SOMENTE_DONO)
public class EquipeController {

    private final EquipeService equipeService;

    /** GET /api/oficina/equipe — membros + convites + uso vs. limite do plano */
    @GetMapping
    public ResponseEntity<EquipeResponse> getEquipe(Authentication auth) {
        return ResponseEntity.ok(equipeService.getEquipe(auth.getName()));
    }

    /** POST /api/oficina/equipe/convites — cria convite e envia e-mail */
    @PostMapping("/convites")
    public ResponseEntity<ConviteEquipeResponse> convidar(Authentication auth,
                                                          @Valid @RequestBody ConvidarUsuarioRequest request) {
        return ResponseEntity.ok(equipeService.convidar(auth.getName(), request));
    }

    /** DELETE /api/oficina/equipe/convites/{id} — revoga convite pendente */
    @DeleteMapping("/convites/{id}")
    public ResponseEntity<Map<String, String>> revogar(Authentication auth, @PathVariable Long id) {
        equipeService.revogarConvite(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Convite revogado"));
    }

    /** POST /api/oficina/equipe/convites/{id}/reenviar — novo token + novo e-mail */
    @PostMapping("/convites/{id}/reenviar")
    public ResponseEntity<ConviteEquipeResponse> reenviar(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(equipeService.reenviarConvite(auth.getName(), id));
    }

    /** PUT /api/oficina/equipe/usuarios/{id}/papel */
    @PutMapping("/usuarios/{id}/papel")
    public ResponseEntity<MembroEquipeResponse> alterarPapel(Authentication auth,
                                                             @PathVariable Long id,
                                                             @Valid @RequestBody AlterarPapelRequest request) {
        return ResponseEntity.ok(equipeService.alterarPapel(auth.getName(), id, request));
    }

    /** PUT /api/oficina/equipe/usuarios/{id}/status */
    @PutMapping("/usuarios/{id}/status")
    public ResponseEntity<MembroEquipeResponse> alterarStatus(Authentication auth,
                                                              @PathVariable Long id,
                                                              @Valid @RequestBody AlterarStatusRequest request) {
        return ResponseEntity.ok(equipeService.alterarStatus(auth.getName(), id, request));
    }
}
