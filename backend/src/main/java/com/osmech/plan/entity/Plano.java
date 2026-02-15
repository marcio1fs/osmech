package com.osmech.plan.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Entidade que representa um Plano de assinatura.
 * Os planos são pré-cadastrados no banco.
 */
@Entity
@Table(name = "planos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Plano {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Código do plano: PRO, PRO_PLUS, PREMIUM */
    @Column(nullable = false, unique = true)
    private String codigo;

    /** Nome de exibição */
    @Column(nullable = false)
    private String nome;

    /** Preço mensal */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal preco;

    /** Limite de OS por mês (0 = ilimitado) */
    @Column(name = "limite_os")
    @Builder.Default
    private Integer limiteOs = 0;

    /** Acesso ao WhatsApp automático */
    @Column(name = "whatsapp_habilitado")
    @Builder.Default
    private Boolean whatsappHabilitado = false;

    /** Acesso à IA */
    @Column(name = "ia_habilitada")
    @Builder.Default
    private Boolean iaHabilitada = false;

    /** Descrição das features do plano */
    @Column(columnDefinition = "TEXT")
    private String descricao;

    @Column(nullable = false)
    @Builder.Default
    private Boolean ativo = true;
}
