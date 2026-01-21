package com.osmech.os.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateServiceOrderRequest {
    
    @NotBlank(message = "Nome do cliente é obrigatório")
    @Size(max = 100)
    private String customerName;
    
    private String customerPhone;
    private String customerEmail;
    
    @NotBlank(message = "Placa do veículo é obrigatória")
    @Size(max = 50)
    private String vehiclePlate;
    
    private String vehicleBrand;
    private String vehicleModel;
    private String vehicleYear;
    
    @NotBlank(message = "Descrição é obrigatória")
    private String description;
    
    private String diagnostics;
    private BigDecimal estimatedCost;
}
