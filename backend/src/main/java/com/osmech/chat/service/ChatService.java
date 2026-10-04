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
    private final ChatDataContextService dataContextService;
    private final ChatToolsService toolsService;

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

    private static final String BASE_PROMPT = """
            Voce e a IA Oficial do OSMECH: especialista no sistema OSMECH e em mecanica automotiva.
            Seu papel e tirar duvidas e guiar o usuario em TODAS as areas do sistema.

            Regras:
            1. Responda em Portugues do Brasil, de forma clara, objetiva e pratica.
            2. Para duvidas do sistema, use o GUIA DO SISTEMA abaixo e cite o nome exato do menu, com passo a passo curto.
            3. Respeite o papel do usuario: se a funcao for restrita a outro papel, explique isso e diga quem pode fazer.
            4. Nao invente telas, botoes ou dados. Se nao souber ou faltar contexto, diga e pergunte.
            5. Voce so conhece os numeros listados em DADOS ATUAIS DA OFICINA (quando presentes); para qualquer outro dado, oriente a consultar a tela correspondente. Nunca invente numeros, clientes ou valores.
            6. Em diagnostico automotivo: peca marca, modelo, ano e sintoma; liste causas provaveis da mais para a menos comum, testes de verificacao e alerte que a confirmacao e presencial.
            7. Se o usuario estiver em uma tela, priorize ajuda sobre ela.
            8. Recuse assuntos fora de oficina e do sistema.
            """;

    private static final String KNOWLEDGE = carregarConhecimento();

    private static String carregarConhecimento() {
        try (var in = ChatService.class.getResourceAsStream("/ai/knowledge/osmech.md")) {
            return in == null ? "" : new String(in.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    private String montarPrompt(Authentication auth, String screen, Usuario user) {
        boolean admin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().endsWith("ADMIN"));
        String papeis = auth.getAuthorities().stream()
                .map(a -> a.getAuthority().replace("ROLE_", ""))
                .collect(Collectors.joining(", "));
        StringBuilder sb = new StringBuilder(BASE_PROMPT);
        sb.append("\nPapel do usuario: ").append(papeis.isBlank() ? "desconhecido" : papeis).append('\n');
        if (screen != null && !screen.isBlank()) {
            sb.append("Tela atual do usuario: ").append(screen.trim(), 0, Math.min(screen.trim().length(), 60)).append('\n');
        }
        sb.append("\nGUIA DO SISTEMA:\n").append(KNOWLEDGE);
        String dados = dataContextService.montarResumo(user, admin);
        if (!dados.isBlank()) {
            sb.append("\nDADOS ATUAIS DA OFICINA (resumo real, somente leitura; use para responder perguntas sobre numeros e cite apenas o que consta aqui):\n").append(dados);
        }
        return sb.toString();
    }

    @Transactional
    public ChatResponse enviarMensagem(ChatRequest request, Authentication auth) {
        Usuario user = getUsuario(auth);

        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = UUID.randomUUID().toString().substring(0, 8);
        }

        ChatMessage userMsg = ChatMessage.builder()
                .usuarioId(user.getOficinaId())
                .sessionId(sessionId)
                .role("user")
                .content(request.getMessage())
                .build();
        chatRepository.save(userMsg);

        boolean admin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().endsWith("ADMIN"));
        String aiResponse = gerarResposta(user, admin, sessionId, request.getMessage(),
                montarPrompt(auth, request.getScreen(), user));

        ChatMessage aiMsg = ChatMessage.builder()
                .usuarioId(user.getOficinaId())
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
        return chatRepository.findByUsuarioIdAndSessionIdOrderByCriadoEmAsc(user.getOficinaId(), sessionId)
                .stream()
                .map(ChatResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<String> getSessoes(Authentication auth) {
        Usuario user = getUsuario(auth);
        return chatRepository.findSessionsByUsuarioId(user.getOficinaId());
    }

    @Transactional
    public void deletarSessao(String sessionId, Authentication auth) {
        Usuario user = getUsuario(auth);
        chatRepository.deleteByUsuarioIdAndSessionId(user.getOficinaId(), sessionId);
    }

    private String gerarResposta(Usuario user, boolean admin, String sessionId, String userMessage, String systemPrompt) {
        if (!aiEnabled || apiKey == null || apiKey.isBlank()) {
            return gerarRespostaLocal(userMessage);
        }

        try {
            return chamarOpenAI(user, admin, sessionId, userMessage, systemPrompt);
        } catch (Exception e) {
            log.error("Erro ao chamar IA externa: {}", e.getMessage());
            return gerarRespostaLocal(userMessage);
        }
    }

    private static final int MAX_RODADAS_FERRAMENTAS = 3;

    @SuppressWarnings("unchecked")
    private String chamarOpenAI(Usuario user, boolean admin, String sessionId, String userMessage, String systemPrompt) {
        List<ChatMessage> history = chatRepository.findRecentMessages(user.getOficinaId(), sessionId, PageRequest.of(0, 20));
        Collections.reverse(history);

        List<Map<String, Object>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", systemPrompt));

        for (ChatMessage msg : history) {
            if (!msg.getContent().equals(userMessage)) {
                messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", userMessage));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        for (int rodada = 0; rodada <= MAX_RODADAS_FERRAMENTAS; rodada++) {
            Map<String, Object> body = new HashMap<>();
            body.put("model", model);
            body.put("messages", messages);
            body.put("max_tokens", 1500);
            body.put("temperature", 0.3);
            if (rodada < MAX_RODADAS_FERRAMENTAS) {
                body.put("tools", toolsService.definicoes());
            }

            ResponseEntity<Map> response = restTemplate.exchange(
                    chatCompletionsUrl, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);

            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) break;
            List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
            if (choices == null || choices.isEmpty()) break;
            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            if (message == null) break;

            List<Map<String, Object>> toolCalls = (List<Map<String, Object>>) message.get("tool_calls");
            if (toolCalls != null && !toolCalls.isEmpty()) {
                Map<String, Object> assistantMsg = new HashMap<>();
                assistantMsg.put("role", "assistant");
                assistantMsg.put("content", message.get("content") == null ? "" : message.get("content"));
                assistantMsg.put("tool_calls", toolCalls);
                messages.add(assistantMsg);

                for (Map<String, Object> call : toolCalls) {
                    Map<String, Object> fn = (Map<String, Object>) call.get("function");
                    String nome = String.valueOf(fn.get("name"));
                    String args = fn.get("arguments") == null ? "{}" : String.valueOf(fn.get("arguments"));
                    String resultado = toolsService.executar(nome, args, user, admin);
                    Map<String, Object> toolMsg = new HashMap<>();
                    toolMsg.put("role", "tool");
                    toolMsg.put("tool_call_id", call.get("id") == null ? nome : call.get("id"));
                    toolMsg.put("name", nome);
                    toolMsg.put("content", resultado);
                    messages.add(toolMsg);
                }
                continue;
            }

            Object content = message.get("content");
            if (content instanceof String text && !text.isBlank()) {
                return text;
            }
            break;
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
