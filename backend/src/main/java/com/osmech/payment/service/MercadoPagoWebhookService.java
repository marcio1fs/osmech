package com.osmech.payment.service;

import com.mercadopago.client.payment.PaymentClient;
import com.mercadopago.resources.payment.Payment;
import com.osmech.payment.entity.Assinatura;
import com.osmech.payment.entity.MercadoPagoWebhookEvent;
import com.osmech.payment.entity.Pagamento;
import com.osmech.payment.entity.StatusPagamento;
import com.osmech.payment.repository.AssinaturaRepository;
import com.osmech.payment.repository.MercadoPagoWebhookEventRepository;
import com.osmech.payment.repository.PagamentoRepository;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class MercadoPagoWebhookService {

    private final PagamentoRepository pagamentoRepository;
    private final AssinaturaRepository assinaturaRepository;
    private final MercadoPagoWebhookEventRepository webhookEventRepository;
    private final UsuarioRepository usuarioRepository;

    @Value("${mercadopago.webhook-secret:}")
    private String webhookSecret;

    private final Environment environment;

    private final PaymentClient paymentClient = new PaymentClient();

    @PostConstruct
    public void validateProductionConfig() {
        // Always require webhook secret configuration - it's critical for security
        // The secret must be set via MERCADOPAGO_WEBHOOK_SECRET environment variable
        if (webhookSecret == null || webhookSecret.isBlank()) {
            log.warn("===========================================================");
            log.warn("WARNING: MercadoPago webhook secret is NOT configured!");
            log.warn("Set MERCADOPAGO_WEBHOOK_SECRET environment variable.");
            log.warn("Webhook requests will be ACCEPTED WITHOUT SIGNATURE VALIDATION.");
            log.warn("This is acceptable for LOCAL DEVELOPMENT only.");
            log.warn("===========================================================");
        } else {
            log.info("MercadoPago webhook signature validation is ENABLED.");
            log.debug("Webhook secret configured (length: {} chars)", webhookSecret.length());
        }
        
        boolean isProd = Arrays.asList(environment.getActiveProfiles()).contains("prod")
                || Arrays.asList(environment.getActiveProfiles()).contains("production");
        
        if (isProd && (webhookSecret == null || webhookSecret.isBlank())) {
            log.error("FATAL: MercadoPago webhook secret is not configured in production! ");
            throw new IllegalStateException(
                "MercadoPago webhook secret MUST be configured in production. "
                + "Set MERCADOPAGO_WEBHOOK_SECRET environment variable."
            );
        }
    }

    @Transactional
    public void processarNotificacao(Map<String, String> queryParams,
                                     Map<String, String> headers,
                                     Map<String, Object> body) {
        String tipoEvento = extrairTipoEvento(queryParams, body);
        if (tipoEvento == null || !tipoEvento.contains("payment")) {
            log.info("Webhook Mercado Pago ignorado. tipo={}", tipoEvento);
            return;
        }

        Long mercadoPagoPaymentId = extrairPaymentId(queryParams, body);
        if (mercadoPagoPaymentId == null) {
            log.warn("Webhook Mercado Pago sem payment id. query={} body={}", queryParams, body);
            return;
        }

        validarAssinaturaSeConfigurada(queryParams, headers, mercadoPagoPaymentId);

        Payment mpPayment = buscarPagamentoMercadoPago(mercadoPagoPaymentId);
        Optional<Pagamento> pagamentoOpt = localizarPagamentoLocal(mpPayment, mercadoPagoPaymentId);

        if (pagamentoOpt.isEmpty()) {
            log.warn("Pagamento local nao encontrado para MP payment {} (externalReference={})",
                    mercadoPagoPaymentId, mpPayment.getExternalReference());
            return;
        }

        Pagamento pagamento = pagamentoOpt.get();
        StatusPagamento novoStatus = mapearStatusPagamento(mpPayment.getStatus());
        if (novoStatus == null) {
            log.info("Status MP sem mapeamento local. paymentId={} status={}",
                    mercadoPagoPaymentId, mpPayment.getStatus());
            return;
        }

        if (!registrarEventoSeNovo(mpPayment, novoStatus)) {
            log.info("Webhook duplicado ignorado. mpPaymentId={} statusMP={}",
                    mercadoPagoPaymentId, mpPayment.getStatus());
            return;
        }

        pagamento.setStatus(novoStatus);
        pagamento.setTransacaoExternaId(String.valueOf(mercadoPagoPaymentId));
        if (StatusPagamento.PAGO.equals(pagamento.getStatus()) && pagamento.getPagoEm() == null) {
            pagamento.setPagoEm(LocalDateTime.now());
        }
        pagamentoRepository.save(pagamento);

        if ("ASSINATURA".equals(pagamento.getTipo()) && pagamento.getReferenciaId() != null) {
            atualizarAssinatura(pagamento);
        }

        log.info("Webhook Mercado Pago processado. mpPaymentId={} pagamentoId={} statusMP={} statusLocal={}",
                mercadoPagoPaymentId, pagamento.getId(), mpPayment.getStatus(), novoStatus);
    }

    private Payment buscarPagamentoMercadoPago(Long mercadoPagoPaymentId) {
        try {
            return paymentClient.get(mercadoPagoPaymentId);
        } catch (Exception e) {
            throw new RuntimeException("Falha ao consultar pagamento no Mercado Pago: " + mercadoPagoPaymentId, e);
        }
    }

    private Optional<Pagamento> localizarPagamentoLocal(Payment mpPayment, Long mercadoPagoPaymentId) {
        String externalReference = trimToNull(mpPayment.getExternalReference());
        if (externalReference != null) {
            try {
                Long pagamentoId = Long.parseLong(externalReference);
                Optional<Pagamento> porId = pagamentoRepository.findById(pagamentoId);
                if (porId.isPresent()) {
                    return porId;
                }
            } catch (NumberFormatException ignored) {
                log.warn("externalReference nao numerica: {}", externalReference);
            }
        }

        return pagamentoRepository.findByTransacaoExternaId(String.valueOf(mercadoPagoPaymentId));
    }

    private void atualizarAssinatura(Pagamento pagamento) {
        Optional<Assinatura> assinaturaOpt = assinaturaRepository.findById(pagamento.getReferenciaId());
        if (assinaturaOpt.isEmpty()) {
            return;
        }

        Assinatura assinatura = assinaturaOpt.get();

        if (StatusPagamento.PAGO.equals(pagamento.getStatus())) {
            assinatura.setStatus("ACTIVE");
            assinatura.setProximaCobranca(LocalDate.now().plusMonths(1));
            assinaturaRepository.save(assinatura);

            usuarioRepository.findById(assinatura.getUsuarioId()).ifPresent(usuario -> {
                usuario.setPlano(assinatura.getPlanoCodigo());
                usuario.setAtivo(true);
                usuarioRepository.save(usuario);
            });
            return;
        }

        if (StatusPagamento.FALHOU.equals(pagamento.getStatus()) || StatusPagamento.CANCELADO.equals(pagamento.getStatus())) {
            assinatura.setStatus("PAST_DUE");
            assinaturaRepository.save(assinatura);
        }
    }

    private boolean registrarEventoSeNovo(Payment mpPayment, StatusPagamento statusLocal) {
        String eventKey = montarEventKey(mpPayment);
        if (webhookEventRepository.existsByEventKey(eventKey)) {
            return false;
        }

        try {
            webhookEventRepository.save(MercadoPagoWebhookEvent.builder()
                    .eventKey(eventKey)
                    .paymentId(mpPayment.getId())
                    .mpStatus(defaultIfBlank(mpPayment.getStatus(), "unknown"))
                    .statusLocal(statusLocal.name())
                    .build());
            return true;
        } catch (DataIntegrityViolationException e) {
            return false;
        }
    }

    private String montarEventKey(Payment payment) {
        String status = defaultIfBlank(payment.getStatus(), "unknown");
        String statusDetail = defaultIfBlank(payment.getStatusDetail(), "na");
        String updatedAt = payment.getDateLastUpdated() != null
                ? payment.getDateLastUpdated().toString()
                : "na";
        return "mp-payment:" + payment.getId()
                + "|status:" + status
                + "|detail:" + statusDetail
                + "|updated:" + updatedAt;
    }

    private String extrairTipoEvento(Map<String, String> queryParams, Map<String, Object> body) {
        String topic = firstNonBlank(
                queryParams.get("topic"),
                queryParams.get("type"),
                asString(body.get("topic")),
                asString(body.get("type")),
                asString(body.get("action"))
        );
        return topic == null ? null : topic.toLowerCase();
    }

    private void validarAssinaturaSeConfigurada(Map<String, String> queryParams,
                                                Map<String, String> headers,
                                                Long paymentId) {
        String secret = trimToNull(webhookSecret);
        if (secret == null) {
            return;
        }

        String signatureHeader = obterHeader(headers, "x-signature");
        String requestId = obterHeader(headers, "x-request-id");
        if (signatureHeader == null || requestId == null) {
            throw new SecurityException("Cabecalhos de assinatura ausentes");
        }

        Map<String, String> assinatura = parseAssinatura(signatureHeader);
        String ts = trimToNull(assinatura.get("ts"));
        String v1 = trimToNull(assinatura.get("v1"));
        if (ts == null || v1 == null) {
            throw new SecurityException("Formato de assinatura invalido");
        }

        String manifest = "id:" + paymentId + ";request-id:" + requestId + ";ts:" + ts + ";";
        String expected = hmacSha256Hex(manifest, secret);
        if (!MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), v1.getBytes(StandardCharsets.UTF_8))) {
            throw new SecurityException("Assinatura invalida");
        }
    }

    private Long extrairPaymentId(Map<String, String> queryParams, Map<String, Object> body) {
        String fromQuery = firstNonBlank(
                queryParams.get("id"),
                queryParams.get("data.id"),
                queryParams.get("data_id")
        );
        if (fromQuery != null) {
            return parseLong(fromQuery);
        }

        Object dataRaw = body.get("data");
        if (dataRaw instanceof Map<?, ?> dataMap) {
            Object id = dataMap.get("id");
            if (id != null) {
                return parseLong(String.valueOf(id));
            }
        }

        Object idRoot = body.get("id");
        if (idRoot != null) {
            return parseLong(String.valueOf(idRoot));
        }

        return null;
    }

    private StatusPagamento mapearStatusPagamento(String mpStatus) {
        if (mpStatus == null) {
            return null;
        }
        return switch (mpStatus.toLowerCase()) {
            case "approved" -> StatusPagamento.PAGO;
            case "pending", "in_process", "in_mediation", "authorized" -> StatusPagamento.PENDENTE;
            case "cancelled" -> StatusPagamento.CANCELADO;
            case "refunded", "charged_back" -> StatusPagamento.REEMBOLSADO;
            case "rejected" -> StatusPagamento.FALHOU;
            default -> null;
        };
    }

    private Long parseLong(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private String obterHeader(Map<String, String> headers, String nome) {
        if (headers == null || headers.isEmpty()) {
            return null;
        }
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            if (entry.getKey() != null && entry.getKey().equalsIgnoreCase(nome)) {
                return trimToNull(entry.getValue());
            }
        }
        return null;
    }

    private Map<String, String> parseAssinatura(String assinaturaRaw) {
        Map<String, String> values = new HashMap<>();
        for (String part : assinaturaRaw.split(",")) {
            String[] kv = part.trim().split("=", 2);
            if (kv.length == 2) {
                values.put(kv[0].trim().toLowerCase(), kv[1].trim());
            }
        }
        return values;
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
            throw new RuntimeException("Falha ao validar assinatura do webhook", e);
        }
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            String normalized = trimToNull(value);
            if (normalized != null) {
                return normalized;
            }
        }
        return null;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String defaultIfBlank(String value, String fallback) {
        String normalized = trimToNull(value);
        return normalized != null ? normalized : fallback;
    }
}
