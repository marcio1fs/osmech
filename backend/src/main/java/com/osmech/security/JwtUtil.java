package com.osmech.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * Utilitário para geração e validação de tokens JWT.
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
     * Gera um token JWT para o usuário informado (sem claims de id).
     */
    public String generateToken(String email, String role) {
        return generateToken(email, role, null, null);
    }

    /**
     * Gera um token JWT para o usuário informado (sem claim de oficina).
     */
    public String generateToken(String email, String role, Long userId) {
        return generateToken(email, role, userId, null);
    }

    /**
     * Gera um token JWT para o usuário informado.
     *
     * @param email     subject do token
     * @param role      papel atual (claim "role") — útil para UX no frontend;
     *                  a autorização server-side usa sempre o papel do banco
     * @param userId    id do usuário (claim "uid"); pode ser null
     * @param oficinaId id da oficina/tenant (claim "oid"); pode ser null
     */
    public String generateToken(String email, String role, Long userId, Long oficinaId) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        var builder = Jwts.builder()
                .subject(email)
                .claim("role", role)
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
