package com.osmech.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

/**
 * Utilitário para geração e validação de tokens JWT.
 * O token carrega: subject=email, role=STRING, permissions=LIST<STRING>, uid=Long, oid=Long
 */
@Component
public class JwtUtil {

    private final SecretKey key;
    private final long expirationMs;

    public JwtUtil(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-ms}") long expirationMs) {
        if (secret == null || secret.isBlank() || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalArgumentException(
                "JWT Secret is not defined or is too short. " +
                "Please set the 'app.jwt.secret' property with a secure key of at least 256 bits (32 bytes)."
            );
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    /**
     * Gera um token JWT com lista de permissões vazia (sem uid/oid).
     */
    public String generateToken(String email, String role) {
        return generateToken(email, role, List.of(), null, null);
    }

    /**
     * Gera um token JWT com uid (sem oid e sem permissões explícitas).
     */
    public String generateToken(String email, String role, Long userId) {
        return generateToken(email, role, List.of(), userId, null);
    }

    /**
     * Gera um token JWT com uid e oid (sem permissões explícitas).
     */
    public String generateToken(String email, String role, Long userId, Long oficinaId) {
        return generateToken(email, role, List.of(), userId, oficinaId);
    }

    /**
     * Gera um token JWT com role e permissões (sem uid/oid).
     */
    public String generateToken(String email, String role, List<String> permissions) {
        return generateToken(email, role, permissions, null, null);
    }

    /**
     * Gera um token JWT completo com todas as claims.
     */
    public String generateToken(String email, String role, List<String> permissions, Long userId, Long oficinaId) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        var builder = Jwts.builder()
                .subject(email)
                .claim("role", role)
                .claim("permissions", permissions != null ? permissions : List.of())
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key);

        if (userId != null) {
            builder.claim("uid", userId);
        }
        if (oficinaId != null) {
            builder.claim("oid", oficinaId);
        }

        return builder.compact();
    }

    /**
     * Extrai o id do usuário (claim "uid") do token, se presente.
     */
    public Long getUserIdFromToken(String token) {
        Object uid = parseClaims(token).get("uid");
        return uid instanceof Number number ? number.longValue() : null;
    }

    /**
     * Extrai o id da oficina/tenant (claim "oid") do token, se presente.
     */
    public Long getOficinaIdFromToken(String token) {
        Object oid = parseClaims(token).get("oid");
        return oid instanceof Number number ? number.longValue() : null;
    }

    /**
     * Extrai o email (subject) do token.
     */
    public String getEmailFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    /**
     * Extrai a role do token.
     */
    public String getRoleFromToken(String token) {
        return parseClaims(token).get("role", String.class);
    }

    /**
     * Extrai a lista de permissions do token.
     * Retorna lista vazia se o claim não existir (tokens antigos sem RBAC).
     */
    @SuppressWarnings("unchecked")
    public List<String> getPermissionsFromToken(String token) {
        Object perms = parseClaims(token).get("permissions");
        if (perms instanceof List) {
            return (List<String>) perms;
        }
        return List.of();
    }

    /**
     * Valida se o token é válido e não expirou.
     */
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
