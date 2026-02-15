package com.osmech.chat.dto;

import com.osmech.chat.entity.ChatMessage;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class ChatResponse {

    private Long id;
    private String sessionId;
    private String role;
    private String content;
    private LocalDateTime criadoEm;

    public static ChatResponse fromEntity(ChatMessage m) {
        return ChatResponse.builder()
                .id(m.getId())
                .sessionId(m.getSessionId())
                .role(m.getRole())
                .content(m.getContent())
                .criadoEm(m.getCriadoEm())
                .build();
    }
}
