package com.osmech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
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
    @NotBlank(message = "Tipo de pagamento e obrigatorio")
    @Size(max = 20, message = "Tipo deve ter no maximo 20 caracteres")
    private String tipo;

    /** ID de referencia (assinatura_id ou os_id) */
    private Long referenciaId;

    /** Descricao do pagamento */
    @Size(max = 500, message = "Descricao deve ter no maximo 500 caracteres")
    private String descricao;

    /** Metodo: PIX, CARTAO_CREDITO, CARTAO_DEBITO, DINHEIRO, BOLETO, TRANSFERENCIA */
    @NotBlank(message = "Metodo de pagamento e obrigatorio")
    @Size(max = 20, message = "Metodo deve ter no maximo 20 caracteres")
    private String metodoPagamento;

    /** Valor do pagamento */
    @NotNull(message = "Valor e obrigatorio")
    @Positive(message = "Valor deve ser positivo")
    private BigDecimal valor;

    /** Observacoes */
    @Size(max = 1000, message = "Observacoes devem ter no maximo 1000 caracteres")
    private String observacoes;
}
