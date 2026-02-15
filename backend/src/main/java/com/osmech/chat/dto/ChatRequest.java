package com.osmech.chat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class ChatRequest {

    @NotBlank(message = "A mensagem é obrigatória")
    private String message;

    private String sessionId; // Se null, cria nova sessão
}
