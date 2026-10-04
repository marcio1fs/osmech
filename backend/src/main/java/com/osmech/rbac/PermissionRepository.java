package com.osmech.rbac;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositório para permissões granulares do sistema.
 */
@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {

    /**
     * Retorna os códigos de permissão de uma determinada role,
     * consultando a tabela role_permissions via query nativa.
     */
    @Query(value = "SELECT rp.permission_code FROM role_permissions rp WHERE rp.role = :role", nativeQuery = true)
    List<String> findPermissionCodesByRole(@Param("role") String role);

    /**
     * Retorna os códigos de permissão específicos atribuídos a um usuário.
     */
    @Query(value = "SELECT up.permission_code FROM usuario_permissions up WHERE up.usuario_id = :usuarioId", nativeQuery = true)
    List<String> findPermissionCodesByUsuarioId(@Param("usuarioId") Long usuarioId);

    /**
     * Retorna todas as permissões cadastradas ordenadas por módulo e código.
     */
    @Query("SELECT p FROM Permission p ORDER BY p.modulo, p.code")
    List<Permission> findAllOrderByModuloAndCode();

    /**
     * Remove todas as permissões customizadas de um usuário.
     */
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query(value = "DELETE FROM usuario_permissions WHERE usuario_id = :usuarioId", nativeQuery = true)
    void deleteAllByUsuarioId(@Param("usuarioId") Long usuarioId);

    /**
     * Insere uma permissão individual para um usuário.
     */
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query(value = "INSERT INTO usuario_permissions (usuario_id, permission_code) VALUES (:usuarioId, :code) ON CONFLICT DO NOTHING", nativeQuery = true)
    void insertUsuarioPermission(@Param("usuarioId") Long usuarioId, @Param("code") String code);
}
