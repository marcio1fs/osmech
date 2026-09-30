package com.osmech.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * DTOs das operações administrativas da plataforma (AdminController).
 */
public final class AdminDtos {

    private AdminDtos() {}

    /** Visão de um usuário na listagem administrativa. */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UsuarioAdmin {
        private Long id;
        private String nome;
        private String email;
        private String telefone;
        private String nomeOficina;
        private Long oficinaId;
        private String role;
        private String plano;
        private Boolean ativo;
        private Boolean emailVerificado;
        private LocalDateTime criadoEm;
    }

    /** Página de resultados + agregados para os cards do dashboard. */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PaginaUsuarios {
        private List<UsuarioAdmin> usuarios;
        private long totalUsuarios;   // total global (todos os usuários)
        private long totalAtivos;
        private long totalPagos;      // plano != FREE
        private long totalFree;
        // metadados da página atual (filtrada)
        private int pagina;
        private int tamanho;
        private long totalFiltrado;
        private int totalPaginas;
    }

    /** Corpo para ativar/inativar usuário. */
    @Data
    public static class AtivoRequest {
        @NotNull(message = "ativo é obrigatório")
        private Boolean ativo;
    }

    /** Corpo para alterar o plano do usuário. */
    @Data
    public static class PlanoRequest {
        @NotBlank(message = "plano é obrigatório")
        private String plano;
    }

    /** Corpo para alterar o papel (role) do usuário. */
    @Data
    public static class PapelRequest {
        @NotBlank(message = "role é obrigatório")
        private String role;
    }
}
