# 🔧 OSMECH - Sistema de Gestão para Oficinas Mecânicas

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Java](https://img.shields.io/badge/Java-17-orange.svg)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.1-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Latest-blue.svg)

Sistema SaaS completo para gestão de Ordens de Serviço em oficinas mecânicas, com automação via WhatsApp, integração com IA e modelo de assinatura mensal.

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Funcionalidades](#funcionalidades)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Execução](#execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [API Endpoints](#api-endpoints)
- [Planos de Assinatura](#planos-de-assinatura)
- [Próximos Passos](#próximos-passos)
- [Licença](#licença)

---

## 🎯 Sobre o Projeto

O **OSMECH** é uma solução SaaS desenvolvida para modernizar a gestão de oficinas mecânicas de pequeno e médio porte. O sistema oferece:

- ✅ Gestão completa de Ordens de Serviço
- ✅ Autenticação segura com JWT
- ✅ Modelo de assinatura mensal (SaaS)
- ✅ Interface mobile-first com Flutter
- ✅ API REST robusta com Spring Boot
- 🚧 Integração com WhatsApp (em desenvolvimento)
- 🚧 Assistente com IA (em desenvolvimento)

**Público-alvo:** Oficinas mecânicas que buscam digitalização e automação.

**Modelo de negócio:** Assinatura mensal com 3 planos (PRO, PRO+, PREMIUM).

---

## 🛠️ Tecnologias

### Backend
- **Java 17**
- **Spring Boot 3.2.1**
  - Spring Security (JWT)
  - Spring Data JPA
  - Spring Web
- **PostgreSQL**
- **Maven**
- **JWT (io.jsonwebtoken)**
- **Lombok**

### Frontend
- **Flutter 3.0+**
- **Dart**
- **Provider** (State Management)
- **HTTP** (API Client)
- **Shared Preferences** (Storage Local)

### Infraestrutura
- PostgreSQL (porta 5432)
- Backend API REST (porta 8080)
- CORS configurado para desenvolvimento local

---

## 🏗️ Arquitetura

### Backend - Camadas

```
com.osmech/
├── auth/               # Autenticação JWT
├── config/             # Configurações (Security, CORS)
├── user/               # Gestão de usuários
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
├── os/                 # Ordens de Serviço
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
└── plan/               # Planos de assinatura
    ├── controller/
    ├── service/
    ├── repository/
    ├── entity/
    └── dto/
```

### Frontend - Estrutura

```
lib/
├── main.dart
├── pages/              # Telas da aplicação
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── dashboard_page.dart
│   ├── pricing_page.dart
│   └── service_orders_page.dart
├── services/           # Comunicação com API
│   ├── auth_service.dart
│   └── service_order_service.dart
├── models/             # Modelos de dados
│   ├── user.dart
│   └── service_order.dart
└── widgets/            # Componentes reutilizáveis
```

---

## 🚀 Funcionalidades

### ✅ Implementadas

- [x] Sistema de autenticação com JWT
- [x] Registro e login de usuários
- [x] Gestão de planos de assinatura
- [x] CRUD completo de Ordens de Serviço
- [x] Dashboard com menu principal
- [x] Tela de visualização de planos
- [x] Interface mobile responsiva
- [x] Associação de usuários a planos
- [x] Controle de status de OS (7 estados)
- [x] Validações de formulário

### 🚧 Em Desenvolvimento

- [ ] Integração com WhatsApp (Twilio/Meta)
- [ ] Assistente com IA (OpenAI)
- [ ] Gateway de pagamento (PIX/Cartão)
- [ ] Relatórios e dashboards analíticos
- [ ] Sistema de notificações
- [ ] Gestão de clientes
- [ ] Gestão de veículos
- [ ] Histórico de manutenções

---

## 📦 Pré-requisitos

Antes de começar, você precisa ter instalado:

- **Java JDK 17+**
- **Maven 3.8+**
- **PostgreSQL 14+**
- **Flutter 3.0+**
- **Git**

---

## ⚙️ Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/marcio1fs/osmech.git
cd osmech
```

### 2. Configure o PostgreSQL

Crie o banco de dados:

```sql
CREATE DATABASE oficina_db;
CREATE USER postgres WITH PASSWORD '3782';
GRANT ALL PRIVILEGES ON DATABASE oficina_db TO postgres;
```

### 3. Backend - Instale dependências

```bash
cd backend
mvn clean install
```

### 4. Frontend - Instale dependências

```bash
cd ../frontend
flutter pub get
```

---

## 🔧 Configuração

### Backend - application.yml

O arquivo está em: `backend/src/main/resources/application.yml`

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/oficina_db
    username: postgres
    password: 3782

jwt:
  secret: sua-chave-secreta-aqui
  expiration: 86400000  # 24 horas
```

⚠️ **IMPORTANTE:** Em produção, use variáveis de ambiente para credenciais sensíveis!

### Frontend - API URL

O arquivo está em: `frontend/lib/services/auth_service.dart`

```dart
static const String baseUrl = 'http://localhost:8080/api';
```

Para produção, altere para a URL do seu servidor.

---

## ▶️ Execução

### 1. Inicie o PostgreSQL

```bash
# Linux/Mac
sudo service postgresql start

# Windows
# Use o pgAdmin ou inicie manualmente
```

### 2. Execute o Backend

```bash
cd backend
mvn spring-boot:run
```

O backend estará disponível em: `http://localhost:8080`

### 3. Execute o Frontend

```bash
cd frontend
flutter run
```

Ou para web:
```bash
flutter run -d chrome
```

---

## 📂 Estrutura do Projeto

```
osmech/
├── backend/
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/osmech/
│       │   ├── OsmechApplication.java
│       │   ├── auth/
│       │   │   ├── JwtService.java
│       │   │   └── JwtAuthenticationFilter.java
│       │   ├── config/
│       │   │   ├── SecurityConfig.java
│       │   │   └── ApplicationConfig.java
│       │   ├── user/
│       │   ├── os/
│       │   └── plan/
│       └── resources/
│           ├── application.yml
│           └── data.sql
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── pages/
│   │   ├── services/
│   │   ├── models/
│   │   └── widgets/
│   └── pubspec.yaml
│
└── README.md
```

---

## 🔌 API Endpoints

### Autenticação

| Método | Endpoint | Descrição | Auth |
|--------|----------|-----------|------|
| POST | `/api/auth/register` | Registra novo usuário | Não |
| POST | `/api/auth/login` | Autentica usuário | Não |

**Exemplo de Request (Login):**
```json
{
  "email": "usuario@email.com",
  "password": "senha123"
}
```

**Exemplo de Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "userId": 1,
  "email": "usuario@email.com",
  "name": "Nome do Usuário",
  "role": "OFICINA",
  "plan": {
    "id": 1,
    "name": "PRO",
    "subscriptionEnd": "2026-02-21T00:00:00"
  }
}
```

### Planos

| Método | Endpoint | Descrição | Auth |
|--------|----------|-----------|------|
| GET | `/api/plans` | Lista planos ativos | Não |
| GET | `/api/plans/{id}` | Busca plano por ID | Não |

### Ordens de Serviço

| Método | Endpoint | Descrição | Auth |
|--------|----------|-----------|------|
| GET | `/api/service-orders` | Lista OS do usuário | Sim |
| POST | `/api/service-orders` | Cria nova OS | Sim |
| GET | `/api/service-orders/{id}` | Busca OS por ID | Sim |
| PUT | `/api/service-orders/{id}` | Atualiza OS | Sim |
| DELETE | `/api/service-orders/{id}` | Deleta OS | Sim |

**Exemplo de Request (Criar OS):**
```json
{
  "customerName": "João Silva",
  "customerPhone": "(11) 98765-4321",
  "customerEmail": "joao@email.com",
  "vehiclePlate": "ABC-1234",
  "vehicleBrand": "Honda",
  "vehicleModel": "Civic",
  "vehicleYear": "2020",
  "description": "Troca de óleo e filtro",
  "estimatedCost": 250.00
}
```

### Autenticação JWT

Para rotas protegidas, inclua o header:
```
Authorization: Bearer {seu-token-aqui}
```

---

## 💳 Planos de Assinatura

### PRO - R$ 49,90/mês
- ✅ Até 50 OS/mês
- ✅ 1 usuário
- ✅ Suporte por email
- ✅ Relatórios básicos

### PRO+ - R$ 79,90/mês (MAIS POPULAR)
- ✅ Até 150 OS/mês
- ✅ Até 3 usuários
- ✅ WhatsApp integrado
- ✅ Suporte prioritário
- ✅ Relatórios avançados

### PREMIUM - R$ 149,90/mês
- ✅ OS ilimitadas
- ✅ Até 10 usuários
- ✅ WhatsApp + IA integrados
- ✅ Suporte 24/7
- ✅ Relatórios personalizados
- ✅ API para integrações

---

## 🎯 Próximos Passos

### Fase 1 - Funcionalidades Core (Atual)
- [x] Estrutura base do projeto
- [x] Autenticação JWT
- [x] CRUD de Ordens de Serviço
- [x] Sistema de planos

### Fase 2 - Expansão de Recursos
- [ ] Gestão completa de clientes
- [ ] Gestão completa de veículos
- [ ] Histórico de manutenções por veículo
- [ ] Sistema de peças e estoque
- [ ] Geração de PDF (OS)

### Fase 3 - Automação
- [ ] Integração WhatsApp (Twilio/Meta Cloud API)
- [ ] Mensagens automáticas (status de OS)
- [ ] Chatbot com IA (OpenAI)
- [ ] Lembretes automáticos

### Fase 4 - Pagamentos e SaaS
- [ ] Gateway de pagamento (Stripe/MercadoPago)
- [ ] Cobrança recorrente
- [ ] Sistema de upgrade/downgrade de planos
- [ ] Dashboard financeiro

### Fase 5 - Analytics e IA
- [ ] Dashboard analítico completo
- [ ] Diagnóstico assistido por IA
- [ ] Previsão de custos
- [ ] Relatórios inteligentes

### Fase 6 - Escalabilidade
- [ ] Deploy em cloud (AWS/Azure/GCP)
- [ ] CI/CD pipeline
- [ ] Testes automatizados
- [ ] Monitoramento e logs

---

## 🔐 Segurança

- ✅ Senhas criptografadas com BCrypt
- ✅ Autenticação JWT com expiração
- ✅ CORS configurado
- ✅ Validações de entrada
- ✅ Proteção contra SQL Injection (JPA)
- ⚠️ **TODO:** Rate limiting
- ⚠️ **TODO:** HTTPS em produção

---

## 🧪 Testes

### Backend
```bash
cd backend
mvn test
```

### Frontend
```bash
cd frontend
flutter test
```

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

---

## 👥 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 📧 Contato

**Desenvolvedor:** Márcio Ferreira  
**GitHub:** [@marcio1fs](https://github.com/marcio1fs)  
**Repositório:** [osmech](https://github.com/marcio1fs/osmech)

---

## ⭐ Agradecimentos

Obrigado por conferir o OSMECH! Se este projeto foi útil, deixe uma ⭐ no repositório!

---

**Feito com ❤️ e ☕ usando Spring Boot + Flutter**
