package com.osmech.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * DTO para alteração de role/perfil de um usuário.
 */
@Data
public class AlterarRoleRequest {

    @NotBlank(message = "Nova role é obrigatória")
    private String novaRole;
}
