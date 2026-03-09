# OSMECH - Sistema de Ordens de Servico para Oficinas Mecanicas

Sistema SaaS para controle de Ordens de Servico, estoque, financeiro e assinaturas.

## Stack

- Backend: Spring Boot 3.2 (Java 17)
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

## Frontend local (dev)

```powershell
cd frontend
flutter pub get
flutter run -d web-server --web-port 8083 --dart-define=API_URL=http://localhost:8081/api
```

Opcional (debug no Chrome):

```powershell
flutter run -d chrome --web-port 8083 --dart-define=API_URL=http://localhost:8081/api
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
flutter build web --release --dart-define=API_URL=https://SEU_BACKEND/api
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
