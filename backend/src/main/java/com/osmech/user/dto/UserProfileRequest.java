package com.osmech.user.dto;

import lombok.Data;

/**
 * DTO para atualização de perfil do usuário.
 */
@Data
public class UserProfileRequest {
    private String nome;
    private String telefone;
    private String nomeOficina;
}
