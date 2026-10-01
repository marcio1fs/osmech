package com.osmech.oficina.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Backfill do tenant Oficina — executa em TODO boot, com ou sem Flyway.
 *
 * Equivalente em Java à migration V12 (que só roda em ambientes com
 * Flyway habilitado). É IDEMPOTENTE: em ambientes com Flyway, não faz
 * nada (as guardas NOT EXISTS / IS NULL falham).
 *
 * Mantém a invariante de igualdade de ids: a oficina criada no backfill
 * recebe o mesmo id do usuário dono, permitindo que as colunas
 * usuario_id das tabelas de negócio passem a significar "tenant id"
 * sem migração de dados.
 *
 * Executa primeiro que os demais runners (ex.: AdminBootstrap).
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
@RequiredArgsConstructor
@Slf4j
public class OficinaBackfillRunner implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    private static final String SQL_BACKFILL_OFICINAS = """
            INSERT INTO oficinas (id, nome, cnpj, telefone, email,
                endereco_logradouro, endereco_numero, endereco_complemento,
                endereco_bairro, endereco_cidade, endereco_estado, endereco_cep,
                site, logo_url, plano, criado_em)
            SELECT u.id,
                   COALESCE(NULLIF(u.nome_oficina, ''), u.nome, 'Minha Oficina'),
                   u.cnpj_oficina, u.telefone, u.email,
                   u.endereco_logradouro, u.endereco_numero, u.endereco_complemento,
                   u.endereco_bairro, u.endereco_cidade, u.endereco_estado, u.endereco_cep,
                   u.site_oficina, u.logo_url, u.plano, u.criado_em
            FROM usuarios u
            WHERE NOT EXISTS (SELECT 1 FROM oficinas o WHERE o.id = u.id)
            """;

    private static final String SQL_VINCULAR_USUARIOS =
            "UPDATE usuarios SET oficina_id = id WHERE oficina_id IS NULL";

    private static final String SQL_REPOSICIONAR_SEQUENCIA = """
            DO $$
            DECLARE seq text;
            BEGIN
                SELECT pg_get_serial_sequence('oficinas', 'id') INTO seq;
                IF seq IS NOT NULL THEN
                    EXECUTE format('SELECT setval(%L, (SELECT GREATEST(MAX(id), 1) FROM oficinas))', seq);
                END IF;
            END $$
            """;

    @Override
    public void run(ApplicationArguments args) {
        int oficinasCriadas = jdbcTemplate.update(SQL_BACKFILL_OFICINAS);
        int usuariosVinculados = jdbcTemplate.update(SQL_VINCULAR_USUARIOS);
        jdbcTemplate.execute(SQL_REPOSICIONAR_SEQUENCIA);

        if (oficinasCriadas > 0 || usuariosVinculados > 0) {
            log.info("Backfill Oficina concluído: {} oficina(s) criada(s), {} usuário(s) vinculado(s).",
                    oficinasCriadas, usuariosVinculados);
        } else {
            log.debug("Backfill Oficina: nada a fazer (ambiente já migrado).");
        }
    }
}
