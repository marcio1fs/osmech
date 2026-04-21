-- ============================================================
-- V1 - Initial schema (baseline for new/empty databases)
-- ============================================================

-- ----------------------------
-- usuarios
-- ----------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(255) NOT NULL,
    nome_oficina VARCHAR(255),
    cnpj_oficina VARCHAR(18),
    endereco_logradouro VARCHAR(120),
    endereco_numero VARCHAR(20),
    endereco_complemento VARCHAR(120),
    endereco_bairro VARCHAR(80),
    endereco_cidade VARCHAR(80),
    endereco_estado VARCHAR(2),
    endereco_cep VARCHAR(10),
    site_oficina VARCHAR(120),
    role VARCHAR(255) NOT NULL DEFAULT 'OFICINA',
    plano VARCHAR(255) NOT NULL DEFAULT 'FREE',
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP
);

-- ----------------------------
-- planos
-- ----------------------------
CREATE TABLE IF NOT EXISTS planos (
    id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(255) NOT NULL UNIQUE,
    nome VARCHAR(255) NOT NULL,
    preco NUMERIC(10, 2) NOT NULL,
    limite_os INTEGER DEFAULT 0,
    whatsapp_habilitado BOOLEAN DEFAULT FALSE,
    ia_habilitada BOOLEAN DEFAULT FALSE,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

-- ----------------------------
-- ordens_servico
-- ----------------------------
CREATE TABLE IF NOT EXISTS ordens_servico (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    cliente_nome VARCHAR(255) NOT NULL,
    cliente_cpf VARCHAR(20),
    cliente_cnpj VARCHAR(30),
    cliente_telefone VARCHAR(255),
    placa VARCHAR(255) NOT NULL,
    modelo VARCHAR(255) NOT NULL,
    montadora VARCHAR(120),
    cor_veiculo VARCHAR(60),
    ano INTEGER,
    quilometragem INTEGER,
    descricao TEXT NOT NULL,
    diagnostico TEXT,
    mecanico_responsavel VARCHAR(255),
    pecas TEXT,
    valor NUMERIC(10, 2) DEFAULT 0,
    status VARCHAR(255) NOT NULL DEFAULT 'ABERTA',
    whatsapp_consentimento BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP,
    concluido_em TIMESTAMP
);

-- ----------------------------
-- mecanicos
-- ----------------------------
CREATE TABLE IF NOT EXISTS mecanicos (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    telefone VARCHAR(255),
    especialidade VARCHAR(255),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP
);

-- ----------------------------
-- stock_items
-- ----------------------------
CREATE TABLE IF NOT EXISTS stock_items (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    categoria VARCHAR(255) NOT NULL DEFAULT 'OUTROS',
    quantidade INTEGER NOT NULL DEFAULT 0,
    quantidade_minima INTEGER NOT NULL DEFAULT 1,
    preco_custo NUMERIC(10, 2) DEFAULT 0,
    preco_venda NUMERIC(10, 2) DEFAULT 0,
    localizacao VARCHAR(255),
    referencia VARCHAR(255),
    marca VARCHAR(255),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP,
    CONSTRAINT uk_stock_items_usuario_codigo UNIQUE (usuario_id, codigo)
);

-- ----------------------------
-- categorias_financeiras
-- ----------------------------
CREATE TABLE IF NOT EXISTS categorias_financeiras (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT,
    nome VARCHAR(255) NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    icone VARCHAR(255),
    sistema BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------
-- assinatura/pagamento
-- ----------------------------
CREATE TABLE IF NOT EXISTS assinaturas (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    plano_id BIGINT NOT NULL,
    plano_codigo VARCHAR(255) NOT NULL,
    valor_mensal NUMERIC(10, 2) NOT NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE',
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    proxima_cobranca DATE NOT NULL,
    data_cancelamento DATE,
    dias_carencia INTEGER DEFAULT 5,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pagamentos (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    referencia_id BIGINT,
    descricao TEXT,
    metodo_pagamento VARCHAR(255) NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'PENDENTE',
    pago_em TIMESTAMP,
    transacao_externa_id VARCHAR(255),
    observacoes TEXT,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mercadopago_webhook_events (
    id BIGSERIAL PRIMARY KEY,
    event_key VARCHAR(255) NOT NULL,
    payment_id BIGINT NOT NULL,
    mp_status VARCHAR(50) NOT NULL,
    status_local VARCHAR(30) NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------
-- chat
-- ----------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    session_id VARCHAR(64) NOT NULL,
    role VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------
-- OS child tables
-- ----------------------------
CREATE TABLE IF NOT EXISTS servicos_os (
    id BIGSERIAL PRIMARY KEY,
    ordem_servico_id BIGINT NOT NULL,
    descricao TEXT NOT NULL,
    quantidade INTEGER NOT NULL DEFAULT 1,
    valor_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0,
    valor_total NUMERIC(10, 2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_servicos_os_ordem_servico
        FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id)
);

CREATE TABLE IF NOT EXISTS itens_os (
    id BIGSERIAL PRIMARY KEY,
    ordem_servico_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    nome_item VARCHAR(255) NOT NULL,
    codigo_item VARCHAR(255),
    quantidade INTEGER NOT NULL DEFAULT 1,
    valor_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0,
    valor_total NUMERIC(10, 2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_itens_os_ordem_servico
        FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id)
);

-- ----------------------------
-- estoque movimentos
-- ----------------------------
CREATE TABLE IF NOT EXISTS stock_movements (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    quantidade INTEGER NOT NULL,
    quantidade_anterior INTEGER NOT NULL,
    quantidade_posterior INTEGER NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    descricao TEXT,
    ordem_servico_id BIGINT,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_movements_stock_item
        FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
);

-- ----------------------------
-- financeiro
-- ----------------------------
CREATE TABLE IF NOT EXISTS transacoes_financeiras (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    categoria_id BIGINT,
    descricao TEXT NOT NULL,
    valor NUMERIC(12, 2) NOT NULL,
    referencia_tipo VARCHAR(255) DEFAULT 'MANUAL',
    referencia_id BIGINT,
    metodo_pagamento VARCHAR(255) DEFAULT 'DINHEIRO',
    data_movimentacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    estorno BOOLEAN DEFAULT FALSE,
    transacao_estornada_id BIGINT,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transacoes_financeiras_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias_financeiras(id)
);

CREATE TABLE IF NOT EXISTS fluxo_caixa (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    data DATE NOT NULL,
    total_entradas NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_saidas NUMERIC(12, 2) NOT NULL DEFAULT 0,
    saldo NUMERIC(12, 2) NOT NULL DEFAULT 0,
    saldo_acumulado NUMERIC(12, 2) NOT NULL DEFAULT 0,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_fluxo_caixa_usuario_data UNIQUE (usuario_id, data)
);

-- ----------------------------
-- indexes for critical queries
-- ----------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uk_mp_webhook_event_key
    ON mercadopago_webhook_events (event_key);

CREATE INDEX IF NOT EXISTS idx_assinaturas_usuario_status
    ON assinaturas (usuario_id, status);

CREATE INDEX IF NOT EXISTS idx_assinaturas_status_proxima_cobranca
    ON assinaturas (status, proxima_cobranca);

CREATE INDEX IF NOT EXISTS idx_pagamentos_usuario_criado_em
    ON pagamentos (usuario_id, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_pagamentos_usuario_status
    ON pagamentos (usuario_id, status);

CREATE INDEX IF NOT EXISTS idx_pagamentos_usuario_tipo
    ON pagamentos (usuario_id, tipo);

CREATE INDEX IF NOT EXISTS idx_pagamentos_referencia
    ON pagamentos (usuario_id, tipo, referencia_id);

CREATE INDEX IF NOT EXISTS idx_pagamentos_transacao_externa_id
    ON pagamentos (transacao_externa_id);

CREATE INDEX IF NOT EXISTS idx_ordens_servico_usuario_criado_em
    ON ordens_servico (usuario_id, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_ordens_servico_usuario_status
    ON ordens_servico (usuario_id, status);

CREATE INDEX IF NOT EXISTS idx_ordens_servico_usuario_placa
    ON ordens_servico (usuario_id, placa);

CREATE INDEX IF NOT EXISTS idx_servicos_os_ordem_servico_id
    ON servicos_os (ordem_servico_id);

CREATE INDEX IF NOT EXISTS idx_itens_os_ordem_servico_id
    ON itens_os (ordem_servico_id);

CREATE INDEX IF NOT EXISTS idx_itens_os_stock_item_id
    ON itens_os (stock_item_id);

CREATE INDEX IF NOT EXISTS idx_mecanicos_usuario_ativo_nome
    ON mecanicos (usuario_id, ativo, nome);

CREATE INDEX IF NOT EXISTS idx_stock_items_usuario_ativo_nome
    ON stock_items (usuario_id, ativo, nome);

CREATE INDEX IF NOT EXISTS idx_stock_items_usuario_categoria_ativo
    ON stock_items (usuario_id, categoria, ativo);

CREATE INDEX IF NOT EXISTS idx_stock_movements_usuario_criado_em
    ON stock_movements (usuario_id, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_stock_movements_stock_item_id
    ON stock_movements (stock_item_id);

CREATE INDEX IF NOT EXISTS idx_stock_movements_ordem_servico_id
    ON stock_movements (ordem_servico_id);

CREATE INDEX IF NOT EXISTS idx_categorias_financeiras_usuario_nome
    ON categorias_financeiras (usuario_id, nome);

CREATE INDEX IF NOT EXISTS idx_categorias_financeiras_sistema_tipo_nome
    ON categorias_financeiras (sistema, tipo, nome);

CREATE INDEX IF NOT EXISTS idx_transacoes_financeiras_usuario_data
    ON transacoes_financeiras (usuario_id, data_movimentacao DESC);

CREATE INDEX IF NOT EXISTS idx_transacoes_financeiras_usuario_tipo_data
    ON transacoes_financeiras (usuario_id, tipo, data_movimentacao DESC);

CREATE INDEX IF NOT EXISTS idx_transacoes_financeiras_referencia
    ON transacoes_financeiras (usuario_id, referencia_tipo, referencia_id, estorno);

CREATE INDEX IF NOT EXISTS idx_fluxo_caixa_usuario_data
    ON fluxo_caixa (usuario_id, data);

CREATE INDEX IF NOT EXISTS idx_chat_messages_usuario_session_criado_em
    ON chat_messages (usuario_id, session_id, criado_em DESC);

-- ----------------------------
-- audit_logs
-- ----------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    audit_id VARCHAR(64) NOT NULL UNIQUE,
    acao VARCHAR(100) NOT NULL,
    entidade VARCHAR(100) NOT NULL,
    entidade_id BIGINT,
    usuario_email VARCHAR(255),
    detalhes TEXT,
    ip_address VARCHAR(45),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_usuario_email
    ON audit_logs (usuario_email, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entidade_entidade_id
    ON audit_logs (entidade, entidade_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_criado_em
    ON audit_logs (criado_em DESC);
