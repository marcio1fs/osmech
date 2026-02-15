package com.osmech.os.entity;

import java.util.List;
import java.util.Map;

/**
 * Enum que define os status válidos de uma Ordem de Serviço
 * e as transições permitidas entre eles.
 */
public enum StatusOS {
    ABERTA,
    EM_ANDAMENTO,
    AGUARDANDO_PECA,
    AGUARDANDO_APROVACAO,
    CONCLUIDA,
    CANCELADA;

    /**
     * Mapa de transições válidas de status.
     * Define quais status podem ser alcançados a partir de cada status.
     */
    private static final Map<StatusOS, List<StatusOS>> TRANSICOES = Map.of(
            ABERTA, List.of(EM_ANDAMENTO, AGUARDANDO_PECA, AGUARDANDO_APROVACAO, CANCELADA),
            EM_ANDAMENTO, List.of(AGUARDANDO_PECA, AGUARDANDO_APROVACAO, CONCLUIDA, CANCELADA),
            AGUARDANDO_PECA, List.of(EM_ANDAMENTO, CANCELADA),
            AGUARDANDO_APROVACAO, List.of(EM_ANDAMENTO, CANCELADA),
            CONCLUIDA, List.of(),  // Status final - não permite transição
            CANCELADA, List.of(ABERTA)  // Pode reabrir uma OS cancelada
    );

    /**
     * Verifica se a transição de status é válida.
     */
    public boolean podeTransicionarPara(StatusOS novoStatus) {
        if (this == novoStatus) return true; // Manter mesmo status é válido
        return TRANSICOES.getOrDefault(this, List.of()).contains(novoStatus);
    }

    /**
     * Converte string para StatusOS com validação.
     * @throws IllegalArgumentException se o status for inválido
     */
    public static StatusOS fromString(String status) {
        if (status == null || status.isBlank()) {
            throw new IllegalArgumentException("Status não pode ser vazio");
        }
        try {
            return StatusOS.valueOf(status.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                    "Status inválido: '" + status + "'. Valores válidos: ABERTA, EM_ANDAMENTO, " +
                            "AGUARDANDO_PECA, AGUARDANDO_APROVACAO, CONCLUIDA, CANCELADA");
        }
    }
}
