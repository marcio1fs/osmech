package com.osmech.os.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * DTO para criacao/atualizacao de um servico na OS.
 */
@Data
public class ServicoOSRequest {

    @NotBlank(message = "Descricao do servico e obrigatoria")
    private String descricao;

    @NotNull(message = "Quantidade e obrigatoria")
    @Min(value = 1, message = "Quantidade deve ser no minimo 1")
    private Integer quantidade;

    @NotNull(message = "Valor unitario e obrigatorio")
    @DecimalMin(value = "0.01", message = "Valor unitario deve ser maior que zero")
    private BigDecimal valorUnitario;

    private Long mecanicoId;

    @DecimalMin(value = "0.0", message = "Percentual de comissao deve ser no minimo 0")
    @DecimalMax(value = "100.0", message = "Percentual de comissao deve ser no maximo 100")
    private BigDecimal percentualComissao;
}
