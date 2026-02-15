package com.osmech.user.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidade que representa um usuário do sistema (dono de oficina / admin).
 */
@Entity
@Table(name = "usuarios")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String senha;

    @Column(nullable = false)
    private String telefone;

    /** Nome da oficina do usuário */
    @Column(name = "nome_oficina")
    private String nomeOficina;

    /** Role do usuário: ADMIN ou OFICINA */
    @Column(nullable = false)
    @Builder.Default
    private String role = "OFICINA";

    /** Plano atual: FREE, PRO, PRO_PLUS, PREMIUM */
    @Column(nullable = false)
    @Builder.Default
    private String plano = "FREE";

    /** Indica se a assinatura está ativa */
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
