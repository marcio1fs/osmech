package com.osmech.finance.controller;

import com.osmech.finance.dto.CategoriaRequest;
import com.osmech.finance.dto.CategoriaResponse;
import com.osmech.finance.service.CategoriaFinanceiraService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST para categorias financeiras.
 */
@RestController
@RequestMapping("/api/finance/category")
@RequiredArgsConstructor
public class CategoriaFinanceiraController {

    private final CategoriaFinanceiraService categoriaService;

    /** POST /api/finance/category - Criar nova categoria */
    @PostMapping
    public ResponseEntity<?> criar(Authentication auth,
                                    @Valid @RequestBody CategoriaRequest request) {
        try {
            CategoriaResponse response = categoriaService.criar(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** GET /api/finance/category - Listar categorias do usuário + sistema */
    @GetMapping
    public ResponseEntity<List<CategoriaResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(categoriaService.listarPorUsuario(auth.getName()));
    }

    /** DELETE /api/finance/category/{id} - Excluir categoria */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> excluir(Authentication auth, @PathVariable Long id) {
        try {
            categoriaService.excluir(auth.getName(), id);
            return ResponseEntity.ok(Map.of("message", "Categoria excluída com sucesso"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
