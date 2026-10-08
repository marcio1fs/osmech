package com.osmech.oficina.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OficinaWhatsAppConfigDTO {

    private String provider; // ZAPI, TWILIO, META
    private String instanceId;
    private String token;
    private String clientToken;
    private Boolean ativo;
    private Boolean connected; // Retornado pelo teste de status do z-api
    private String statusDetalhe;
}
