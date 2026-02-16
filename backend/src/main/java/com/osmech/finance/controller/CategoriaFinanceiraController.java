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
    public ResponseEntity<CategoriaResponse> criar(Authentication auth,
                                                      @Valid @RequestBody CategoriaRequest request) {
        return ResponseEntity.ok(categoriaService.criar(auth.getName(), request));
    }

    /** GET /api/finance/category - Listar categorias do usuário + sistema */
    @GetMapping
    public ResponseEntity<List<CategoriaResponse>> listar(Authentication auth) {
        return ResponseEntity.ok(categoriaService.listarPorUsuario(auth.getName()));
    }

    /** DELETE /api/finance/category/{id} - Excluir categoria */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> excluir(Authentication auth, @PathVariable Long id) {
        categoriaService.excluir(auth.getName(), id);
        return ResponseEntity.ok(Map.of("message", "Categoria excluída com sucesso"));
    }
}
