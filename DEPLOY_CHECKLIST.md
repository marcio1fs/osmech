# OSMECH - Deploy Checklist

## 1) Perfis de execucao

- `dev`: desenvolvimento local
- `prod`: producao

Defina o perfil ativo:

```powershell
$env:SPRING_PROFILES_ACTIVE="prod"
```

## 2) Variaveis obrigatorias (producao)

### Banco

- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`

### JWT

- `JWT_SECRET`
- `JWT_EXPIRATION` (opcional, default 86400000)

### CORS

- `CORS_ORIGINS`

### Mercado Pago

- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_PUBLIC_KEY`
- `MERCADOPAGO_SUCCESS_URL`
- `MERCADOPAGO_PENDING_URL`
- `MERCADOPAGO_FAILURE_URL`
- `MERCADOPAGO_NOTIFICATION_URL`
- `MERCADOPAGO_WEBHOOK_SECRET`

### Flyway

- `FLYWAY_ENABLED` (recomendado `true`)
- `FLYWAY_BASELINE_ON_MIGRATE` (recomendado `true`)
- `FLYWAY_BASELINE_VERSION` (recomendado `1`)

## 3) Backend (Spring Boot)

Na pasta `backend`:

```powershell
mvn clean package
mvn spring-boot:run
```

Ou sem entrar na pasta:

```powershell
mvn -f backend\pom.xml clean package
mvn -f backend\pom.xml spring-boot:run
```

## 4) Frontend (Flutter Web)

Na pasta `frontend`:

```powershell
flutter pub get
flutter build web --release --dart-define=API_URL=https://SEU_BACKEND
```

Para desenvolvimento local:

```powershell
flutter run -d chrome --web-port 8083 --dart-define=API_URL=http://localhost:8081
```

## 5) Validacoes antes de publicar

- Backend compila: `mvn -f backend\pom.xml -DskipTests compile`
- Frontend builda: `flutter build web --release ...`
- Flyway sobe schema base em banco vazio (migração `V1__init_schema.sql`)
- Webhook Mercado Pago responde 200 para notificacoes validas
- Pagamento aprovado atualiza:
  - `pagamentos.status = PAGO`
  - `assinaturas.status = ACTIVE`
  - `usuarios.plano` e `usuarios.ativo`

## 6) Observacoes importantes

- Nao versionar segredos em arquivo.
- Em `prod`, manter `ddl-auto=validate` e migracoes via Flyway.
- Use HTTPS no backend e nas URLs do Mercado Pago.
