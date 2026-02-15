package com.osmech.finance.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

/**
 * DTO com resumo/sumário financeiro para dashboard.
 */
@Data
@AllArgsConstructor
@Builder
public class ResumoFinanceiroDTO {
    /** Total de entradas (receita acumulada) */
    private BigDecimal totalEntradas;
    /** Total de saídas (despesas acumuladas) */
    private BigDecimal totalSaidas;
    /** Lucro total (entradas - saídas) */
    private BigDecimal lucroTotal;
    /** Entradas do mês atual */
    private BigDecimal entradasMes;
    /** Saídas do mês atual */
    private BigDecimal saidasMes;
    /** Lucro do mês atual */
    private BigDecimal lucroMes;
    /** Saldo atual (fluxo de caixa acumulado) */
    private BigDecimal saldoAtual;
    /** Quantidade de transações no mês */
    private long qtdTransacoesMes;
    /** Quantidade de transações pendentes de categorização */
    private long qtdSemCategoria;
}
