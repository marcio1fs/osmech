package com.osmech.config;

/**
 * Exceção para recursos não encontrados.
 * Automaticamente mapeada para HTTP 404 pelo GlobalExceptionHandler.
 */
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
