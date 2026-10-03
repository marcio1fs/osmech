package com.osmech.rbac;

import jakarta.persistence.*;
import lombok.*;

/**
 * Entidade que representa uma permissão granular do sistema.
 * Ex: "os.criar", "financeiro.visualizar", "usuarios.bloquear"
 */
@Entity
@Table(name = "permissions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Permission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Código único da permissão. Ex: "os.criar" */
    @Column(nullable = false, unique = true, length = 100)
    private String code;

    /** Descrição legível da permissão. */
    @Column(length = 255)
    private String descricao;

    /** Módulo ao qual a permissão pertence. Ex: "OS", "FINANCEIRO". */
    @Column(nullable = false, length = 60)
    private String modulo;
}
