package com.osmech.payment.controller;

import com.osmech.payment.service.MercadoPagoWebhookService;
import com.osmech.security.JwtAuthFilter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MercadoPagoWebhookController.class)
@AutoConfigureMockMvc(addFilters = false)
class MercadoPagoWebhookControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private MercadoPagoWebhookService webhookService;

    @MockBean
    private JwtAuthFilter jwtAuthFilter;

    @Test
    void deveRetornar401QuandoAssinaturaInvalida() throws Exception {
        doThrow(new SecurityException("Assinatura invalida"))
                .when(webhookService)
                .processarNotificacao(anyMap(), anyMap(), anyMap());

        mockMvc.perform(post("/api/mercadopago/webhook")
                        .queryParam("id", "123")
                        .queryParam("topic", "payment")
                        .header("x-signature", "ts=1,v1=invalid")
                        .header("x-request-id", "req-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"data\":{\"id\":\"123\"}}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("webhook nao autorizado"));

        verify(webhookService, times(1)).processarNotificacao(anyMap(), anyMap(), anyMap());
    }

    @Test
    void deveRetornar200QuandoAssinaturaAceita() throws Exception {
        doNothing()
                .when(webhookService)
                .processarNotificacao(anyMap(), anyMap(), anyMap());

        mockMvc.perform(post("/api/mercadopago/webhook")
                        .queryParam("id", "123")
                        .queryParam("topic", "payment")
                        .header("x-signature", "ts=1,v1=valid")
                        .header("x-request-id", "req-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"data\":{\"id\":\"123\"}}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("received"));

        verify(webhookService, times(1)).processarNotificacao(anyMap(), anyMap(), anyMap());
    }
}
