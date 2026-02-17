package com.osmech.os.dto;

import lombok.*;
import java.math.BigDecimal;

/**
 * DTO de resposta de um item de estoque na OS.
 */
@Data
@AllArgsConstructor
@Builder
public class ItemOSResponse {
    private Long id;
    private Long stockItemId;
    private String nomeItem;
    private String codigoItem;
    private Integer quantidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
}
