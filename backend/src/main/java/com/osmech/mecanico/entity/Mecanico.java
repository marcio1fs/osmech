package com.osmech.mecanico.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "mecanicos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Mecanico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /**
     * Conta de usuário (login) do mecânico, quando ele faz parte da equipe.
     * Preenchida automaticamente ao aceitar um convite com papel MECANICO
     * ou manualmente via PUT /mecanicos/{id}/vincular-conta.
     * Nota: usuarioId acima é a oficina (tenant); este campo é a PESSOA.
     */
    @Column(name = "usuario_conta_id")
    private Long usuarioContaId;

    @Column(nullable = false)
    private String nome;

    private String telefone;

    private String especialidade;

    @Column(name = "percentual_comissao", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal percentualComissao = BigDecimal.ZERO;

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
}
