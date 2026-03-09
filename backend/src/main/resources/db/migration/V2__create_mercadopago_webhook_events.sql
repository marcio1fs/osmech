CREATE TABLE IF NOT EXISTS mercadopago_webhook_events (
    id BIGSERIAL PRIMARY KEY,
    event_key VARCHAR(255) NOT NULL,
    payment_id BIGINT NOT NULL,
    mp_status VARCHAR(50) NOT NULL,
    status_local VARCHAR(30) NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_mp_webhook_event_key
    ON mercadopago_webhook_events (event_key);
