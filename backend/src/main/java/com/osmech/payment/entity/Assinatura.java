package com.osmech.payment.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entidade que representa uma Assinatura de plano de uma oficina.
 */
@Entity
@Table(name = "assinaturas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Assinatura {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono desta assinatura */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** ID do plano assinado (referência à tabela planos) */
    @Column(name = "plano_id", nullable = false)
    private Long planoId;

    /** Código do plano (PRO, PRO_PLUS, PREMIUM) para consulta rápida */
    @Column(name = "plano_codigo", nullable = false)
    private String planoCodigo;

    /** Valor mensal da assinatura no momento da contratação */
    @Column(name = "valor_mensal", nullable = false, precision = 10, scale = 2)
    private BigDecimal valorMensal;

    /**
     * Status da assinatura:
     * ACTIVE - Ativa e em dia
     * PAST_DUE - Pagamento atrasado (período de carência)
     * CANCELED - Cancelada pelo usuário
     * SUSPENDED - Suspensa por inadimplência
     */
    @Column(nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    /** Data de início da assinatura */
    @Column(name = "data_inicio", nullable = false)
    @Builder.Default
    private LocalDate dataInicio = LocalDate.now();

    /** Data do próximo faturamento */
    @Column(name = "proxima_cobranca", nullable = false)
    private LocalDate proximaCobranca;

    /** Data de cancelamento (se cancelada) */
    @Column(name = "data_cancelamento")
    private LocalDate dataCancelamento;

    /** Dias de atraso antes de suspender (carência padrão: 5 dias) */
    @Column(name = "dias_carencia")
    @Builder.Default
    private Integer diasCarencia = 5;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
    }
}
