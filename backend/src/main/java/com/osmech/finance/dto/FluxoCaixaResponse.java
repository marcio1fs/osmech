package com.osmech.finance.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * DTO de resposta do fluxo de caixa diário.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FluxoCaixaResponse {
    private Long id;
    private LocalDate data;
    private BigDecimal totalEntradas;
    private BigDecimal totalSaidas;
    private BigDecimal saldo;
    private BigDecimal saldoAcumulado;
    /** true quando o dia não tem movimentação real (preenchido para continuidade) */
    private boolean semMovimentacao;
}
