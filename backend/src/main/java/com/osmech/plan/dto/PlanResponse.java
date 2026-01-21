package com.osmech.plan.dto;

import com.osmech.plan.entity.Plan;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlanResponse {
    private Long id;
    private String name;
    private BigDecimal price;
    private Integer maxServiceOrders;
    private Boolean whatsappEnabled;
    private Boolean aiEnabled;
    private Integer maxUsers;
    private String description;
    
    public static PlanResponse fromEntity(Plan plan) {
        PlanResponse response = new PlanResponse();
        response.setId(plan.getId());
        response.setName(plan.getName());
        response.setPrice(plan.getPrice());
        response.setMaxServiceOrders(plan.getMaxServiceOrders());
        response.setWhatsappEnabled(plan.getWhatsappEnabled());
        response.setAiEnabled(plan.getAiEnabled());
        response.setMaxUsers(plan.getMaxUsers());
        response.setDescription(plan.getDescription());
        return response;
    }
}
