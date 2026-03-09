package com.osmech.config;

import com.mercadopago.MercadoPagoConfig;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import java.util.Arrays;

/**
 * Inicializa o SDK do Mercado Pago e valida variáveis obrigatórias em produção.
 */
@Configuration
public class MercadoPagoInitializer {

    private final Environment environment;

    public MercadoPagoInitializer(Environment environment) {
        this.environment = environment;
    }

    @Value("${mercadopago.access-token:}")
    private String accessToken;

    @Value("${mercadopago.webhook-secret:}")
    private String webhookSecret;

    @PostConstruct
    public void init() {
        boolean isProd = Arrays.asList(environment.getActiveProfiles()).contains("prod");
        if (isProd && (webhookSecret == null || webhookSecret.isBlank())) {
            throw new IllegalStateException("MERCADOPAGO_WEBHOOK_SECRET e obrigatorio em producao.");
        }

        if (accessToken != null && !accessToken.isBlank()) {
            MercadoPagoConfig.setAccessToken(accessToken);
        }
    }
}
