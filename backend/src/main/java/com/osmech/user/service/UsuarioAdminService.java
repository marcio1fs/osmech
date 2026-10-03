package com.osmech.user.service;

import com.osmech.audit.AuditService;
import com.osmech.config.ResourceNotFoundException;
import com.osmech.rbac.PermissionService;
import com.osmech.user.dto.UsuarioAdminRequest;
import com.osmech.user.dto.UsuarioAdminResponse;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Serviço para gerenciamento administrativo de usuários.
 * Inclui proteções para:
 * - Não permitir escalação de privilégio
 * - Proteger o último administrador ativo
 * - Isolar membros de oficina por owner_id
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UsuarioAdminService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final PermissionService permissionService;
    private final AuditService auditService;

    /** Roles que somente o ADMIN global pode atribuir. */
    private static final List<String> ROLES_ADMIN_EXCLUSIVAS = List.of("ADMIN");

    /** Roles válidas disponíveis no sistema. */
    private static final List<String> ROLES_VALIDAS = PermissionService.ALL_ROLES;

    // ─────────────────────────────────────────────────────────────────────────
    // LISTAGEM
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Lista todos os usuários (ADMIN global) ou apenas os membros da oficina (GERENTE/OFICINA).
     *
     * @param operadorEmail email do usuário que está realizando a consulta
     * @param operadorRole  role do operador (determina escopo da consulta)
     * @param pageable      paginação
     */
    public Page<UsuarioAdminResponse> listar(String operadorEmail, String operadorRole, Pageable pageable) {
        if ("ADMIN".equals(operadorRole)) {
            return usuarioRepository.findAllByOrderByCriadoEmDesc(pageable)
                    .map(this::toResponse);
        }

        // GERENTE/OFICINA → vê apenas os membros da sua oficina
        Usuario operador = getUsuario(operadorEmail);
        Long ownerId = operador.getOwnerId() != null ? operador.getOwnerId() : operador.getId();
        return usuarioRepository.findByOficinaMembrosPageable(ownerId, pageable)
                .map(this::toResponse);
    }

    /**
     * Retorna os detalhes de um usuário específico.
     */
    public UsuarioAdminResponse buscarPorId(Long id, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);
        return toResponse(usuario);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CRIAÇÃO
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cria um novo sub-usuário vinculado à oficina do operador.
     *
     * @param request       dados do novo usuário
     * @param operadorEmail quem está criando
     * @param operadorRole  role de quem está criando (controla quais roles pode atribuir)
     */
    @Transactional
    public UsuarioAdminResponse criar(UsuarioAdminRequest request, String operadorEmail, String operadorRole) {
        validarRolePodeSerAtribuida(request.getRole(), operadorRole);

        String email = request.getEmail().toLowerCase().trim();
        if (usuarioRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Este e-mail já está em uso.");
        }

        if (request.getSenha() == null || request.getSenha().length() < 8) {
            throw new IllegalArgumentException("Senha é obrigatória e deve ter ao menos 8 caracteres.");
        }

        // Determina o owner_id: o sub-usuário pertence à oficina do operador
        Usuario operador = getUsuario(operadorEmail);
        Long ownerId = operador.getOwnerId() != null ? operador.getOwnerId() : operador.getId();

        // ADMIN global criando usuário → sem owner_id (ou pode especificar)
        Long ownerIdFinal = "ADMIN".equals(operadorRole) ? null : ownerId;

        Usuario novo = Usuario.builder()
                .nome(request.getNome().trim())
                .email(email)
                .senha(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone() != null ? request.getTelefone() : "")
                .role(request.getRole().toUpperCase())
                .ativo(request.getAtivo() != null ? request.getAtivo() : true)
                .ownerId(ownerIdFinal)
                .build();

        usuarioRepository.save(novo);

        auditService.registrarUsuarioCriado(novo.getId(), novo.getEmail(), operadorEmail, novo.getRole());
        log.info("[UsuarioAdminService] Usuário criado: {} (role={}) por {}", novo.getEmail(), novo.getRole(), operadorEmail);

        return toResponse(novo);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EDIÇÃO
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Edita dados básicos de um usuário (nome, telefone, status).
     * Não permite edição de e-mail (seria necessária revalidação) nem role direto por este endpoint.
     */
    @Transactional
    public UsuarioAdminResponse editar(Long id, UsuarioAdminRequest request, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        if (request.getNome() != null && !request.getNome().isBlank()) {
            usuario.setNome(request.getNome().trim());
        }
        if (request.getTelefone() != null) {
            usuario.setTelefone(request.getTelefone());
        }
        // Senha opcional — só atualiza se fornecida
        if (request.getSenha() != null && !request.getSenha().isBlank()) {
            if (request.getSenha().length() < 8) {
                throw new IllegalArgumentException("Nova senha deve ter ao menos 8 caracteres.");
            }
            usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        }

        usuarioRepository.save(usuario);
        auditService.registrarUsuarioEditado(usuario.getId(), usuario.getEmail(), operadorEmail);
        return toResponse(usuario);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ALTERAÇÃO DE ROLE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Altera a role/perfil de um usuário.
     * Proibições:
     * - Operador não pode promover para role maior que a sua
     * - Não é possível remover o último ADMIN ativo
     * - Operador não pode alterar o próprio perfil (prevenção de escalação)
     */
    @Transactional
    public UsuarioAdminResponse alterarRole(Long id, String novaRole, String operadorEmail, String operadorRole) {
        if (!ROLES_VALIDAS.contains(novaRole.toUpperCase())) {
            throw new IllegalArgumentException("Role inválida: " + novaRole);
        }

        validarRolePodeSerAtribuida(novaRole, operadorRole);

        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        // Prevenção de auto-escalação: operador não pode alterar o próprio perfil
        if (usuario.getEmail().equalsIgnoreCase(operadorEmail)) {
            throw new AccessDeniedException("Você não pode alterar o seu próprio perfil.");
        }

        String roleAnterior = usuario.getRole();

        // Proteção do último ADMIN
        if ("ADMIN".equals(roleAnterior) && !"ADMIN".equals(novaRole.toUpperCase())) {
            long adminsAtivos = usuarioRepository.countByRoleAndAtivo("ADMIN", true);
            if (adminsAtivos <= 1) {
                throw new IllegalStateException("Não é possível remover o único administrador ativo do sistema.");
            }
        }

        usuario.setRole(novaRole.toUpperCase());
        usuarioRepository.save(usuario);

        auditService.registrarRoleAlterada(usuario.getId(), usuario.getEmail(), roleAnterior, novaRole, operadorEmail);
        log.info("[UsuarioAdminService] Role alterada: {} {} → {} por {}",
                usuario.getEmail(), roleAnterior, novaRole, operadorEmail);

        return toResponse(usuario);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BLOQUEIO / DESBLOQUEIO
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Bloqueia ou desbloqueia um usuário.
     * Não é possível bloquear o último ADMIN ativo.
     * Operador não pode bloquear a si mesmo.
     */
    @Transactional
    public UsuarioAdminResponse alterarStatus(Long id, boolean novoStatus, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        // Prevenção de auto-bloqueio
        if (usuario.getEmail().equalsIgnoreCase(operadorEmail)) {
            throw new AccessDeniedException("Você não pode bloquear a sua própria conta.");
        }

        // Proteção do último ADMIN ativo
        if (!novoStatus && "ADMIN".equals(usuario.getRole())) {
            long adminsAtivos = usuarioRepository.countByRoleAndAtivo("ADMIN", true);
            if (adminsAtivos <= 1) {
                throw new IllegalStateException("Não é possível bloquear o único administrador ativo do sistema.");
            }
        }

        usuario.setAtivo(novoStatus);
        usuarioRepository.save(usuario);

        String acao = novoStatus ? "DESBLOQUEADO" : "BLOQUEADO";
        auditService.registrarStatusAlterado(usuario.getId(), usuario.getEmail(), acao, operadorEmail);
        log.info("[UsuarioAdminService] Usuário {} {} por {}", usuario.getEmail(), acao, operadorEmail);

        return toResponse(usuario);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RESET DE SENHA
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Gera uma senha temporária aleatória para o usuário e a retorna ao admin.
     * O usuário deverá alterá-la no próximo login.
     */
    @Transactional
    public String resetarSenha(Long id, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        String novaSenhaTemp = UUID.randomUUID().toString().replace("-", "").substring(0, 12) + "!";
        usuario.setSenha(passwordEncoder.encode(novaSenhaTemp));
        usuarioRepository.save(usuario);

        auditService.registrar("SENHA_RESETADA", "USUARIO", usuario.getId(), operadorEmail,
                "{\"email\":\"" + usuario.getEmail() + "\"}");

        return novaSenhaTemp;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXCLUSÃO DE USUÁRIO
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Exclui um usuário da oficina.
     * Restrições:
     * - Não pode excluir a própria conta
     * - Não pode excluir o último ADMIN ativo
     * - Não pode excluir o dono da oficina se for sub-usuário
     */
    @Transactional
    public void excluir(Long id, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        // Prevenção de auto-exclusão
        if (usuario.getEmail().equalsIgnoreCase(operadorEmail)) {
            throw new AccessDeniedException("Você não pode excluir sua própria conta.");
        }

        // Proteção do último ADMIN ativo
        if ("ADMIN".equals(usuario.getRole())) {
            long adminsAtivos = usuarioRepository.countByRoleAndAtivo("ADMIN", true);
            if (adminsAtivos <= 1) {
                throw new IllegalStateException("Não é possível excluir o único administrador ativo do sistema.");
            }
        }

        // Se for um dono de oficina (owner_id == null), impede se tiver sub-usuários vinculados a não ser que seja ADMIN global
        if (usuario.getOwnerId() == null && !"ADMIN".equals(operadorRole)) {
            throw new AccessDeniedException("Não é permitido excluir o usuário principal da oficina.");
        }

        // Remove permissões customizadas antes
        permissionService.salvarPermissoesUsuario(usuario.getId(), List.of());

        usuarioRepository.delete(usuario);
        auditService.registrar("USUARIO_EXCLUIDO", "USUARIO", id, operadorEmail,
                "{\"email\":\"" + usuario.getEmail() + "\",\"nome\":\"" + usuario.getNome() + "\"}");
        log.info("[UsuarioAdminService] Usuário excluído: id={} email={} por {}", id, usuario.getEmail(), operadorEmail);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GESTÃO DE PERMISSÕES CUSTOMIZADAS POR USUÁRIO
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Retorna a lista detalhada de permissões de um usuário:
     * - permissions: todas as permissões do sistema
     * - rolePermissions: quais vêm da role do usuário
     * - customPermissions: quais foram concedidas individualmente ao usuário
     * - effectivePermissions: união das permissões ativas
     */
    public java.util.Map<String, Object> buscarPermissoesUsuario(Long id, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        List<com.osmech.rbac.Permission> todasPermissoes = permissionService.getAllPermissions();
        List<String> rolePermissions = permissionService.getPermissionsForRole(usuario.getRole());
        List<String> customPermissions = new java.util.ArrayList<>(usuario.getCustomPermissions());
        
        java.util.Set<String> combinadas = new java.util.LinkedHashSet<>(rolePermissions);
        combinadas.addAll(usuario.getCustomPermissions());
        List<String> effectivePermissions = new java.util.ArrayList<>(combinadas);

        return java.util.Map.of(
                "usuarioId", usuario.getId(),
                "nome", usuario.getNome(),
                "email", usuario.getEmail(),
                "role", usuario.getRole(),
                "todasPermissoes", todasPermissoes,
                "rolePermissions", rolePermissions,
                "customPermissions", customPermissions,
                "effectivePermissions", effectivePermissions
        );
    }

    /**
     * Atualiza as permissões específicas concedidas a um usuário.
     */
    @Transactional
    public List<String> atualizarPermissoesUsuario(Long id, List<String> permissoes, String operadorEmail, String operadorRole) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
        verificarAcessoAoUsuario(usuario, operadorEmail, operadorRole);

        java.util.Set<String> novas = new java.util.HashSet<>();
        if (permissoes != null) {
            for (String p : permissoes) {
                if (p != null && !p.isBlank()) novas.add(p.trim());
            }
        }

        usuario.setCustomPermissions(novas);
        usuarioRepository.save(usuario);

        auditService.registrar("PERMISSOES_USUARIO_ALTERADAS", "USUARIO", usuario.getId(), operadorEmail,
                "{\"email\":\"" + usuario.getEmail() + "\",\"novasPermissoes\":\"" + permissoes + "\"}");

        return permissionService.getPermissionsForUser(usuario.getId(), usuario.getRole());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS PRIVADOS
    // ─────────────────────────────────────────────────────────────────────────

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado: " + email));
    }

    /**
     * Verifica se o operador tem autoridade sobre o usuário alvo.
     * ADMIN global → acesso a todos.
     * GERENTE/OFICINA → apenas membros da sua oficina.
     */
    private void verificarAcessoAoUsuario(Usuario alvo, String operadorEmail, String operadorRole) {
        if ("ADMIN".equals(operadorRole)) return; // ADMIN global acessa tudo

        Usuario operador = getUsuario(operadorEmail);
        Long operadorOwnerId = operador.getOwnerId() != null ? operador.getOwnerId() : operador.getId();

        // O alvo deve ser o próprio operador, ou ter owner_id igual ao operador, ou ser o dono
        boolean ehMembro = operadorOwnerId.equals(alvo.getId())
                || operadorOwnerId.equals(alvo.getOwnerId());

        if (!ehMembro) {
            throw new AccessDeniedException("Acesso negado: usuário fora do escopo da sua oficina.");
        }
    }

    /**
     * Valida que o operador pode atribuir a role solicitada.
     * Apenas ADMIN pode criar/promover para roles exclusivas de ADMIN.
     */
    private void validarRolePodeSerAtribuida(String roleAlvo, String operadorRole) {
        String roleUp = roleAlvo.toUpperCase();
        if (!ROLES_VALIDAS.contains(roleUp)) {
            throw new IllegalArgumentException("Role inválida: " + roleAlvo);
        }
        if (ROLES_ADMIN_EXCLUSIVAS.contains(roleUp) && !"ADMIN".equals(operadorRole)) {
            throw new AccessDeniedException("Apenas administradores podem atribuir a role ADMIN.");
        }
    }

    private UsuarioAdminResponse toResponse(Usuario u) {
        return UsuarioAdminResponse.builder()
                .id(u.getId())
                .nome(u.getNome())
                .email(u.getEmail())
                .role(u.getRole())
                .plano(u.getPlano())
                .ativo(u.getAtivo())
                .telefone(u.getTelefone())
                .nomeOficina(u.getNomeOficina())
                .ownerId(u.getOwnerId())
                .criadoEm(u.getCriadoEm())
                .ultimoAcesso(u.getUltimoAcesso())
                .build();
    }
}
