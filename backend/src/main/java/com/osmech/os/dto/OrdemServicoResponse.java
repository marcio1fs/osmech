package com.osmech.os.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO de resposta da Ordem de Serviço.
 * Inclui serviços e itens de estoque associados.
 */
@Data
@AllArgsConstructor
@Builder
public class OrdemServicoResponse {

    private Long id;
    private String clienteNome;
    private String clienteTelefone;
    private String placa;
    private String modelo;
    private Integer ano;
    private Integer quilometragem;
    private String descricao;
    private String diagnostico;
    private String pecas;
    private BigDecimal valor;
    private String status;
    private Boolean whatsappConsentimento;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;
    private LocalDateTime concluidoEm;

    /** Serviços detalhados da OS */
    private List<ServicoOSResponse> servicos;

    /** Itens de estoque utilizados na OS */
    private List<ItemOSResponse> itens;
}
