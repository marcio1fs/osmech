package com.osmech.os.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class EncerrarOsResponse {
    private OrdemServicoResponse os;
    private String metodoPagamento;
    private Long transacaoFinanceiraId;
    private String recibo;
    private Boolean whatsappEnviado;
    private String whatsappDestino;
    private String whatsappDetalhe;
}
