package com.osmech.security;

import com.osmech.user.entity.Papel;

/**
 * Expressões SpEL de autorização para @PreAuthorize, derivadas do enum
 * {@link Papel} (fonte única de verdade — sem Strings soltas).
 *
 * Uso: {@code @PreAuthorize(PapeisSeguranca.GESTORES)}
 *
 * São constantes de compilação (annotation-safe). ADMIN recebe ROLE_DONO
 * no JwtAuthFilter, portanto passa em todas as expressões abaixo.
 */
public final class PapeisSeguranca {

    private static final String T = "T(com.osmech.user.entity.Papel).";

    /** Apenas ADMIN da plataforma */
    public static final String SOMENTE_ADMIN = "hasRole(" + T + "ADMIN.name())";

    /** Apenas o DONO da oficina (ADMIN herda) */
    public static final String SOMENTE_DONO = "hasRole(" + T + "DONO.name())";

    /** DONO e GERENTE — financeiro, relatórios, escrita de estoque/equipe */
    public static final String GESTORES =
            "hasAnyRole(" + T + "DONO.name(), " + T + "GERENTE.name())";

    /** Todos os membros da oficina — operações do dia a dia (OS, leituras) */
    public static final String MEMBROS_OFICINA =
            "hasAnyRole(" + T + "DONO.name(), " + T + "GERENTE.name(), "
                    + T + "ATENDENTE.name(), " + T + "VENDEDOR.name(), " + T + "MECANICO.name())";

    private PapeisSeguranca() {
    }
}
