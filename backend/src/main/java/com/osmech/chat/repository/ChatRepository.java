package com.osmech.chat.repository;

import com.osmech.chat.entity.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ChatRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findByUsuarioIdAndSessionIdOrderByCriadoEmAsc(Long usuarioId, String sessionId);

    @Query("SELECT DISTINCT c.sessionId FROM ChatMessage c WHERE c.usuarioId = :usuarioId ORDER BY c.sessionId DESC")
    List<String> findSessionsByUsuarioId(Long usuarioId);

    @Query("SELECT c FROM ChatMessage c WHERE c.usuarioId = :usuarioId AND c.sessionId = :sessionId ORDER BY c.criadoEm DESC")
    List<ChatMessage> findRecentMessages(Long usuarioId, String sessionId, Pageable pageable);

    void deleteByUsuarioIdAndSessionId(Long usuarioId, String sessionId);
}
