package com.osmech.user.controller;

import com.osmech.user.dto.ChangePasswordRequest;
import com.osmech.user.dto.UserProfileRequest;
import com.osmech.user.dto.UserProfileResponse;
import com.osmech.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller REST para gerenciamento de perfil do usuário.
 */
@RestController
@RequestMapping("/api/usuario")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * GET /api/usuario/perfil - Retorna dados do perfil
     */
    @GetMapping("/perfil")
    public ResponseEntity<UserProfileResponse> getPerfil(Authentication auth) {
        return ResponseEntity.ok(userService.getPerfil(auth.getName()));
    }

    /**
     * PUT /api/usuario/perfil - Atualiza dados do perfil
     */
    @PutMapping("/perfil")
    public ResponseEntity<?> atualizarPerfil(Authentication auth,
                                              @Valid @RequestBody UserProfileRequest request) {
        try {
            UserProfileResponse response = userService.atualizarPerfil(auth.getName(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/usuario/senha - Alterar senha
     */
    @PutMapping("/senha")
    public ResponseEntity<?> alterarSenha(Authentication auth,
                                           @Valid @RequestBody ChangePasswordRequest request) {
        try {
            userService.alterarSenha(auth.getName(), request);
            return ResponseEntity.ok(Map.of("message", "Senha alterada com sucesso"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
