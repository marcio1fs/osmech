package com.osmech.user.controller;

import com.osmech.user.dto.ChangePasswordRequest;
import com.osmech.user.dto.SenhaConfirmacaoRequest;
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
@RequestMapping("/usuario")
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

    /** PUT /api/usuario/2fa/ativar - Ativa 2FA por e-mail (exige senha atual) */
    @PutMapping("/2fa/ativar")
    public ResponseEntity<Map<String, String>> ativar2fa(Authentication auth,
                                                           @Valid @RequestBody SenhaConfirmacaoRequest request) {
        userService.alterarDoisFa(auth.getName(), request.getSenha(), true);
        return ResponseEntity.ok(Map.of("message", "Verificação em duas etapas ativada"));
    }

    /** PUT /api/usuario/2fa/desativar - Desativa 2FA (exige senha atual) */
    @PutMapping("/2fa/desativar")
    public ResponseEntity<Map<String, String>> desativar2fa(Authentication auth,
                                                           @Valid @RequestBody SenhaConfirmacaoRequest request) {
        userService.alterarDoisFa(auth.getName(), request.getSenha(), false);
        return ResponseEntity.ok(Map.of("message", "Verificação em duas etapas desativada"));
    }

    /** POST /api/usuario/logout-todos - Encerra todas as sessões do usuário (Fase 4) */
    @PostMapping("/logout-todos")
    public ResponseEntity<Map<String, String>> logoutTodos(Authentication auth) {
        userService.logoutTodas(auth.getName());
        return ResponseEntity.ok(Map.of("message", "Todas as sessões foram encerradas"));
    }

    /** POST /api/usuario/logo - Faz upload da logo da oficina */
    @PostMapping("/logo")
    public ResponseEntity<Map<String, String>> uploadLogo(Authentication auth,
                                                          @RequestParam("file") org.springframework.web.multipart.MultipartFile file) throws Exception {
        String logoUrl = userService.uploadLogo(auth.getName(), file);
        return ResponseEntity.ok(Map.of("logoUrl", logoUrl));
    }
}
