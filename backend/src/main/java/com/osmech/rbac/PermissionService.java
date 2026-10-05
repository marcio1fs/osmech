package com.osmech.rbac;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Serviço de permissões RBAC.
 * Carrega as permissões de cada role do banco e as mantém em cache em memória.
 * O cache é recarregado automaticamente ao inicializar o contexto Spring.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PermissionService {

    private final PermissionRepository permissionRepository;

    /** Cache em memória: role → lista de permission codes */
    private final Map<String, List<String>> permissionsCache = new ConcurrentHashMap<>();

    /** Roles suportadas pelo sistema. */
    public static final List<String> ALL_ROLES = List.of(
        "ADMIN", "DONO", "GERENTE", "OFICINA", "VENDEDOR", "ATENDENTE", "MECANICO", "ESTOQUISTA", "FINANCEIRO"
    );

    /**
     * Carrega o cache de permissões ao iniciar a aplicação.
     * Se o banco ainda não tiver dados (primeira execução), retorna lista vazia por role.
     */
    @PostConstruct
    public void carregarCache() {
        for (String role : ALL_ROLES) {
            try {
                List<String> perms = permissionRepository.findPermissionCodesByRole(role);
                if (perms == null) {
                    perms = List.of();
                }
                permissionsCache.put(role, Collections.unmodifiableList(perms));
                log.debug("[PermissionService] Role {} → {} permissões carregadas", role, perms.size());
            } catch (Exception e) {
                permissionsCache.put(role, List.of());
                log.warn("[PermissionService] Role {} sem permissões disponíveis no banco ou ainda não inicializada: {}", role, e.getMessage());
            }
        }
        log.info("[PermissionService] Cache de permissões inicializado com {} roles.", ALL_ROLES.size());
    }

    /**
     * Retorna a lista de permission codes para a role informada.
     * Sempre consulta o cache (eficiente para ser chamado a cada login).
     *
     * @param role Nome da role (ex: "ADMIN", "DONO", "ATENDENTE")
     * @return Lista imutável de códigos de permissão
     */
    public List<String> getPermissionsForRole(String role) {
        if (role == null) return List.of();
        String roleUpper = role.toUpperCase();
        List<String> perms = permissionsCache.getOrDefault(roleUpper, List.of());
        
        // Fallback e compatibilidade: DONO e OFICINA (legado) possuem o mesmo conjunto de permissões
        if (perms.isEmpty()) {
            if ("DONO".equals(roleUpper)) {
                return permissionsCache.getOrDefault("OFICINA", List.of());
            } else if ("OFICINA".equals(roleUpper)) {
                return permissionsCache.getOrDefault("DONO", List.of());
            }
        }
        return perms;
    }

    /**
     * Retorna a lista combinada de permissões para um usuário específico:
     * permissões da sua role + permissões individuais adicionais concedidas.
     */
    public List<String> getPermissionsForUser(Long usuarioId, String role) {
        List<String> rolePerms = getPermissionsForRole(role);
        if (usuarioId == null) return rolePerms;

        try {
            List<String> userCustomPerms = permissionRepository.findPermissionCodesByUsuarioId(usuarioId);
            if (userCustomPerms == null || userCustomPerms.isEmpty()) {
                return rolePerms;
            }
            java.util.Set<String> combined = new java.util.LinkedHashSet<>(rolePerms);
            combined.addAll(userCustomPerms);
            return List.copyOf(combined);
        } catch (Exception e) {
            log.debug("[PermissionService] Tabela de permissões customizadas ainda não existe ou vazia para usuário {}: {}", usuarioId, e.getMessage());
            return rolePerms;
        }
    }

    /**
     * Retorna a lista combinada de permissões diretamente a partir da entidade Usuario.
     */
    public List<String> getPermissionsForUser(com.osmech.user.entity.Usuario usuario) {
        if (usuario == null) return List.of();
        List<String> rolePerms = getPermissionsForRole(usuario.getRole());
        if (usuario.getCustomPermissions() == null || usuario.getCustomPermissions().isEmpty()) {
            return rolePerms;
        }
        java.util.Set<String> combined = new java.util.LinkedHashSet<>(rolePerms);
        combined.addAll(usuario.getCustomPermissions());
        return List.copyOf(combined);
    }

    /**
     * Retorna apenas as permissões customizadas (específicas) concedidas ao usuário.
     */
    public List<String> getCustomPermissionsForUser(Long usuarioId) {
        if (usuarioId == null) return List.of();
        try {
            return permissionRepository.findPermissionCodesByUsuarioId(usuarioId);
        } catch (Exception e) {
            log.warn("[PermissionService] Erro ao buscar permissões do usuário {}: {}", usuarioId, e.getMessage());
            return List.of();
        }
    }

    /**
     * Retorna a lista completa de permissões do sistema com metadados (código, descrição, módulo).
     */
    public List<Permission> getAllPermissions() {
        return permissionRepository.findAllOrderByModuloAndCode();
    }

    /**
     * Atualiza as permissões específicas/customizadas de um usuário.
     */
    @org.springframework.transaction.annotation.Transactional
    public void salvarPermissoesUsuario(Long usuarioId, List<String> permissions) {
        if (usuarioId == null) return;
        permissionRepository.deleteAllByUsuarioId(usuarioId);
        if (permissions != null && !permissions.isEmpty()) {
            for (String perm : permissions) {
                if (perm != null && !perm.isBlank()) {
                    permissionRepository.insertUsuarioPermission(usuarioId, perm.trim());
                }
            }
        }
        log.info("[PermissionService] Permissões atualizadas para o usuário {}: {}", usuarioId, permissions);
    }

    /**
     * Invalida e recarrega o cache de permissões.
     * Deve ser chamado quando as permissões de uma role são alteradas pelo administrador.
     */
    public void invalidarCache() {
        permissionsCache.clear();
        carregarCache();
        log.info("[PermissionService] Cache de permissões invalidado e recarregado.");
    }

    /**
     * Retorna todos os módulos e permissões disponíveis por role (para a tela de admin).
     */
    public Map<String, List<String>> getAllRolesWithPermissions() {
        return Collections.unmodifiableMap(permissionsCache);
    }
}
