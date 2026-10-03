-- ============================================================
-- V11 - RBAC: Roles, Permissões e Sub-usuários
-- ============================================================

-- Adiciona campos de RBAC à tabela de usuários
ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS owner_id BIGINT NULL,
    ADD COLUMN IF NOT EXISTS ultimo_acesso TIMESTAMP NULL;

-- Tabela de permissões granulares (código + descrição + módulo)
CREATE TABLE IF NOT EXISTS permissions (
    id        BIGSERIAL    PRIMARY KEY,
    code      VARCHAR(100) NOT NULL UNIQUE,
    descricao VARCHAR(255),
    modulo    VARCHAR(60)  NOT NULL
);

-- Relacionamento: role → conjunto de permissões
CREATE TABLE IF NOT EXISTS role_permissions (
    role            VARCHAR(50)  NOT NULL,
    permission_code VARCHAR(100) NOT NULL,
    PRIMARY KEY (role, permission_code),
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE
);

-- ============================================================
-- SEED: permissões granulares
-- ============================================================
INSERT INTO permissions (code, descricao, modulo) VALUES
  -- Dashboard
  ('dashboard.visualizar',       'Visualizar dashboard principal',           'DASHBOARD'),
  -- OS
  ('os.visualizar',              'Listar e consultar ordens de serviço',     'OS'),
  ('os.criar',                   'Criar nova ordem de serviço',              'OS'),
  ('os.editar',                  'Editar ordem de serviço existente',        'OS'),
  ('os.cancelar',                'Cancelar ordem de serviço',                'OS'),
  ('os.finalizar',               'Finalizar/encerrar ordem de serviço',      'OS'),
  -- Mecânicos
  ('mecanicos.visualizar',       'Visualizar lista de mecânicos',            'MECANICOS'),
  ('mecanicos.criar',            'Cadastrar mecânico',                       'MECANICOS'),
  ('mecanicos.editar',           'Editar dados de mecânico',                 'MECANICOS'),
  -- Financeiro
  ('financeiro.visualizar',      'Visualizar dashboard financeiro',          'FINANCEIRO'),
  ('financeiro.criar',           'Criar lançamento financeiro',              'FINANCEIRO'),
  ('financeiro.editar',          'Editar lançamento financeiro',             'FINANCEIRO'),
  ('financeiro.cancelar',        'Estornar lançamento financeiro',           'FINANCEIRO'),
  ('fluxo_caixa.visualizar',     'Visualizar fluxo de caixa',               'FINANCEIRO'),
  ('categorias.visualizar',      'Visualizar categorias financeiras',        'FINANCEIRO'),
  ('categorias.criar',           'Criar categoria financeira',               'FINANCEIRO'),
  ('categorias.editar',          'Editar categoria financeira',              'FINANCEIRO'),
  ('historico.visualizar',       'Visualizar histórico de transações',       'FINANCEIRO'),
  -- Estoque
  ('estoque.visualizar',         'Visualizar itens de estoque',              'ESTOQUE'),
  ('estoque.criar',              'Cadastrar novo item de estoque',           'ESTOQUE'),
  ('estoque.editar',             'Editar item de estoque',                   'ESTOQUE'),
  ('estoque.entrada',            'Registrar entrada de estoque',             'ESTOQUE'),
  ('estoque.saida',              'Registrar saída de estoque',               'ESTOQUE'),
  ('estoque.ajuste',             'Realizar ajuste de estoque',               'ESTOQUE'),
  -- Relatórios
  ('relatorios.visualizar',      'Visualizar relatórios',                    'RELATORIOS'),
  ('relatorios.exportar',        'Exportar relatórios (PDF/Excel)',           'RELATORIOS'),
  -- Pagamentos e Assinatura
  ('pagamentos.visualizar',      'Visualizar histórico de pagamentos',       'PAGAMENTOS'),
  ('assinatura.visualizar',      'Visualizar e gerenciar assinatura',        'ASSINATURA'),
  -- Chat / IA
  ('chat.usar',                  'Usar assistente de IA',                    'CHAT'),
  -- Perfil
  ('perfil.visualizar',          'Visualizar perfil próprio',                'PERFIL'),
  ('perfil.editar',              'Editar perfil próprio',                    'PERFIL'),
  -- Usuários (gestão)
  ('usuarios.visualizar',        'Listar usuários da oficina',               'USUARIOS'),
  ('usuarios.criar',             'Criar novo usuário na oficina',            'USUARIOS'),
  ('usuarios.editar',            'Editar dados de usuário',                  'USUARIOS'),
  ('usuarios.bloquear',          'Bloquear/desbloquear usuário',             'USUARIOS'),
  ('usuarios.alterar_perfil',    'Alterar perfil/role de usuário',           'USUARIOS'),
  -- Configurações
  ('configuracoes.visualizar',   'Visualizar configurações administrativas', 'CONFIGURACOES'),
  ('configuracoes.editar',       'Editar configurações administrativas',     'CONFIGURACOES')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- SEED: permissões por role
-- ============================================================

-- ADMIN: acesso total
INSERT INTO role_permissions (role, permission_code) SELECT 'ADMIN', code FROM permissions
ON CONFLICT DO NOTHING;

-- GERENTE: acesso amplo (sem configuracoes.editar - reservado ao ADMIN OSMECH)
INSERT INTO role_permissions (role, permission_code) SELECT 'GERENTE', code FROM permissions
  WHERE code NOT IN ('configuracoes.editar')
ON CONFLICT DO NOTHING;

-- ATENDENTE: OS, mecânicos (somente visualizar), perfil
INSERT INTO role_permissions (role, permission_code) VALUES
  ('ATENDENTE', 'dashboard.visualizar'),
  ('ATENDENTE', 'os.visualizar'),
  ('ATENDENTE', 'os.criar'),
  ('ATENDENTE', 'os.editar'),
  ('ATENDENTE', 'mecanicos.visualizar'),
  ('ATENDENTE', 'perfil.visualizar'),
  ('ATENDENTE', 'perfil.editar')
ON CONFLICT DO NOTHING;

-- MECANICO: somente OS e perfil
INSERT INTO role_permissions (role, permission_code) VALUES
  ('MECANICO', 'dashboard.visualizar'),
  ('MECANICO', 'os.visualizar'),
  ('MECANICO', 'os.editar'),
  ('MECANICO', 'perfil.visualizar'),
  ('MECANICO', 'perfil.editar')
ON CONFLICT DO NOTHING;

-- ESTOQUISTA: estoque, OS (visualizar), perfil
INSERT INTO role_permissions (role, permission_code) VALUES
  ('ESTOQUISTA', 'dashboard.visualizar'),
  ('ESTOQUISTA', 'os.visualizar'),
  ('ESTOQUISTA', 'estoque.visualizar'),
  ('ESTOQUISTA', 'estoque.criar'),
  ('ESTOQUISTA', 'estoque.editar'),
  ('ESTOQUISTA', 'estoque.entrada'),
  ('ESTOQUISTA', 'estoque.saida'),
  ('ESTOQUISTA', 'estoque.ajuste'),
  ('ESTOQUISTA', 'perfil.visualizar'),
  ('ESTOQUISTA', 'perfil.editar')
ON CONFLICT DO NOTHING;

-- FINANCEIRO: financeiro completo, relatórios, OS visualizar, perfil
INSERT INTO role_permissions (role, permission_code) VALUES
  ('FINANCEIRO', 'dashboard.visualizar'),
  ('FINANCEIRO', 'os.visualizar'),
  ('FINANCEIRO', 'financeiro.visualizar'),
  ('FINANCEIRO', 'financeiro.criar'),
  ('FINANCEIRO', 'financeiro.editar'),
  ('FINANCEIRO', 'financeiro.cancelar'),
  ('FINANCEIRO', 'fluxo_caixa.visualizar'),
  ('FINANCEIRO', 'categorias.visualizar'),
  ('FINANCEIRO', 'categorias.criar'),
  ('FINANCEIRO', 'categorias.editar'),
  ('FINANCEIRO', 'historico.visualizar'),
  ('FINANCEIRO', 'relatorios.visualizar'),
  ('FINANCEIRO', 'relatorios.exportar'),
  ('FINANCEIRO', 'perfil.visualizar'),
  ('FINANCEIRO', 'perfil.editar')
ON CONFLICT DO NOTHING;

-- OFICINA: role legada → mesmo acesso que GERENTE (dono da oficina)
INSERT INTO role_permissions (role, permission_code) SELECT 'OFICINA', code FROM permissions
  WHERE code NOT IN ('configuracoes.editar')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Migração de dados: OFICINA permanece OFICINA (compatibilidade)
-- ultimo_acesso inicializado com atualizado_em ou criado_em
-- ============================================================
UPDATE usuarios
SET ultimo_acesso = COALESCE(atualizado_em, criado_em)
WHERE ultimo_acesso IS NULL;

-- Índices
CREATE INDEX IF NOT EXISTS idx_usuarios_owner_id     ON usuarios (owner_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_role         ON usuarios (role);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions (role);
