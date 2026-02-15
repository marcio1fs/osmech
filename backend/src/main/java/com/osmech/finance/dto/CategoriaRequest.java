package com.osmech.finance.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * DTO para criação de categoria financeira.
 */
@Data
public class CategoriaRequest {

    @NotBlank(message = "Nome da categoria é obrigatório")
    private String nome;

    @NotBlank(message = "Tipo é obrigatório (ENTRADA ou SAIDA)")
    private String tipo;

    private String icone;
}
