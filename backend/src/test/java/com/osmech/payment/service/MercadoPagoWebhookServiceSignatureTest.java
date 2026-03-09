package com.osmech.payment.service;

import com.osmech.payment.repository.AssinaturaRepository;
import com.osmech.payment.repository.MercadoPagoWebhookEventRepository;
import com.osmech.payment.repository.PagamentoRepository;
import com.osmech.user.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MercadoPagoWebhookServiceSignatureTest {

    @Test
    void deveAceitarAssinaturaValida() {
        MercadoPagoWebhookService service = novoService();
        ReflectionTestUtils.setField(service, "webhookSecret", "segredo-teste");

        Long paymentId = 123L;
        String requestId = "req-123";
        String ts = "1700000000";
        String manifest = "id:" + paymentId + ";request-id:" + requestId + ";ts:" + ts + ";";
        String assinaturaValida = "ts=" + ts + ",v1=" + hmacSha256Hex(manifest, "segredo-teste");

        Map<String, String> queryParams = Map.of("id", String.valueOf(paymentId));
        Map<String, String> headers = new HashMap<>();
        headers.put("x-signature", assinaturaValida);
        headers.put("x-request-id", requestId);

        assertDoesNotThrow(() -> ReflectionTestUtils.invokeMethod(
                service, "validarAssinaturaSeConfigurada", queryParams, headers, paymentId));
    }

    @Test
    void deveRejeitarAssinaturaInvalida() {
        MercadoPagoWebhookService service = novoService();
        ReflectionTestUtils.setField(service, "webhookSecret", "segredo-teste");

        Long paymentId = 123L;
        Map<String, String> queryParams = Map.of("id", String.valueOf(paymentId));
        Map<String, String> headers = new HashMap<>();
        headers.put("x-signature", "ts=1700000000,v1=assinatura-invalida");
        headers.put("x-request-id", "req-123");

        assertThrows(SecurityException.class, () -> ReflectionTestUtils.invokeMethod(
                service, "validarAssinaturaSeConfigurada", queryParams, headers, paymentId));
    }

    @Test
    void deveIgnorarValidacaoQuandoSecretNaoConfigurado() {
        MercadoPagoWebhookService service = novoService();
        ReflectionTestUtils.setField(service, "webhookSecret", "");

        Long paymentId = 123L;
        Map<String, String> queryParams = Map.of("id", String.valueOf(paymentId));
        Map<String, String> headers = Map.of();

        assertDoesNotThrow(() -> ReflectionTestUtils.invokeMethod(
                service, "validarAssinaturaSeConfigurada", queryParams, headers, paymentId));
    }

    private MercadoPagoWebhookService novoService() {
        PagamentoRepository pagamentoRepository = mock(PagamentoRepository.class);
        AssinaturaRepository assinaturaRepository = mock(AssinaturaRepository.class);
        MercadoPagoWebhookEventRepository webhookEventRepository = mock(MercadoPagoWebhookEventRepository.class);
        UsuarioRepository usuarioRepository = mock(UsuarioRepository.class);
        Environment environment = mock(Environment.class);
        
        // Return "dev" profile so @PostConstruct doesn't fail
        when(environment.getActiveProfiles()).thenReturn(new String[]{"dev"});
        
        return new MercadoPagoWebhookService(
                pagamentoRepository,
                assinaturaRepository,
                webhookEventRepository,
                usuarioRepository,
                environment
        );
    }

    private String hmacSha256Hex(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] digest = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
