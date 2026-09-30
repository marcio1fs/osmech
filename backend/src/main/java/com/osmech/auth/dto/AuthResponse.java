package com.osmech.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;


/**
 * DTO de resposta após login/cadastro bem-sucedido.
 *
 * Fase 4:
 *  - login de quem tem 2FA ativo responde requer2fa=true + sessao
 *    (id do desafio) SEM tokens; o cliente chama /auth/2fa/verificar;
 *  - respostas autenticadas carregam também refreshToken (rotação em
 *    /api/auth/refresh).
 */
@Data
@AllArgsConstructor
@Builder
public class AuthResponse {

    private String token;
    private String refreshToken;
    private String email;
    private String nome;
    private String role;
    private String plano;

    /** true quando falta o código 2FA para concluir o login */
    private Boolean requer2fa;

    /** Id do desafio 2FA pendente (usar em /auth/2fa/verificar) */
    private Long sessao;

    // Campo opcional para compatibilidade com versões do código que esperam mensagem.
    // Mantido como null por padrão.
    private String message;

}
