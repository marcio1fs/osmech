package com.osmech.auth;

import com.osmech.auth.dto.AuthResponse;
import com.osmech.auth.dto.LoginRequest;
import com.osmech.auth.dto.RegisterRequest;
import com.osmech.config.JwtUtil;
import com.osmech.user.Usuario;
import com.osmech.user.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Check if email already exists
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email já cadastrado");
        }

        // Create new user
        Usuario usuario = new Usuario();
        usuario.setNomeOficina(request.getNomeOficina());
        usuario.setEmail(request.getEmail());
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));

        usuario = usuarioRepository.save(usuario);

        // Generate JWT token
        String token = jwtUtil.generateToken(usuario.getEmail(), usuario.getId());

        return new AuthResponse(token, usuario.getId(), usuario.getNomeOficina(), usuario.getEmail());
    }

    public AuthResponse login(LoginRequest request) {
        // Find user by email
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Credenciais inválidas"));

        // Verify password
        if (!passwordEncoder.matches(request.getSenha(), usuario.getSenha())) {
            throw new RuntimeException("Credenciais inválidas");
        }

        // Generate JWT token
        String token = jwtUtil.generateToken(usuario.getEmail(), usuario.getId());

        return new AuthResponse(token, usuario.getId(), usuario.getNomeOficina(), usuario.getEmail());
    }
}
