package com.osmech.plan.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

/**
 * DTO de resposta do Plano.
 */
@Data
@AllArgsConstructor
@Builder
public class PlanoResponse {

    private Long id;
    private String codigo;
    private String nome;
    private BigDecimal preco;
    private Integer limiteOs;
    private Boolean whatsappHabilitado;
    private Boolean iaHabilitada;
    private String descricao;
}
