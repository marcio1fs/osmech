package com.osmech.user.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * DTO para edição de usuário pelo administrador.
 * Na edição, o e-mail não é alterado e a role tem endpoint próprio ou opcional.
 */
@Data
public class UsuarioAdminUpdateRequest {

    @Size(min = 2, max = 120, message = "Nome deve ter entre 2 e 120 caracteres")
    private String nome;

    private String email;

    /** Senha (opcional na edição). */
    @Size(min = 8, message = "Senha deve ter pelo menos 8 caracteres")
    private String senha;

    private String role;

    private String telefone;

    /** true = ativo, false = bloqueado */
    private Boolean ativo;
}
