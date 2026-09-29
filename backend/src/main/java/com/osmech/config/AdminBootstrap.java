package com.osmech.config;

import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Protege a conta de administrador contra a senha seed vazada no repositório.
 *
 * O hash BCrypt de V10__seed_admin_user.sql é público (está no Git). Este
 * componente executa em TODO boot, com ou sem Flyway, e garante que:
 *
 *  - Se a senha atual for o hash exposto (ou o marcador deixado pela migration V11):
 *      · ADMIN_INITIAL_PASSWORD definida (mín. 8) → redefine a senha, reativa e verifica a conta;
 *      · caso contrário → BLOQUEIA a conta com uma senha aleatória desconhecida.
 *  - Se a conta admin não existir e ADMIN_INITIAL_PASSWORD estiver definida → cria a conta.
 *  - Uma senha já trocada pelo dono NUNCA é sobrescrita pela variável de ambiente.
 *
 * Configuração (application.yml → env):
 *   ADMIN_EMAIL               (default: marciofs426@gmail.com)
 *   ADMIN_INITIAL_PASSWORD    (sem default; obrigatória para desbloquear/criar)
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AdminBootstrap implements ApplicationRunner {

    /** Hash BCrypt exposto publicamente em V10__seed_admin_user.sql */
    private static final String LEAKED_SEED_HASH =
            "$2b$12$j2enNOrCVwZuTL7SjkRyHObX5YU9nNv7sDR5qUttiEArgtvNKjkzK";

    /** Marcador gravado pela migration V11 ao neutralizar a senha vazada */
    private static final String LOCKED_SEED_MARKER = "LOCKED_LEAKED_SEED_PASSWORD";

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.admin.email:}")
    private String adminEmail;

    @Value("${app.admin.initial-password:}")
    private String initialPassword;

    @Override
    public void run(ApplicationArguments args) {
        if (adminEmail == null || adminEmail.isBlank()) {
            return;
        }

        String email = adminEmail.toLowerCase().trim();

        if (initialPassword != null && !initialPassword.isBlank() && initialPassword.length() < 8) {
            log.warn("ADMIN_INITIAL_PASSWORD ignorada: precisa ter pelo menos 8 caracteres.");
        }
        boolean hasInitial = initialPassword != null && initialPassword.length() >= 8;

        var existente = usuarioRepository.findByEmail(email);
        if (existente.isPresent()) {
            neutralizarSeComprometida(existente.get(), email, hasInitial);
            return;
        }

        if (hasInitial) {
            usuarioRepository.save(Usuario.builder()
                    .nome("Administrador OSMECH")
                    .email(email)
                    .senha(passwordEncoder.encode(initialPassword))
                    .telefone("00000000000") // coluna NOT NULL no schema
                    .role(Papel.ADMIN.name())
                    .plano("PREMIUM")
                    .ativo(true)
                    .emailVerificado(true)
                    .build());
            log.info("Conta admin criada para {} a partir de ADMIN_INITIAL_PASSWORD.", email);
        }
    }

    /**
     * Se a conta ainda usa a senha vazada (hash original V10 ou marcador V11),
     * redefine via env ou bloqueia com senha aleatória desconhecida.
     */
    private void neutralizarSeComprometida(Usuario admin, String email, boolean hasInitial) {
        boolean comprometida = LEAKED_SEED_HASH.equals(admin.getSenha())
                || LOCKED_SEED_MARKER.equals(admin.getSenha());
        if (!comprometida) {
            return; // senha já foi trocada pelo dono — jamais sobrescrever
        }

        if (hasInitial) {
            admin.setSenha(passwordEncoder.encode(initialPassword));
            admin.setAtivo(true);
            admin.setEmailVerificado(true);
            usuarioRepository.save(admin);
            log.info("Senha da conta admin ({}) redefinida via ADMIN_INITIAL_PASSWORD. "
                    + "A variável pode ser removida do ambiente após este boot.", email);
        } else {
            admin.setSenha(passwordEncoder.encode(UUID.randomUUID().toString()));
            usuarioRepository.save(admin);
            log.warn("Conta admin ({}) usava a senha seed exposta no repositório e foi BLOQUEADA. "
                    + "Defina ADMIN_INITIAL_PASSWORD (mín. 8 caracteres) para redefini-la no próximo boot.", email);
        }
    }
}
