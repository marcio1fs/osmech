package com.osmech.security;

import java.security.Principal;

/**
 * Principal autenticado exposto no SecurityContext pelo JwtAuthFilter.
 *
 * Implementa {@link Principal} para que {@code Authentication#getName()}
 * continue retornando o e-mail — nenhum service existente quebra.
 * Carrega também id do usuário, id da oficina (tenant) e papel.
 */
public record UsuarioAutenticado(Long id, Long oficinaId, String email, String papel) implements Principal {

    @Override
    public String getName() {
        return email;
    }
}
