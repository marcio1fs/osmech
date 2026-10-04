package com.osmech.mecanico.controller;

import com.osmech.mecanico.dto.MecanicoRequest;
import com.osmech.mecanico.dto.MecanicoResponse;
import com.osmech.mecanico.dto.VincularContaRequest;
import com.osmech.mecanico.service.MecanicoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import com.osmech.security.PapeisSeguranca;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/mecanicos")
@PreAuthorize(PapeisSeguranca.MEMBROS_OFICINA)
@RequiredArgsConstructor
public class MecanicoController {

    private final MecanicoService mecanicoService;

    @PreAuthorize(PapeisSeguranca.GESTORES)
    @PostMapping
    public ResponseEntity<MecanicoResponse> criar(Authentication auth, @Valid @RequestBody MecanicoRequest request) {
        return ResponseEntity.ok(mecanicoService.criar(auth.getName(), request));
    }

    @GetMapping
    public ResponseEntity<List<MecanicoResponse>> listar(Authentication auth,
                                                         @RequestParam(defaultValue = "true") boolean ativosOnly) {
        return ResponseEntity.ok(mecanicoService.listar(auth.getName(), ativosOnly));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MecanicoResponse> buscarPorId(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(mecanicoService.buscarPorId(auth.getName(), id));
    }

    @PreAuthorize(PapeisSeguranca.GESTORES)
    @PutMapping("/{id}")
    public ResponseEntity<MecanicoResponse> atualizar(Authentication auth, @PathVariable Long id,
                                                      @Valid @RequestBody MecanicoRequest request) {
        return ResponseEntity.ok(mecanicoService.atualizar(auth.getName(), id, request));
    }

    @PreAuthorize(PapeisSeguranca.GESTORES)
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> desativar(Authentication auth, @PathVariable Long id) {
        mecanicoService.desativar(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Mecânico desativado com sucesso"));
    }

    @PreAuthorize(PapeisSeguranca.GESTORES)
    @PatchMapping("/{id}/reativar")
    public ResponseEntity<Map<String, String>> reativar(Authentication auth, @PathVariable Long id) {
        mecanicoService.reativar(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Mecânico reativado com sucesso"));
    }

    // ==================== vínculo com conta de usuário (módulo Equipe) ====================

    /** Vincula uma conta de usuário da equipe à ficha do mecânico (DONO/GERENTE). */
    @PreAuthorize(PapeisSeguranca.GESTORES)
    @PutMapping("/{id}/vincular-conta")
    public ResponseEntity<MecanicoResponse> vincularConta(Authentication auth, @PathVariable Long id,
                                                          @Valid @RequestBody VincularContaRequest request) {
        return ResponseEntity.ok(mecanicoService.vincularConta(auth.getName(), id, request.getUsuarioId()));
    }

    /** Remove o vínculo da ficha do mecânico com a conta de usuário (DONO/GERENTE). */
    @PreAuthorize(PapeisSeguranca.GESTORES)
    @DeleteMapping("/{id}/vincular-conta")
    public ResponseEntity<MecanicoResponse> desvincularConta(Authentication auth, @PathVariable Long id) {
        return ResponseEntity.ok(mecanicoService.desvincularConta(auth.getName(), id));
    }

    /** Ficha + total de comissões do mecânico logado (qualquer membro). */
    @GetMapping("/minhas-comissoes")
    public ResponseEntity<MecanicoResponse> minhasComissoes(Authentication auth) {
        return ResponseEntity.ok(mecanicoService.minhasComissoes(auth.getName()));
    }
}
