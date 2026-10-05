package com.osmech.user.repository;

import com.osmech.user.entity.Usuario;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
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

    /**
     * Listagem administrativa paginada com busca opcional por nome/e-mail/oficina.
     * Restrita a donos/titulares de oficinas e administradores da plataforma.
     * Colaboradores internos (mecânicos, atendentes, etc.) cadastrados pelas oficinas
     * são de gestão estritamente interna de cada oficina e não aparecem para o admin da plataforma.
     */
    @Query("SELECT u FROM Usuario u WHERE (u.ownerId IS NULL OR u.role IN ('ADMIN', 'DONO', 'OFICINA')) "
            + "AND (:termo IS NULL OR :termo = '' "
            + "OR LOWER(u.nome) LIKE LOWER(CONCAT('%', :termo, '%')) "
            + "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :termo, '%')) "
            + "OR LOWER(u.nomeOficina) LIKE LOWER(CONCAT('%', :termo, '%')))")
    Page<Usuario> buscarAdmin(@Param("termo") String termo, Pageable pageable);

    /** Conta usuários por role (para proteção do último admin). */
    long countByRole(String role);

    /** Conta admins ativos. */
    long countByRoleAndAtivo(String role, Boolean ativo);

    /**
     * Lista todos os sub-usuários de uma oficina (owner_id = ownerId)
     * mais o próprio dono (id = ownerId).
     */
    @Query("SELECT u FROM Usuario u WHERE u.ownerId = :ownerId OR u.id = :ownerId ORDER BY u.criadoEm ASC")
    List<Usuario> findByOficinaMembros(@Param("ownerId") Long ownerId);

    /** Busca paginada de todos os usuários (para ADMIN global). */
    Page<Usuario> findAllByOrderByCriadoEmDesc(Pageable pageable);

    /** Busca paginada dos usuários de uma oficina (isolamento multi-tenant). */
    Page<Usuario> findByOficinaIdOrderByCriadoEmDesc(Long oficinaId, Pageable pageable);

    /** Busca paginada dos membros de uma oficina específica. */
    @Query("SELECT u FROM Usuario u WHERE u.ownerId = :ownerId OR u.id = :ownerId ORDER BY u.criadoEm DESC")
    Page<Usuario> findByOficinaMembrosPageable(@Param("ownerId") Long ownerId, Pageable pageable);

    /** Verifica se um e-mail pertence a um membro de uma oficina específica. */
    @Query("SELECT COUNT(u) > 0 FROM Usuario u WHERE u.email = :email AND (u.ownerId = :ownerId OR u.id = :ownerId)")
    boolean existsByEmailAndOficina(@Param("email") String email, @Param("ownerId") Long ownerId);
}
