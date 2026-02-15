package com.osmech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * DTO para criar/atualizar uma assinatura.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssinaturaRequest {

    /** Código do plano (PRO, PRO_PLUS, PREMIUM) */
    @NotBlank(message = "Código do plano é obrigatório")
    private String planoCodigo;

    /** Método de pagamento para a assinatura */
    @NotBlank(message = "Método de pagamento é obrigatório")
    private String metodoPagamento;
}
