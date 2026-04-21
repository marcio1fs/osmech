package com.osmech.payment.controller;

import com.osmech.payment.service.MercadoPagoWebhookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.Map;

@RestController
@RequestMapping("/mercadopago")
@RequiredArgsConstructor
@Slf4j
public class MercadoPagoWebhookController {

    private final MercadoPagoWebhookService webhookService;

    @PostMapping("/webhook")
    public ResponseEntity<Map<String, String>> receberPost(
            @RequestParam Map<String, String> queryParams,
            @org.springframework.web.bind.annotation.RequestHeader Map<String, String> headers,
            @RequestBody(required = false) Map<String, Object> body) {
        return processarWebhook(queryParams, headers, body);
    }

    @GetMapping("/webhook")
    public ResponseEntity<Map<String, String>> receberGet(
            @RequestParam Map<String, String> queryParams,
            @org.springframework.web.bind.annotation.RequestHeader Map<String, String> headers) {
        return processarWebhook(queryParams, headers, Collections.emptyMap());
    }

    private ResponseEntity<Map<String, String>> processarWebhook(
            Map<String, String> queryParams,
            Map<String, String> headers,
            Map<String, Object> body) {
        try {
            webhookService.processarNotificacao(
                    queryParams != null ? queryParams : Collections.emptyMap(),
                    headers != null ? headers : Collections.emptyMap(),
                    body != null ? body : Collections.emptyMap()
            );
            return ResponseEntity.ok(Map.of("status", "received"));
        } catch (SecurityException e) {
            log.warn("Webhook Mercado Pago rejeitado: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "webhook nao autorizado"));
        } catch (Exception e) {
            log.error("Falha ao processar webhook do Mercado Pago", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "falha ao processar webhook"));
        }
    }
}
