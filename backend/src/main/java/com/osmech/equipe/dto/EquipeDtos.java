package com.osmech.equipe.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * DTOs do módulo de equipe (convites e membros da oficina).
 */
public final class EquipeDtos {

    private EquipeDtos() {
    }

    /** POST /oficina/equipe/convites */
    @Data
    public static class ConvidarUsuarioRequest {
        @NotBlank(message = "E-mail é obrigatório")
        @Email(message = "E-mail inválido")
        private String email;

        @NotBlank(message = "Papel é obrigatório (GERENTE, ATENDENTE, VENDEDOR ou MECANICO)")
        private String papel;
    }

    /** PUT /oficina/equipe/usuarios/{id}/papel */
    @Data
    public static class AlterarPapelRequest {
        @NotBlank(message = "Papel é obrigatório")
        private String papel;
    }

    /** PUT /oficina/equipe/usuarios/{id}/status */
    @Data
    public static class AlterarStatusRequest {
        @NotNull(message = "Campo 'ativo' é obrigatório")
        private Boolean ativo;
    }

    /** POST /auth/convites/aceitar */
    @Data
    public static class AceitarConviteRequest {
        @NotBlank(message = "Token é obrigatório")
        private String token;

        @NotBlank(message = "Nome é obrigatório")
        private String nome;

        @NotBlank(message = "Telefone é obrigatório")
        @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
        private String telefone;

        @NotBlank(message = "Senha é obrigatória")
        @Size(min = 8, message = "Senha deve ter no mínimo 8 caracteres")
        private String senha;
    }

    /** Membro atual da oficina */
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MembroEquipeResponse {
        private Long id;
        private String nome;
        private String email;
        private String papel;
        private Boolean ativo;
        private LocalDateTime criadoEm;
    }

    /** Convite pendente/revogado/aceito/expirado */
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ConviteEquipeResponse {
        private Long id;
        private String email;
        private String papel;
        private String status;
        private LocalDateTime criadoEm;
        private LocalDateTime expiraEm;
    }

    /** GET /oficina/equipe — visão consolidada para a tela Equipe */
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class EquipeResponse {
        /** Limite do plano (0 ou null = ilimitado) */
        private Integer limiteUsuarios;
        /** Usuários ativos + convites pendentes */
        private long usuariosEmUso;
        private boolean limiteAtingido;
        private List<MembroEquipeResponse> membros;
        private List<ConviteEquipeResponse> convites;
    }

    /** GET /auth/convites/{token} — dados públicos do convite (tela de aceite) */
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ConviteInfoResponse {
        private String email;
        private String nomeOficina;
        private String papel;
        private LocalDateTime expiraEm;
    }
}
