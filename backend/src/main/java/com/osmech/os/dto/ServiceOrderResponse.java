package com.osmech.os.dto;

import com.osmech.os.entity.ServiceOrder;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceOrderResponse {
    private Long id;
    private String osNumber;
    private String customerName;
    private String customerPhone;
    private String customerEmail;
    private String vehiclePlate;
    private String vehicleBrand;
    private String vehicleModel;
    private String vehicleYear;
    private String description;
    private String diagnostics;
    private BigDecimal estimatedCost;
    private BigDecimal finalCost;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime finishedAt;
    
    public static ServiceOrderResponse fromEntity(ServiceOrder order) {
        ServiceOrderResponse response = new ServiceOrderResponse();
        response.setId(order.getId());
        response.setOsNumber(order.getOsNumber());
        response.setCustomerName(order.getCustomerName());
        response.setCustomerPhone(order.getCustomerPhone());
        response.setCustomerEmail(order.getCustomerEmail());
        response.setVehiclePlate(order.getVehiclePlate());
        response.setVehicleBrand(order.getVehicleBrand());
        response.setVehicleModel(order.getVehicleModel());
        response.setVehicleYear(order.getVehicleYear());
        response.setDescription(order.getDescription());
        response.setDiagnostics(order.getDiagnostics());
        response.setEstimatedCost(order.getEstimatedCost());
        response.setFinalCost(order.getFinalCost());
        response.setStatus(order.getStatus().name());
        response.setCreatedAt(order.getCreatedAt());
        response.setUpdatedAt(order.getUpdatedAt());
        response.setFinishedAt(order.getFinishedAt());
        return response;
    }
}
