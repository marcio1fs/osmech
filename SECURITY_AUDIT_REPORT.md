# Relatório de Análise de Segurança e Pontos de Quebra

## Visão Geral do Projeto

O projeto **OSMECH** é um sistema de gestão para oficinas mecânicas com:
- Backend: Java Spring Boot (API REST)
- Frontend: Flutter
- Banco de dados: PostgreSQL
- Integração com Mercado Pago para pagamentos
- Integração com WhatsApp (Twilio/Meta)
- Sistema de assinaturas (planos FREE, PRO, PRO+, PREMIUM)

---

## 🔴 Vulnerabilidades Críticas

### 1. **Segurança do Webhook do Mercado Pago**

**Problema:** O webhook está completamente exposto sem validação de assinatura quando `mercadopago.webhook-secret` não está configurado.

**Arquivo:** [`MercadoPagoWebhookService.java`](backend/src/main/java/com/osmech/payment/service/MercadoPagoWebhookService.java:194-220)

```java
private void validarAssinaturaSeConfigurada(...) {
    String secret = trimToNull(webhookSecret);
    if (secret == null) {
        return; // ❌ RETORNA SEM VALIDAÇÃO!
    }
    // ... validação só acontece se secret estiver configurado
}
```

**Risco:** Um atacante pode enviar webhooks falsos e ativar assinaturas fraudulentas, alterando o plano de usuários para PREMIUM sem pagamento.

**Recomendação:**
1. **Tornar o webhook-secret obrigatório** em produção
2. Adicionar logging de alertas quando webhook for recebido sem assinatura
3. Implementar lista de IPs autorizados do Mercado Pago

---

### 2. **JWT Secret Obrigatório sem Fallback Seguro**

**Problema:** O JWT secret é lido de variável de ambiente, mas se não estiver configurado, o sistema pode não iniciar corretamente.

**Arquivo:** [`application.yml`](backend/src/main/resources/application.yml:42)

```yaml
app:
  jwt:
    secret: ${JWT_SECRET}  # Sem valor padrão!
```

**Recomendação:** Adicionar validação no startup que impeça a aplicação de iniciar sem JWT_SECRET em produção.

---

### 3. **Exposição de Detalhes de Erro em Produção**

**Problema:** O `GlobalExceptionHandler` expõe mensagens de erro detalhadas em desenvolvimento.

**Arquivo:** [`GlobalExceptionHandler.java`](backend/src/main/java/com/osmech/config/GlobalExceptionHandler.java:177-187)

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
    // ...
    if (activeProfile != null && activeProfile.contains("dev")) {
        body.put("detail", ex.getMessage());  // ❌ Exposição em dev
    }
}
```

**Risco:** Informações de stack trace podem vazar em ambientes mal configurados.

**Recomendação:** Usar `Arrays.asList(environment.getActiveProfiles()).contains("dev")` em vez de string contains.

---

## 🟠 Vulnerabilidades Médias

### 4. **Validação de Input Insuficiente**

**Problema:** Diversos campos aceitam entrada sem validação rigorosa de tamanho ou formato.

**Exemplos:**
- `nome` em [`Usuario.java`](backend/src/main/java/com/osmech/user/entity/Usuario.java:24) - sem `@Size`
- `email` - sem validação de formato regex
- `descricao` em transações - sem limite de tamanho

**Recomendação:** Adicionar anotações de validação em todas as entidades DTO:
```java
@Size(max = 255, message = "Nome deve ter no máximo 255 caracteres")
private String nome;

@Email(message = "Email deve ser válido")
private String email;

@Size(max = 1000, message = "Descrição deve ter no máximo 1000 caracteres")
private String descricao;
```

---

### 5. **Rate Limiting Ausente**

**Problema:** Não há limitação de requisições, permitindo ataques de força bruta e DDoS.

**Impacto:**
- Tentativas ilimitadas de login
- Enumeração de usuários via API
- Abuso de webhooks

**Recomendação:** Implementar Rate Limiting com:
- `@RateLimiter` do Resilience4j
- Limite de 5 tentativas de login por IP/10min
- Limite de 100 requisições/minuto por usuário autenticado

---

### 6. **CORS Configurado com Padrão Inseguro em Dev**

**Problema:** Em desenvolvimento, CORS permite qualquer origem localhost.

**Arquivo:** [`SecurityConfig.java`](backend/src/main/java/com/osmech/config/SecurityConfig.java:85-91)

```java
if (isDev) {
    config.setAllowedOriginPatterns(Collections.singletonList("http://localhost:*"));
}
```

**Recomendação:** Em produção, garantir que `cors.allowed-origins` seja configurado com origens específicas.

---

### 7. **Ausência de Auditoria e Logging**

**Problema:** Operações sensíveis não são logadas adequadamente:
- Alterações de plano de usuário
- Cancelamento de assinaturas
- Alterações em transações financeiras
- Exclusões de dados

**Recomendação:** Adicionar logging estruturado para operações sensíveis:
```java
log.info("AUDIT: Assinatura atualizada - assinaturaId={}, usuarioId={}, novoStatus={}", 
    assinatura.getId(), assinatura.getUsuarioId(), novoStatus);
```

---

## 🟡 Vulnerabilidades Leves / Pontos de Melhoria

### 8. **Senha sem Política de Strength**

**Problema:** Não há validação de força de senha no registro.

**Arquivo:** [`AuthService.java`](backend/src/main/java/com/osmech/auth/service/AuthService.java:41)

```java
.senha(passwordEncoder.encode(request.getSenha()))  // Sem validação
```

**Recomendação:** Adicionar validação de senha:
- Mínimo 8 caracteres
- Pelo menos uma letra maiúscula
- Pelo menos um número
- Recomendação: usar biblioteca como zxcvbn

---

### 9. **Transação Automática sem Confirmação**

**Problema:** Ao encerrar uma OS, é criada automaticamente transação financeira.

**Arquivo:** [`OrdemServicoService.java`](backend/src/main/java/com/osmech/os/service/OrdemServicoService.java:249-259)

```java
if ("CONCLUIDA".equals(os.getStatus()) && ... && os.getValor().signum() > 0) {
    financeiroService.criarEntradaOS(...);  // Automatico
}
```

**Risco:** Valor pode estar incorreto; método de pagamento pode não ser aplicável.

**Recomendação:** Tornar a criação da transação opcional ou confirmar com o usuário.

---

### 10. **ID de Usuário Exposto em APIs**

**Problema:** IDs de usuários aparecem em responses de API (usuárioId em entidades).

**Recomendação:** Usar IDs opacos (UUIDs) em vez de IDs sequenciais para exposição externa.

---

### 11. **Ausência de Timeout em Requisições Externas**

**Problema:** Requisições ao Mercado Pago, Twilio, Meta não têm timeout configurado.

**Arquivo:** [`RestTemplateConfig.java`](backend/src/main/java/com/osmech/config/RestTemplateConfig.java)

**Recomendação:** Configurar timeouts:
```java
@Bean
public RestTemplate restTemplate() {
    return new RestTemplateBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .readTimeout(Duration.ofSeconds(10))
        .build();
}
```

---

### 12. **Mensagens de Erro Genéricas em Login**

**Problema:**both "usuário não encontrado" e "senha incorreta" retornam a mesma mensagem.

**Arquivo:** [`AuthService.java`](backend/src/main/java/com/osmech/auth/service/AuthService.java:70-76)

```java
.orElseThrow(() -> new IllegalArgumentException("Credenciais inválidas"));
// ...
if (!passwordEncoder.matches(request.getSenha(), usuario.getSenha())) {
    throw new IllegalArgumentException("Credenciais inválidas");
}
```

**Risco:** Permite enumeração de usuários válidos.

**Recomendação:** Manter mensagem genérica, mas implementar rate limiting no login.

---

### 13. **Planejamento de Limite de OS Ignorado**

**Problema:** [`DataSeeder.java`](backend/src/main/java/com/osmech/config/DataSeeder.java) cria planos com dados fixos, mas o plano FREE tem limite de 10 OS/mês.

**Risco:** Se o计画 não for verificado corretamente, pode permitir excesso de OS.

**Recomendação:** A verificação já existe em [`OrdemServicoService.java:402-416`](backend/src/main/java/com/osmech/os/service/OrdemServicoService.java:402), mas adicionar testes unitários.

---

## ⚠️ Pontos de Quebra (Breaking Points)

### 14. **Falha na Inicialização sem Variáveis de Ambiente**

O sistema depende de diversas variáveis de ambiente obrigatórias:
- `JWT_SECRET` - obrigatório
- `MERCADOPAGO_ACCESS_TOKEN` - necessário para pagamentos
- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` - banco de dados

**Impacto:** Aplicação não inicia se qualquer variável obrigatória estiver faltando.

**Recomendação:** Documentar claramente todas as variáveis obrigatórias e criar script de validação no startup.

---

### 15. **Negociação de Preço manual sem Validação**

**Problema:** O valor da OS pode ser definido manualmente sem validação de limite.

**Arquivo:** [`OrdemServicoRequest.java`](backend/src/main/java/com/osmech/os/dto/OrdemServicoRequest.java)

**Recomendação:** Adicionar validação de valor mínimo e máximo.

---

### 16. **Integração WhatsApp sem Consentimento Verificado**

**Problema:** Consentimento do WhatsApp é armazenado mas não há verificação de opt-in real.

**Recomendação:** Implementar verificação de consentimento via token duplo-opt-in.

---

### 17. **Sem Backups Automatizados**

O sistema não possui configuração de backup automatizado do banco de dados.

**Recomendação:** Adicionar script de backup no `docker-compose.yml` ou cron job.

---

## 📋 Checklist de Melhorias Prioritárias

| Prioridade | Item | Impacto |
|------------|------|---------|
| 🔴 Alta | Validar webhook signature do Mercado Pago | Financeiro |
| 🔴 Alta | Implementar rate limiting | Segurança |
| 🟠 Média | Adicionar validação de input (DTOs) | Dados |
| 🟠 Média | Configurar timeouts em RestTemplate | Disponibilidade |
| 🟠 Média | Melhorar logging de auditoria | Monitoramento |
| 🟡 Baixa | Política de senha forte | UX/Segurança |
| 🟡 Baixa | Usar UUIDs para IDs externos | Privacidade |

---

## 🚀 Recomendações de Arquitetura

### 18. **Adicionar API Gateway**

Considerar adicionar um API Gateway (Spring Cloud Gateway ou Kong) para:
- Rate limiting centralizado
- Autenticação/Autorização centralizada
- Logs de acesso
- Cache

---

### 19. **Implementar Circuit Breaker**

Usar Resilience4j para:
- Falhas em serviços externos (Mercado Pago, WhatsApp)
- Evitar cascata de falhas

---

### 20. **Monitoramento e Alertas**

Adicionar:
- Prometheus + Grafana para métricas
- Alertmanager para alertas
- Distributed tracing (Spring Cloud Sleuth)

---

## Conclusão

O projeto tem uma **base sólida** com:
- ✅ Autenticação JWT funcionando
- ✅ Senhas hashed com BCrypt
- ✅ Autorização por roles
- ✅ CSRF desabilitado (stateless API)
- ✅ Transações com @Transactional
- ✅ Validação de transições de status em OS

**Principais ações recomendadas:**
1. **Imediato:** Implementar validação de webhook signature
2. **Imediato:** Adicionar rate limiting
3. **Curto prazo:** Adicionar validação de input em DTOs
4. **Médio prazo:** Adicionar auditoria e monitoramento

---

*Relatório gerado em: 2026-02-27*
*Projeto: OSMECH - Sistema de Gestão para Oficinas*
