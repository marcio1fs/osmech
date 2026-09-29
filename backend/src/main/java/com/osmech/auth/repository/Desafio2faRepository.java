package com.osmech.auth.repository;

import com.osmech.auth.entity.Desafio2fa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface Desafio2faRepository extends JpaRepository<Desafio2fa, Long> {

    List<Desafio2fa> findByUsuarioId(Long usuarioId);

    void deleteByUsuarioId(Long usuarioId);
}
