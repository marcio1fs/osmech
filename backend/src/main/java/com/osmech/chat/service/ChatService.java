package com.osmech.chat.service;

import com.osmech.chat.dto.ChatRequest;
import com.osmech.chat.dto.ChatResponse;
import com.osmech.chat.entity.ChatMessage;
import com.osmech.chat.repository.ChatRepository;
import com.osmech.config.ResourceNotFoundException;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatService {

    private final ChatRepository chatRepository;
    private final UsuarioRepository userRepository;
    private final RestTemplate restTemplate;

    @Value("${ai.enabled:false}")
    private boolean aiEnabled;

    @Value("${ai.openai.api-key:}")
    private String apiKey;

    @Value("${ai.openai.model:gemini-2.0-flash}")
    private String model;

    @Value("${ai.provider:gemini}")
    private String provider;

    @Value("${ai.openai.base-url:https://generativelanguage.googleapis.com/v1beta/openai/chat/completions}")
    private String chatCompletionsUrl;

    private static final String SYSTEM_PROMPT = """
            Voce e a IA Oficial do OSMECH, assistente especializado em oficinas mecanicas.

            Regras:
            1. Responda em Portugues do Brasil.
            2. Seja claro, objetivo e pratico.
            3. Nao invente dados; se faltar contexto, pergunte.
            4. Nao forneca diagnostico definitivo sem validacao presencial.
            5. Foque em oficina: diagnostico, OS, estoque, financeiro e planos.
            """;

    @Transactional
    public ChatResponse enviarMensagem(ChatRequest request, Authentication auth) {
        Usuario user = getUsuario(auth);

        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = UUID.randomUUID().toString().substring(0, 8);
        }

        ChatMessage userMsg = ChatMessage.builder()
                .usuarioId(user.getId())
                .sessionId(sessionId)
                .role("user")
                .content(request.getMessage())
                .build();
        chatRepository.save(userMsg);

        String aiResponse = gerarResposta(user.getId(), sessionId, request.getMessage());

        ChatMessage aiMsg = ChatMessage.builder()
                .usuarioId(user.getId())
                .sessionId(sessionId)
                .role("assistant")
                .content(aiResponse)
                .build();
        chatRepository.save(aiMsg);

        return ChatResponse.fromEntity(aiMsg);
    }

    @Transactional(readOnly = true)
    public List<ChatResponse> getHistoricoSessao(String sessionId, Authentication auth) {
        Usuario user = getUsuario(auth);
        return chatRepository.findByUsuarioIdAndSessionIdOrderByCriadoEmAsc(user.getId(), sessionId)
                .stream()
                .map(ChatResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<String> getSessoes(Authentication auth) {
        Usuario user = getUsuario(auth);
        return chatRepository.findSessionsByUsuarioId(user.getId());
    }

    @Transactional
    public void deletarSessao(String sessionId, Authentication auth) {
        Usuario user = getUsuario(auth);
        chatRepository.deleteByUsuarioIdAndSessionId(user.getId(), sessionId);
    }

    private String gerarResposta(Long usuarioId, String sessionId, String userMessage) {
        if (!aiEnabled || apiKey == null || apiKey.isBlank()) {
            return gerarRespostaLocal(userMessage);
        }

        try {
            return chamarOpenAI(usuarioId, sessionId, userMessage);
        } catch (Exception e) {
            log.error("Erro ao chamar IA externa: {}", e.getMessage());
            return gerarRespostaLocal(userMessage);
        }
    }

    @SuppressWarnings("unchecked")
    private String chamarOpenAI(Long usuarioId, String sessionId, String userMessage) {
        List<ChatMessage> history = chatRepository.findRecentMessages(usuarioId, sessionId, PageRequest.of(0, 20));
        Collections.reverse(history);

        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));

        for (ChatMessage msg : history) {
            if (!msg.getContent().equals(userMessage)) {
                messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", userMessage));

        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("messages", messages);
        body.put("max_tokens", 1500);
        body.put("temperature", 0.7);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                chatCompletionsUrl,
                HttpMethod.POST,
                entity,
                Map.class
        );

        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
            if (choices != null && !choices.isEmpty()) {
                Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                Object content = message.get("content");
                if (content instanceof String text && !text.isBlank()) {
                    return text;
                }
            }
        }

        return gerarRespostaLocal(userMessage);
    }

    private String gerarRespostaLocal(String msg) {
        String lower = msg.toLowerCase().trim();

        if (lower.matches(".*(oi|ola|bom dia|boa tarde|boa noite|eai|e ai|hey|hello).*")) {
            return "Ola! Sou a IA do OSMECH, assistente da oficina.\n\n"
                    + "Posso ajudar com:\n"
                    + "- Duvidas tecnicas de veiculos\n"
                    + "- Ordens de servico (OS)\n"
                    + "- Estoque\n"
                    + "- Financeiro\n\n"
                    + "Como posso ajudar hoje?";
        }

        if (lower.matches(".*(ordem de servico|ordem de serviço|\\bos\\b|criar os|abrir os|status os|fechar os).*")) {
            return "Ordens de Servico:\n\n"
                    + "- Criar OS: menu Nova OS\n"
                    + "- Consultar: menu Ordens de Servico\n"
                    + "- Status: Orcamento -> Em andamento -> Concluida\n\n"
                    + "Dica: descreva bem o problema para facilitar o diagnostico.";
        }

        if (lower.matches(".*(estoque|peca|peça|reposicao|reposição|falt).*")) {
            return "Controle de Estoque:\n\n"
                    + "- Cadastro de pecas\n"
                    + "- Entrada e saida\n"
                    + "- Alerta de estoque minimo\n"
                    + "- Organizacao por categoria";
        }

        if (lower.matches(".*(financ|pagamento|receita|despesa|fluxo|caixa|cobr).*")) {
            return "Financeiro:\n\n"
                    + "- Visao de receitas e despesas\n"
                    + "- Fluxo de caixa por periodo\n"
                    + "- Historico de transacoes\n\n"
                    + "Dica: registre todas as movimentacoes.";
        }

        if (lower.matches(".*(motor|aquec|superaquec|ferveu|fumaca|fumaça|barulho motor|batendo).*")) {
            return "Possiveis causas (motor):\n\n"
                    + "- Superaquecimento: radiador, bomba d'agua, termostato, ventoinha e nivel do liquido.\n"
                    + "- Fumaca branca: junta de cabecote ou trinca.\n"
                    + "- Fumaca preta: mistura rica (injecao, filtro, MAP/MAF).\n"
                    + "- Fumaca azul: queima de oleo (aneis e retentores).\n"
                    + "- Barulho: tensor, correia, biela ou tuchos.\n\n"
                    + "Observacao: orientacao inicial. Confirmar com verificacao presencial.";
        }

        if (lower.matches(".*(freio|frear|frenagem|pastilha|disco|pedal duro|pedal mole).*")) {
            return "Sistema de Freios:\n\n"
                    + "- Pedal mole: ar no sistema, vazamento ou cilindro mestre.\n"
                    + "- Pedal duro: servo-freio/hidrovacuo ou mangueira de vacuo.\n"
                    + "- Vibracao: disco empenado.\n"
                    + "- Ruido: pastilha gasta.\n"
                    + "- Puxa para um lado: pinca travada ou desgaste irregular.";
        }

        if (lower.matches(".*(suspens|amortec|balanc|alinhamento|barulho roda|estalo).*")) {
            return "Suspensao e Direcao:\n\n"
                    + "- Barulho em buraco: amortecedor, bucha, bieleta, batente.\n"
                    + "- Estalo ao virar: homocinetica.\n"
                    + "- Volante tremendo: balanceamento/pneu/terminal.\n"
                    + "- Carro puxando: alinhamento, pneu ou suspensao.";
        }

        if (lower.matches(".*(eletric|bateria|alternador|motor partida|nao liga|não liga|luz|farol|fusivel|fusível).*")) {
            return "Sistema Eletrico:\n\n"
                    + "- Nao liga: bateria, terminais, partida, rele e fusivel.\n"
                    + "- Luz falhando: fusivel, rele, aterramento, chicote.\n"
                    + "- Bateria descarregando: consumo parasita, alternador, bateria antiga.";
        }

        if (lower.matches(".*(plano|assinatura|pro|premium|upgrade).*")) {
            return "Planos OSMECH:\n\n"
                    + "- Basico\n"
                    + "- PRO\n"
                    + "- PRO+ (recursos avancados e IA ampliada)\n\n"
                    + "Acesse a tela de Planos para detalhes.";
        }

        return "Entendi sua pergunta. Posso ajudar com diagnostico tecnico, OS, estoque, financeiro e planos."
                + " Se quiser, descreva o sintoma com mais detalhes (carro, ano, motor e quando ocorre).";
    }

    private Usuario getUsuario(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));
    }
}
