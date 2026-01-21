package com.osmech.plan.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Entidade que representa os planos de assinatura do sistema
 */
@Entity
@Table(name = "plans")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Plan {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 50)
    private String name; // PRO, PRO+, PREMIUM
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    
    @Column(name = "max_service_orders")
    private Integer maxServiceOrders; // Limite de OS por mês (null = ilimitado)
    
    @Column(name = "whatsapp_enabled")
    private Boolean whatsappEnabled;
    
    @Column(name = "ai_enabled")
    private Boolean aiEnabled;
    
    @Column(name = "max_users")
    private Integer maxUsers; // Número máximo de usuários
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(nullable = false)
    private Boolean active = true;
}
