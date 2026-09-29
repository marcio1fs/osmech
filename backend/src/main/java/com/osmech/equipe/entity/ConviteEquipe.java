package com.osmech.equipe.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Convite para uma pessoa entrar na equipe de uma oficina (Fase 3).
 *
 * Fluxo: DONO convida por e-mail → convidado recebe link com token →
 * aceite cria o usuário já vinculado à oficina com o papel definido.
 * Token de uso único com expiração (7 dias por padrão).
 */
@Entity
@Table(name = "convites_equipe")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConviteEquipe {

    public static final String STATUS_PENDENTE = "PENDENTE";
    public static final String STATUS_ACEITO = "ACEITO";
    public static final String STATUS_REVOGADO = "REVOGADO";
    public static final String STATUS_EXPIRADO = "EXPIRADO";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Oficina (tenant) que está convidando */
    @Column(name = "oficina_id", nullable = false)
    private Long oficinaId;

    /** E-mail do convidado */
    @Column(nullable = false)
    private String email;

    /** Papel que o convidado terá na oficina (GERENTE, ATENDENTE ou MECANICO) */
    @Column(nullable = false)
    private String papel;

    /** Token único do convite (vai no link do e-mail) */
    @Column(nullable = false, unique = true)
    private String token;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = STATUS_PENDENTE;

    /** Usuário (dono) que criou o convite */
    @Column(name = "criado_por_usuario_id")
    private Long criadoPorUsuarioId;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    /** Data/hora de expiração do token */
    @Column(name = "expira_em", nullable = false)
    private LocalDateTime expiraEm;

    @Column(name = "aceito_em")
    private LocalDateTime aceitoEm;

    /** Marca o convite como expirado se passou da validade. Retorna true se expirou. */
    public boolean marcarExpiradoSeVencido(LocalDateTime agora) {
        if (STATUS_PENDENTE.equals(status) && expiraEm != null && expiraEm.isBefore(agora)) {
            this.status = STATUS_EXPIRADO;
            return true;
        }
        return false;
    }
}
