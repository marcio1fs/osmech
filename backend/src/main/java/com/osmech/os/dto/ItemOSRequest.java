package com.osmech.os.dto;

import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;

/**
 * DTO para adicionar um item de estoque à OS.
 */
@Data
public class ItemOSRequest {

    @NotNull(message = "ID do item de estoque é obrigatório")
    private Long stockItemId;

    @NotNull(message = "Quantidade é obrigatória")
    @Min(value = 1, message = "Quantidade deve ser no mínimo 1")
    private Integer quantidade;

    /** Valor unitário — se não informado, usa o preço de venda do item */
    @DecimalMin(value = "0.0", message = "Valor unitário não pode ser negativo")
    private BigDecimal valorUnitario;
}
