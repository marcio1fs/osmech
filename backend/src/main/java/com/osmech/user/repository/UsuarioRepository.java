package com.osmech.user.repository;

import com.osmech.user.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repositório para operações de persistência de Usuário.
 */
@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<Usuario> findByVerificationToken(String verificationToken);

    Optional<Usuario> findByResetPasswordToken(String resetPasswordToken);

    /** Todos os usuários vinculados a uma oficina (tenant) */
    java.util.List<Usuario> findAllByOficinaId(Long oficinaId);

    /** Usuário por id, garantindo escopo da oficina */
    Optional<Usuario> findByIdAndOficinaId(Long id, Long oficinaId);

    /** Quantidade de usuários ativos da oficina */
    long countByOficinaIdAndAtivoTrue(Long oficinaId);
}
