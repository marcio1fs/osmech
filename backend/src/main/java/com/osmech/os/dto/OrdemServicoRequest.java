package com.osmech.os.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

/**
 * DTO para criação/atualização de Ordem de Serviço.
 */
@Data
public class OrdemServicoRequest {

    @NotBlank(message = "Nome do cliente é obrigatório")
    private String clienteNome;

    private String clienteTelefone;

    @NotBlank(message = "Placa é obrigatória")
    private String placa;

    @NotBlank(message = "Modelo é obrigatório")
    private String modelo;

    private Integer ano;

    private Integer quilometragem;

    @NotBlank(message = "Descrição é obrigatória")
    private String descricao;

    private String diagnostico;

    private String pecas;

    private BigDecimal valor;

    private String status;

    private Boolean whatsappConsentimento;
}
