package com.osmech.plan.service;

import com.osmech.plan.dto.PlanResponse;
import com.osmech.plan.entity.Plan;
import com.osmech.plan.repository.PlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Serviço de gerenciamento de planos
 */
@Service
@RequiredArgsConstructor
public class PlanService {
    
    private final PlanRepository planRepository;
    
    /**
     * Lista todos os planos ativos
     */
    public List<PlanResponse> getAllActivePlans() {
        return planRepository.findByActiveTrue()
                .stream()
                .map(PlanResponse::fromEntity)
                .collect(Collectors.toList());
    }
    
    /**
     * Busca um plano por ID
     */
    public PlanResponse getPlanById(Long id) {
        Plan plan = planRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Plano não encontrado"));
        return PlanResponse.fromEntity(plan);
    }
}
