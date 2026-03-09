package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioClienteQuantidadeOs {
    private Long clienteId;
    private String nome;
    private String cpf;
    private String telefone;
    private Long quantidadeOs;
    private BigDecimal valorTotal;
    private String ultimaOs;
}
