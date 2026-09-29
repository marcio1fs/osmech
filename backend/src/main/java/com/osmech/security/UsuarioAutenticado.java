package com.osmech.security;

import java.security.Principal;

/**
 * Principal autenticado exposto no SecurityContext pelo JwtAuthFilter.
 *
 * Implementa {@link Principal} para que {@code Authentication#getName()}
 * continue retornando o e-mail — nenhum service existente quebra.
 * Carrega também id e papel, eliminando a necessidade de novo lookup
 * de banco nos pontos que só precisam do identificador (usado a partir
 * da Fase 1 do plano de controle de usuários).
 */
public record UsuarioAutenticado(Long id, String email, String papel) implements Principal {

    @Override
    public String getName() {
        return email;
    }
}
