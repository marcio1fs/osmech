-- Tabela de usuários (oficinas)
CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    nome_oficina VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para busca rápida por email
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- Tabela de clientes
CREATE TABLE clientes (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    usuario_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Índice para busca rápida por usuário
CREATE INDEX idx_clientes_usuario_id ON clientes(usuario_id);

-- Tabela de veículos
CREATE TABLE veiculos (
    id BIGSERIAL PRIMARY KEY,
    placa VARCHAR(20) NOT NULL,
    modelo VARCHAR(255) NOT NULL,
    cliente_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_veiculos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

-- Índice para busca rápida por cliente
CREATE INDEX idx_veiculos_cliente_id ON veiculos(cliente_id);

-- Tabela de ordens de serviço
CREATE TABLE ordens_servico (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    veiculo_id BIGINT NOT NULL,
    usuario_id BIGINT NOT NULL,
    descricao_problema TEXT NOT NULL,
    servicos_realizados TEXT,
    valor DECIMAL(10, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'ABERTA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_os_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    CONSTRAINT fk_os_veiculo FOREIGN KEY (veiculo_id) REFERENCES veiculos(id) ON DELETE CASCADE,
    CONSTRAINT fk_os_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Índices para performance
CREATE INDEX idx_os_usuario_id ON ordens_servico(usuario_id);
CREATE INDEX idx_os_status ON ordens_servico(status);
CREATE INDEX idx_os_created_at ON ordens_servico(created_at DESC);
CREATE INDEX idx_os_usuario_status ON ordens_servico(usuario_id, status);
