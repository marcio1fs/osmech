package com.osmech.security;

import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Filtro que intercepta requisições HTTP e valida o token JWT no header Authorization.
 *
 * O usuário é carregado do banco a cada request, o que garante:
 *  - conta inativada perde acesso no próximo request;
 *  - o papel usado na autorização é SEMPRE o do banco (não o do token, que
 *    poderia ficar defasado até a expiração do JWT).
 *
 * O principal exposto é {@link UsuarioAutenticado} (id + email + papel);
 * como ele implementa {@link java.security.Principal}, {@code auth.getName()}
 * continua retornando o e-mail para os services existentes.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthFilter.class);

    private final JwtUtil jwtUtil;
    private final UsuarioRepository usuarioRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);

            if (jwtUtil.validateToken(token)) {
                String email = jwtUtil.getEmailFromToken(token);

                // Usuário precisa existir e estar ativo — papel vem do banco (sempre fresco)
                Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);

                if (usuario != null && Boolean.TRUE.equals(usuario.getAtivo())) {
                    String papel = Papel.from(usuario.getRole()).name();
                    var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + papel));
                    var principal = new UsuarioAutenticado(usuario.getId(), usuario.getEmail(), papel);
                    var authToken = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    log.warn("JWT válido mas usuário não encontrado ou inativo: {}", email);
                }
            } else {
                log.debug("Token JWT inválido ou expirado para {} {}", request.getMethod(), request.getRequestURI());
            }
        }

        filterChain.doFilter(request, response);
    }
}
