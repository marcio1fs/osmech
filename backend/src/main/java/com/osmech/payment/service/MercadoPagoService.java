package com.osmech.payment.service;

import com.mercadopago.client.preference.PreferenceBackUrlsRequest;
import com.mercadopago.client.preference.PreferenceClient;
import com.mercadopago.client.preference.PreferenceItemRequest;
import com.mercadopago.client.preference.PreferenceRequest;
import com.mercadopago.exceptions.MPApiException;
import com.mercadopago.resources.preference.Preference;
import com.osmech.payment.entity.Assinatura;
import com.osmech.payment.entity.Pagamento;
import com.osmech.plan.entity.Plano;
import com.osmech.user.entity.Usuario;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.util.Collections;

@Service
@RequiredArgsConstructor
@Slf4j
public class MercadoPagoService {

    @Value("${mercadopago.back-urls.success:}")
    private String backUrlSuccess;

    @Value("${mercadopago.back-urls.pending:}")
    private String backUrlPending;

    @Value("${mercadopago.back-urls.failure:}")
    private String backUrlFailure;

    @Value("${mercadopago.notification-url:}")
    private String notificationUrl;

    @Value("${mercadopago.access-token:}")
    private String accessToken;

    // Lazy-initialized client for better testability
    private PreferenceClient preferenceClient;

    private PreferenceClient getPreferenceClient() {
        if (preferenceClient == null) {
            preferenceClient = new PreferenceClient();
        }
        return preferenceClient;
    }

    // Setter for testing purposes
    public void setPreferenceClient(PreferenceClient client) {
        this.preferenceClient = client;
    }

    public Preference criarPreferenciaAssinatura(Usuario usuario,
                                                 Plano plano,
                                                 Assinatura assinatura,
                                                 Pagamento pagamento) {
        log.debug("Criando preferencia de pagamento com back-urls: success='{}', pending='{}', failure='{}'",
                backUrlSuccess, backUrlPending, backUrlFailure);

        if (accessToken == null || accessToken.isBlank()) {
            throw new IllegalStateException("MERCADOPAGO_ACCESS_TOKEN nao configurado");
        }

        try {
            PreferenceItemRequest item = PreferenceItemRequest.builder()
                    .id(String.valueOf(assinatura.getId()))
                    .title("Assinatura " + plano.getNome())
                    .description(pagamento.getDescricao())
                    .quantity(1)
                    .currencyId("BRL")
                    .unitPrice(pagamento.getValor())
                    .build();

            Preference preference;
            try {
                preference = getPreferenceClient().create(buildPreferenceRequest(item, pagamento, true));
            } catch (MPApiException e) {
                String apiBody = e.getApiResponse() != null ? e.getApiResponse().getContent() : "";
                if (e.getStatusCode() == 400 && apiBody != null && apiBody.contains("invalid_auto_return")) {
                    log.warn("Mercado Pago rejeitou auto_return, tentando novamente sem auto_return. assinaturaId={}",
                            assinatura.getId());
                    preference = getPreferenceClient().create(buildPreferenceRequest(item, pagamento, false));
                } else {
                    throw e;
                }
            }

            log.info("Preferencia Mercado Pago criada para assinatura {} (usuario {}): {}",
                    assinatura.getId(), usuario.getEmail(), preference.getId());

            return preference;
        } catch (MPApiException e) {
            String apiBody = e.getApiResponse() != null ? e.getApiResponse().getContent() : null;
            log.error("Erro Mercado Pago ao criar preferencia da assinatura {}. status={}, response={}",
                    assinatura.getId(), e.getStatusCode(), apiBody, e);
            throw new RuntimeException("Falha ao criar preferencia de pagamento no Mercado Pago", e);
        } catch (Exception e) {
            log.error("Erro ao criar preferencia no Mercado Pago para assinatura {}: {}",
                    assinatura.getId(), e.getMessage(), e);
            throw new RuntimeException("Falha ao criar preferencia de pagamento no Mercado Pago", e);
        }
    }

    private PreferenceRequest buildPreferenceRequest(PreferenceItemRequest item,
                                                     Pagamento pagamento,
                                                     boolean includeAutoReturn) {
        PreferenceRequest.PreferenceRequestBuilder builder = PreferenceRequest.builder()
                .items(Collections.singletonList(item))
                .externalReference(String.valueOf(pagamento.getId()));

        String successUrl = normalizeBackUrl(backUrlSuccess);
        String pendingUrl = normalizeBackUrl(backUrlPending);
        String failureUrl = normalizeBackUrl(backUrlFailure);

        if (successUrl != null || pendingUrl != null || failureUrl != null) {
            PreferenceBackUrlsRequest backUrls = PreferenceBackUrlsRequest.builder()
                    .success(successUrl)
                    .pending(pendingUrl)
                    .failure(failureUrl)
                    .build();
            builder.backUrls(backUrls);
        }

        if (includeAutoReturn && successUrl != null) {
            builder.autoReturn("approved");
        }

        String webhookUrl = trimToNull(notificationUrl);
        if (webhookUrl != null) {
            builder.notificationUrl(webhookUrl);
        }

        return builder.build();
    }

    public String resolverCheckoutUrl(Preference preference) {
        if (preference == null) {
            return null;
        }

        if (isTokenTeste(accessToken)) {
            String sandboxUrl = trimToNull(preference.getSandboxInitPoint());
            if (sandboxUrl != null) {
                return sandboxUrl;
            }
        }

        return trimToNull(preference.getInitPoint());
    }

    public String resolverCheckoutUrlPorPreferenciaId(String preferenceId) {
        String id = trimToNull(preferenceId);
        if (id == null) {
            return null;
        }
        try {
            Preference preference = getPreferenceClient().get(id);
            return resolverCheckoutUrl(preference);
        } catch (Exception e) {
            log.warn("Nao foi possivel resolver checkout para preferenceId={} ({})", id, e.getMessage());
            return null;
        }
    }

    private String normalizeBackUrl(String rawUrl) {
        String url = trimToNull(rawUrl);
        if (url == null) {
            return null;
        }

        try {
            URI uri = URI.create(url);
            String fragment = trimToNull(uri.getFragment());
            if (fragment != null && fragment.startsWith("/")) {
                String basePath = uri.getPath() != null ? uri.getPath() : "";
                URI normalized = new URI(
                        uri.getScheme(),
                        uri.getUserInfo(),
                        uri.getHost(),
                        uri.getPort(),
                        basePath + fragment,
                        uri.getQuery(),
                        null
                );
                return normalized.toString();
            }
            return uri.toString();
        } catch (Exception e) {
            log.warn("Back URL invalida ignorada: {}", rawUrl);
            return null;
        }
    }

    private boolean isTokenTeste(String token) {
        String normalized = trimToNull(token);
        return normalized != null && normalized.startsWith("TEST-");
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
