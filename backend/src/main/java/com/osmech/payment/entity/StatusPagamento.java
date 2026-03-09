package com.osmech.payment.entity;

/**
 * Enum representing payment statuses.
 * Replaces String-based status field to prevent typos and ensure consistency.
 */
public enum StatusPagamento {
    PENDENTE("Pendente - Aguardando pagamento"),
    PAGO("Pago - Pagamento confirmado"),
    FALHOU("Falhou - Pagamento rejeitado"),
    CANCELADO("Cancelado - Pagamento cancelado"),
    REEMBOLSADO("Reembolsado - Estorno realizado");

    private final String descricao;

    StatusPagamento(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    /**
     * Converts string to enum, returning null for unknown values.
     */
    public static StatusPagamento fromString(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return StatusPagamento.valueOf(value.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
