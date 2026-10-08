package com.osmech.notification.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class WhatsAppService {

    private final RestTemplate restTemplate;

    @Value("${whatsapp.enabled:false}")
    private boolean enabled;

    @Value("${whatsapp.provider:twilio}")
    private String provider;

    @Value("${whatsapp.twilio.account-sid:}")
    private String twilioAccountSid;

    @Value("${whatsapp.twilio.auth-token:}")
    private String twilioAuthToken;

    @Value("${whatsapp.twilio.from-number:}")
    private String twilioFromNumber;

    @Value("${whatsapp.meta.phone-number-id:}")
    private String metaPhoneNumberId;

    @Value("${whatsapp.meta.access-token:}")
    private String metaAccessToken;

    /**
     * Envia mensagem usando as configurações específicas da Oficina (Z-API prioritário).
     * Se a oficina não tiver Z-API configurado, faz fallback para as configurações globais do sistema.
     */
    public ResultadoEnvio enviarMensagem(com.osmech.oficina.entity.Oficina oficina, String telefone, String mensagem) {
        String destino = normalizarTelefone(telefone);
        if (destino == null) {
            throw new IllegalArgumentException("Telefone do cliente inválido para envio WhatsApp");
        }

        if (oficina != null && Boolean.TRUE.equals(oficina.getWhatsappAtivo())) {
            String prov = oficina.getWhatsappProvider() != null ? oficina.getWhatsappProvider().trim().toUpperCase() : "ZAPI";
            if ("ZAPI".equals(prov)) {
                return enviarViaZApi(oficina.getZapiInstanceId(), oficina.getZapiToken(), oficina.getZapiClientToken(), destino, mensagem);
            }
        }

        // Fallback para envio global (Twilio / Meta configurado no application.yml)
        return enviarMensagem(telefone, mensagem);
    }

    public ResultadoEnvio enviarViaZApi(String instanceId, String token, String clientToken, String destino, String mensagem) {
        if (isBlank(instanceId) || isBlank(token) || isBlank(clientToken)) {
            return new ResultadoEnvio(false, destino, "Credenciais Z-API incompletas para esta oficina");
        }

        String url = "https://api.z-api.io/instances/" + instanceId.trim() + "/token/" + token.trim() + "/send-text";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Client-Token", clientToken.trim());

        Map<String, Object> body = Map.of(
                "phone", destino,
                "message", mensagem
        );

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url, new HttpEntity<>(body, headers), String.class);
            boolean ok = response.getStatusCode().is2xxSuccessful();
            return new ResultadoEnvio(ok, destino, ok ? "Mensagem enviada com sucesso via Z-API" : "Falha Z-API: " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("Falha no envio via Z-API (instance={}): {}", instanceId, e.getMessage());
            return new ResultadoEnvio(false, destino, "Falha Z-API: " + e.getMessage());
        }
    }

    /**
     * Consulta se a instância da Z-API está conectada ao WhatsApp
     */
    public Map<String, Object> consultarStatusZApi(String instanceId, String token, String clientToken) {
        if (isBlank(instanceId) || isBlank(token) || isBlank(clientToken)) {
            return Map.of("connected", false, "error", "Credenciais Z-API incompletas");
        }

        String url = "https://api.z-api.io/instances/" + instanceId.trim() + "/token/" + token.trim() + "/status";
        HttpHeaders headers = new HttpHeaders();
        headers.set("Client-Token", clientToken.trim());

        try {
            org.springframework.http.HttpEntity<Void> entity = new org.springframework.http.HttpEntity<>(headers);
            ResponseEntity<Map> response = restTemplate.exchange(url, org.springframework.http.HttpMethod.GET, entity, Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            }
            return Map.of("connected", false, "status", response.getStatusCode().toString());
        } catch (Exception e) {
            log.warn("Falha ao checar status Z-API (instance={}): {}", instanceId, e.getMessage());
            return Map.of("connected", false, "error", e.getMessage());
        }
    }

    public ResultadoEnvio enviarMensagem(String telefone, String mensagem) {
        String destino = normalizarTelefone(telefone);
        if (destino == null) {
            throw new IllegalArgumentException("Telefone do cliente invalido para envio WhatsApp");
        }
        if (!enabled) {
            return new ResultadoEnvio(false, destino, "WhatsApp desabilitado na configuracao");
        }

        String normalizedProvider = provider == null ? "" : provider.trim().toLowerCase();
        return switch (normalizedProvider) {
            case "meta" -> enviarViaMeta(destino, mensagem);
            case "twilio" -> enviarViaTwilio(destino, mensagem);
            default -> new ResultadoEnvio(false, destino, "Provider WhatsApp invalido: " + provider);
        };
    }

    private ResultadoEnvio enviarViaTwilio(String destino, String mensagem) {
        if (isBlank(twilioAccountSid) || isBlank(twilioAuthToken) || isBlank(twilioFromNumber)) {
            return new ResultadoEnvio(false, destino, "Credenciais Twilio incompletas");
        }

        String url = "https://api.twilio.com/2010-04-01/Accounts/" + twilioAccountSid + "/Messages.json";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        headers.set(HttpHeaders.AUTHORIZATION, "Basic " + basicAuth(twilioAccountSid, twilioAuthToken));

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("To", "whatsapp:" + destino);
        form.add("From", "whatsapp:" + twilioFromNumber.trim());
        form.add("Body", mensagem);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url, new HttpEntity<>(form, headers), String.class);
            boolean ok = response.getStatusCode().is2xxSuccessful();
            return new ResultadoEnvio(ok, destino, ok ? "Mensagem enviada via Twilio" : "Falha Twilio: " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("Falha envio WhatsApp (Twilio): {}", e.getMessage());
            return new ResultadoEnvio(false, destino, "Falha Twilio: " + e.getMessage());
        }
    }

    private ResultadoEnvio enviarViaMeta(String destino, String mensagem) {
        if (isBlank(metaPhoneNumberId) || isBlank(metaAccessToken)) {
            return new ResultadoEnvio(false, destino, "Credenciais Meta incompletas");
        }

        String url = "https://graph.facebook.com/v19.0/" + metaPhoneNumberId + "/messages";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(metaAccessToken.trim());

        Map<String, Object> payload = Map.of(
                "messaging_product", "whatsapp",
                "to", destino,
                "type", "text",
                "text", Map.of("body", mensagem)
        );

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url, new HttpEntity<>(payload, headers), String.class);
            boolean ok = response.getStatusCode().is2xxSuccessful();
            return new ResultadoEnvio(ok, destino, ok ? "Mensagem enviada via Meta" : "Falha Meta: " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("Falha envio WhatsApp (Meta): {}", e.getMessage());
            return new ResultadoEnvio(false, destino, "Falha Meta: " + e.getMessage());
        }
    }

    private String basicAuth(String user, String pass) {
        return Base64.getEncoder().encodeToString((user + ":" + pass).getBytes(StandardCharsets.UTF_8));
    }

    private String normalizarTelefone(String telefone) {
        if (telefone == null) return null;
        String digits = telefone.replaceAll("[^0-9]", "");
        if (digits.isBlank()) return null;
        if (!digits.startsWith("55") && digits.length() <= 11) {
            digits = "55" + digits;
        }
        return digits;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    public record ResultadoEnvio(boolean enviado, String destino, String detalhe) {}
}
