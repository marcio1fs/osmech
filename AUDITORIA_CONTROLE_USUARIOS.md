# OSMECH — Auditoria do Projeto e Plano de Controle de Usuários

**Data:** 28/09/2026
**Escopo:** Backend (Spring Boot 3.2 / Java 21), Frontend (Flutter Web), schema PostgreSQL (Flyway V1–V10)
**Foco:** estado atual da autenticação/autorização e melhor arquitetura para **controle de usuários** (multi-usuário por oficina)

> ✅ **STATUS — Fases 0 e 1 IMPLEMENTADAS (28/09/2026).** Resumo das entregas na seção 5 ao final.

---

## 1. Resumo executivo

O projeto já possui uma base de segurança razoável: JWT stateless, BCrypt, rate limiting em login, CORS por perfil, entrypoint 401/403 separados, auditoria genérica (`AuditService`) e isolamento de dados por `usuario_id` em todas as tabelas de negócio.

Porém, o **controle de usuários está incompleto e inconsistente**:

- O sistema trata **1 usuário = 1 oficina**. Não existe forma de uma oficina ter mecânicos/atendentes com logins próprios — o dono compartilha a única conta, o que elimina a rastreabilidade individual.
- O schema **já antecipa multi-usuário** (`planos.limite_usuarios` = 1/3/6/15 criado na V6 e populado na V8), mas **nenhuma linha de Java usa esse limite** — a entidade `Plano` nem sequer mapeia o campo.
- Verificação de e-mail, esqueci/resetar senha: **telas Flutter + endpoints existem, mas o service lança `UnsupportedOperationException`** ("modo local rápido"). As colunas da V7 (`email_verificado`, `verification_token`…) existem no banco mas não são mapeadas na entidade `Usuario`.
- A senha do ADMIN seeded (V10) tem hash BCrypt **versionado no Git** — credencial efetivamente pública.

| Área | Nota | Comentário |
|---|---|---|
| Autenticação (login/JWT) | 🟡 Boa base | Falta refresh token; role no JWT fica até 24h desatualizada |
| Autorização (RBAC) | 🔴 Quase inexistente | Só `AdminController` usa `@PreAuthorize`; 2 roles apenas |
| Multi-usuário por oficina | 🔴 Ausente | Schema sugere a intenção (`limite_usuarios`), código ignora |
| Verificação de e-mail / reset | 🔴 Desligado | Frontend pronto, backend lança exceção |
| Isolamento de tenant | 🟢 Funcional | Por `usuario_id`; vai precisar migrar para `oficina_id` |
| Gestão pelo ADMIN | 🟡 Mínima | Dashboard lista tudo sem paginação nem ações |
| Auditoria | 🟡 Estrutura existe | Registra só e-mail do dono da conta (sem ator individual) |

---

## 2. Como funciona hoje

```
 Usuario (1 = oficina inteira)
   ├─ role: "ADMIN" | "OFICINA"      ← String solta, sem enum
   ├─ plano: "FREE" | "PRO" | ...    ← String solta, dessincronizável com tabela planos
   └─ é o TENANT: ordens_servico.usuario_id, stock_items.usuario_id,
      mecanicos.usuario_id, transacoes_financeiras.usuario_id, etc.

 Login → JWT { sub: email, role: "OFICINA", exp: 24h }
 Request → JwtAuthFilter → findByEmail(email)  ← 1 query extra POR request
 Services → cada um faz getUsuario(email) de novo (N+1 lookups por request)
```

**Pontos fortes encontrados**
1. `JwtAuthFilter` valida que o usuário **existe e está ativo** a cada request (inativação tem efeito imediato).
2. Rate limit dedicado a login/register: 5/min e 15/15min por IP (`RateLimitFilter`), mais 60 req/min geral; versão Redis para multi-instância.
3. `SecurityConfig` correto para API stateless: CSRF off, 401 vs 403 distintos, CORS restrito por perfil (dev usa patterns, prod lista explícita).
4. Senha com BCrypt + `@Size(min=8)` no backend.
5. Plan enforcement existe para **OS/mês** (`verificarLimitePlano`) — modelo a repetir para usuários.

**Problemas e riscos (ordenados por severidade)**

| # | Severidade | Problema | Evidência |
|---|---|---|---|
| 1 | 🔴 Crítica | Sem multi-usuário: oficina inteira divide 1 login; `limite_usuarios` do plano nunca é cobrado | `Plano.java` não mapeia o campo; nenhum service o consulta |
| 2 | 🔴 Alta | Hash da senha do ADMIN publicado no repositório | `V10__seed_admin_user.sql` |
| 3 | 🔴 Alta | Reset de senha e verificação de e-mail derrubam o request com exceção | `AuthService.forgotPassword/resetPassword/verifyEmail` |
| 4 | 🟠 Média | `role`/`plano` como `String` livre — typo vira falha de autorização silenciosa | `Usuario.role`, `AuthService.register` |
| 5 | 🟠 Média | Role embutida no JWT fica defasada até 24h após mudança (sem refresh nem invalidação) | `JwtUtil.generateToken`, `JwtAuthFilter` (lê role do token, não do banco) |
| 6 | 🟠 Média | 1 lookup de usuário por request no filtro + 1 por service (sem cache) | `JwtAuthFilter`, `getUsuario(email)` em todos os services |
| 7 | 🟠 Média | JWT sem `userId`/`oficinaId`: toda autorização transita por e-mail (subject) | `JwtUtil` |
| 8 | 🟠 Média | `AdminController` lista todos os usuários sem paginação e não permite nenhuma ação (ativar/inativar, trocar plano/role) | `AdminController` |
| 9 | 🟡 Baixa | Sem logout/revogação server-side (ok para stateless, mas audit-logs e inativação são as únicas mitigações) | — |
| 10 | 🟡 Baixa | Audit log registra apenas `usuario_email` (dono), impossível saber qual funcionário fez a ação | `AuditLog.usuarioEmail` |

> Observação: já existem três relatórios (`AUDIT_REPORT.md`, `SECURITY_AUDIT_REPORT.md`, `SECURITY_VULNERABILITY_REPORT.md`) com achados gerais (CORS, ddl-auto, webhook MP sem assinatura obrigatória etc.). Este documento foca exclusivamente no **controle de usuários** e não os substitui.

---

## 3. A melhor maneira de implementar o controle de usuários

### Decisão de arquitetura

O próprio schema já aponta a direção: planos limitam **usuários por oficina** (BÁSICO=3, PRO=6, PRO+=15). Portanto a recomendação é **separar os conceitos `Oficina` (tenant/assinatura) e `Usuario` (pessoa que faz login)**:

```
 Oficina (tenant)  1 ──── N  Usuario (pessoa, login próprio)
   ├─ dados da empresa (nome, CNPJ, endereço, logo, site)
   ├─ plano / assinatura / limites
   └─ usuários com PAPÉIS:
        DONO          → tudo (inclusive gerenciar usuários e assinatura)
        GERENTE       → operações + financeiro + relatórios
        ATENDENTE     → OS e clientes (sem financeiro/estoque crítico)
        MECANICO      → apenas OS atribuídas / execução
```

**Alternativa mais barata (não recomendada como alvo final):** manter tenant = usuário e adicionar `usuarios.conta_pai_id` apontando para o dono. Economiza a migração das 8 tabelas de negócio, mas carrega para sempre um modelo confuso (assinatura no "usuário-pai", herança de tenant implícita). Serve só como passo emergencial.

### Implementação em fases (cada fase entrega valor e pode ir a produção sozinha)

**Fase 0 — Fundação (risco baixo, 1–2 dias)**
1. Remover o hash do admin do Git: seed passa a ler `ADMIN_INITIAL_PASSWORD` de env; se ausente em prod, o app não cria admin. **Trocar a senha atual em produção imediatamente.**
2. Mapear os campos da V7 na entidade `Usuario` e implementar de verdade `verifyEmail`, `forgotPassword`, `resetPassword` (token UUID com expiração, envio via `EmailService`, resposta sempre 200 para não vazar existência de e-mail).
3. Criar `enum Papel { ADMIN, DONO, GERENTE, ATENDENTE, MECANICO }` e parar de usar Strings soltas (coluna continua `VARCHAR` — migração compatível).
4. Colocar `uid` (userId) no JWT e resolver `Usuario` uma única vez por request (guardar no `SecurityContext`), eliminando os N+1 lookups.

**Fase 1 — Tenant `oficinas` (núcleo da mudança)**
1. Migration: `CREATE TABLE oficinas` (id, dados hoje em `usuarios.nome_oficina`, `cnpj_oficina`, endereço, `logo_url`, `site_oficina`, `plano`).
2. Backfill: 1 oficina por usuário existente; `usuarios.oficina_id` NOT NULL; negócio migra `usuario_id → oficina_id` nas 8 tabelas (`ordens_servico`, `mecanicos`, `stock_items`, `stock_movements`, `categorias_financeiras`, `transacoes_financeiras`, `fluxo_caixa`, `chat_messages`) com índices espelhados.
3. JWT ganha claim `oid` (oficinaId) + `papel`; `TenantContext.oficinaId()` vira a única fonte de tenant nos services; repositórios `findByUsuarioId → findByOficinaId`.
4. Assinatura/pagamento passam a referenciar a oficina (plano é da empresa, não de uma pessoa).

**Fase 2 — RBAC + limite do plano**
1. Spring Security: authorities `PAPEL_*` + matriz de permissões com `@PreAuthorize` por controller:
   - Financeiro/relatórios → `DONO, GERENTE`
   - Gestão de usuários/assinatura → `DONO`
   - Estoque write → `DONO, GERENTE`
   - OS read/execução → todos, com filtro "minhas OS" para `MECANICO`
2. Mapear `Plano.limiteUsuarios` e **cobrar no convite**: `oficina.usuariosAtivos >= plano.limite → 402/409 "upgrade necessário"`.
3. Frontend: esconder menus por papel (lê claim do JWT) — UX, nunca segurança (backend sempre valida).

**Fase 3 — Convites e gestão (UX do controle de usuários)**
1. `POST /oficina/usuarios/convidar { email, papel }` → token com expiração + e-mail; aceite cria senha (ou usa conta existente se já tem login OSMECH).
2. Endpoints do dono: listar usuários da oficina, alterar papel, ativar/inativar, reenviar convite.
3. Tela Flutter "Equipe" (crud + badges de papel + contador "3/6 usuários do plano").
4. Audit log passa a gravar `oficina_id + usuario_id + papel` — rastreio individual real.
5. AdminController ganha ações de gestão (inativar conta, trocar plano, paginação).

**Fase 4 — Hardening (opcional/próximo trimestre)**
- Refresh token (access 15min + refresh rotativo em cookie `HttpOnly`)
- `tokenVersion` em `usuarios` para logout global / revogação de sessões
- 2FA (TOTP) obrigatório para `ADMIN` e opcional para `DONO`
- Bloqueio progressivo por conta (além do rate limit por IP)

### Ordem de prioridade com melhor custo-benefício imediato

1. **Trocar senha do admin + remover hash do repo** (Fase 0.1) — risco ativo hoje.
2. **Implementar reset/verificação de e-mail** (Fase 0.2) — telas já existem, usuário final sente na hora.
3. **Tenant `oficinas` + convites com limite do plano** (Fases 1–3) — transforma `limite_usuarios` em **receita**: hoje o plano BÁSICO vende "3 usuários" que o sistema não entrega.
4. RBAC por papel (Fase 2) + refresh token (Fase 4).

---

## 4. Impacto estimado

| Fase | Arquivos tocados (aprox.) | Migration | Risco |
|---|---|---|---|
| 0 | 8–10 Java, 0 Flutter | V11 (índices/ajustes) | Baixo |
| 1 | ~40 Java (services/repositories), 0 Flutter | V12–V14 (oficinas + backfill + FKs) | Médio (testar bem) |
| 2 | ~15 Java, ~6 Dart | V15 (seed papéis se necessário) | Médio |
| 3 | ~10 Java, ~8 Dart | V16 (convites) | Baixo |
| 4 | ~8 Java, ~4 Dart | V17 (token_version) | Médio |

Testes sugeridos por fase: integração com `spring-security-test` (`@WithMockUser` por papel), teste de isolamento entre oficinas (tenant A nunca lê tenant B), e teste de cobrança de limite no convite.

---

## 5. Status de implementação

### ✅ Fase 0 — Fundação (concluída em 28/09/2026)

**Senha do admin fora do Git**
- `V11__lock_leaked_admin_password.sql`: substitui o hash vazado por marcador inválido + cria índices para os tokens (V7).
- `AdminBootstrap` (`config/`): roda em todo boot, **com ou sem Flyway**. Se a senha for a vazada → redefine via `ADMIN_INITIAL_PASSWORD` (mín. 8) ou bloqueia com senha aleatória. Se a conta não existir → cria com a env. Nunca sobrescreve senha já trocada.

**Verificação de e-mail e recuperação de senha reais**
- `Usuario` passa a mapear os campos da V7 (`emailVerificado`, `verificationToken`, `resetPasswordToken`, `resetPasswordTokenExpiry`).
- `register` grava token e dispara e-mail; `verifyEmail` confirma e invalida o token; `forgotPassword` gera token de 1h **sem vazar se o e-mail existe**; `resetPassword` é de uso único com checagem de expiração.
- Rate limit de login estendido a `forgot-password`, `reset-password` e `verify-email` (`RateLimitFilter`).
- Config: `AUTH_REQUIRE_VERIFIED_EMAIL=true` opcionalmente bloqueia login sem e-mail verificado (default false, não quebra contas legadas).

**Enum de papéis + JWT com `uid`**
- Novo `Papel` (ADMIN/OFICINA) com `from()` de fallback seguro; `AuthService`, `JwtAuthFilter` e `AdminController` (SpEL com referência ao enum) não usam mais String solta.
- JWT ganha claim `uid`; novo principal `UsuarioAutenticado(id, email, papel)` no SecurityContext (implementa `Principal` → `auth.getName()` segue retornando e-mail, zero quebra nos services).
- **Autorização agora usa o papel do banco** a cada request (a role defasada do JWT deixou de ser fonte de verdade server-side).
- Login passa a rejeitar conta desativada (`DisabledException`) e credenciais inválidas agora retornam **401** (antes caíam em 500) via novo handler de `AuthenticationException`.

**Novos testes:** `AuthServiceTest` (11 cenários) e `JwtUtilTest` (4 cenários) em `backend/src/test`.
**Novas envs:** `ADMIN_EMAIL`, `ADMIN_INITIAL_PASSWORD`, `APP_FRONTEND_URL`, `AUTH_REQUIRE_VERIFIED_EMAIL` (documentadas em `.env.example` e `.env.prod.example`).

**Ação manual necessária em produção:** definir `ADMIN_INITIAL_PASSWORD` com uma senha forte e subir o backend 1x. Sem isso, a conta admin seed será bloqueada no próximo deploy (intencional — a senha vazou no Git).

### ✅ Fase 1 — Tenant `oficinas` (concluída em 28/09/2026)

**Decisão de implementação — estratégia de igualdade de ids:** em vez de renomear `usuario_id → oficina_id` nas 10 tabelas de negócio (flyway + risco de dessincronia nos ambientes com `ddl-auto=update`), a oficina criada no backfill **recebe o mesmo id do usuário dono**. Assim, as colunas `usuario_id` passam a significar *"id do tenant (oficina)"* sem nenhuma migração de dados — zero risco em produção, e o multi-usuário da Fase 2/3 funcionará sem tocar nessas tabelas. Colunas podem ser renomeadas no futuro somente por clareza (opcional).

**Entregas:**
- `V12__create_oficinas.sql`: tabela `oficinas` (perfil da empresa + plano), backfill com id = id do dono, `usuarios.oficina_id` NOT NULL + FK + índice, sequência reposicionada.
- `OficinaBackfillRunner`: equivalente Java **idempotente** que roda em todo boot (ambient sem Flyway — `ddl-auto=update` — recebem o mesmo backfill automaticamente).
- Entidade `Oficina` + `OficinaRepository`; `usuarios.oficinaId` mapeado; `UsuarioRepository.findAllByOficinaId`.
- JWT ganha claim **`oid`**; principal `UsuarioAutenticado(id, oficinaId, email, papel)`; o filtro **rejeita usuário sem oficina vinculada**.
- `register` cria a oficina e vincula; login emite `oid`.
- **78 pontos** em 9 services/controllers passaram a usar `usuario.getOficinaId()` como tenant (OS, estoque, financeiro, mecânicos, categorias, chat, pagamentos, assinaturas, WhatsApp, relatórios) — dono e futuros membros veem os mesmos dados.
- **Plano é autoritativo na oficina**: `verificarLimitePlano` (OS), ativação via webhook MP (resolve pela oficina e espelha `usuarios.plano` de todos os membros), cancelamento de assinatura.
- Dados da empresa (nome/CNPJ/endereço/logo/site) são **espelhados** na oficina ao atualizar perfil/logo (`UserService`).
- `AdminBootstrap` cria o admin já com oficina própria.
- Testes atualizados (`AuthServiceTest` cobre criação da oficina no registro e claims `uid`/`oid`; `JwtUtilTest` cobre `oid`).

**Compatibilidade:** dados existentes funcionam sem migração manual (backfill no boot); frontend não precisou de mudanças. Contas criadas após a Fase 1 recebem oficina com id novo (sequência independente) — o código sempre trata `oficina_id` como tenant, então não há colisão semântica.

⏭️ Próximas fases pendentes: 2 (RBAC por papel + limite de usuários do plano), 3 (convites + tela Equipe), 4 (refresh token/2FA).
