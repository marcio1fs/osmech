# Copilot Instructions for OSMECH

## Visão Geral
- OSMECH é um sistema de gestão para oficinas mecânicas, composto por um backend Java (Spring Boot) e um frontend Flutter.
- O backend está em `/backend` e o frontend em `/frontend`.

## Arquitetura
- **Backend:**
  - Estruturado em módulos: `auth`, `config`, `integration`, `os`, `plan`, `user`.
  - Usa Spring Boot 3, JPA, JWT, e integrações externas (ex: Twilio para WhatsApp).
  - Entrypoint: [`OsmechApplication.java`](../backend/src/main/java/com/osmech/OsmechApplication.java)
  - Serviços de integração (ex: WhatsApp) ficam em [`integration/`](../backend/src/main/java/com/osmech/integration/).
  - Controllers REST em cada domínio, ex: [`OrdemServicoController`](../backend/src/main/java/com/osmech/os/OrdemServicoController.java).
  - Configurações sensíveis (Twilio, DB) via `application.yml`.
- **Frontend:**
  - Estruturado em páginas e serviços (`lib/pages`, `lib/services`).
  - Comunicação HTTP com backend, autenticação JWT.
  - Entrypoint: [`main.dart`](../frontend/lib/main.dart)

## Fluxos de Desenvolvimento
- **Build Backend:**
  - Use Maven: `cd backend && ./mvnw spring-boot:run` ou `mvn spring-boot:run`.
- **Build Frontend:**
  - Use Flutter: `cd frontend && flutter run`.
- **Variáveis sensíveis:**
  - Configure credenciais (Twilio, DB) em `backend/src/main/resources/application.yml`.
- **Testes:**
  - Não há testes automatizados detectados. Siga padrões Spring Boot para adicionar.

## Padrões e Convenções
- Controllers usam `@RestController` e endpoints `/api/{domínio}`.
- Serviços de integração (ex: WhatsApp) sempre logam tentativas em entidades JPA (`WhatsAppLog`).
- DTOs são usados para comunicação entre frontend e backend.
- Autenticação JWT obrigatória para quase todos endpoints (exceto `/api/auth/**`).
- O frontend espera respostas JSON e tokens JWT.

## Integrações e Pontos Críticos
- **Twilio WhatsApp:**
  - Serviço: [`TwilioWhatsAppService`](../backend/src/main/java/com/osmech/integration/TwilioWhatsAppService.java)
  - Templates de mensagem configurados via `application.yml`.
  - Logs de envio em [`WhatsAppLog`](../backend/src/main/java/com/osmech/integration/WhatsAppLog.java).
- **Banco de Dados:**
  - PostgreSQL, configurado em `application.yml`.
- **Autenticação:**
  - JWT, implementado em `auth/` e `SecurityConfig.java`.

## Exemplos de Arquivos-Chave
- Backend: `OsmechApplication.java`, `OrdemServicoController.java`, `TwilioWhatsAppService.java`, `WhatsAppLog.java`
- Frontend: `main.dart`, `auth_service.dart`, `os_service.dart`

## Observações
- Siga a estrutura de pacotes existente ao criar novos módulos.
- Sempre registre logs de integrações externas.
- Atualize `application.yml` para novas integrações/configurações.
