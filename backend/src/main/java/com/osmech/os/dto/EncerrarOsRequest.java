package com.osmech.os.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class EncerrarOsRequest {

    @NotBlank(message = "Metodo de pagamento e obrigatorio")
    private String metodoPagamento;

    private Boolean enviarReciboWhatsapp;

    /** Opcional: sobrescreve o telefone do cliente no envio do recibo. */
    private String telefoneWhatsapp;

    private String observacoesPagamento;
}
