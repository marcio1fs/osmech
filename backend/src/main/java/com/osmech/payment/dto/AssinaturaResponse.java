package com.osmech.payment.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DTO de resposta para Assinatura.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssinaturaResponse {

    private Long id;
    private Long usuarioId;
    private Long planoId;
    private String planoCodigo;
    private String planoNome;
    private BigDecimal valorMensal;
    private String status;
    private LocalDate dataInicio;
    private LocalDate proximaCobranca;
    private LocalDate dataCancelamento;
    private Integer diasCarencia;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;

    /**
     * Dados opcionais de pagamento via Mercado Pago (Checkout Pro).
     * - checkoutUrl: URL para redirecionar o usuário ao checkout.
     * - preferenceId: identificador da preferência criada no Mercado Pago.
     */
    private String checkoutUrl;
    private String preferenceId;
}
