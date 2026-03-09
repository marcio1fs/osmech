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
public class RelatorioOsPorMecanico {
    private String mecanico;
    private Long totalOs;
    private Long osConcluidas;
    private BigDecimal valorTotal;
    private BigDecimal valorMedio;
}
