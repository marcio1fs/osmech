package com.osmech.os.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * DTO para atualização de status de uma Ordem de Serviço.
 */
@Data
public class StatusUpdateRequest {

    @NotBlank(message = "Status é obrigatório")
    private String status;
}
