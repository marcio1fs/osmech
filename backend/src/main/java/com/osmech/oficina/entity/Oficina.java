package com.osmech.oficina.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Oficina — o TENANT do sistema (Fase 1 do plano de controle de usuários).
 *
 * Até a Fase 0, "usuário" e "oficina" eram a mesma coisa. A partir desta
 * entidade, a oficina passa a ser a dona dos dados de negócio: usuários
 * pertencem a uma oficina ({@code usuarios.oficina_id}) e as colunas
 * {@code usuario_id} das tabelas de negócio armazenam, na prática, o id da
 * oficina (ver migration V12 — backfill mantém oficina.id = id do dono).
 *
 * Campos de empresa que antes moravam em {@code usuarios} (nome da oficina,
 * CNPJ, endereço, logo, site) são espelhados aqui; o {@code plano} da
 * assinatura é autoritativo nesta entidade (o campo em usuarios é espelho
 * para telas legadas).
 */
@Entity
@Table(name = "oficinas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Oficina {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Nome da oficina */
    @Column(nullable = false)
    private String nome;

    /** CNPJ da oficina (apenas dígitos) */
    @Column(length = 18)
    private String cnpj;

    private String telefone;

    private String email;

    @Column(name = "endereco_logradouro", length = 120)
    private String enderecoLogradouro;

    @Column(name = "endereco_numero", length = 20)
    private String enderecoNumero;

    @Column(name = "endereco_complemento", length = 120)
    private String enderecoComplemento;

    @Column(name = "endereco_bairro", length = 80)
    private String enderecoBairro;

    @Column(name = "endereco_cidade", length = 80)
    private String enderecoCidade;

    @Column(name = "endereco_estado", length = 2)
    private String enderecoEstado;

    @Column(name = "endereco_cep", length = 10)
    private String enderecoCep;

    @Column(length = 120)
    private String site;

    @Column(name = "logo_url")
    private String logoUrl;

    /**
     * Plano da assinatura (FREE, PRO, PRO_PLUS, PREMIUM) — FONTE AUTORITATIVA.
     * O campo usuarios.plano passa a ser espelho para telas legadas.
     */
    @Column(nullable = false)
    @Builder.Default
    private String plano = "FREE";

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
