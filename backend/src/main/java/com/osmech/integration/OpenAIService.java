package com.osmech.integration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class OpenAIService implements IAService {

    @Value("${openai.api.key}")
    private String apiKey;

    @Value("${openai.api.url}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final Logger logger = LoggerFactory.getLogger(OpenAIService.class);

    @Override
    public String gerarResposta(String input) {
        return enviarRequisicaoIA("Gere uma resposta para: " + input);
    }

    @Override
    public String diagnosticarProblema(String descricaoProblema) {
        return enviarRequisicaoIA("Diagnostique o seguinte problema: " + descricaoProblema);
    }

    @Override
    public String gerarResumoOS(String detalhesOS) {
        return enviarRequisicaoIA("Gere um resumo para a seguinte ordem de serviço: " + detalhesOS);
    }

    @Override
    public String analisarHistoricoVeiculo(String historico) {
        return enviarRequisicaoIA("Analise o seguinte histórico do veículo: " + historico);
    }

    private String enviarRequisicaoIA(String prompt) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.set("Content-Type", "application/json");

        String body = "{\"model\": \"text-davinci-003\", \"prompt\": \"" + prompt + "\", \"max_tokens\": 150}";

        HttpEntity<String> request = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(apiUrl, HttpMethod.POST, request, String.class);
            return response.getBody();
        } catch (IllegalArgumentException e) {
            logger.error("Erro de argumento inválido: {}", e.getMessage(), e);
            return "Erro de argumento inválido: " + e.getMessage();
        } catch (IllegalStateException e) {
            logger.error("Erro de estado ilegal: {}", e.getMessage(), e);
            return "Erro de estado ilegal: " + e.getMessage();
        }
    }
}