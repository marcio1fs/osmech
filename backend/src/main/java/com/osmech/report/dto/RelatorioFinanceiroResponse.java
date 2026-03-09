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
public class RelatorioFinanceiroResponse {
    private LocalDate dataInicio;
    private LocalDate dataFim;
    private BigDecimal totalReceitas;
    private BigDecimal totalDespesas;
    private BigDecimal saldo;
    private Long totalTransacoes;
    private List<TransacaoFinanceiraDTO> transacoes;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TransacaoFinanceiraDTO {
        private Long id;
        private String tipo;
        private String descricao;
        private BigDecimal valor;
        private String categoria;
        private String metodoPagamento;
        private LocalDate data;
    }
}
