package com.osmech.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * DTOs dos fluxos de sessão e 2FA (Fase 4).
 */
public class SessaoDtos {

    /** POST /auth/refresh e POST /auth/logout */
    @Data
    public static class RefreshRequest {
        @NotBlank(message = "Refresh token é obrigatório")
        private String refreshToken;
    }

    /** POST /auth/2fa/verificar */
    @Data
    public static class DoisFaVerificarRequest {
        @NotNull(message = "Sessão é obrigatória")
        private Long sessao;

        @NotBlank(message = "Código é obrigatório")
        @Pattern(regexp = "\\d{6}", message = "O código deve ter 6 dígitos")
        private String codigo;
    }

    /** POST /auth/2fa/reenviar */
    @Data
    public static class DoisFaReenviarRequest {
        @NotNull(message = "Sessão é obrigatória")
        private Long sessao;
    }
}
