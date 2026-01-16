package com.osmech.os;

import com.osmech.os.dto.OrdemServicoRequest;
import com.osmech.os.dto.OrdemServicoResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/os")
@CrossOrigin(origins = "*")
public class OrdemServicoController {

    @Autowired
    private OrdemServicoService ordemServicoService;

    private Long getUsuarioId(HttpServletRequest request) {
        Object usuarioId = request.getAttribute("usuarioId");
        if (usuarioId == null) {
            throw new RuntimeException("Usuário não autenticado");
        }
        return (Long) usuarioId;
    }

    @PostMapping
    public ResponseEntity<OrdemServicoResponse> criar(
            @Valid @RequestBody OrdemServicoRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUsuarioId(httpRequest);
        OrdemServicoResponse response = ordemServicoService.criarOS(request, usuarioId);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<OrdemServicoResponse>> listar(HttpServletRequest httpRequest) {
        Long usuarioId = getUsuarioId(httpRequest);
        List<OrdemServicoResponse> ordens = ordemServicoService.listarOS(usuarioId);
        return ResponseEntity.ok(ordens);
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrdemServicoResponse> buscar(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUsuarioId(httpRequest);
        OrdemServicoResponse response = ordemServicoService.buscarPorId(id, usuarioId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrdemServicoResponse> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody OrdemServicoRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUsuarioId(httpRequest);
        OrdemServicoResponse response = ordemServicoService.atualizarOS(id, request, usuarioId);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUsuarioId(httpRequest);
        ordemServicoService.deletarOS(id, usuarioId);
        return ResponseEntity.noContent().build();
    }
}
