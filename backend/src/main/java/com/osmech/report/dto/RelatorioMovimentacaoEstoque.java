package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioMovimentacaoEstoque {
    private Long id;
    private String itemNome;
    private String itemCodigo;
    private String tipoMovimentacao;
    private Integer quantidade;
    private Integer saldoAnterior;
    private Integer saldoAtual;
    private String motivo;
    private LocalDateTime data;
}
