package com.osmech.stock.dto;

import lombok.*;
import java.math.BigDecimal;

/**
 * DTO de alerta de estoque (item abaixo do mínimo ou zerado).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockAlertResponse {

    private Long id;
    private String codigo;
    private String nome;
    private String categoria;
    private Integer quantidade;
    private Integer quantidadeMinima;
    private BigDecimal precoCusto;
    private BigDecimal precoVenda;

    /**
     * Nível do alerta:
     * CRITICO  - estoque zerado
     * ALERTA   - estoque <= mínimo
     */
    private String nivel;
    private String mensagem;
}
