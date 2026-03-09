package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioEstoqueBaixo {
    private Long id;
    private String nome;
    private String codigo;
    private String categoria;
    private Integer quantidadeAtual;
    private Integer quantidadeMinima;
    private String unidade;
}
