# OSMECH - Sistema de Ordens de Serviço para Oficinas Mecânicas

Sistema SaaS de controle de Ordens de Serviço para oficinas mecânicas, com automação via WhatsApp, inteligência artificial e modelo de assinatura mensal.

## Tecnologias

| Camada    | Tecnologia           |
|-----------|---------------------|
| Frontend  | Flutter (mobile-first) |
| Backend   | Spring Boot 3.2      |
| Banco     | PostgreSQL           |
| Auth      | JWT (JJWT)           |
| Segurança | Spring Security      |

## Estrutura do Projeto

```
osmech/
├── backend/           → API Spring Boot
│   ├── pom.xml
│   └── src/main/java/com/osmech/
│       ├── auth/      → Autenticação (login/cadastro)
│       ├── config/    → Segurança, CORS, DataSeeder
│       ├── os/        → Ordens de Serviço (CRUD)
│       ├── plan/      → Planos de assinatura
│       ├── security/  → JWT (filtro, utilidades)
│       └── user/      → Entidade Usuário
│
└── frontend/          → App Flutter
    └── lib/
        ├── pages/     → Telas (Login, Cadastro, Dashboard, OS, Planos)
        ├── services/  → Serviços HTTP (auth, OS)
        └── main.dart  → Entrada do app
```

## Configuração

### Pré-requisitos
- Java 17+
- Maven 3.8+
- PostgreSQL 14+
- Flutter 3.16+

### Banco de Dados

1. Crie o banco no PostgreSQL:
```sql
CREATE DATABASE oficina_db;
```

2. Configuração em `backend/src/main/resources/application.yml`:
- Host: `localhost`
- Porta: `5432`
- Banco: `oficina_db`
- Usuário: `postgres`
- Senha: `3782`

### Backend

```bash
cd backend
mvn clean install
mvn spring-boot:run
```

O servidor inicia na porta **8080**.

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

> Para emulador Android, a API aponta para `10.0.2.2:8080`.
> Para dispositivo físico, altere o IP em `lib/services/api_config.dart`.

## API Endpoints

### Autenticação (público)
| Método | Rota               | Descrição       |
|--------|-------------------|-----------------|
| POST   | /api/auth/register | Cadastro        |
| POST   | /api/auth/login    | Login           |

### Ordens de Serviço (JWT obrigatório)
| Método | Rota              | Descrição       |
|--------|------------------|-----------------|
| GET    | /api/os           | Listar OS       |
| GET    | /api/os/{id}      | Buscar OS       |
| POST   | /api/os           | Criar OS        |
| PUT    | /api/os/{id}      | Atualizar OS    |
| DELETE | /api/os/{id}      | Excluir OS      |
| GET    | /api/os/dashboard | Dashboard stats |

### Planos (público)
| Método | Rota                | Descrição            |
|--------|--------------------|--------------------- |
| GET    | /api/planos         | Listar planos        |
| GET    | /api/planos/{codigo}| Buscar por código    |

## Planos de Assinatura

| Plano   | Preço      | OS/mês | WhatsApp | IA  |
|---------|-----------|--------|----------|-----|
| PRO     | R$ 49,90  | 50     | Não      | Não |
| PRO+    | R$ 79,90  | 200    | Sim      | Não |
| PREMIUM | R$ 149,90 | Ilimitado | Sim   | Sim |

## Roadmap

- [x] Autenticação JWT (login/cadastro)
- [x] CRUD de Ordens de Serviço
- [x] Dashboard com estatísticas
- [x] Tela de Planos (pricing)
- [x] Seed automático de planos
- [ ] Integração WhatsApp (Twilio / Meta)
- [ ] IA para diagnóstico e atendimento
- [ ] Pagamento (PIX / Cartão)
- [ ] Controle de limites por plano
- [ ] Painel Admin

## Licença

Projeto proprietário — todos os direitos reservados.
