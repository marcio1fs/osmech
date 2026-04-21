# OSMECH - Sistema de Ordens de Servico para Oficinas Mecanicas

Sistema SaaS para controle de Ordens de Servico, estoque, financeiro e assinaturas.

## Stack

- Backend: Spring Boot 3.2 (Java 21)
- Frontend: Flutter Web
- Banco: PostgreSQL
- Auth: JWT
- Pagamentos: Mercado Pago (Checkout Pro)

## Estrutura

```text
osmech/
|- backend/    # API Spring Boot
|- frontend/   # App Flutter Web
|- DEPLOY_CHECKLIST.md
```

## Portas padrao

- Backend: `8081`
- Frontend Web (dev): `8083`

## Backend local (dev)

```powershell
cd backend
$env:SPRING_PROFILES_ACTIVE="dev"
mvn spring-boot:run
```

Atalho com `.env`:

```powershell
cd backend
.\run-dev.ps1
```

Nota sobre Vault:

- Em dev, o Vault fica desativado por padrao com `SPRING_CLOUD_VAULT_ENABLED=false` (definido no `.env`).
- Se quiser usar Vault local, habilite e configure `VAULT_TOKEN` e `VAULT_URI`.

## Rodar tudo (backend + frontend)

Modo padrao:

```powershell
.\run-dev.ps1
```

Modo com API customizada:

```powershell
.\run-dev-custom-api.ps1 -ApiUrl http://127.0.0.1:8081
```

Com Chrome:

```powershell
.\run-dev-custom-api.ps1 -ApiUrl http://127.0.0.1:8081 -UseChrome
```

## Frontend local (dev)

```powershell
cd frontend
flutter pub get
flutter run -d web-server --web-port 8083 --dart-define=API_URL=http://127.0.0.1:8081
```

Opcional (debug no Chrome):

```powershell
flutter run -d chrome --web-port 8083 --dart-define=API_URL=http://127.0.0.1:8081
```

## Build de producao

### Backend

```powershell
cd backend
mvn clean package
```

### Frontend

```powershell
cd frontend
flutter build web --release --dart-define=API_URL=https://SEU_BACKEND
```

## Perfis de ambiente

- `application.yml`: base
- `application-dev.yml`: defaults locais para desenvolvimento
- `application-prod.yml`: configuracao segura para producao

## Deploy

Use o checklist completo em:

- `DEPLOY_CHECKLIST.md`
- `backend/.env.example`
- `frontend/.env.example`

Ele inclui:
- variaveis obrigatorias
- regras de seguranca
- comandos de subida
- validacoes pre-publicacao

## Observacoes

- Nao versionar segredos.
- Em producao, usar `SPRING_PROFILES_ACTIVE=prod`.
- Em producao, manter schema via Flyway e `ddl-auto=validate`.

## Troubleshooting rapido

Verificar se o backend esta de pe:

```text
http://127.0.0.1:8081/api/actuator/health
```

Erros comuns:

- `ERR_CONNECTION_REFUSED`: backend nao esta rodando ou porta errada.
- `Could not resolve placeholder 'JWT_SECRET'`: variavel `JWT_SECRET` nao carregada no ambiente.
- `Cannot create authentication mechanism for TOKEN`: Vault habilitado sem token (desative com `SPRING_CLOUD_VAULT_ENABLED=false` no dev).
