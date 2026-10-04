package com.osmech.auditoria.repository;

import com.osmech.auditoria.entity.LogAuditoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LogAuditoriaRepository extends JpaRepository<LogAuditoria, Long> {

    /** Últimas 100 ações da oficina (trilha para o DONO/GERENTE) */
    List<LogAuditoria> findTop100ByOficinaIdOrderByIdDesc(Long oficinaId);
}
