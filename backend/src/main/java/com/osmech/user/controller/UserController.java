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

    /** GET /api/usuario/perfil - Retorna dados do perfil */
    @GetMapping("/perfil")
    public ResponseEntity<UserProfileResponse> getPerfil(Authentication auth) {
        return ResponseEntity.ok(userService.getPerfil(auth.getName()));
    }

    /** PUT /api/usuario/perfil - Atualiza dados do perfil */
    @PutMapping("/perfil")
    public ResponseEntity<UserProfileResponse> atualizarPerfil(Authentication auth,
                                                                 @Valid @RequestBody UserProfileRequest request) {
        return ResponseEntity.ok(userService.atualizarPerfil(auth.getName(), request));
    }

    /** PUT /api/usuario/senha - Alterar senha */
    @PutMapping("/senha")
    public ResponseEntity<Map<String, String>> alterarSenha(Authentication auth,
                                                              @Valid @RequestBody ChangePasswordRequest request) {
        userService.alterarSenha(auth.getName(), request);
        return ResponseEntity.ok(Map.of("message", "Senha alterada com sucesso"));
    }
}
