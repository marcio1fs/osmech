package com.osmech.user.dto;

import com.osmech.plan.entity.Plan;
import com.osmech.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private String type = "Bearer";
    private Long userId;
    private String email;
    private String name;
    private String role;
    private PlanInfo plan;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PlanInfo {
        private Long id;
        private String name;
        private LocalDateTime subscriptionEnd;
    }
    
    public static AuthResponse fromUser(User user, String token) {
        AuthResponse response = new AuthResponse();
        response.setToken(token);
        response.setUserId(user.getId());
        response.setEmail(user.getEmail());
        response.setName(user.getName());
        response.setRole(user.getRole().name());
        
        if (user.getPlan() != null) {
            PlanInfo planInfo = new PlanInfo();
            planInfo.setId(user.getPlan().getId());
            planInfo.setName(user.getPlan().getName());
            planInfo.setSubscriptionEnd(user.getSubscriptionEnd());
            response.setPlan(planInfo);
        }
        
        return response;
    }
}
