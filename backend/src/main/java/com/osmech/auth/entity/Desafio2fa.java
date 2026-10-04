package com.osmech.auth.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Desafio de segundo fator pendente (Fase 4).
 * Criado no login quando o usuário tem 2FA ativo; o código de 6 dígitos
 * vai por e-mail e só o hash fica no banco.
 */
@Entity
@Table(name = "desafios_2fa")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Desafio2fa {

    public static final int MAX_TENTATIVAS = 5;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** SHA-256 (hex) do código de 6 dígitos */
    @Column(name = "codigo_hash", nullable = false, length = 64)
    private String codigoHash;

    @Column(nullable = false)
    @Builder.Default
    private Integer tentativas = 0;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "expira_em", nullable = false)
    private LocalDateTime expiraEm;

    @Transient
    public boolean isExpirado() {
        return expiraEm.isBefore(LocalDateTime.now());
    }
}
