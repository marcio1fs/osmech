-- ============================================================
-- V12 - RBAC: Permissões extras para ATENDENTE (Vendedor)
-- ============================================================
-- O ATENDENTE precisa acessar Pagamentos e Chat IA.
-- As demais permissões (dashboard, OS, mecânicos, perfil) já
-- foram configuradas na V11.

INSERT INTO role_permissions (role, permission_code) VALUES
  ('ATENDENTE', 'pagamentos.visualizar'),
  ('ATENDENTE', 'chat.usar')
ON CONFLICT DO NOTHING;
