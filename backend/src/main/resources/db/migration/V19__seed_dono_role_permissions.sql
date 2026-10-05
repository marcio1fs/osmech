-- ============================================================
-- V19 - Permissões RBAC para a role DONO
--
-- O sistema persistia novos donos de oficina com role = 'DONO',
-- mas a tabela role_permissions apenas possuía seeds para
-- 'ADMIN', 'GERENTE', 'OFICINA' (legado), etc.
-- Como resultado, usuários DONO não recebiam permissões no JWT,
-- ficando sem acesso aos módulos do sistema.
--
-- Esta migração concede à role DONO todas as permissões das
-- oficinas (idêntico a OFICINA e GERENTE, exceto 'configuracoes.editar'
-- que é exclusivo do ADMIN global do sistema OSMECH).
-- ============================================================

INSERT INTO role_permissions (role, permission_code)
SELECT 'DONO', code FROM permissions
WHERE code NOT IN ('configuracoes.editar')
ON CONFLICT DO NOTHING;
