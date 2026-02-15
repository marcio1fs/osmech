package com.osmech.finance.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Fluxo de caixa diário — consolidação de entradas/saídas por dia.
 * Atualizado automaticamente a cada transação.
 */
@Entity
@Table(name = "fluxo_caixa", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"usuario_id", "data"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FluxoCaixa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** Data do fluxo */
    @Column(nullable = false)
    private LocalDate data;

    /** Total de entradas no dia */
    @Column(name = "total_entradas", nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal totalEntradas = BigDecimal.ZERO;

    /** Total de saídas no dia */
    @Column(name = "total_saidas", nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal totalSaidas = BigDecimal.ZERO;

    /** Saldo do dia (entradas - saídas) */
    @Column(nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal saldo = BigDecimal.ZERO;

    /** Saldo acumulado até este dia */
    @Column(name = "saldo_acumulado", nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal saldoAcumulado = BigDecimal.ZERO;

    @Column(name = "atualizado_em")
    @Builder.Default
    private LocalDateTime atualizadoEm = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
    }
}
