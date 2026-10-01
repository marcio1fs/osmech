-- ============================================================
-- V13 - RBAC: Adição do perfil VENDEDOR e permissões operacionais
-- ============================================================

-- Permissões para VENDEDOR:
-- Foco em criação de orçamentos, vendas de peças/balcão, abertura e acompanhamento de OS e clientes
INSERT INTO role_permissions (role, permission_code) VALUES
  ('VENDEDOR', 'dashboard.visualizar'),
  ('VENDEDOR', 'os.visualizar'),
  ('VENDEDOR', 'os.criar'),
  ('VENDEDOR', 'os.editar'),
  ('VENDEDOR', 'estoque.visualizar'),
  ('VENDEDOR', 'estoque.saida'),
  ('VENDEDOR', 'pagamentos.visualizar'),
  ('VENDEDOR', 'mecanicos.visualizar'),
  ('VENDEDOR', 'chat.usar'),
  ('VENDEDOR', 'perfil.visualizar'),
  ('VENDEDOR', 'perfil.editar')
ON CONFLICT DO NOTHING;
