package com.osmech.equipe.repository;

import com.osmech.equipe.entity.ConviteEquipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositório de convites de equipe.
 */
@Repository
public interface ConviteEquipeRepository extends JpaRepository<ConviteEquipe, Long> {

    Optional<ConviteEquipe> findByToken(String token);

    List<ConviteEquipe> findByOficinaIdAndStatusOrderByCriadoEmDesc(Long oficinaId, String status);

    long countByOficinaIdAndStatus(Long oficinaId, String status);

    boolean existsByOficinaIdAndEmailAndStatus(Long oficinaId, String email, String status);

    /** Busca convite da oficina por id (garante escopo do tenant) */
    Optional<ConviteEquipe> findByIdAndOficinaId(Long id, Long oficinaId);
}
