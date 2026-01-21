package com.osmech.user.service;

import com.osmech.auth.JwtService;
import com.osmech.plan.entity.Plan;
import com.osmech.plan.repository.PlanRepository;
import com.osmech.user.dto.AuthResponse;
import com.osmech.user.dto.LoginRequest;
import com.osmech.user.dto.RegisterRequest;
import com.osmech.user.entity.User;
import com.osmech.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * Serviço de autenticação
 */
@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UserRepository userRepository;
    private final PlanRepository planRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    
    /**
     * Registra um novo usuário
     */
    public AuthResponse register(RegisterRequest request) {
        // Verifica se o email já existe
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email já cadastrado");
        }
        
        // Cria o usuário
        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setPhone(request.getPhone());
        user.setRole(User.UserRole.OFICINA);
        user.setActive(true);
        
        // Associa ao plano se fornecido
        if (request.getPlanId() != null) {
            Plan plan = planRepository.findById(request.getPlanId())
                    .orElseThrow(() -> new RuntimeException("Plano não encontrado"));
            user.setPlan(plan);
            user.setSubscriptionStart(LocalDateTime.now());
            user.setSubscriptionEnd(LocalDateTime.now().plusMonths(1)); // 1 mês de assinatura
        }
        
        user = userRepository.save(user);
        
        // Gera o token JWT
        String token = jwtService.generateToken(user);
        
        return AuthResponse.fromUser(user, token);
    }
    
    /**
     * Realiza o login do usuário
     */
    public AuthResponse login(LoginRequest request) {
        // Autentica o usuário
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );
        
        // Busca o usuário
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));
        
        // Gera o token JWT
        String token = jwtService.generateToken(user);
        
        return AuthResponse.fromUser(user, token);
    }
}
