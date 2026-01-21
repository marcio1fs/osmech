package com.osmech.os.entity;

import com.osmech.user.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidade que representa uma Ordem de Serviço
 */
@Entity
@Table(name = "service_orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceOrder {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 20)
    private String osNumber; // Ex: OS-2026-0001
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false, length = 100)
    private String customerName;
    
    @Column(length = 20)
    private String customerPhone;
    
    @Column(length = 100)
    private String customerEmail;
    
    @Column(nullable = false, length = 50)
    private String vehiclePlate;
    
    @Column(length = 50)
    private String vehicleBrand;
    
    @Column(length = 50)
    private String vehicleModel;
    
    @Column(length = 10)
    private String vehicleYear;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(columnDefinition = "TEXT")
    private String diagnostics;
    
    @Column(precision = 10, scale = 2)
    private BigDecimal estimatedCost;
    
    @Column(precision = 10, scale = 2)
    private BigDecimal finalCost;
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.ABERTA;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "finished_at")
    private LocalDateTime finishedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public enum OrderStatus {
        ABERTA,         // Ordem criada
        EM_ANALISE,     // Mecânico analisando
        EM_ANDAMENTO,   // Serviço sendo executado
        AGUARDANDO_PECAS, // Aguardando peças
        CONCLUIDA,      // Serviço finalizado
        CANCELADA,      // Ordem cancelada
        ENTREGUE        // Veículo entregue ao cliente
    }
}
