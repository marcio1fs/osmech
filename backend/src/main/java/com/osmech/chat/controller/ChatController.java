package com.osmech.chat.controller;

import com.osmech.chat.dto.ChatRequest;
import com.osmech.chat.dto.ChatResponse;
import com.osmech.chat.service.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    /** POST /api/chat - Enviar mensagem */
    @PostMapping
    public ResponseEntity<ChatResponse> enviarMensagem(@Valid @RequestBody ChatRequest request,
                                                         Authentication auth) {
        return ResponseEntity.ok(chatService.enviarMensagem(request, auth));
    }

    /** GET /api/chat/session/{sessionId} - Histórico de uma sessão */
    @GetMapping("/session/{sessionId}")
    public ResponseEntity<List<ChatResponse>> getHistorico(@PathVariable String sessionId,
                                                             Authentication auth) {
        return ResponseEntity.ok(chatService.getHistoricoSessao(sessionId, auth));
    }

    /** GET /api/chat/sessions - Listar sessões do usuário */
    @GetMapping("/sessions")
    public ResponseEntity<List<String>> getSessoes(Authentication auth) {
        return ResponseEntity.ok(chatService.getSessoes(auth));
    }

    /** DELETE /api/chat/session/{sessionId} - Deletar sessão */
    @DeleteMapping("/session/{sessionId}")
    public ResponseEntity<Map<String, String>> deletarSessao(@PathVariable String sessionId,
                                                               Authentication auth) {
        chatService.deletarSessao(sessionId, auth);
        return ResponseEntity.ok(Map.of("message", "Sessão removida"));
    }
}
