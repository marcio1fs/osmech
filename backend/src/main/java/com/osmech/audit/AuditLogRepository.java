package com.osmech.audit;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    
    Optional<AuditLog> findByAuditId(String auditId);
    
    List<AuditLog> findByUsuarioEmailOrderByCriadoEmDesc(String usuarioEmail);
    
    List<AuditLog> findByEntidadeAndEntidadeIdOrderByCriadoEmDesc(String entidade, Long entidadeId);
    
    List<AuditLog> findTop100ByOrderByCriadoEmDesc();
}
