# Staging Runbook

## .env (staging)
Coloque em `backend/.env` no servidor de staging:
```
SPRING_PROFILES_ACTIVE=prod
PORT=8081
DB_URL=jdbc:postgresql://<host>:5432/osmech_stg
DB_USERNAME=osmech
DB_PASSWORD=CHANGE_ME
JPA_DDL_AUTO=validate

FLYWAY_ENABLED=true
FLYWAY_BASELINE_ON_MIGRATE=true
FLYWAY_BASELINE_VERSION=1

JWT_SECRET=CHANGE_ME_MIN_32_BYTES
JWT_EXPIRATION=86400000

CORS_ORIGINS=https://stg.osmech.app,https://app-stg.osmech.com

MERCADOPAGO_ACCESS_TOKEN=CHANGE_ME
MERCADOPAGO_PUBLIC_KEY=CHANGE_ME
MERCADOPAGO_SUCCESS_URL=https://stg.osmech.app/assinatura/sucesso
MERCADOPAGO_PENDING_URL=https://stg.osmech.app/assinatura/pendente
MERCADOPAGO_FAILURE_URL=https://stg.osmech.app/assinatura/falha
MERCADOPAGO_NOTIFICATION_URL=https://stg-api.osmech.com/api/mercadopago/webhook
MERCADOPAGO_WEBHOOK_SECRET=CHANGE_ME

WHATSAPP_ENABLED=false
AI_ENABLED=false
```

## Subir backend (staging)
- `cd backend`
- `mvn clean package`
- `java -jar target/osmech-backend-0.1.0.jar`
- Validar logs: Flyway aplica `V1__init_schema`…`V4__...`; sem erros.
- Health: `GET http://<host>:8081/actuator/health` deve retornar 200.

## Subir frontend (staging)
- `cd frontend`
- `flutter build web --release --dart-define=API_URL=https://stg-api.osmech.com`
- Publicar conteúdo de `frontend/build/web` (nginx/S3/CloudFront).

## Smoke rápido
- Registro/login via UI.
- Criar OS, encerrar com pagamento (qualquer método) e ver recibo.
- Verificar financeiro: entrada criada.
- Webhook Mercado Pago: `POST https://stg-api.osmech.com/api/mercadopago/webhook` com payload de teste; deve retornar 200/401 conforme secret configurado.
