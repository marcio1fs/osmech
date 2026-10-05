package com.osmech.user.entity;

/**
 * Papéis (roles) reconhecidos pela plataforma OSMECH.
 *
 * Persistidos como String na coluna usuarios.role (VARCHAR) — use sempre
 * {@link #name()} ao gravar e {@link #from(String)} ao ler.
 *
 * Níveis:
 *  - ADMIN      → administrador da plataforma (acesso /admin/**).
 *                 Herda as permissões de DONO via JwtAuthFilter.
 *  - DONO       → dono da oficina: tudo, inclusive equipe e assinatura.
 *  - GERENTE    → operação + financeiro + relatórios + estoque.
 *  - ATENDENTE  → OS e leituras operacionais (sem financeiro/estoque crítico).
 *  - MECANICO   → OS e leituras operacionais (escopo mais restrito de UX).
 *
 * Compatibilidade: o valor legado "OFICINA" (pré-Fase 2) é mapeado para DONO,
 * dispensando migração de dados nos ambientes sem Flyway.
 */
public enum Papel {

    ADMIN,
    DONO,
    GERENTE,
    ATENDENTE,
    VENDEDOR,
    MECANICO;

    /**
     * Converte o valor persistido em enum.
     * "OFICINA" (legado) vira DONO; valor desconhecido/ausente também cai em
     * DONO — papel padrão histórico da plataforma (todo usuário legado é dono
     * da própria oficina). O impacto de um valor corrompido fica limitado à
     * própria oficina do usuário (nunca vira ADMIN).
     */
    public static Papel from(String valor) {
        if (valor != null) {
            String v = valor.trim().toUpperCase();
            if ("OFICINA".equals(v)) {
                return DONO; // papel legado
            }
            try {
                return Papel.valueOf(v);
            } catch (IllegalArgumentException ignored) {
                // cai no fallback abaixo
            }
        }
        return DONO;
    }

    /**
     * Papéis que podem ser atribuídos via convite/gestão de equipe.
     * DONO não é convidável (propriedade única) e ADMIN é reservado à plataforma.
     */
    public boolean convidavel() {
        return this == GERENTE || this == ATENDENTE || this == VENDEDOR || this == MECANICO;
    }
}
