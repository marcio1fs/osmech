package com.osmech.auth.service;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.security.JwtUtil;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Serviço responsável por autenticação e cadastro de usuários.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * Realiza o cadastro de um novo usuário.
     *
     * @throws IllegalArgumentException se o email já estiver em uso
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Verifica se email já existe
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email já cadastrado");
        }

        // Cria o usuário com senha criptografada
        Usuario usuario = Usuario.builder()
                .nome(request.getNome())
                .email(request.getEmail())
                .senha(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone())
                .nomeOficina(request.getNomeOficina())
                .role("OFICINA")
                .plano("FREE")
                .ativo(true)
                .build();

        usuarioRepository.save(usuario);

        // Gera token JWT
        String token = jwtUtil.generateToken(usuario.getEmail(), usuario.getRole());

        return AuthResponse.builder()
                .token(token)
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(usuario.getRole())
                .plano(usuario.getPlano())
                .build();
    }

    /**
     * Realiza o login do usuário.
     *
     * @throws IllegalArgumentException se credenciais forem inválidas
     */
    public AuthResponse login(LoginRequest request) {
        // Busca usuário pelo email
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Credenciais inválidas"));

        // Verifica senha
        if (!passwordEncoder.matches(request.getSenha(), usuario.getSenha())) {
            throw new IllegalArgumentException("Credenciais inválidas");
        }

        // Verifica se está ativo
        if (!usuario.getAtivo()) {
            throw new IllegalArgumentException("Conta desativada. Entre em contato com o suporte.");
        }

        // Gera token JWT
        String token = jwtUtil.generateToken(usuario.getEmail(), usuario.getRole());

        return AuthResponse.builder()
                .token(token)
                .email(usuario.getEmail())
                .nome(usuario.getNome())
                .role(usuario.getRole())
                .plano(usuario.getPlano())
                .build();
    }
}
