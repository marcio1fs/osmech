-- ============================================================
-- V14 - Permissões Customizadas por Usuário (RBAC Granular)
-- ============================================================

CREATE TABLE IF NOT EXISTS usuario_permissions (
    usuario_id      BIGINT       NOT NULL,
    permission_code VARCHAR(100) NOT NULL,
    PRIMARY KEY (usuario_id, permission_code),
    CONSTRAINT fk_up_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_up_permission FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_usuario_permissions_usuario ON usuario_permissions(usuario_id);
