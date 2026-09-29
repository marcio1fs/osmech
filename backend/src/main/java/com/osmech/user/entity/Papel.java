package com.osmech.user.entity;

/**
 * Papéis (roles) reconhecidos pela plataforma OSMECH.
 *
 * Persistidos como String na coluna usuarios.role (VARCHAR) para manter
 * compatibilidade total com os dados existentes — use sempre {@link #name()}
 * ao gravar e {@link #from(String)} ao ler.
 *
 * ADMIN   → administrador da plataforma OSMECH (acesso ao /admin/**).
 * OFICINA → dono de oficina (tenant atual: 1 usuário = 1 oficina).
 *
 * Fase 2 do plano de controle de usuários expandirá para
 * DONO / GERENTE / ATENDENTE / MECANICO dentro da entidade Oficina.
 */
public enum Papel {

    ADMIN,
    OFICINA;

    /**
     * Converte o valor persistido em enum com fallback seguro.
     * Valor desconhecido/ausente vira OFICINA (menor privilégio),
     * nunca ADMIN — evita escalação por dado corrompido.
     */
    public static Papel from(String valor) {
        if (valor != null) {
            try {
                return Papel.valueOf(valor.trim().toUpperCase());
            } catch (IllegalArgumentException ignored) {
                // cai no fallback abaixo
            }
        }
        return OFICINA;
    }
}
