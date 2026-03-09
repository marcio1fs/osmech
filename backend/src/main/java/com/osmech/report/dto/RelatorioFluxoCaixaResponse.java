package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioFluxoCaixaResponse {
    private LocalDate dataInicio;
    private LocalDate dataFim;
    private BigDecimal saldoInicial;
    private BigDecimal totalEntradas;
    private BigDecimal totalSaidas;
    private BigDecimal saldoFinal;
    private List<MovimentacaoDiaria> movimentacoes;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MovimentacaoDiaria {
        private LocalDate data;
        private BigDecimal entradas;
        private BigDecimal saidas;
        private BigDecimal saldoDia;
    }
}
