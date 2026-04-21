package com.osmech.mecanico.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class MecanicoRequest {
    @NotBlank(message = "Nome do mecanico e obrigatorio")
    @Size(max = 120, message = "Nome deve ter no maximo 120 caracteres")
    private String nome;

    @Size(max = 20, message = "Telefone deve ter no maximo 20 caracteres")
    private String telefone;

    @Size(max = 120, message = "Especialidade deve ter no maximo 120 caracteres")
    private String especialidade;

    @DecimalMin(value = "0.0", message = "Percentual de comissao deve ser no minimo 0")
    @DecimalMax(value = "100.0", message = "Percentual de comissao deve ser no maximo 100")
    private BigDecimal percentualComissao;

    private Boolean ativo;
}
