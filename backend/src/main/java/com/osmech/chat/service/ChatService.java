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
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.*;
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

    @Value("${ai.openai.model:gpt-4o-mini}")
    private String model;

    // ── System Prompt completo ──────────────────────────────────────────
    private static final String SYSTEM_PROMPT = """
            Você é a **IA Oficial do OSMECH** — assistente inteligente especializado em oficinas mecânicas.

            ## Seus papéis:
            - 🔧 Consultor técnico automotivo
            - 📋 Assistente administrativo de oficina
            - 💰 Apoio financeiro básico
            - 📦 Apoio em controle de estoque
            - 📲 Suporte ao dono da oficina e atendentes

            ## Contexto do sistema OSMECH:
            O sistema é usado por oficinas mecânicas, centros automotivos e mecânicos autônomos.
            O usuário pode ser dono da oficina, funcionário ou atendente.
            O sistema possui: Ordens de Serviço (OS), Controle de Estoque, Financeiro, Planos de Assinatura.

            ## Suas capacidades:

            ### 🔧 Técnico Mecânico
            - Explicar defeitos comuns de veículos
            - Sugerir diagnósticos prováveis
            - Informar causas prováveis de problemas
            - Sugerir manutenção preventiva
            - Recomendar procedimentos de reparo

            ### 🧾 Ordens de Serviço
            - Explicar status de OS (orçamento, em andamento, concluída)
            - Ajudar a preencher OS corretamente
            - Sugerir serviços relacionados
            - Explicar valores e etapas dos serviços

            ### 📦 Estoque
            - Informar impacto da OS no estoque
            - Alertar sobre estoque baixo ou zerado
            - Sugerir reposição de peças
            - Ajudar na organização do estoque por categorias

            ### 💰 Financeiro
            - Explicar fluxo de caixa
            - Informar sobre valores pendentes
            - Ajudar a entender relatórios financeiros
            - Orientar sobre precificação de serviços

            ## Regras de comportamento:
            1. Sempre responda de forma clara, objetiva e prática
            2. Use linguagem simples (nível técnico de mecânico)
            3. Nunca invente dados — se não tiver informação, pergunte
            4. Quando algo depender do plano, informe educadamente
            5. Nunca execute ações sem confirmação do usuário
            6. Seja educado, profissional e prestativo
            7. Responda SEMPRE em Português do Brasil
            8. Use formatação com marcadores e emojis para organizar respostas
            9. Mantenha respostas concisas mas completas

            ## O que NUNCA fazer:
            ❌ Dar diagnóstico definitivo (sempre sugira verificação profissional)
            ❌ Substituir um mecânico — você auxilia, não decide
            ❌ Inventar preços ou valores
            ❌ Acessar dados que não foram informados
            ❌ Prometer resultados mecânicos
            ❌ Responder sobre temas fora do contexto automotivo/oficina
            """;

    // ── Enviar mensagem ─────────────────────────────────────────────────
    @Transactional
    public ChatResponse enviarMensagem(ChatRequest request, Authentication auth) {
        Usuario user = getUsuario(auth);

        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = UUID.randomUUID().toString().substring(0, 8);
        }

        // Salvar mensagem do usuário
        ChatMessage userMsg = ChatMessage.builder()
                .usuarioId(user.getId())
                .sessionId(sessionId)
                .role("user")
                .content(request.getMessage())
                .build();
        chatRepository.save(userMsg);

        // Gerar resposta da IA
        String aiResponse = gerarResposta(user.getId(), sessionId, request.getMessage());

        // Salvar resposta da IA
        ChatMessage aiMsg = ChatMessage.builder()
                .usuarioId(user.getId())
                .sessionId(sessionId)
                .role("assistant")
                .content(aiResponse)
                .build();
        chatRepository.save(aiMsg);

        return ChatResponse.fromEntity(aiMsg);
    }

    // ── Buscar histórico ────────────────────────────────────────────────
    @Transactional(readOnly = true)
    public List<ChatResponse> getHistoricoSessao(String sessionId, Authentication auth) {
        Usuario user = getUsuario(auth);
        return chatRepository.findByUsuarioIdAndSessionIdOrderByCriadoEmAsc(user.getId(), sessionId)
                .stream()
                .map(ChatResponse::fromEntity)
                .collect(Collectors.toList());
    }

    // ── Listar sessões ──────────────────────────────────────────────────
    @Transactional(readOnly = true)
    public List<String> getSessoes(Authentication auth) {
        Usuario user = getUsuario(auth);
        return chatRepository.findSessionsByUsuarioId(user.getId());
    }

    // ── Deletar sessão ──────────────────────────────────────────────────
    @Transactional
    public void deletarSessao(String sessionId, Authentication auth) {
        Usuario user = getUsuario(auth);
        chatRepository.deleteByUsuarioIdAndSessionId(user.getId(), sessionId);
    }

    // ── Gerar resposta ──────────────────────────────────────────────────
    private String gerarResposta(Long usuarioId, String sessionId, String userMessage) {
        if (!aiEnabled || apiKey == null || apiKey.isBlank()) {
            return gerarRespostaLocal(userMessage);
        }

        try {
            return chamarOpenAI(usuarioId, sessionId, userMessage);
        } catch (Exception e) {
            log.error("Erro ao chamar OpenAI: {}", e.getMessage());
            return gerarRespostaLocal(userMessage);
        }
    }

    // ── Chamar OpenAI API ────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    private String chamarOpenAI(Long usuarioId, String sessionId, String userMessage) {
        // Montar histórico de contexto
        List<ChatMessage> history = chatRepository.findRecentMessages(usuarioId, sessionId, PageRequest.of(0, 20));
        Collections.reverse(history); // Mais antigo primeiro

        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));

        for (ChatMessage msg : history) {
            if (!msg.getContent().equals(userMessage)) { // Evitar duplicar a última
                messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", userMessage));

        // Requisição para OpenAI
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
                "https://api.openai.com/v1/chat/completions",
                HttpMethod.POST,
                entity,
                Map.class
        );

        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
            if (choices != null && !choices.isEmpty()) {
                Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                return (String) message.get("content");
            }
        }

        return gerarRespostaLocal(userMessage);
    }

    // ── Resposta local (sem API key) ────────────────────────────────────
    private String gerarRespostaLocal(String msg) {
        String lower = msg.toLowerCase().trim();

        // Saudações
        if (lower.matches(".*(oi|olá|ola|bom dia|boa tarde|boa noite|eai|e ai|hey|hello).*")) {
            return "👋 Olá! Sou a **IA do OSMECH**, seu assistente de oficina mecânica.\n\n"
                    + "Posso ajudar com:\n"
                    + "🔧 **Dúvidas técnicas** sobre veículos\n"
                    + "📋 **Ordens de Serviço** — como preencher, status, etc\n"
                    + "📦 **Estoque** — consultas e gestão de peças\n"
                    + "💰 **Financeiro** — fluxo de caixa, pagamentos\n\n"
                    + "Como posso ajudar você hoje?";
        }

        // OS - Ordem de Serviço
        if (lower.matches(".*(ordem de servi[cç]o|os |criar os|abrir os|status os|fechar os).*")) {
            return "📋 **Ordens de Serviço**\n\n"
                    + "No OSMECH você pode:\n"
                    + "• **Criar OS** — menu \"Nova OS\" na sidebar\n"
                    + "• **Consultar** — menu \"Ordens de Serviço\"\n"
                    + "• **Status**: Orçamento → Em andamento → Concluída\n\n"
                    + "💡 **Dica**: Preencha sempre o modelo do veículo e a descrição detalhada do problema para facilitar o diagnóstico.\n\n"
                    + "O que gostaria de saber sobre OS?";
        }

        // Estoque
        if (lower.matches(".*(estoque|peça|peca|pe[cç]a|falt|reposi[cç]).*")) {
            return "📦 **Controle de Estoque**\n\n"
                    + "O módulo de estoque permite:\n"
                    + "• **Cadastrar peças** com código, categoria e preços\n"
                    + "• **Registrar entrada/saída** de peças\n"
                    + "• **Alertas automáticos** quando o estoque atinge o mínimo\n"
                    + "• **Categorias**: Motor, Suspensão, Freios, Elétrica, etc.\n\n"
                    + "💡 **Dica**: Mantenha o estoque mínimo configurado para cada peça para evitar falta.\n\n"
                    + "Acesse pelo menu **Estoque** na sidebar.";
        }

        // Financeiro
        if (lower.matches(".*(financ|pagamento|pagar|receita|despesa|fluxo|caixa|dinheiro|cobr).*")) {
            return "💰 **Módulo Financeiro**\n\n"
                    + "O OSMECH oferece:\n"
                    + "• **Dashboard financeiro** com visão geral\n"
                    + "• **Lançamentos** de receitas e despesas\n"
                    + "• **Categorias** personalizadas\n"
                    + "• **Fluxo de caixa** por período\n"
                    + "• **Histórico** completo de transações\n\n"
                    + "💡 **Dica**: Registre todas as entradas e saídas para ter uma visão precisa da saúde financeira da oficina.\n\n"
                    + "Acesse pelo menu **Financeiro** na sidebar.";
        }

        // Diagnóstico motor
        if (lower.matches(".*(motor|aquec|superaquec|ferveu|fumac|fumaça|barulho motor|batendo).*")) {
            return "🔧 **Possíveis causas (motor)**\n\n"
                    + "Alguns diagnósticos comuns:\n\n"
                    + "🌡️ **Superaquecimento**: Verificar radiador, bomba d'água, termostato, ventoinhas e nível do líquido de arrefecimento.\n\n"
                    + "💨 **Fumaça branca**: Possível junta do cabeçote queimada ou trinca no bloco.\n\n"
                    + "💨 **Fumaça preta**: Mistura rica — verificar injeção, filtro de ar, sensor MAP/MAF.\n\n"
                    + "💨 **Fumaça azul**: Queima de óleo — anéis de segmento, retentores de válvula.\n\n"
                    + "🔊 **Barulho**: Pode ser tensor, correia, biela ou tuchos hidráulicos.\n\n"
                    + "⚠️ *Lembre-se: isso é uma orientação. Sempre faça a verificação presencial antes de confirmar o diagnóstico.*";
        }

        // Freios
        if (lower.matches(".*(freio|frear|frenagem|pastilha|disco|pedal duro|pedal mole).*")) {
            return "🔧 **Sistema de Freios**\n\n"
                    + "Problemas comuns:\n\n"
                    + "📌 **Pedal mole/afundando**: Possível ar no sistema, vazamento de fluido ou cilindro mestre com defeito.\n\n"
                    + "📌 **Pedal duro**: Verificar servo-freio (hidrovácuo), mangueira de vácuo.\n\n"
                    + "📌 **Vibração ao frear**: Disco empenado — precisa retificar ou trocar.\n\n"
                    + "📌 **Ruído ao frear**: Pastilha gasta, verificar espessura mínima (geralmente 2-3mm).\n\n"
                    + "📌 **Puxando para um lado**: Pinça travada, flexível obstruído ou pastilha irregular.\n\n"
                    + "⚠️ *Freios são item de segurança! Sempre priorize o reparo.*";
        }

        // Suspensão
        if (lower.matches(".*(suspens|amortec|balan[cç]|alinhamento|barulho roda|estalo|batendo).*")) {
            return "🔧 **Suspensão e Direção**\n\n"
                    + "Problemas mais comuns:\n\n"
                    + "📌 **Barulho ao passar em buracos**: Verificar amortecedores, batentes, buchas, bieletas.\n\n"
                    + "📌 **Estalo ao virar volante**: Junta homocinética (coifa rasgada).\n\n"
                    + "📌 **Volante tremendo**: Rodas desbalanceadas, pneu deformado ou terminal de direção.\n\n"
                    + "📌 **Carro puxando**: Desalinhamento, pneu com pressão desigual ou problema na suspensão.\n\n"
                    + "📌 **Desgaste irregular do pneu**: Alinhamento/Cambagem fora de especificação.\n\n"
                    + "💡 *Recomendação: Alinhamento e balanceamento a cada 10.000 km ou ao trocar pneus.*";
        }

        // Elétrica
        if (lower.matches(".*(el[eé]tric|bateria|alternador|motor partida|n[aã]o liga|n[aã]o pega|luz|farol|fusível).*")) {
            return "🔧 **Sistema Elétrico**\n\n"
                    + "Problemas comuns:\n\n"
                    + "🔋 **Não liga/não pega**: Verificar bateria (carga e terminais), motor de partida, relê e fusíveis.\n\n"
                    + "💡 **Luzes falhando**: Verificar fusíveis, relês, aterramento e chicote elétrico.\n\n"
                    + "⚡ **Bateria descarregando**: Possível consumo parasita, alternador fraco ou bateria velha (vida útil ~3-4 anos).\n\n"
                    + "🔌 **Falhas intermitentes**: Mau contato, oxidação em terminais, aterramento ruim.\n\n"
                    + "💡 *Dica: Teste a bateria com multímetro — deve marcar entre 12.4V e 12.7V com motor desligado, e 13.5V-14.5V com motor ligado.*";
        }

        // Planos
        if (lower.matches(".*(plano|assinatura|pro|premium|upgrade|recurso bloqueado).*")) {
            return "⭐ **Planos OSMECH**\n\n"
                    + "O sistema possui diferentes planos:\n"
                    + "• **Básico** — Funcionalidades essenciais\n"
                    + "• **PRO** — Módulos avançados (Financeiro, Estoque)\n"
                    + "• **PRO+** — Tudo + WhatsApp + IA ilimitada\n\n"
                    + "Acesse **Planos** na sidebar para ver detalhes e fazer upgrade.\n\n"
                    + "Alguma dúvida sobre os planos?";
        }

        // Ajuda geral
        if (lower.matches(".*(ajuda|help|como funciona|o que voc[eê]|comandos|funcionalidade).*")) {
            return "🤖 **Como posso ajudar?**\n\n"
                    + "Sou a IA do OSMECH e posso auxiliar com:\n\n"
                    + "🔧 **Dúvidas técnicas** — Me pergunte sobre qualquer sistema do veículo\n"
                    + "📋 **Ordens de serviço** — Como criar, gerenciar e acompanhar\n"
                    + "📦 **Estoque** — Gestão de peças e alertas\n"
                    + "💰 **Financeiro** — Fluxo de caixa e relatórios\n"
                    + "⭐ **Planos** — Informações sobre assinaturas\n\n"
                    + "💡 Basta digitar sua dúvida que eu faço o melhor para ajudar!";
        }

        // Resposta padrão
        return "🤖 Entendi sua pergunta!\n\n"
                + "Sou a IA do OSMECH especializada em oficinas mecânicas. "
                + "Posso ajudar com:\n\n"
                + "🔧 Diagnósticos técnicos de veículos\n"
                + "📋 Ordens de Serviço\n"
                + "📦 Estoque de peças\n"
                + "💰 Questões financeiras\n\n"
                + "Para respostas mais inteligentes e personalizadas, peça ao administrador para configurar a **chave da API OpenAI** nas configurações do sistema.\n\n"
                + "Como posso ajudar?";
    }

    // ── Helpers ──────────────────────────────────────────────────────────
    private Usuario getUsuario(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }
}
