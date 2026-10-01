-- ============================================================
-- V15 - RBAC: VENDEDOR recebe TODAS as permissões, exceto as do
--       módulo FINANCEIRO (financeiro.*, fluxo_caixa, categorias,
--       historico de transações).
--
-- Decisão de negócio: o vendedor opera OS, estoque, clientes,
-- relatórios etc., mas não enxerga nem movimenta o financeiro.
--
-- Idempotente: pode ser executada mais de uma vez sem efeito
-- colateral (ON CONFLICT DO NOTHING). Também cobre permissões
-- criadas em versões anteriores sem precisar listá-las uma a uma.
-- ============================================================

INSERT INTO role_permissions (role, permission_code)
SELECT 'VENDEDOR', p.code
FROM permissions p
WHERE p.modulo <> 'FINANCEIRO'
ON CONFLICT DO NOTHING;
