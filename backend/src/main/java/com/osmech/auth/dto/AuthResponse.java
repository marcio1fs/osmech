package com.osmech.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private String tipo = "Bearer";
    private Long usuarioId;
    private String nomeOficina;
    private String email;

    public AuthResponse(String token, Long usuarioId, String nomeOficina, String email) {
        this.token = token;
        this.tipo = "Bearer";
        this.usuarioId = usuarioId;
        this.nomeOficina = nomeOficina;
        this.email = email;
    }
}
