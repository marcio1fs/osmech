package com.osmech.security;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Helper para resolver o "usuário de dados" de um request autenticado.
 *
 * No modelo multi-tenant do OSMECH:
 * - Donos de oficina (role OFICINA/GERENTE/ADMIN) possuem owner_id = null.
 *   Seus dados estão registrados com usuario_id = seu próprio id.
 * - Sub-usuários (ATENDENTE, MECANICO, ESTOQUISTA, FINANCEIRO) possuem owner_id apontando
 *   para o dono da oficina. Para consultas de dados operacionais, deve-se usar o owner_id.
 *
 * Uso nos services:
 *   Long dataId = securityContextHelper.getDataOwnerId(auth.getName());
 *   repository.findByUsuarioId(dataId, pageable);
 */
@Component
@RequiredArgsConstructor
public class SecurityContextHelper {

    private final UsuarioRepository usuarioRepository;

    /**
     * Retorna o ID a ser usado para filtrar dados operacionais (OS, estoque, financeiro...).
     *
     * - Se o usuário for dono (owner_id = null): retorna o seu próprio ID
     * - Se o usuário for sub-usuário (owner_id != null): retorna o ID do dono da oficina
     *
     * @param email E-mail do usuário autenticado (auth.getName())
     * @return ID do usuário de dados (owner ou próprio)
     */
    public Long getDataOwnerId(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado: " + email));
        return usuario.getOwnerId() != null ? usuario.getOwnerId() : usuario.getId();
    }

    /**
     * Retorna o usuário completo a partir do email autenticado.
     *
     * @param email E-mail do usuário autenticado
     * @return Entidade Usuario
     */
    public Usuario getUsuarioAutenticado(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado: " + email));
    }

    /**
     * Verifica se o usuário autenticado é sub-usuário de uma oficina.
     *
     * @param email E-mail do usuário autenticado
     * @return true se for sub-usuário (owner_id != null)
     */
    public boolean isSubUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .map(u -> u.getOwnerId() != null)
                .orElse(false);
    }
}
