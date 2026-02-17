package com.osmech.os.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Entidade que representa um serviço dentro de uma Ordem de Serviço.
 * Cada OS pode ter múltiplos serviços com descrição, quantidade e valor unitário.
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

    /** Ordem de Serviço associada */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ordem_servico_id", nullable = false)
    private OrdemServico ordemServico;

    /** Descrição do serviço */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String descricao;

    /** Quantidade do serviço */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantidade = 1;

    /** Valor unitário do serviço */
    @Column(name = "valor_unitario", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valorUnitario = BigDecimal.ZERO;

    /** Valor total (quantidade * valorUnitario) — calculado antes de salvar */
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
