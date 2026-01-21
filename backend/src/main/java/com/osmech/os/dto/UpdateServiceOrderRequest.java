package com.osmech.os.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateServiceOrderRequest {
    private String description;
    private String diagnostics;
    private BigDecimal estimatedCost;
    private BigDecimal finalCost;
    private String status; // ABERTA, EM_ANALISE, EM_ANDAMENTO, etc.
}
