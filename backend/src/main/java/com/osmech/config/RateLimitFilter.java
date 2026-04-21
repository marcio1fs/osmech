package com.osmech.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Rate Limiter abstrato que define a interface para implementacoes.
 * Duas implementacoes disponiveis:
 * - InMemoryRateLimiter: modo em memoria (default) - para desenvolvimento
 * - RedisRateLimiter: modo Redis - para producao multi-instancia
 * 
 * Configure o modo via propriedade: rate-limit.mode=memory | redis
 */
@Slf4j
public abstract class RateLimitFilter implements Filter {

    // Configuracoes de limite
    protected static final int MAX_REQUESTS_PER_MINUTE = 60;
    protected static final int MAX_LOGIN_ATTEMPTS_PER_MINUTE = 5;
    protected static final int MAX_LOGIN_ATTEMPTS_PER_15_MINUTES = 15;
    protected static final long ENTRY_EXPIRE_MILLIS = 120000; // 2 minutes

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String clientIp = getClientIP(httpRequest);
        String path = httpRequest.getRequestURI();

        // Skip rate limiting for webhook endpoints
        if (path.contains("/mercadopago/webhook")) {
            chain.doFilter(request, response);
            return;
        }

        // Verifica rate limiting para login
        if (path.contains("/auth/login") || path.contains("/auth/register")) {
            if (!checkLoginRateLimit(clientIp, httpResponse)) {
                return;
            }
        }

        // Verifica rate limiting geral
        if (!checkRateLimit(clientIp, httpResponse)) {
            return;
        }

        chain.doFilter(request, response);
    }

    protected boolean checkLoginRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        throw new UnsupportedOperationException("Implement checkLoginRateLimit in subclass");
    }

    protected boolean checkRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        throw new UnsupportedOperationException("Implement checkRateLimit in subclass");
    }

    protected void sendTooManyRequests(HttpServletResponse response, String message) throws IOException {
        response.setStatus(429);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\":\"" + message + "\"}");
    }

    protected String getClientIP(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
