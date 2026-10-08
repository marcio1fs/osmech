-- ============================================================
-- V21 - Configuração de WhatsApp Z-API por Oficina (Tenant)
-- ============================================================

ALTER TABLE oficinas
    ADD COLUMN IF NOT EXISTS whatsapp_provider VARCHAR(50) DEFAULT 'ZAPI',
    ADD COLUMN IF NOT EXISTS zapi_instance_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS zapi_token VARCHAR(100),
    ADD COLUMN IF NOT EXISTS zapi_client_token VARCHAR(100),
    ADD COLUMN IF NOT EXISTS whatsapp_ativo BOOLEAN DEFAULT FALSE;
