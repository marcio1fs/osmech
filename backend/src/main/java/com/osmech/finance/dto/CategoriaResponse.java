package com.osmech.finance.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * DTO de resposta de uma categoria financeira.
 */
@Data
@AllArgsConstructor
@Builder
public class CategoriaResponse {
    private Long id;
    private String nome;
    private String tipo;
    private String icone;
    private Boolean sistema;
    private LocalDateTime criadoEm;
}
