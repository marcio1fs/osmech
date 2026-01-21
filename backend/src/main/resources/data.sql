-- Script de inicialização dos planos do OSMECH
-- Executar após a criação das tabelas

-- Limpa dados existentes (apenas em desenvolvimento)
DELETE FROM plans;

-- Insere os planos do sistema
INSERT INTO plans (id, name, price, max_service_orders, whatsapp_enabled, ai_enabled, max_users, description, active) 
VALUES 
(1, 'PRO', 49.90, 50, false, false, 1, 'Plano ideal para oficinas iniciantes. Até 50 OS/mês, 1 usuário.', true),
(2, 'PRO+', 79.90, 150, true, false, 3, 'Plano intermediário com WhatsApp. Até 150 OS/mês, até 3 usuários.', true),
(3, 'PREMIUM', 149.90, null, true, true, 10, 'Plano completo com IA e WhatsApp. OS ilimitadas, até 10 usuários.', true);

-- Reseta a sequence do ID
ALTER SEQUENCE plans_id_seq RESTART WITH 4;
