package com.osmech.os.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Entidade que representa um servico dentro de uma Ordem de Servico.
 */
@Entity
@Table(name = "servicos_os")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServicoOS {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ordem_servico_id", nullable = false)
    private OrdemServico ordemServico;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descricao;

    @Column(nullable = false)
    @Builder.Default
    private Integer quantidade = 1;

    @Column(name = "valor_unitario", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorUnitario = BigDecimal.ZERO;

    @Column(name = "valor_total", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorTotal = BigDecimal.ZERO;

    @Column(name = "mecanico_id")
    private Long mecanicoId;

    @Column(name = "mecanico_nome")
    private String mecanicoNome;

    @Column(name = "percentual_comissao", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal percentualComissao = BigDecimal.ZERO;

    @Column(name = "valor_comissao", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorComissao = BigDecimal.ZERO;

    @PrePersist
    @PreUpdate
    public void calcularTotal() {
        if (quantidade != null && valorUnitario != null) {
            this.valorTotal = valorUnitario.multiply(BigDecimal.valueOf(quantidade));
        }

        if (valorTotal != null && percentualComissao != null) {
            this.valorComissao = valorTotal
                    .multiply(percentualComissao)
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        }
    }
}
