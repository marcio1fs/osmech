package com.osmech.oficina.repository;

import com.osmech.oficina.entity.Oficina;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.Optional;

/**
 * Repositório da entidade Oficina (tenant).
 */
@Repository
public interface OficinaRepository extends JpaRepository<Oficina, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM Oficina o WHERE o.id = :id")
    Optional<Oficina> findByIdForUpdate(@Param("id") Long id);
}
