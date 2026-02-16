package com.osmech.os.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
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

    @Min(value = 1900, message = "Ano deve ser no mínimo 1900")
    @Max(value = 2100, message = "Ano deve ser no máximo 2100")
    private Integer ano;

    @Min(value = 0, message = "Quilometragem não pode ser negativa")
    private Integer quilometragem;

    @NotBlank(message = "Descrição é obrigatória")
    private String descricao;

    private String diagnostico;

    private String pecas;

    @DecimalMin(value = "0.0", message = "Valor não pode ser negativo")
    private BigDecimal valor;

    private String status;

    private Boolean whatsappConsentimento;
}
