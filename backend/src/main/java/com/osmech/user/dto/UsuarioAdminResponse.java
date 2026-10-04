package com.osmech.user.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * DTO de resposta com dados de usuário para a tela de administração.
 * Nunca expõe senha ou tokens de segurança.
 */
@Data
@Builder
public class UsuarioAdminResponse {

    private Long id;
    private String nome;
    private String email;
    private String role;
    private String plano;
    private Boolean ativo;
    private String telefone;
    private String nomeOficina;
    private Long ownerId;
    private LocalDateTime criadoEm;
    private LocalDateTime ultimoAcesso;
}
