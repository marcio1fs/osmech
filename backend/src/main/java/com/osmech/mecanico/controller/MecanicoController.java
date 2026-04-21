package com.osmech.mecanico.controller;

import com.osmech.mecanico.dto.MecanicoRequest;
import com.osmech.mecanico.dto.MecanicoResponse;
import com.osmech.mecanico.service.MecanicoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/mecanicos")
@RequiredArgsConstructor
public class MecanicoController {

    private final MecanicoService mecanicoService;

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

    @PutMapping("/{id}")
    public ResponseEntity<MecanicoResponse> atualizar(Authentication auth, @PathVariable Long id,
                                                      @Valid @RequestBody MecanicoRequest request) {
        return ResponseEntity.ok(mecanicoService.atualizar(auth.getName(), id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> desativar(Authentication auth, @PathVariable Long id) {
        mecanicoService.desativar(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Mecânico desativado com sucesso"));
    }

    @PatchMapping("/{id}/reativar")
    public ResponseEntity<Map<String, String>> reativar(Authentication auth, @PathVariable Long id) {
        mecanicoService.reativar(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Mecânico reativado com sucesso"));
    }
}
