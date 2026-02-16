package com.osmech.plan.repository;

import com.osmech.plan.entity.Plano;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositório para operações de persistência de Plano.
 */
@Repository
public interface PlanoRepository extends JpaRepository<Plano, Long> {

    Optional<Plano> findByCodigo(String codigo);

    List<Plano> findByAtivoTrue();
}
