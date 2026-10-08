package com.osmech.os.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Runner para garantir que a coluna 'numero' exista na tabela 'ordens_servico'
 * mesmo em ambientes locais/dev onde o Flyway está desativado (FLYWAY_ENABLED=false).
 * Totalmente idempotente.
 */
@Component
@Order(10)
@RequiredArgsConstructor
@Slf4j
public class OrdemServicoNumeroBackfillRunner implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        try {
            // 1. Adicionar coluna numero se não existir
            jdbcTemplate.execute("ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS numero BIGINT;");

            // 2. Preencher registros existentes sem número com sequência 1..N por oficina
            String sqlBackfill = """
                WITH numeracao AS (
                    SELECT id, ROW_NUMBER() OVER (PARTITION BY usuario_id ORDER BY criado_em ASC, id ASC) AS novo_numero
                    FROM ordens_servico
                )
                UPDATE ordens_servico os
                SET numero = n.novo_numero
                FROM numeracao n
                WHERE os.id = n.id AND os.numero IS NULL;
            """;
            int atualizados = jdbcTemplate.update(sqlBackfill);
            if (atualizados > 0) {
                log.info("Backfill de número de OS concluído: {} ordem(ns) numerada(s).", atualizados);
            }

            // 3. Criar índice único composto se não existir
            jdbcTemplate.execute("""
                CREATE UNIQUE INDEX IF NOT EXISTS uq_ordens_servico_usuario_numero
                ON ordens_servico (usuario_id, numero);
            """);

            // 4. Garantir colunas Z-API na tabela oficinas
            jdbcTemplate.execute("""
                ALTER TABLE oficinas
                    ADD COLUMN IF NOT EXISTS whatsapp_provider VARCHAR(50) DEFAULT 'ZAPI',
                    ADD COLUMN IF NOT EXISTS zapi_instance_id VARCHAR(100),
                    ADD COLUMN IF NOT EXISTS zapi_token VARCHAR(100),
                    ADD COLUMN IF NOT EXISTS zapi_client_token VARCHAR(100),
                    ADD COLUMN IF NOT EXISTS whatsapp_ativo BOOLEAN DEFAULT FALSE;
            """);

            log.info("Schema de ordens_servico e oficinas (Z-API) verificado com sucesso.");
        } catch (Exception e) {
            log.error("Erro ao aplicar migração automática da coluna numero em ordens_servico: {}", e.getMessage(), e);
        }
    }
}
