package com.osmech.sessao.repository;

import com.osmech.sessao.entity.SessaoUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SessaoUsuarioRepository extends JpaRepository<SessaoUsuario, Long> {

    Optional<SessaoUsuario> findByRefreshTokenHash(String refreshTokenHash);

    List<SessaoUsuario> findByUsuarioIdAndRevogadoEmIsNull(Long usuarioId);
}
