package com.osmech.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Testes do JwtUtil: claim "uid", validação e regras do secret.
 */
class JwtUtilTest {

    private static final String SECRET = "segredo-de-teste-com-mais-de-32-bytes-para-hs256-ok";
    private static final long EXPIRATION_MS = 60_000;

    private final JwtUtil jwtUtil = new JwtUtil(SECRET, EXPIRATION_MS);

    @Test
    @DisplayName("generateToken deve embutir uid, oid, role e subject")
    void tokenComUidEOid() {
        String token = jwtUtil.generateToken("user@oficina.com", "OFICINA", 42L, 7L);

        assertThat(jwtUtil.validateToken(token)).isTrue();
        assertThat(jwtUtil.getEmailFromToken(token)).isEqualTo("user@oficina.com");
        assertThat(jwtUtil.getRoleFromToken(token)).isEqualTo("OFICINA");
        assertThat(jwtUtil.getUserIdFromToken(token)).isEqualTo(42L);
        assertThat(jwtUtil.getOficinaIdFromToken(token)).isEqualTo(7L);
    }

    @Test
    @DisplayName("token sem ids (método legado) deve retornar null nos getters de id")
    void tokenSemIds() {
        String token = jwtUtil.generateToken("user@oficina.com", "ADMIN");

        assertThat(jwtUtil.validateToken(token)).isTrue();
        assertThat(jwtUtil.getUserIdFromToken(token)).isNull();
        assertThat(jwtUtil.getOficinaIdFromToken(token)).isNull();
    }

    @Test
    @DisplayName("token adulterado/expirado deve ser rejeitado")
    void tokenInvalido() {
        assertThat(jwtUtil.validateToken("token.falso.assinatura")).isFalse();
        assertThat(jwtUtil.validateToken("")).isFalse();
    }

    @Test
    @DisplayName("secret curto deve impedir a construção")
    void secretCurto() {
        assertThatThrownBy(() -> new JwtUtil("curto", EXPIRATION_MS))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
