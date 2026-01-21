package com.osmech.plan.controller;

import com.osmech.plan.dto.PlanResponse;
import com.osmech.plan.service.PlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller de planos
 */
@RestController
@RequestMapping("/api/plans")
@RequiredArgsConstructor
public class PlanController {
    
    private final PlanService planService;
    
    @GetMapping
    public ResponseEntity<List<PlanResponse>> getAllPlans() {
        return ResponseEntity.ok(planService.getAllActivePlans());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<PlanResponse> getPlanById(@PathVariable Long id) {
        return ResponseEntity.ok(planService.getPlanById(id));
    }
}
