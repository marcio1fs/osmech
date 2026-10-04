package com.osmech.sessao.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Sessão autenticada de longa duração (Fase 4).
 *
 * O cliente guarda o refresh token em claro; no banco fica apenas o hash
 * SHA-256 — um vazamento do banco não entrega tokens utilizáveis.
 * A rotação (um token novo a cada refresh) cria a trilha que permite
 * detectar reuso de token já trocado.
 */
@Entity
@Table(name = "sessoes_usuario")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SessaoUsuario {

    public static final String MOTIVO_LOGOUT = "LOGOUT";
    public static final String MOTIVO_ROTACAO = "ROTACAO";
    public static final String MOTIVO_EXPIRADA = "EXPIRADA";
    public static final String MOTIVO_REUSO_DETECTADO = "REUSO_DETECTADO";
    public static final String MOTIVO_SENHA_ALTERADA = "SENHA_ALTERADA";
    public static final String MOTIVO_CONTA_DESATIVADA = "CONTA_DESATIVADA";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /**
     * Oficina da sessão. Nullable: contas legadas (criadas antes do
     * multi-tenant) podem não ter oficina e ainda precisam logar.
     */
    @Column(name = "oficina_id")
    private Long oficinaId;

    /** SHA-256 (hex) do refresh token — nunca o token em claro */
    @Column(name = "refresh_token_hash", nullable = false, unique = true, length = 64)
    private String refreshTokenHash;

    /** Navegador/app que iniciou a sessão (melhor esforço, pode ser null) */
    @Column(name = "user_agent", length = 300)
    private String userAgent;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "expira_em", nullable = false)
    private LocalDateTime expiraEm;

    @Column(name = "revogado_em")
    private LocalDateTime revogadoEm;

    @Column(name = "motivo_revogacao", length = 60)
    private String motivoRevogacao;

    @Transient
    public boolean isAtiva() {
        return revogadoEm == null && expiraEm.isAfter(LocalDateTime.now());
    }
}
