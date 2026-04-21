package com.osmech.os.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

/**
 * DTO de resposta de um servico na OS.
 */
@Data
@AllArgsConstructor
@Builder
public class ServicoOSResponse {
    private Long id;
    private String descricao;
    private Integer quantidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
    private Long mecanicoId;
    private String mecanicoNome;
    private BigDecimal percentualComissao;
    private BigDecimal valorComissao;
}
