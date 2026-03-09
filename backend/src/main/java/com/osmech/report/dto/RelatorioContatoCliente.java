package com.osmech.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RelatorioContatoCliente {
    private Long clienteId;
    private String nome;
    private String cpf;
    private String cnpj;
    private String telefone;
    private String email;
}
