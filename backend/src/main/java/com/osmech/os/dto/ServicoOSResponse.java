package com.osmech.os.dto;

import lombok.*;
import java.math.BigDecimal;

/**
 * DTO de resposta de um serviço na OS.
 */
@Data
@AllArgsConstructor
@Builder
public class ServicoOSResponse {
    private Long id;
    private String descricao;
    private Integer quantidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
}
