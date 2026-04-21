package com.osmech.config;

import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Duration;

/**
 * Implementação Redis do Rate Limiter.
 * Recomendado para produção multi-instância.
 * Usa Redis para compartilhar contadores entre todas as instâncias.
 * 
 * Configuração (application.yml):
 * rate-limit:
 *   mode: redis
 *   redis:
 *     requests-per-minute: 60
 *     login-per-minute: 5
 *     login-per-15-minutes: 15
 */
@Component
@ConditionalOnProperty(name = "rate-limit.mode", havingValue = "redis")
@RequiredArgsConstructor
@Slf4j
public class RedisRateLimiter extends RateLimitFilter {

    private final StringRedisTemplate redisTemplate;

    // Configurações via application.yml
    private int requestsPerMinute = 60;
    private int loginPerMinute = 5;
    private int loginPer15Minutes = 15;

    public void setRequestsPerMinute(int requestsPerMinute) {
        this.requestsPerMinute = requestsPerMinute;
    }

    public void setLoginPerMinute(int loginPerMinute) {
        this.loginPerMinute = loginPerMinute;
    }

    public void setLoginPer15Minutes(int loginPer15Minutes) {
        this.loginPer15Minutes = loginPer15Minutes;
    }

    @Override
    protected boolean checkLoginRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        long currentMinute = System.currentTimeMillis() / 60000;
        
        // Chave para contagem por minuto
        String keyMinute = "rate:login:" + clientIp + ":min:" + currentMinute;
        // Chave para contagem por 15 minutos
        String key15Min = "rate:login:" + clientIp + ":15min:" + (currentMinute / 15);

        try {
            // Incrementa e verifica limite por minuto
            Long countMinute = redisTemplate.opsForValue().increment(keyMinute);
            if (countMinute != null && countMinute == 1) {
                redisTemplate.expire(keyMinute, Duration.ofMinutes(1));
            }
            
            if (countMinute != null && countMinute > loginPerMinute) {
                log.warn("Rate limit excedido para login (por minuto): {}", clientIp);
                sendTooManyRequests(response, "Muitas tentativas de login. Tente novamente em 1 minuto.");
                return false;
            }

            // Incrementa e verifica limite por 15 minutos
            Long count15Min = redisTemplate.opsForValue().increment(key15Min);
            if (count15Min != null && count15Min == 1) {
                redisTemplate.expire(key15Min, Duration.ofMinutes(15));
            }
            
            if (count15Min != null && count15Min > loginPer15Minutes) {
                log.warn("Rate limit excedido para login (por 15 minutos): {}", clientIp);
                sendTooManyRequests(response, "Muitas tentativas de login. Tente novamente em 15 minutos.");
                return false;
            }

            return true;
        } catch (Exception e) {
            // Em caso de erro no Redis, permite a requisição (fail-open)
            // mas loga o erro
            log.error("Erro ao verificar rate limit no Redis: {}", e.getMessage());
            return true;
        }
    }

    @Override
    protected boolean checkRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        long currentMinute = System.currentTimeMillis() / 60000;
        String key = "rate:req:" + clientIp + ":" + currentMinute;

        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1) {
                // Expira em 1 minuto
                redisTemplate.expire(key, Duration.ofMinutes(1));
            }

            if (count != null && count > requestsPerMinute) {
                log.warn("Rate limit geral excedido: {}", clientIp);
                sendTooManyRequests(response, "Muitas requisições. Tente novamente em 1 minuto.");
                return false;
            }

            return true;
        } catch (Exception e) {
            // Em caso de erro no Redis, permite a requisição (fail-open)
            log.error("Erro ao verificar rate limit no Redis: {}", e.getMessage());
            return true;
        }
    }
}
