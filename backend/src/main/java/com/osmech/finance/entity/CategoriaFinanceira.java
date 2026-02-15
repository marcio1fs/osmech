package com.osmech.finance.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Categoria financeira (ex: Peças, Salários, Aluguel, Serviço OS).
 * Cada oficina pode ter suas próprias categorias.
 */
@Entity
@Table(name = "categorias_financeiras")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoriaFinanceira {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono desta categoria. NULL = categoria padrão do sistema */
    @Column(name = "usuario_id")
    private Long usuarioId;

    /** Nome da categoria */
    @Column(nullable = false)
    private String nome;

    /**
     * Tipo da categoria:
     * ENTRADA - receita
     * SAIDA   - despesa
     */
    @Column(nullable = false)
    private String tipo;

    /** Ícone (opcional, para frontend) */
    private String icone;

    /** Se é categoria do sistema (não pode ser alterada pelo usuário) */
    @Column(name = "sistema")
    @Builder.Default
    private Boolean sistema = false;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
