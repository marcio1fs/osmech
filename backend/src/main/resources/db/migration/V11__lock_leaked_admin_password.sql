-- ============================================================
-- V11 - Segurança: neutraliza a senha do admin exposta no Git
-- ============================================================
-- O hash BCrypt de V10 está publicamente conhecido no repositório.
-- Esta migração substitui esse hash por um marcador inválido
-- (nenhuma senha autentica contra ele). O AdminBootstrap (Java)
-- redefine a senha no boot quando ADMIN_INITIAL_PASSWORD está
-- definida no ambiente — inclusive em ambientes sem Flyway.

UPDATE usuarios
SET senha = 'LOCKED_LEAKED_SEED_PASSWORD'
WHERE email = 'marciofs426@gmail.com'
  AND senha = '$2b$12$j2enNOrCVwZuTL7SjkRyHObX5YU9nNv7sDR5qUttiEArgtvNKjkzK';

-- Índices para os fluxos de verificação de e-mail e recuperação de senha (V7)
CREATE INDEX IF NOT EXISTS idx_usuarios_verification_token
    ON usuarios (verification_token);

CREATE INDEX IF NOT EXISTS idx_usuarios_reset_password_token
    ON usuarios (reset_password_token);
