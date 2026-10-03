package com.osmech.equipe.service;

/**
 * Lançada quando a oficina atinge o limite de usuários do plano
 * ao convidar/aceitar novos membros. Mapeada para HTTP 409 no
 * GlobalExceptionHandler.
 */
public class LimiteEquipeException extends RuntimeException {

    public LimiteEquipeException(String message) {
        super(message);
    }
}
