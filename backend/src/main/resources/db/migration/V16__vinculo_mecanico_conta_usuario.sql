-- ============================================================
-- V16 - Integração Equipe ↔ Mecânicos
--
-- Adiciona mecanicos.usuario_conta_id: a CONTA DE USUÁRIO (login)
-- do mecânico, criada pelo módulo Equipe. Com isso, as comissões
-- (servicos_os.valor_comissao → mecanicos) ficam ligadas à pessoa.
--
-- Obs.: mecanicos.usuario_id continua sendo a OFICINA (tenant).
--
-- Backfill: vincula automaticamente membros da equipe com papel
-- MECANICO às fichas existentes quando há exatamente 1 ficha sem
-- vínculo e 1 usuário com o mesmo nome na mesma oficina (evita
-- vínculos errados em caso de homônimos).
-- ============================================================

ALTER TABLE mecanicos
    ADD COLUMN IF NOT EXISTS usuario_conta_id BIGINT NULL;

CREATE INDEX IF NOT EXISTS idx_mecanicos_usuario_conta
    ON mecanicos (usuario_conta_id)
    WHERE usuario_conta_id IS NOT NULL;

UPDATE mecanicos m
SET usuario_conta_id = u.id
FROM usuarios u
WHERE m.usuario_conta_id IS NULL
  AND u.oficina_id = m.usuario_id
  AND u.role = 'MECANICO'
  AND LOWER(TRIM(u.nome)) = LOWER(TRIM(m.nome))
  AND (SELECT COUNT(*) FROM mecanicos m2
        WHERE m2.usuario_id = m.usuario_id
          AND m2.usuario_conta_id IS NULL
          AND LOWER(TRIM(m2.nome)) = LOWER(TRIM(u.nome))) = 1
  AND (SELECT COUNT(*) FROM usuarios u2
        WHERE u2.oficina_id = m.usuario_id
          AND u2.role = 'MECANICO'
          AND LOWER(TRIM(u2.nome)) = LOWER(TRIM(m.nome))) = 1
  AND NOT EXISTS (SELECT 1 FROM mecanicos m3 WHERE m3.usuario_conta_id = u.id);
