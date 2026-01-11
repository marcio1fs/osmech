package com.osmech.plan;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/plans")
@CrossOrigin
public class PlanController {

    @Autowired
    private PlanRepository planRepository;

    @GetMapping
    public List<Plan> getAllPlans() {
        return planRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<Plan> createPlan(@RequestBody Plan plan) {
        Plan savedPlan = planRepository.save(plan);
        return ResponseEntity.ok(savedPlan);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Plan> updatePlan(@PathVariable Long id, @RequestBody Plan plan) {
        return planRepository.findById(id)
                .map(existingPlan -> {
                    existingPlan.setName(plan.getName());
                    existingPlan.setPrice(plan.getPrice());
                    existingPlan.setDescription(plan.getDescription());
                    Plan updatedPlan = planRepository.save(existingPlan);
                    return ResponseEntity.ok(updatedPlan);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable Long id) {
        if (planRepository.existsById(id)) {
            planRepository.deleteById(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
