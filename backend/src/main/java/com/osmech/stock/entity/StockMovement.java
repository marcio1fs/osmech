package com.osmech.stock.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Movimentação de estoque — registro de entrada ou saída de peças.
 * Toda alteração de quantidade gera uma movimentação para rastreabilidade.
 */
@Entity
@Table(name = "stock_movements")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** Item do estoque movimentado */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "stock_item_id", nullable = false)
    private StockItem stockItem;

    /**
     * Tipo da movimentação:
     * ENTRADA - compra, ajuste positivo, devolução
     * SAIDA   - uso em OS, perda, ajuste negativo, consumo interno
     */
    @Column(nullable = false)
    private String tipo;

    /** Quantidade movimentada (sempre positivo) */
    @Column(nullable = false)
    private Integer quantidade;

    /** Quantidade anterior (antes da movimentação) */
    @Column(name = "quantidade_anterior", nullable = false)
    private Integer quantidadeAnterior;

    /** Quantidade posterior (depois da movimentação) */
    @Column(name = "quantidade_posterior", nullable = false)
    private Integer quantidadePosterior;

    /**
     * Motivo/origem da movimentação:
     * COMPRA, AJUSTE, PERDA, CONSUMO_INTERNO, OS, DEVOLUCAO
     */
    @Column(nullable = false)
    private String motivo;

    /** Descrição/observação da movimentação */
    @Column(columnDefinition = "TEXT")
    private String descricao;

    /** ID da OS relacionada (quando motivo = OS) */
    @Column(name = "ordem_servico_id")
    private Long ordemServicoId;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
