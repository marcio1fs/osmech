package com.osmech.stock.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * DTO de movimentação de estoque.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockMovementRequest {

    @NotNull(message = "ID do item é obrigatório")
    private Long stockItemId;

    @NotBlank(message = "Tipo é obrigatório (ENTRADA ou SAIDA)")
    private String tipo;

    @NotNull(message = "Quantidade é obrigatória")
    @Min(value = 1, message = "Quantidade deve ser pelo menos 1")
    private Integer quantidade;

    @NotBlank(message = "Motivo é obrigatório")
    private String motivo;

    private String descricao;

    /** ID da OS (quando motivo = OS) */
    private Long ordemServicoId;
}
