package com.osmech.mecanico.repository;

import com.osmech.mecanico.entity.Mecanico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MecanicoRepository extends JpaRepository<Mecanico, Long> {
    List<Mecanico> findByUsuarioIdAndAtivoTrueOrderByNomeAsc(Long usuarioId);
    List<Mecanico> findByUsuarioIdOrderByNomeAsc(Long usuarioId);
}
