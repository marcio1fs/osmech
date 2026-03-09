package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioOsResponse {
    private LocalDate dataInicio;
    private LocalDate dataFim;
    private Long totalOs;
    private Long osAbertas;
    private Long osEmAndamento;
    private Long osConcluidas;
    private Long osCanceladas;
    private BigDecimal valorTotal;
    private BigDecimal valorMedioOs;
    private List<Map<String, Object>> detalhamento;
}
