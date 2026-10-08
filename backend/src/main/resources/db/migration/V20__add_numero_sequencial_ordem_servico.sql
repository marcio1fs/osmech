-- ============================================================
-- V20 - Sequência numérica própria de Ordem de Serviço por oficina
-- ============================================================

-- 1. Adiciona a coluna numero em ordens_servico
ALTER TABLE ordens_servico
    ADD COLUMN IF NOT EXISTS numero BIGINT;

-- 2. Backfill: preenche o campo numero para as OS existentes por oficina
--    Gera sequência 1..N ordenada pela data de criação / id para cada oficina (usuario_id)
WITH numeracao AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY usuario_id ORDER BY criado_em ASC, id ASC) AS novo_numero
    FROM ordens_servico
)
UPDATE ordens_servico os
SET numero = n.novo_numero
FROM numeracao n
WHERE os.id = n.id AND os.numero IS NULL;

-- 3. Torna o campo NOT NULL após o preenchimento
ALTER TABLE ordens_servico
    ALTER COLUMN numero SET NOT NULL;

-- 4. Cria índice único composto garantindo que cada oficina não repita o número da OS
CREATE UNIQUE INDEX IF NOT EXISTS uq_ordens_servico_usuario_numero
    ON ordens_servico (usuario_id, numero);
