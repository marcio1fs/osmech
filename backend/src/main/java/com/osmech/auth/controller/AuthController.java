package com.osmech.auth.controller;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.auth.dto.ForgotPasswordRequest;
import com.osmech.auth.dto.ResetPasswordRequest;
import com.osmech.auth.dto.SessaoDtos;
import com.osmech.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller responsável pelas rotas de autenticação (login e cadastro).
 * Rotas públicas: não exigem JWT.
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/auth/register
     * Cadastra um novo usuário e retorna o token JWT.
     */
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    /**
     * POST /api/auth/login
     * Autentica o usuário e retorna o token JWT + refresh token.
     * Com 2FA ativo, retorna o desafio (sem tokens).
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request,
                                              @RequestHeader(value = "User-Agent", required = false) String userAgent) {
        return ResponseEntity.ok(authService.login(request, userAgent));
    }

    /**
     * POST /api/auth/refresh
     * Troca o refresh token por novo par access+refresh (rotação).
     */
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody SessaoDtos.RefreshRequest request,
                                                @RequestHeader(value = "User-Agent", required = false) String userAgent) {
        return ResponseEntity.ok(authService.refresh(request.getRefreshToken(), userAgent));
    }

    /**
     * POST /api/auth/logout
     * Revoga a sessão identificada pelo refresh token.
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody(required = false) SessaoDtos.RefreshRequest request) {
        authService.logout(request == null ? null : request.getRefreshToken());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/auth/reenviar-verificacao
     * Reenvia o e-mail de verificação (sempre 200 — anti-enumeração).
     */
    @PostMapping("/reenviar-verificacao")
    public ResponseEntity<Void> reenviarVerificacao(@Valid @RequestBody ForgotPasswordRequest request) {
        authService.reenviarVerificacao(request.getEmail());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/auth/2fa/verificar
     * Conclui o login de quem tem 2FA ativo.
     */
    @PostMapping("/2fa/verificar")
    public ResponseEntity<AuthResponse> verificar2fa(@Valid @RequestBody SessaoDtos.DoisFaVerificarRequest request,
                                                     @RequestHeader(value = "User-Agent", required = false) String userAgent) {
        return ResponseEntity.ok(authService.verificar2fa(request.getSessao(), request.getCodigo(), userAgent));
    }

    /**
     * POST /api/auth/2fa/reenviar
     */
    @PostMapping("/2fa/reenviar")
    public ResponseEntity<Void> reenviar2fa(@Valid @RequestBody SessaoDtos.DoisFaReenviarRequest request) {
        authService.reenviar2fa(request.getSessao());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/auth/forgot-password
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Void> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request.getEmail());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/auth/reset-password
     */
    @PostMapping("/reset-password")
    public ResponseEntity<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request.getToken(), request.getNovaSenha());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/auth/verify-email
     */
    @PostMapping("/verify-email")
    public ResponseEntity<Void> verifyEmail(@RequestParam String token) {
        authService.verifyEmail(token);
        return ResponseEntity.ok().build();
    }
}
