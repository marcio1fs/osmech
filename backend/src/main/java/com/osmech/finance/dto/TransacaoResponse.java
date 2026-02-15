package com.osmech.finance.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO de resposta de uma transação financeira.
 */
@Data
@AllArgsConstructor
@Builder
public class TransacaoResponse {
    private Long id;
    private String tipo;
    private Long categoriaId;
    private String categoriaNome;
    private String descricao;
    private BigDecimal valor;
    private String referenciaTipo;
    private Long referenciaId;
    private String metodoPagamento;
    private LocalDateTime dataMovimentacao;
    private String observacoes;
    private Boolean estorno;
    private Long transacaoEstornadaId;
    private LocalDateTime criadoEm;
}
