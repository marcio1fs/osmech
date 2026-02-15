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

    // ── Enviar mensagem ────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<?> enviarMensagem(
            @Valid @RequestBody ChatRequest request,
            Authentication auth) {
        try {
            ChatResponse response = chatService.enviarMensagem(request, auth);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Histórico de uma sessão ────────────────────────────────────
    @GetMapping("/session/{sessionId}")
    public ResponseEntity<?> getHistorico(
            @PathVariable String sessionId,
            Authentication auth) {
        try {
            List<ChatResponse> historico = chatService.getHistoricoSessao(sessionId, auth);
            return ResponseEntity.ok(historico);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Listar sessões do usuário ──────────────────────────────────
    @GetMapping("/sessions")
    public ResponseEntity<?> getSessoes(Authentication auth) {
        try {
            List<String> sessoes = chatService.getSessoes(auth);
            return ResponseEntity.ok(sessoes);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Deletar sessão ─────────────────────────────────────────────
    @DeleteMapping("/session/{sessionId}")
    public ResponseEntity<?> deletarSessao(
            @PathVariable String sessionId,
            Authentication auth) {
        try {
            chatService.deletarSessao(sessionId, auth);
            return ResponseEntity.ok(Map.of("message", "Sessão removida"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
