package com.osmech.payment.dto;

import lombok.*;
import java.math.BigDecimal;

/**
 * DTO com resumo financeiro para o dashboard de pagamentos.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ResumoFinanceiroResponse {

    /** Receita total (todos os pagamentos confirmados) */
    private BigDecimal receitaTotal;

    /** Receita no mês atual */
    private BigDecimal receitaMesAtual;

    /** Total de pagamentos pendentes */
    private BigDecimal totalPendente;

    /** Quantidade de pagamentos no mês */
    private long qtdPagamentosMes;

    /** Quantidade de pagamentos pendentes */
    private long qtdPendentes;

    /** Quantidade de OS pagas no mês */
    private long qtdOsPagasMes;

    /** Status da assinatura atual */
    private String statusAssinatura;

    /** Plano atual */
    private String planoAtual;

    /** Valor da assinatura */
    private BigDecimal valorAssinatura;
}
