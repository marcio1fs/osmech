package com.osmech.auditoria.service;

import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.repository.LogAuditoriaRepository;
import com.osmech.user.entity.Usuario;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Trilha de auditoria de ações sensíveis (Fase 4).
 * Escreve em transação separada (REQUIRES_NEW) para que o registro
 * sobreviva a rollbacks do fluxo principal (ex.: login recusado).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuditoriaService {

    private final LogAuditoriaRepository repository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrar(Long oficinaId, Long usuarioId, String usuarioEmail,
                          String acao, String detalhes) {
        try {
            repository.save(LogAuditoria.builder()
                    .oficinaId(oficinaId)
                    .usuarioId(usuarioId)
                    .usuarioEmail(usuarioEmail)
                    .acao(acao)
                    .detalhes(detalhes == null || detalhes.length() <= 1000
                            ? detalhes : detalhes.substring(0, 1000))
                    .build());
        } catch (Exception e) {
            // Auditoria nunca derruba o fluxo principal
            log.warn("[Auditoria] Falha ao registrar {}: {}", acao, e.getMessage());
        }
    }

    public void registrar(Usuario usuario, String acao, String detalhes) {
        registrar(usuario == null ? null : usuario.getOficinaId(),
                usuario == null ? null : usuario.getId(),
                usuario == null ? null : usuario.getEmail(), acao, detalhes);
    }

    @Transactional(readOnly = true)
    public List<LogAuditoria> ultimasDaOficina(Long oficinaId) {
        return repository.findTop100ByOficinaIdOrderByIdDesc(oficinaId);
    }
}
