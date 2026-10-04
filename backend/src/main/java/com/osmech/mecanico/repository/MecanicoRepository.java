package com.osmech.mecanico.repository;

import com.osmech.mecanico.entity.Mecanico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MecanicoRepository extends JpaRepository<Mecanico, Long> {
    List<Mecanico> findByUsuarioIdAndAtivoTrueOrderByNomeAsc(Long usuarioId);
    List<Mecanico> findByUsuarioIdOrderByNomeAsc(Long usuarioId);

    /** Ficha de mecânico vinculada à conta de usuário informada (módulo Equipe). */
    Optional<Mecanico> findByUsuarioContaId(Long usuarioContaId);

    /** Ficha sem vínculo, na mesma oficina e com o mesmo nome (match no aceite do convite). */
    Optional<Mecanico> findFirstByUsuarioIdAndNomeIgnoreCaseAndUsuarioContaIdIsNull(Long usuarioId, String nome);
}
