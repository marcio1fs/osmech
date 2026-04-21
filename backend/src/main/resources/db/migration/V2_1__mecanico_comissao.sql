ALTER TABLE mecanicos
    ADD COLUMN IF NOT EXISTS percentual_comissao NUMERIC(5, 2) NOT NULL DEFAULT 0;

ALTER TABLE servicos_os
    ADD COLUMN IF NOT EXISTS mecanico_id BIGINT,
    ADD COLUMN IF NOT EXISTS mecanico_nome VARCHAR(255),
    ADD COLUMN IF NOT EXISTS percentual_comissao NUMERIC(5, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS valor_comissao NUMERIC(10, 2) NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_servicos_os_mecanico_id
    ON servicos_os (mecanico_id);
