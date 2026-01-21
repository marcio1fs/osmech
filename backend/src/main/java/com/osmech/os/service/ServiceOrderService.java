package com.osmech.os.service;

import com.osmech.os.dto.CreateServiceOrderRequest;
import com.osmech.os.dto.ServiceOrderResponse;
import com.osmech.os.dto.UpdateServiceOrderRequest;
import com.osmech.os.entity.ServiceOrder;
import com.osmech.os.repository.ServiceOrderRepository;
import com.osmech.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Serviço de gerenciamento de Ordens de Serviço
 */
@Service
@RequiredArgsConstructor
public class ServiceOrderService {
    
    private final ServiceOrderRepository serviceOrderRepository;
    
    /**
     * Cria uma nova ordem de serviço
     */
    public ServiceOrderResponse createServiceOrder(CreateServiceOrderRequest request, User user) {
        ServiceOrder order = new ServiceOrder();
        order.setOsNumber(generateOsNumber());
        order.setUser(user);
        order.setCustomerName(request.getCustomerName());
        order.setCustomerPhone(request.getCustomerPhone());
        order.setCustomerEmail(request.getCustomerEmail());
        order.setVehiclePlate(request.getVehiclePlate());
        order.setVehicleBrand(request.getVehicleBrand());
        order.setVehicleModel(request.getVehicleModel());
        order.setVehicleYear(request.getVehicleYear());
        order.setDescription(request.getDescription());
        order.setDiagnostics(request.getDiagnostics());
        order.setEstimatedCost(request.getEstimatedCost());
        order.setStatus(ServiceOrder.OrderStatus.ABERTA);
        
        order = serviceOrderRepository.save(order);
        return ServiceOrderResponse.fromEntity(order);
    }
    
    /**
     * Lista todas as ordens de serviço do usuário
     */
    public List<ServiceOrderResponse> getUserServiceOrders(User user) {
        return serviceOrderRepository.findByUserOrderByCreatedAtDesc(user)
                .stream()
                .map(ServiceOrderResponse::fromEntity)
                .collect(Collectors.toList());
    }
    
    /**
     * Busca uma ordem de serviço por ID
     */
    public ServiceOrderResponse getServiceOrderById(Long id, User user) {
        ServiceOrder order = serviceOrderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));
        
        // Verifica se a OS pertence ao usuário
        if (!order.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Acesso negado");
        }
        
        return ServiceOrderResponse.fromEntity(order);
    }
    
    /**
     * Atualiza uma ordem de serviço
     */
    public ServiceOrderResponse updateServiceOrder(Long id, UpdateServiceOrderRequest request, User user) {
        ServiceOrder order = serviceOrderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));
        
        // Verifica se a OS pertence ao usuário
        if (!order.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Acesso negado");
        }
        
        if (request.getDescription() != null) {
            order.setDescription(request.getDescription());
        }
        if (request.getDiagnostics() != null) {
            order.setDiagnostics(request.getDiagnostics());
        }
        if (request.getEstimatedCost() != null) {
            order.setEstimatedCost(request.getEstimatedCost());
        }
        if (request.getFinalCost() != null) {
            order.setFinalCost(request.getFinalCost());
        }
        if (request.getStatus() != null) {
            order.setStatus(ServiceOrder.OrderStatus.valueOf(request.getStatus()));
            
            // Se concluída, registra a data de finalização
            if (order.getStatus() == ServiceOrder.OrderStatus.CONCLUIDA) {
                order.setFinishedAt(LocalDateTime.now());
            }
        }
        
        order = serviceOrderRepository.save(order);
        return ServiceOrderResponse.fromEntity(order);
    }
    
    /**
     * Deleta uma ordem de serviço
     */
    public void deleteServiceOrder(Long id, User user) {
        ServiceOrder order = serviceOrderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));
        
        // Verifica se a OS pertence ao usuário
        if (!order.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Acesso negado");
        }
        
        serviceOrderRepository.delete(order);
    }
    
    /**
     * Gera um número único de OS no formato OS-YYYY-XXXX
     */
    private String generateOsNumber() {
        int year = Year.now().getValue();
        long count = serviceOrderRepository.count() + 1;
        return String.format("OS-%d-%04d", year, count);
    }
}
