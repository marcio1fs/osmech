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
public class RelatorioDespesasResponse {
    private LocalDate dataInicio;
    private LocalDate dataFim;
    private BigDecimal totalDespesas;
    private Long totalTransacoes;
    private List<DespesaDTO> despesas;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DespesaDTO {
        private Long id;
        private String descricao;
        private BigDecimal valor;
        private String categoria;
        private LocalDate data;
    }
}
