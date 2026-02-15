package com.osmech.payment.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidade que representa um Pagamento.
 * Pode ser pagamento de assinatura ou pagamento de OS pelo cliente.
 */
@Entity
@Table(name = "pagamentos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Pagamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono deste pagamento */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /**
     * Tipo do pagamento:
     * ASSINATURA - Pagamento da mensalidade do plano
     * OS - Pagamento de uma Ordem de Serviço pelo cliente
     */
    @Column(nullable = false)
    private String tipo;

    /** ID de referência (assinatura_id ou os_id, dependendo do tipo) */
    @Column(name = "referencia_id")
    private Long referenciaId;

    /** Descrição do pagamento */
    @Column(columnDefinition = "TEXT")
    private String descricao;

    /**
     * Método de pagamento:
     * PIX, CARTAO_CREDITO, CARTAO_DEBITO, DINHEIRO, BOLETO, TRANSFERENCIA
     */
    @Column(name = "metodo_pagamento", nullable = false)
    private String metodoPagamento;

    /** Valor do pagamento */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal valor;

    /**
     * Status do pagamento:
     * PENDENTE - Aguardando pagamento
     * PAGO - Pagamento confirmado
     * FALHOU - Pagamento rejeitado/falhou
     * CANCELADO - Pagamento cancelado
     * REEMBOLSADO - Pagamento estornado
     */
    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDENTE";

    /** Data/hora do pagamento efetivo (quando foi confirmado) */
    @Column(name = "pago_em")
    private LocalDateTime pagoEm;

    /** ID externo da transação (gateway de pagamento) */
    @Column(name = "transacao_externa_id")
    private String transacaoExternaId;

    /** Observações adicionais */
    @Column(columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
        if ("PAGO".equals(this.status) && this.pagoEm == null) {
            this.pagoEm = LocalDateTime.now();
        }
    }
}
