package com.osmech.finance.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Transação financeira — registro de entrada ou saída de dinheiro.
 * Transações nunca são deletadas; apenas estornadas (gera nova transação inversa).
 */
@Entity
@Table(name = "transacoes_financeiras")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransacaoFinanceira {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono desta transação */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /**
     * Tipo da transação:
     * ENTRADA - receita / dinheiro que entrou
     * SAIDA   - despesa / dinheiro que saiu
     */
    @Column(nullable = false)
    private String tipo;

    /** Categoria da transação */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "categoria_id")
    private CategoriaFinanceira categoria;

    /** Descrição da movimentação */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String descricao;

    /** Valor (sempre positivo, o tipo define se é entrada ou saída) */
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal valor;

    /**
     * Tipo de referência (origem automática):
     * OS      - vinda de uma Ordem de Serviço concluída/paga
     * MANUAL  - lançamento manual
     * ESTORNO - estorno de outra transação
     */
    @Column(name = "referencia_tipo")
    @Builder.Default
    private String referenciaTipo = "MANUAL";

    /** ID de referência (ex: id da OS, id da transação estornada) */
    @Column(name = "referencia_id")
    private Long referenciaId;

    /**
     * Método de pagamento:
     * PIX, DINHEIRO, CARTAO, BOLETO, TRANSFERENCIA, OUTRO
     */
    @Column(name = "metodo_pagamento")
    @Builder.Default
    private String metodoPagamento = "DINHEIRO";

    /** Data efetiva da movimentação (pode ser diferente de criadoEm) */
    @Column(name = "data_movimentacao", nullable = false)
    @Builder.Default
    private LocalDateTime dataMovimentacao = LocalDateTime.now();

    /** Observações adicionais */
    @Column(columnDefinition = "TEXT")
    private String observacoes;

    /** Se esta transação é um estorno de outra */
    @Column(name = "estorno")
    @Builder.Default
    private Boolean estorno = false;

    /** ID da transação original que foi estornada (se for estorno) */
    @Column(name = "transacao_estornada_id")
    private Long transacaoEstornadaId;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
