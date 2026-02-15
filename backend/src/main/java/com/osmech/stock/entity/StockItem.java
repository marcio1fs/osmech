package com.osmech.stock.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Item do estoque — peça, material ou insumo.
 * Cada item pertence a uma oficina (usuario_id).
 */
@Entity
@Table(name = "stock_items", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"usuario_id", "codigo"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono deste item */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** Código interno da peça (único por oficina) */
    @Column(nullable = false, length = 50)
    private String codigo;

    /** Nome/descrição da peça */
    @Column(nullable = false)
    private String nome;

    /**
     * Categoria da peça:
     * MOTOR, SUSPENSAO, FREIOS, ELETRICA, TRANSMISSAO,
     * ARREFECIMENTO, FILTROS, OLEOS, FUNILARIA, ACESSORIOS, OUTROS
     */
    @Column(nullable = false)
    @Builder.Default
    private String categoria = "OUTROS";

    /** Quantidade atual em estoque */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantidade = 0;

    /** Quantidade mínima — abaixo disso gera alerta */
    @Column(name = "quantidade_minima", nullable = false)
    @Builder.Default
    private Integer quantidadeMinima = 1;

    /** Preço de custo (compra) */
    @Column(name = "preco_custo", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal precoCusto = BigDecimal.ZERO;

    /** Preço de venda (cobrado do cliente) */
    @Column(name = "preco_venda", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal precoVenda = BigDecimal.ZERO;

    /** Localização no estoque (prateleira, gaveta, etc.) */
    private String localizacao;

    /** Se o item está ativo (soft delete) */
    @Column(nullable = false)
    @Builder.Default
    private Boolean ativo = true;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
    }

    /** Verifica se o estoque está abaixo do mínimo */
    public boolean isEstoqueBaixo() {
        return quantidade <= quantidadeMinima;
    }

    /** Verifica se o estoque está zerado */
    public boolean isEstoqueZerado() {
        return quantidade <= 0;
    }
}
