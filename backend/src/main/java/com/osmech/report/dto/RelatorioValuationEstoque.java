package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioValuationEstoque {
    private Long totalItens;
    private Long totalQuantidade;
    private BigDecimal valorTotalEstoque;
    private BigDecimal custoTotal;
    private BigDecimal margemEstimada;
}
