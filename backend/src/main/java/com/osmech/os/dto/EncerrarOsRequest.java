package com.osmech.os.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class EncerrarOsRequest {

    @NotBlank(message = "Metodo de pagamento e obrigatorio")
    private String metodoPagamento;

    private Boolean enviarReciboWhatsapp;

    /** Opcional: sobrescreve o telefone do cliente no envio do recibo. */
    private String telefoneWhatsapp;

    private String observacoesPagamento;

    /** Desconto em percentual — 0 a 10% */
    @DecimalMin(value = "0", message = "Desconto minimo e 0%")
    @DecimalMax(value = "10", message = "Desconto maximo e 10%")
    private BigDecimal descontoPercentual;
}
