package com.osmech.finance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO para criação de transação financeira.
 */
@Data
public class TransacaoRequest {

    @NotBlank(message = "Tipo é obrigatório (ENTRADA ou SAIDA)")
    private String tipo;

    private Long categoriaId;

    @NotBlank(message = "Descrição é obrigatória")
    private String descricao;

    @NotNull(message = "Valor é obrigatório")
    @Positive(message = "Valor deve ser positivo")
    private BigDecimal valor;

    private String referenciaTipo;
    private Long referenciaId;
    private String metodoPagamento;
    private LocalDateTime dataMovimentacao;
    private String observacoes;
}
