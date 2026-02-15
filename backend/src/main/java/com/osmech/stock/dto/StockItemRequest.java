package com.osmech.stock.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * DTO de criação/edição de item de estoque.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockItemRequest {

    /** Código auto-gerado pelo sistema (opcional no request) */
    private String codigo;

    @NotBlank(message = "Nome é obrigatório")
    private String nome;

    private String categoria;

    @Min(value = 0, message = "Quantidade não pode ser negativa")
    private Integer quantidade;

    @Min(value = 0, message = "Quantidade mínima não pode ser negativa")
    private Integer quantidadeMinima;

    @DecimalMin(value = "0.0", message = "Preço de custo não pode ser negativo")
    private BigDecimal precoCusto;

    @DecimalMin(value = "0.0", message = "Preço de venda não pode ser negativo")
    private BigDecimal precoVenda;

    private String localizacao;
}
