package com.osmech.os.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Entidade que representa um item de estoque utilizado em uma Ordem de Serviço.
 * Ao criar/atualizar a OS, os itens geram movimentações de SAÍDA no estoque.
 */
@Entity
@Table(name = "itens_os")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemOS {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Ordem de Serviço associada */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ordem_servico_id", nullable = false)
    private OrdemServico ordemServico;

    /** ID do item de estoque (referência) */
    @Column(name = "stock_item_id", nullable = false)
    private Long stockItemId;

    /** Nome do item (snapshot no momento da criação) */
    @Column(name = "nome_item", nullable = false)
    private String nomeItem;

    /** Código do item (snapshot) */
    @Column(name = "codigo_item")
    private String codigoItem;

    /** Quantidade utilizada */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantidade = 1;

    /** Valor unitário (preço de venda do item no momento) */
    @Column(name = "valor_unitario", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorUnitario = BigDecimal.ZERO;

    /** Valor total (quantidade * valorUnitario) */
    @Column(name = "valor_total", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorTotal = BigDecimal.ZERO;

    @PrePersist
    @PreUpdate
    public void calcularTotal() {
        if (quantidade != null && valorUnitario != null) {
            this.valorTotal = valorUnitario.multiply(BigDecimal.valueOf(quantidade));
        }
    }
}
