package com.osmech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;
import java.math.BigDecimal;

/**
 * DTO para registrar um pagamento (assinatura ou OS).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PagamentoRequest {

    /** Tipo: ASSINATURA ou OS */
    @NotBlank(message = "Tipo de pagamento é obrigatório")
    private String tipo;

    /** ID de referência (assinatura_id ou os_id) */
    private Long referenciaId;

    /** Descrição do pagamento */
    private String descricao;

    /** Método: PIX, CARTAO_CREDITO, CARTAO_DEBITO, DINHEIRO, BOLETO, TRANSFERENCIA */
    @NotBlank(message = "Método de pagamento é obrigatório")
    private String metodoPagamento;

    /** Valor do pagamento */
    @NotNull(message = "Valor é obrigatório")
    @Positive(message = "Valor deve ser positivo")
    private BigDecimal valor;

    /** Observações */
    private String observacoes;
}
