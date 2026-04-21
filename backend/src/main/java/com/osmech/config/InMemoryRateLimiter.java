package com.osmech.config;

import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Implementação em memória do Rate Limiter.
 * Adequado para desenvolvimento e instâncias únicas.
 * Para produção multi-instância, use RedisRateLimiter.
 */
@Component
@org.springframework.boot.autoconfigure.condition.ConditionalOnProperty(
    name = "rate-limit.mode", 
    havingValue = "memory", 
    matchIfMissing = true
)
@Slf4j
public class InMemoryRateLimiter extends RateLimitFilter {

    // Armazenamento em memória
    private static final long REQUEST_ENTRY_EXPIRE_MILLIS = ENTRY_EXPIRE_MILLIS;      // 2 min (herdado)
    private static final long LOGIN_ENTRY_EXPIRE_MILLIS = 15 * 60_000L;               // 15 min

    private final Map<String, RateLimitEntry> requestCounts = new ConcurrentHashMap<>();
    private final Map<String, RateLimitEntry> loginAttempts = new ConcurrentHashMap<>();

    @Override
    protected boolean checkLoginRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        long currentMinute = System.currentTimeMillis() / 60000;
        String keyMinute = clientIp + ":min:" + currentMinute;
        String key15Min = clientIp + ":15min:" + (currentMinute / 15);

        cleanupOldEntries(requestCounts, REQUEST_ENTRY_EXPIRE_MILLIS);
        cleanupOldEntries(loginAttempts, LOGIN_ENTRY_EXPIRE_MILLIS);

        RateLimitEntry minuteCounter = loginAttempts.computeIfAbsent(keyMinute, k -> new RateLimitEntry());
        RateLimitEntry fifteenMinuteCounter = loginAttempts.computeIfAbsent(key15Min, k -> new RateLimitEntry());

        // Limite por minuto
        if (minuteCounter.incrementAndGet() > MAX_LOGIN_ATTEMPTS_PER_MINUTE) {
            log.warn("Rate limit excedido para login (por minuto): {}", clientIp);
            sendTooManyRequests(response, "Muitas tentativas de login. Tente novamente em 1 minuto.");
            return false;
        }

        // Limite por 15 minutos
        if (fifteenMinuteCounter.incrementAndGet() > MAX_LOGIN_ATTEMPTS_PER_15_MINUTES) {
            log.warn("Rate limit excedido para login (por 15 minutos): {}", clientIp);
            sendTooManyRequests(response, "Muitas tentativas de login. Tente novamente em 15 minutos.");
            return false;
        }

        return true;
    }

    @Override
    protected boolean checkRateLimit(String clientIp, HttpServletResponse response) throws IOException {
        long currentMinute = System.currentTimeMillis() / 60000;
        String key = clientIp + ":" + currentMinute;

        cleanupOldEntries(requestCounts, REQUEST_ENTRY_EXPIRE_MILLIS);

        RateLimitEntry counter = requestCounts.computeIfAbsent(key, k -> new RateLimitEntry());

        if (counter.incrementAndGet() > MAX_REQUESTS_PER_MINUTE) {
            log.warn("Rate limit geral excedido: {}", clientIp);
            sendTooManyRequests(response, "Muitas requisições. Tente novamente em 1 minuto.");
            return false;
        }

        return true;
    }

    private void cleanupOldEntries(Map<String, RateLimitEntry> map, long maxAgeMs) {
        long now = System.currentTimeMillis();
        Iterator<Map.Entry<String, RateLimitEntry>> iterator = map.entrySet().iterator();
        while (iterator.hasNext()) {
            Map.Entry<String, RateLimitEntry> entry = iterator.next();
            if (now - entry.getValue().getCreatedAt() > maxAgeMs) {
                iterator.remove();
            }
        }
    }

    /**
     * Cleanup agendado - executa a cada minuto para remover entradas expiradas.
     */
    @Scheduled(fixedRate = 60000)
    public void scheduledCleanup() {
        cleanupOldEntries(requestCounts, REQUEST_ENTRY_EXPIRE_MILLIS);
        cleanupOldEntries(loginAttempts, LOGIN_ENTRY_EXPIRE_MILLIS);
        if (log.isDebugEnabled()) {
            log.debug("Rate limit cleanup executed. requestCounts={}, loginAttempts={}", 
                    requestCounts.size(), loginAttempts.size());
        }
    }

    // Classe auxiliar
    private static class RateLimitEntry {
        private final AtomicInteger count = new AtomicInteger(0);
        private final long createdAt = System.currentTimeMillis();

        public int incrementAndGet() {
            return count.incrementAndGet();
        }

        public long getCreatedAt() {
            return createdAt;
        }
    }
}
