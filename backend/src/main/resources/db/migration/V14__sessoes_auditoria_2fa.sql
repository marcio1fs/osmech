-- ============================================================
-- V14 — Fase 4 (hardening de sessão)
-- 1) sessoes_usuario: refresh tokens rotativos com revogação
-- 2) desafios_2fa: códigos de segundo fator pendentes
-- 3) usuarios.dois_fa_ativo: opt-in por usuário
-- 4) audit_log: trilha de ações sensíveis por oficina
-- ============================================================

CREATE TABLE IF NOT EXISTS sessoes_usuario (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    oficina_id BIGINT NOT NULL REFERENCES oficinas (id),
    refresh_token_hash VARCHAR(64) NOT NULL,
    user_agent VARCHAR(300),
    criado_em TIMESTAMP NOT NULL DEFAULT now(),
    expira_em TIMESTAMP NOT NULL,
    revogado_em TIMESTAMP,
    motivo_revogacao VARCHAR(60)
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_sessoes_refresh_hash
    ON sessoes_usuario (refresh_token_hash);
CREATE INDEX IF NOT EXISTS idx_sessoes_usuario
    ON sessoes_usuario (usuario_id);

CREATE TABLE IF NOT EXISTS desafios_2fa (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    codigo_hash VARCHAR(64) NOT NULL,
    tentativas INT NOT NULL DEFAULT 0,
    criado_em TIMESTAMP NOT NULL DEFAULT now(),
    expira_em TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_desafios_2fa_usuario
    ON desafios_2fa (usuario_id);

ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS dois_fa_ativo BOOLEAN DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    oficina_id BIGINT,
    usuario_id BIGINT,
    usuario_email VARCHAR(150),
    acao VARCHAR(60) NOT NULL,
    detalhes VARCHAR(1000),
    criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_oficina
    ON audit_log (oficina_id, id DESC);
