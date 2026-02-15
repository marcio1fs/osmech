package com.osmech.payment.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO de resposta para Pagamento.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PagamentoResponse {

    private Long id;
    private Long usuarioId;
    private String tipo;
    private Long referenciaId;
    private String descricao;
    private String metodoPagamento;
    private BigDecimal valor;
    private String status;
    private LocalDateTime pagoEm;
    private String transacaoExternaId;
    private String observacoes;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;
}
