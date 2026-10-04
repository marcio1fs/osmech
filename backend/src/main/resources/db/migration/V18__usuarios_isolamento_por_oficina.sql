-- ============================================================
-- V18 - Isolamento do controle de usuários por oficina
--
-- O módulo de controle de usuários (/admin/usuarios) passava a
-- isolar por owner_id (legado) e criava usuários SEM oficina_id,
-- gerando contas órfãs invisíveis para a equipe da oficina.
--
-- O código agora isola tudo por oficina_id. Este backfill dá
-- oficina aos usuários antigos criados por aquele fluxo: eles
-- herdam a oficina do seu dono (owner_id).
-- ============================================================

UPDATE usuarios u
SET oficina_id = o.oficina_id
FROM usuarios o
WHERE u.oficina_id IS NULL
  AND u.owner_id = o.id
  AND o.oficina_id IS NOT NULL;

-- Conferência: deve sobrar apenas ADMINs de plataforma (ou nada)
-- SELECT id, email, role, owner_id FROM usuarios WHERE oficina_id IS NULL;
