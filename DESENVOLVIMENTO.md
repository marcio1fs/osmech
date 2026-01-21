# OSMECH - Guia de Desenvolvimento

## 🎯 Decisões Técnicas

### 1. Por que Spring Boot 3.2.1?
- Versão LTS mais recente
- Suporte nativo a Java 17
- Performance aprimorada
- Spring Security 6.x (mais seguro)

### 2. Por que JWT?
- Stateless (escalável)
- Ideal para APIs REST
- Funciona nativamente com mobile
- Não depende de sessões no servidor

### 3. Por que Flutter?
- Mobile-first (iOS + Android com único código)
- Performance nativa
- Hot reload (produtividade)
- Compilação para Web também

### 4. Por que PostgreSQL?
- Open source robusto
- Suporte a JSON (futuro)
- ACID compliant
- Ótima performance

---

## 📐 Padrões de Código

### Backend (Java)

#### Nomenclatura
- **Classes:** PascalCase (`ServiceOrder`, `UserRepository`)
- **Métodos:** camelCase (`createServiceOrder`, `findByEmail`)
- **Constantes:** UPPER_SNAKE_CASE (`BASE_URL`, `MAX_ATTEMPTS`)
- **Packages:** lowercase (`com.osmech.auth`)

#### DTOs vs Entities
- **Entities:** Representam tabelas do banco
- **DTOs:** Transportam dados entre camadas
- **Nunca exponha Entities diretamente na API!**

#### Exemplo de Controller:
```java
@RestController
@RequestMapping("/api/resource")
@RequiredArgsConstructor
public class ResourceController {
    
    private final ResourceService service;
    
    @GetMapping
    public ResponseEntity<List<ResourceDTO>> getAll() {
        return ResponseEntity.ok(service.getAll());
    }
    
    @PostMapping
    public ResponseEntity<ResourceDTO> create(@Valid @RequestBody CreateResourceRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(service.create(request));
    }
}
```

### Frontend (Flutter)

#### Nomenclatura
- **Classes:** PascalCase (`LoginPage`, `AuthService`)
- **Variáveis:** camelCase (`isLoading`, `userEmail`)
- **Constantes:** lowerCamelCase (`baseUrl`, `maxRetries`)
- **Arquivos:** snake_case (`login_page.dart`, `auth_service.dart`)

#### State Management
- Usamos **Provider** para gerenciar estado
- Services são ChangeNotifiers
- UI escuta mudanças com `Consumer` ou `watch`

#### Exemplo de Service:
```dart
class ExampleService with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    // ... código assíncrono
    
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 🔒 Segurança

### Checklist de Segurança

#### Backend
- [x] Senhas hasheadas (BCrypt)
- [x] JWT com expiração
- [x] CORS configurado
- [x] Validação de entrada (@Valid)
- [x] SQL Injection protegido (JPA)
- [ ] HTTPS em produção
- [ ] Rate limiting
- [ ] Logs de auditoria

#### Frontend
- [x] Token armazenado localmente
- [x] Nunca logar senhas
- [x] Validação de formulários
- [ ] Criptografia de dados sensíveis
- [ ] Timeout de sessão

### Nunca faça:
❌ Commit de senhas/secrets  
❌ Expor entities na API  
❌ Usar `SELECT *` desnecessariamente  
❌ Ignorar validações  
❌ Logar dados sensíveis  

---

## 🧪 Testes

### Backend - Estrutura de Testes

```java
@SpringBootTest
@AutoConfigureMockMvc
class ServiceOrderControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void shouldCreateServiceOrder() throws Exception {
        // Given
        String requestBody = """
            {
                "customerName": "Test",
                "vehiclePlate": "ABC-1234",
                "description": "Test"
            }
            """;
        
        // When & Then
        mockMvc.perform(post("/api/service-orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody)
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.osNumber").exists());
    }
}
```

### Frontend - Estrutura de Testes

```dart
void main() {
  testWidgets('Login page shows error on invalid credentials', (tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Find widgets
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).at(1);
    final loginButton = find.text('Entrar');
    
    // Interact
    await tester.enterText(emailField, 'invalid@email.com');
    await tester.enterText(passwordField, 'wrong');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    
    // Verify
    expect(find.text('Email ou senha incorretos'), findsOneWidget);
  });
}
```

---

## 🚀 Deploy

### Backend (Produção)

#### 1. Configure variáveis de ambiente:
```bash
export DB_URL=jdbc:postgresql://seu-servidor:5432/oficina_db
export DB_USERNAME=seu_usuario
export DB_PASSWORD=senha_segura
export JWT_SECRET=chave_super_secreta_256_bits
```

#### 2. Build da aplicação:
```bash
mvn clean package -DskipTests
```

#### 3. Execute o JAR:
```bash
java -jar target/osmech-backend-1.0.0.jar
```

### Frontend (Produção)

#### Android:
```bash
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS:
```bash
flutter build ios --release
# Abrir no Xcode para assinar e publicar
```

#### Web:
```bash
flutter build web --release
# Arquivos em: build/web/
```

---

## 📊 Monitoramento

### Logs do Backend

Spring Boot usa Logback por padrão:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class MyService {
    private static final Logger logger = LoggerFactory.getLogger(MyService.class);
    
    public void doSomething() {
        logger.info("Iniciando operação");
        logger.error("Erro ocorreu", exception);
    }
}
```

### Health Checks

Adicione ao pom.xml:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Endpoints disponíveis:
- `/actuator/health` - Status da aplicação
- `/actuator/metrics` - Métricas
- `/actuator/info` - Informações

---

## 🔄 Versionamento de API

### Estratégia Recomendada: URL Versioning

```java
@RestController
@RequestMapping("/api/v1/service-orders")
public class ServiceOrderControllerV1 { ... }

@RestController
@RequestMapping("/api/v2/service-orders")
public class ServiceOrderControllerV2 { ... }
```

### Migração de Breaking Changes

1. Criar nova versão (v2)
2. Deprecar versão antiga (v1)
3. Manter v1 por 6 meses
4. Remover v1 após período

---

## 💡 Próximas Features - Como Implementar

### WhatsApp (Twilio)

1. Cadastrar em: https://www.twilio.com/
2. Obter credenciais (Account SID, Auth Token)
3. Adicionar dependency:
```xml
<dependency>
    <groupId>com.twilio.sdk</groupId>
    <artifactId>twilio</artifactId>
    <version>9.14.1</version>
</dependency>
```

4. Criar serviço:
```java
@Service
public class WhatsAppService {
    public void sendMessage(String to, String body) {
        Twilio.init(ACCOUNT_SID, AUTH_TOKEN);
        Message message = Message.creator(
            new PhoneNumber("whatsapp:" + to),
            new PhoneNumber("whatsapp:" + FROM_NUMBER),
            body
        ).create();
    }
}
```

### OpenAI Integration

1. Cadastrar em: https://platform.openai.com/
2. Obter API Key
3. Adicionar dependency:
```xml
<dependency>
    <groupId>com.theokanning.openai-gpt3-java</groupId>
    <artifactId>service</artifactId>
    <version>0.18.2</version>
</dependency>
```

4. Criar serviço:
```java
@Service
public class AIService {
    private final OpenAiService openAiService;
    
    public String generateDiagnostic(String description) {
        ChatCompletionRequest request = ChatCompletionRequest.builder()
            .model("gpt-4")
            .messages(List.of(
                new ChatMessage("user", "Diagnóstico para: " + description)
            ))
            .build();
        return openAiService.createChatCompletion(request)
            .getChoices().get(0).getMessage().getContent();
    }
}
```

---

## 🤝 Contribuindo

### Workflow de Desenvolvimento

1. Crie uma issue descrevendo a feature/bug
2. Crie uma branch: `git checkout -b feature/nome-da-feature`
3. Desenvolva seguindo os padrões deste guia
4. Teste localmente
5. Commit com mensagens claras: `git commit -m "feat: adiciona endpoint de clientes"`
6. Push: `git push origin feature/nome-da-feature`
7. Abra um Pull Request

### Commit Messages (Conventional Commits)

- `feat:` Nova feature
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação (não afeta código)
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

Exemplo:
```
feat: adiciona endpoint de listagem de clientes

- Cria controller ClientController
- Implementa serviço ClientService
- Adiciona validações de entrada
```

---

## 📚 Referências

### Documentação Oficial
- [Spring Boot](https://spring.io/projects/spring-boot)
- [Spring Security](https://spring.io/projects/spring-security)
- [Flutter](https://flutter.dev/)
- [PostgreSQL](https://www.postgresql.org/docs/)

### Tutoriais Recomendados
- [JWT com Spring Boot](https://www.baeldung.com/spring-security-oauth-jwt)
- [Flutter State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro)
- [REST API Best Practices](https://restfulapi.net/)

---

**Última atualização:** 21/01/2026
