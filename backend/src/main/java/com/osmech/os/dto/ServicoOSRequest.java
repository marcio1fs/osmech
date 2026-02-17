package com.osmech.os.dto;

import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;

/**
 * DTO para criação/atualização de um serviço na OS.
 */
@Data
public class ServicoOSRequest {

    @NotBlank(message = "Descrição do serviço é obrigatória")
    private String descricao;

    @NotNull(message = "Quantidade é obrigatória")
    @Min(value = 1, message = "Quantidade deve ser no mínimo 1")
    private Integer quantidade;

    @NotNull(message = "Valor unitário é obrigatório")
    @DecimalMin(value = "0.01", message = "Valor unitário deve ser maior que zero")
    private BigDecimal valorUnitario;
}
