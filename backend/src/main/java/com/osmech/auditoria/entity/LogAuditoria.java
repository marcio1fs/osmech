package com.osmech.auditoria.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Trilha de auditoria de ações sensíveis (Fase 4).
 * oficina_id pode ser null (ex.: tentativa de login de e-mail inexistente).
 */
@Entity
@Table(name = "audit_log")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LogAuditoria {

    // ---- ações de autenticação/sessão ----
    public static final String LOGIN = "LOGIN";
    public static final String LOGIN_RECUSADO = "LOGIN_RECUSADO";
    public static final String LOGIN_2FA_SOLICITADO = "LOGIN_2FA_SOLICITADO";
    public static final String LOGIN_2FA_OK = "LOGIN_2FA_OK";
    public static final String LOGIN_2FA_RECUSADO = "LOGIN_2FA_RECUSADO";
    public static final String LOGOUT = "LOGOUT";
    public static final String SESSAO_RENOVADA = "SESSAO_RENOVADA";
    public static final String SESSAO_REUSO_DETECTADO = "SESSAO_REUSO_DETECTADO";
    public static final String SENHA_REDEFINIDA = "SENHA_REDEFINIDA";
    public static final String SENHA_ALTERADA = "SENHA_ALTERADA";
    public static final String DOIS_FA_ATIVADO = "DOIS_FA_ATIVADO";
    public static final String DOIS_FA_DESATIVADO = "DOIS_FA_DESATIVADO";
    public static final String EMAIL_VERIFICACAO_REENVIADO = "EMAIL_VERIFICACAO_REENVIADO";

    // ---- ações de equipe ----
    public static final String CONVITE_CRIADO = "CONVITE_CRIADO";
    public static final String CONVITE_REVOGADO = "CONVITE_REVOGADO";
    public static final String CONVITE_REENVIADO = "CONVITE_REENVIADO";
    public static final String CONVITE_ACEITO = "CONVITE_ACEITO";
    public static final String MEMBRO_PAPEL_ALTERADO = "MEMBRO_PAPEL_ALTERADO";
    public static final String MEMBRO_DESATIVADO = "MEMBRO_DESATIVADO";
    public static final String MEMBRO_ATIVADO = "MEMBRO_ATIVADO";

    // Ações administrativas da plataforma (AdminController)
    public static final String ADMIN_USUARIO_ATIVADO = "ADMIN_USUARIO_ATIVADO";
    public static final String ADMIN_USUARIO_DESATIVADO = "ADMIN_USUARIO_DESATIVADO";
    public static final String ADMIN_PLANO_ALTERADO = "ADMIN_PLANO_ALTERADO";
    public static final String ADMIN_PAPEL_ALTERADO = "ADMIN_PAPEL_ALTERADO";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "oficina_id")
    private Long oficinaId;

    @Column(name = "usuario_id")
    private Long usuarioId;

    /** E-mail denormalizado — facilita leitura e sobrevive à remoção do usuário */
    @Column(name = "usuario_email", length = 150)
    private String usuarioEmail;

    @Column(nullable = false, length = 60)
    private String acao;

    @Column(length = 1000)
    private String detalhes;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
