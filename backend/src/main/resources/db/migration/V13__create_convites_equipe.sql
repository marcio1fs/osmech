-- ============================================================
-- V13 - Convites de equipe + normalização do papel legado
-- ============================================================

-- Convites de usuários para uma oficina (Fase 3)
CREATE TABLE IF NOT EXISTS convites_equipe (
    id BIGSERIAL PRIMARY KEY,
    oficina_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    papel VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE', -- PENDENTE | ACEITO | REVOGADO | EXPIRADO
    criado_por_usuario_id BIGINT,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em TIMESTAMP NOT NULL,
    aceito_em TIMESTAMP,
    CONSTRAINT fk_convites_equipe_oficina
        FOREIGN KEY (oficina_id) REFERENCES oficinas (id)
);

CREATE INDEX IF NOT EXISTS idx_convites_equipe_oficina_status
    ON convites_equipe (oficina_id, status);

CREATE UNIQUE INDEX IF NOT EXISTS uk_convites_equipe_token
    ON convites_equipe (token);

CREATE INDEX IF NOT EXISTS idx_convites_equipe_email
    ON convites_equipe (email);

-- Fase 2: papel OFICINA (legado) passa a se chamar DONO.
-- Papel.from("OFICINA") = DONO mantém compatibilidade nos ambientes sem Flyway.
UPDATE usuarios SET role = 'DONO' WHERE role = 'OFICINA';
