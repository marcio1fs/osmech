package com.osmech.config;

import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MercadoPagoInitializerTest {

    @Test
    void deveFalharEmProdSemWebhookSecret() {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[]{"prod"});

        MercadoPagoInitializer initializer = new MercadoPagoInitializer(environment);
        ReflectionTestUtils.setField(initializer, "accessToken", "");
        ReflectionTestUtils.setField(initializer, "webhookSecret", "");

        assertThrows(IllegalStateException.class, initializer::init);
    }

    @Test
    void naoDeveFalharEmDevSemWebhookSecret() {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[]{"dev"});

        MercadoPagoInitializer initializer = new MercadoPagoInitializer(environment);
        ReflectionTestUtils.setField(initializer, "accessToken", "");
        ReflectionTestUtils.setField(initializer, "webhookSecret", "");

        assertDoesNotThrow(initializer::init);
    }

    @Test
    void naoDeveFalharEmProdComWebhookSecret() {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[]{"prod"});

        MercadoPagoInitializer initializer = new MercadoPagoInitializer(environment);
        ReflectionTestUtils.setField(initializer, "accessToken", "");
        ReflectionTestUtils.setField(initializer, "webhookSecret", "secret-ok");

        assertDoesNotThrow(initializer::init);
    }
}
