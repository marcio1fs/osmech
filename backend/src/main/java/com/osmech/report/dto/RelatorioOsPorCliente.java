package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioOsPorCliente {
    private String clienteNome;
    private String clienteCpf;
    private String clienteTelefone;
    private Long totalOs;
    private BigDecimal valorTotal;
    private LocalDate ultimaOs;
}
