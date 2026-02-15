package com.osmech.user.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * DTO de resposta com dados do perfil do usuário.
 */
@Data
@Builder
public class UserProfileResponse {
    private Long id;
    private String nome;
    private String email;
    private String telefone;
    private String nomeOficina;
    private String role;
    private String plano;
    private Boolean ativo;
    private LocalDateTime criadoEm;
}
