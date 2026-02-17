package com.osmech.os.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Entidade que representa uma Ordem de Serviço.
 */
@Entity
@Table(name = "ordens_servico")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrdemServico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID do usuário (oficina) dono desta OS */
    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    /** Nome do cliente da OS */
    @Column(name = "cliente_nome", nullable = false)
    private String clienteNome;

    /** Telefone do cliente (para WhatsApp) */
    @Column(name = "cliente_telefone")
    private String clienteTelefone;

    /** Placa do veículo */
    @Column(nullable = false)
    private String placa;

    /** Modelo do veículo */
    @Column(nullable = false)
    private String modelo;

    /** Ano do veículo */
    private Integer ano;

    /** Quilometragem atual */
    private Integer quilometragem;

    /** Descrição do problema / serviço solicitado */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String descricao;

    /** Diagnóstico do mecânico */
    @Column(columnDefinition = "TEXT")
    private String diagnostico;

    /** Peças utilizadas */
    @Column(columnDefinition = "TEXT")
    private String pecas;

    /** Valor total do serviço */
    @Column(precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal valor = BigDecimal.ZERO;

    /**
     * Status da OS:
     * ABERTA, EM_ANDAMENTO, AGUARDANDO_PECA, AGUARDANDO_APROVACAO, CONCLUIDA, CANCELADA
     */
    @Column(nullable = false)
    @Builder.Default
    private String status = "ABERTA";

    /** Cliente autorizou receber mensagens no WhatsApp */
    @Column(name = "whatsapp_consentimento")
    @Builder.Default
    private Boolean whatsappConsentimento = false;

    /** Serviços da OS (descrição, quantidade, valor) */
    @OneToMany(mappedBy = "ordemServico", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ServicoOS> servicos = new ArrayList<>();

    /** Itens de estoque utilizados na OS */
    @OneToMany(mappedBy = "ordemServico", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ItemOS> itens = new ArrayList<>();

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @Column(name = "concluido_em")
    private LocalDateTime concluidoEm;

    @PreUpdate
    protected void onUpdate() {
        this.atualizadoEm = LocalDateTime.now();
        if ("CONCLUIDA".equals(this.status) && this.concluidoEm == null) {
            this.concluidoEm = LocalDateTime.now();
        }
    }
}
