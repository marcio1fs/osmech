package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioOsPorVeiculo {
    private String placa;
    private String modelo;
    private String montadora;
    private Long totalOs;
    private BigDecimal valorTotal;
    private LocalDate ultimaOs;
}
