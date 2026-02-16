package com.osmech.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * DTO para requisição de cadastro de usuário.
 */
@Data
public class RegisterRequest {

    @NotBlank(message = "Nome é obrigatório")
    private String nome;

    @NotBlank(message = "Email é obrigatório")
    @Email(message = "Email inválido")
    private String email;

    @NotBlank(message = "Senha é obrigatória")
    @Size(min = 8, message = "Senha deve ter no mínimo 8 caracteres")
    private String senha;

    @NotBlank(message = "Telefone é obrigatório")
    @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
    private String telefone;

    @Size(max = 100, message = "Nome da oficina deve ter no máximo 100 caracteres")
    private String nomeOficina;
}
