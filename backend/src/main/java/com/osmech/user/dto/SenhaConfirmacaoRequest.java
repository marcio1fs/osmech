package com.osmech.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * DTO para operações sensíveis confirmadas com a senha atual
 * (ex.: ativar/desativar 2FA).
 */
@Data
public class SenhaConfirmacaoRequest {

    @NotBlank(message = "Senha é obrigatória")
    private String senha;
}
