package com.osmech.oficina.repository;

import com.osmech.oficina.entity.Oficina;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositório da entidade Oficina (tenant).
 */
@Repository
public interface OficinaRepository extends JpaRepository<Oficina, Long> {
}
