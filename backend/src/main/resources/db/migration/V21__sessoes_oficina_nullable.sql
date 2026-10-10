-- ============================================================
-- V17 - sessoes_usuario.oficina_id passa a aceitar NULL
--
-- Contas legadas (criadas antes do multi-tenant) têm
-- usuarios.oficina_id = NULL. O INSERT da sessão no login
-- violava o NOT NULL e devolvia 409 Conflict no /auth/login.
-- ============================================================

ALTER TABLE sessoes_usuario ALTER COLUMN oficina_id DROP NOT NULL;
