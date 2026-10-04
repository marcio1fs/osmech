-- ============================================================
-- V12 - Tenant Oficina: tabela `oficinas` + vínculo em `usuarios`
-- ============================================================
-- Estratégia de igualdade de ids:
--   A oficina criada no backfill RECEBE O MESMO ID do usuário dono.
--   Desse modo, as colunas `usuario_id` das tabelas de negócio
--   (ordens_servico, mecanicos, stock_items, stock_movements,
--   categorias_financeiras, transacoes_financeiras, fluxo_caixa,
--   chat_messages, assinaturas, pagamentos) passam a significar
--   "id do tenant (oficina)" SEM nenhuma migração de dados.
--   Todo o código escreve/consulta usando o oficina_id.

CREATE TABLE IF NOT EXISTS oficinas (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    cnpj VARCHAR(18),
    telefone VARCHAR(255),
    email VARCHAR(255),
    endereco_logradouro VARCHAR(120),
    endereco_numero VARCHAR(20),
    endereco_complemento VARCHAR(120),
    endereco_bairro VARCHAR(80),
    endereco_cidade VARCHAR(80),
    endereco_estado VARCHAR(2),
    endereco_cep VARCHAR(10),
    site VARCHAR(120),
    logo_url VARCHAR(255),
    plano VARCHAR(255) NOT NULL DEFAULT 'FREE',
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP
);

-- Backfill: 1 oficina por usuário existente, oficina.id = usuario.id
INSERT INTO oficinas (id, nome, cnpj, telefone, email,
    endereco_logradouro, endereco_numero, endereco_complemento,
    endereco_bairro, endereco_cidade, endereco_estado, endereco_cep,
    site, logo_url, plano, criado_em)
SELECT u.id,
       COALESCE(NULLIF(u.nome_oficina, ''), u.nome, 'Minha Oficina'),
       u.cnpj_oficina,
       u.telefone,
       u.email,
       u.endereco_logradouro,
       u.endereco_numero,
       u.endereco_complemento,
       u.endereco_bairro,
       u.endereco_cidade,
       u.endereco_estado,
       u.endereco_cep,
       u.site_oficina,
       u.logo_url,
       u.plano,
       u.criado_em
FROM usuarios u
WHERE NOT EXISTS (SELECT 1 FROM oficinas o WHERE o.id = u.id);

-- Reposiciona a sequência após os ids explícitos (serial ou identity)
DO $$
DECLARE seq text;
BEGIN
    SELECT pg_get_serial_sequence('oficinas', 'id') INTO seq;
    IF seq IS NOT NULL THEN
        EXECUTE format('SELECT setval(%L, (SELECT GREATEST(MAX(id), 1) FROM oficinas))', seq);
    END IF;
END $$;

-- Vínculo usuário -> oficina
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS oficina_id BIGINT;

UPDATE usuarios SET oficina_id = id WHERE oficina_id IS NULL;

ALTER TABLE usuarios ALTER COLUMN oficina_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_usuarios_oficina_id ON usuarios (oficina_id);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_usuarios_oficina') THEN
        ALTER TABLE usuarios
            ADD CONSTRAINT fk_usuarios_oficina
            FOREIGN KEY (oficina_id) REFERENCES oficinas (id);
    END IF;
END $$;
