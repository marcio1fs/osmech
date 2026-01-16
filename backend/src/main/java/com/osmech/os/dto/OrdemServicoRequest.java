package com.osmech.os.dto;

import com.osmech.os.OrdemServico;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class OrdemServicoRequest {
    @NotBlank(message = "Nome do cliente é obrigatório")
    private String nomeCliente;

    @NotBlank(message = "Telefone é obrigatório")
    private String telefone;

    @NotBlank(message = "Placa é obrigatória")
    private String placa;

    @NotBlank(message = "Modelo do veículo é obrigatório")
    private String modelo;

    @NotBlank(message = "Descrição do problema é obrigatória")
    private String descricaoProblema;

    private String servicosRealizados;

    private BigDecimal valor;

    @NotNull(message = "Status é obrigatório")
    private OrdemServico.StatusOS status;
}
