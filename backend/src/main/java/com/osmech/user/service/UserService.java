package com.osmech.user.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.user.dto.ChangePasswordRequest;
import com.osmech.user.dto.UserProfileRequest;
import com.osmech.user.dto.UserProfileResponse;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Serviço de gerenciamento de perfil do usuário.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Retorna o perfil do usuário logado.
     */
    public UserProfileResponse getPerfil(String email) {
        Usuario usuario = getUsuario(email);
        return toResponse(usuario);
    }

    /**
     * Atualiza dados do perfil do usuário.
     */
    @Transactional
    public UserProfileResponse atualizarPerfil(String email, UserProfileRequest request) {
        Usuario usuario = getUsuario(email);

        if (request.getNome() != null && !request.getNome().isBlank()) {
            usuario.setNome(request.getNome());
        }
        if (request.getTelefone() != null && !request.getTelefone().isBlank()) {
            usuario.setTelefone(request.getTelefone());
        }
        if (request.getNomeOficina() != null) {
            usuario.setNomeOficina(request.getNomeOficina());
        }

        usuarioRepository.save(usuario);
        log.info("Perfil atualizado para usuário: {}", email);
        return toResponse(usuario);
    }

    /**
     * Altera a senha do usuário.
     */
    @Transactional
    public void alterarSenha(String email, ChangePasswordRequest request) {
        Usuario usuario = getUsuario(email);

        // Verificar senha atual
        if (!passwordEncoder.matches(request.getSenhaAtual(), usuario.getSenha())) {
            throw new IllegalArgumentException("Senha atual incorreta");
        }

        // Validar nova senha
        if (request.getNovaSenha().length() < 8) {
            throw new IllegalArgumentException("Nova senha deve ter pelo menos 8 caracteres");
        }

        usuario.setSenha(passwordEncoder.encode(request.getNovaSenha()));
        usuarioRepository.save(usuario);
        log.info("Senha alterada para usuário: {}", email);
    }

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    private UserProfileResponse toResponse(Usuario usuario) {
        return UserProfileResponse.builder()
                .id(usuario.getId())
                .nome(usuario.getNome())
                .email(usuario.getEmail())
                .telefone(usuario.getTelefone())
                .nomeOficina(usuario.getNomeOficina())
                .role(usuario.getRole())
                .plano(usuario.getPlano())
                .ativo(usuario.getAtivo())
                .criadoEm(usuario.getCriadoEm())
                .build();
    }
}
