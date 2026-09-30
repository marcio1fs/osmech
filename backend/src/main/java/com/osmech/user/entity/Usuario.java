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
    /** CNPJ da oficina */
    @Column(name = "cnpj_oficina")
    private String cnpjOficina;

    /** Endereco da oficina */
    @Column(name = "endereco_logradouro")
    private String enderecoLogradouro;

    @Column(name = "endereco_numero")
    private String enderecoNumero;

    @Column(name = "endereco_complemento")
    private String enderecoComplemento;

    @Column(name = "endereco_bairro")
    private String enderecoBairro;

    @Column(name = "endereco_cidade")
    private String enderecoCidade;

    @Column(name = "endereco_estado")
    private String enderecoEstado;

    @Column(name = "endereco_cep")
    private String enderecoCep;

    @Column(name = "logo_url")
    private String logoUrl;

    /** Site da oficina */
    @Column(name = "site_oficina")
    private String siteOficina;

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

    /**
     * Oficina (tenant) à qual o usuário pertence — Fase 1.
     * Para usuários migrados pelo backfill, oficina_id == id do próprio
     * usuário (invariante que preserva os dados de negócio existentes).
     * É OBRIGATÓRIO para autenticação (JwtAuthFilter rejeita sem ele).
     */
    @Column(name = "oficina_id")
    private Long oficinaId;

    // --- Campos de verificação de e-mail e recuperação de senha (migration V7) ---

    /**
     * Indica se o e-mail do usuário foi verificado.
     * Mantido nullable de propósito: em bancos legados com ddl-auto=update,
     * uma coluna nova NOT NULL falharia no ALTER TABLE com linhas existentes.
     * Leituras devem usar Boolean.TRUE.equals(...) (null = não verificado).
     */
    @Column(name = "email_verificado")
    @Builder.Default
    private Boolean emailVerificado = false;

    /** Token único de verificação de e-mail (null após verificado) */
    @Column(name = "verification_token")
    private String verificationToken;

    /**
     * 2FA por código de e-mail (Fase 4). Opt-in por usuário.
     * Nullable de propósito mesmo motivo de emailVerificado (ddl-auto=update).
     */
    @Column(name = "dois_fa_ativo")
    @Builder.Default
    private Boolean doisFaAtivo = false;

    /** Token único de recuperação de senha (null após uso/expiração) */
    @Column(name = "reset_password_token")
    private String resetPasswordToken;

    /** Expiração do token de recuperação de senha */
    @Column(name = "reset_password_token_expiry")
    private LocalDateTime resetPasswordTokenExpiry;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    /** Getter alias para compatibilidade com código que usa getResetTokenExpiry */
    public LocalDateTime getResetTokenExpiry() {
        return resetPasswordTokenExpiry;
    }

    /** Setter alias para compatibilidade com código que usa setResetTokenExpiry */
    public void setResetTokenExpiry(LocalDateTime resetTokenExpiry) {
        this.resetPasswordTokenExpiry = resetTokenExpiry;
    }

    /**
     * ID do usuário dono da oficina (para sub-usuários como ATENDENTE, MECANICO etc.)
     * NULL para usuários donos de oficina (OFICINA/GERENTE/ADMIN).
     */
    @Column(name = "owner_id")
    private Long ownerId;

    /** Data/hora do último acesso autenticado ao sistema. */
    @Column(name = "ultimo_acesso")
    private LocalDateTime ultimoAcesso;

    /**
     * Permissões granulares adicionais específicas atribuídas diretamente a este usuário.
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "usuario_permissions", joinColumns = @JoinColumn(name = "usuario_id"))
    @Column(name = "permission_code")
    @Builder.Default
    private java.util.Set<String> customPermissions = new java.util.HashSet<>();

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
    }
}


