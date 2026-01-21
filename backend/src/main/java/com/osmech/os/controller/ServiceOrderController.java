package com.osmech.os.controller;

import com.osmech.os.dto.CreateServiceOrderRequest;
import com.osmech.os.dto.ServiceOrderResponse;
import com.osmech.os.dto.UpdateServiceOrderRequest;
import com.osmech.os.service.ServiceOrderService;
import com.osmech.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller de Ordens de Serviço
 */
@RestController
@RequestMapping("/api/service-orders")
@RequiredArgsConstructor
public class ServiceOrderController {
    
    private final ServiceOrderService serviceOrderService;
    
    @PostMapping
    public ResponseEntity<ServiceOrderResponse> createServiceOrder(
            @Valid @RequestBody CreateServiceOrderRequest request,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(serviceOrderService.createServiceOrder(request, user));
    }
    
    @GetMapping
    public ResponseEntity<List<ServiceOrderResponse>> getUserServiceOrders(
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(serviceOrderService.getUserServiceOrders(user));
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ServiceOrderResponse> getServiceOrderById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(serviceOrderService.getServiceOrderById(id, user));
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<ServiceOrderResponse> updateServiceOrder(
            @PathVariable Long id,
            @Valid @RequestBody UpdateServiceOrderRequest request,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(serviceOrderService.updateServiceOrder(id, request, user));
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteServiceOrder(
            @PathVariable Long id,
            @AuthenticationPrincipal User user
    ) {
        serviceOrderService.deleteServiceOrder(id, user);
        return ResponseEntity.noContent().build();
    }
}
