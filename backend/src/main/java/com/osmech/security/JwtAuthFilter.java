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
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Filtro que intercepta requisições HTTP, valida o token JWT e configura
 * o SecurityContext com as authorities do usuário:
 * - ROLE_{role}  → para controle de role (ex: ROLE_ADMIN, ROLE_DONO)
 * - PERM_{code}  → para cada permissão granular (ex: PERM_os.criar)
 *
 * O usuário é carregado do banco a cada request, garantindo:
 *  - conta inativada perde acesso imediatamente;
 *  - o principal exposto é UsuarioAutenticado (id + email + papel + oficinaId).
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
                List<String> permissions = jwtUtil.getPermissionsFromToken(token);

                Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);

                if (usuario != null && Boolean.TRUE.equals(usuario.getAtivo())) {
                    if (usuario.getOficinaId() == null) {
                        log.error("Usuário {} sem oficina vinculada; acesso negado até o backfill.", email);
                    } else {
                        Papel papel = Papel.from(usuario.getRole());
                        List<SimpleGrantedAuthority> authorities = new ArrayList<>();
                        
                        if (papel == Papel.ADMIN) {
                            authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
                            authorities.add(new SimpleGrantedAuthority("ROLE_DONO"));
                        } else {
                            authorities.add(new SimpleGrantedAuthority("ROLE_" + papel.name()));
                        }

                        for (String perm : permissions) {
                            authorities.add(new SimpleGrantedAuthority("PERM_" + perm));
                        }

                        var principal = new UsuarioAutenticado(
                                usuario.getId(), usuario.getOficinaId(), usuario.getEmail(), papel.name());
                        var authToken = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                        SecurityContextHolder.getContext().setAuthentication(authToken);

                        atualizarUltimoAcesso(usuario);
                    }
                } else if (usuario == null) {
                    log.warn("[JwtAuthFilter] JWT válido mas usuário não encontrado: {}", email);
                } else {
                    log.warn("[JwtAuthFilter] JWT válido mas usuário BLOQUEADO/DESATIVADO: {}", email);
                }
            } else {
                log.debug("[JwtAuthFilter] Token JWT inválido/expirado para {} {}",
                        request.getMethod(), request.getRequestURI());
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Atualiza o campo ultimo_acesso do usuário.
     */
    protected void atualizarUltimoAcesso(Usuario usuario) {
        try {
            usuario.setUltimoAcesso(LocalDateTime.now());
            usuarioRepository.save(usuario);
        } catch (Exception e) {
            log.debug("[JwtAuthFilter] Falha ao atualizar ultimo_acesso para {}: {}", usuario.getEmail(), e.getMessage());
        }
    }
}
