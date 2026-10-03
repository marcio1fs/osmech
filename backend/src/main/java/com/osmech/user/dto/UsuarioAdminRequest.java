package com.osmech.user.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

/**
 * DTO para criação e edição de usuário pelo administrador.
 */
@Data
public class UsuarioAdminRequest {

    @NotBlank(message = "Nome é obrigatório")
    @Size(min = 2, max = 120, message = "Nome deve ter entre 2 e 120 caracteres")
    private String nome;

    @NotBlank(message = "E-mail é obrigatório")
    @Email(message = "E-mail inválido")
    private String email;

    /** Senha (obrigatório na criação, opcional na edição). */
    @Size(min = 8, message = "Senha deve ter pelo menos 8 caracteres")
    private String senha;

    @NotBlank(message = "Role é obrigatória")
    private String role;

    private String telefone;

    /** true = ativo, false = bloqueado */
    private Boolean ativo = true;
}
