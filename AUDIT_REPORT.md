# OSMECH — Comprehensive Project Audit Report

**Date:** June 2025  
**Scope:** Full backend (Spring Boot) + frontend (Flutter Web) codebase  
**Total files reviewed:** 90+ (all Java + Dart source files)

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 6     |
| HIGH     | 14    |
| MEDIUM   | 15    |
| LOW      | 12    |
| **Total**| **47**|

---

## CRITICAL Issues

### 1. Password validation mismatch between frontend and backend
- **Files:** `backend/.../auth/RegisterRequest.java`, `frontend/.../pages/register_page.dart`
- **Description:** Backend enforces `@Size(min = 8)` on the `senha` field, but the frontend register form validates `min 6 characters` (`if (v.length < 6) return 'Mínimo 6 caracteres'`). Users will see a confusing API error when entering 6–7 character passwords.
- **Fix:** Change the frontend validator to `min 8` and update the hint text to "Mínimo 8 caracteres" to match the backend. Also update `profile_page.dart` which already correctly validates 8 chars.

### 2. Stock not deducted when OS is completed
- **Files:** `backend/.../stock/StockService.java` (method `darBaixaOS`), `backend/.../os/OrdemServicoService.java`
- **Description:** `StockService.darBaixaOS(Long osId, Map<Long, Integer> itens)` exists and is fully implemented, but it is **never called** from `OrdemServicoService.atualizarStatus()` when an OS transitions to `CONCLUIDA`. Auto-creating a financial entry works, but stock levels are never affected.
- **Fix:** Inject `StockService` into `OrdemServicoService` and call `darBaixaOS` when status transitions to `CONCLUIDA`, using parts specified in the OS.

### 3. CORS origin mismatch
- **Files:** `backend/.../config/SecurityConfig.java`, `backend/src/main/resources/application.yml`, `frontend/.../services/api_config.dart`
- **Description:** `application.yml` configures allowed CORS origins as `http://localhost:8083,http://localhost:3000`, but the Flutter frontend targets `http://localhost:8081` (the backend port itself). If Flutter Web runs on any other port (e.g., the default `8083` from `flutter run -d chrome --web-port 8083`), CORS may or may not work depending on port matching. The real issue is that the allowed origins list does not dynamically include the Flutter dev server's actual port.
- **Fix:** Add the Flutter dev server port (commonly random or configurable) to allowed origins, or add `http://localhost:*` pattern during development. In production, set the exact frontend domain.

### 4. ChatRepository uses non-standard JPQL `LIMIT`
- **File:** `backend/.../chat/ChatRepository.java`
- **Description:** The JPQL query `@Query("SELECT c FROM ChatMessage c WHERE ... ORDER BY c.criadoEm DESC LIMIT 20")` uses `LIMIT`, which is **not valid JPQL**. It works with Hibernate 6.x's extension but will fail on other JPA providers and may break on Hibernate version upgrades.
- **Fix:** Replace with Spring Data's `Pageable` parameter: `Pageable.ofSize(20)` and remove `LIMIT 20` from the query.

### 5. JWT secret has hardcoded fallback
- **File:** `backend/src/main/resources/application.yml`
- **Description:** `jwt.secret` falls back to a hardcoded value (`${JWT_SECRET:chave-secreta-padrao-dev-osmech-2024-super-segura}`). If the environment variable is not set in production, any attacker who reads the source code can forge JWT tokens.
- **Fix:** Remove the default fallback entirely. Application should fail to start if `JWT_SECRET` is not configured. Add a `@PostConstruct` validation in `JwtUtil` to verify the secret is not the default value.

### 6. Hibernate `ddl-auto: update` used as default
- **File:** `backend/src/main/resources/application.yml`
- **Description:** `spring.jpa.hibernate.ddl-auto: update` automatically modifies the production database schema. This can cause data loss (dropped columns), inconsistencies, and makes schema changes unreproducible.
- **Fix:** Use a migration tool (Flyway or Liquibase) for schema management. Set `ddl-auto: validate` in production to only verify schema matches entities.

---

## HIGH Issues

### 7. No pagination on list endpoints
- **Files:** `OrdemServicoController.java`, `FinanceiroController.java`, `StockController.java`, `PagamentoController.java`
- **Description:** All list endpoints (`GET /os`, `GET /financeiro/transacoes`, `GET /stock/itens`, `GET /pagamentos`) return the **entire dataset** without pagination. With thousands of records, this causes memory pressure, slow responses, and frontend rendering issues.
- **Fix:** Add `Pageable` parameter to all list endpoints and return `Page<T>`. Update frontend services to support pagination parameters.

### 8. JwtAuthFilter queries database on every request
- **File:** `backend/.../security/JwtAuthFilter.java`
- **Description:** Every authenticated HTTP request triggers a `usuarioRepository.findByEmail()` database query to verify the user still exists. This is a significant performance bottleneck under load.
- **Fix:** Cache user lookups with Spring's `@Cacheable` or a lightweight in-memory cache (e.g., Caffeine) with a short TTL (5 minutes). Invalidate on user changes.

### 9. ChatService creates RestTemplate inline
- **File:** `backend/.../chat/ChatService.java`
- **Description:** `new RestTemplate()` is created inside the method call for each OpenAI API request. This bypasses Spring's connection pooling, has no timeout configuration, and creates excessive socket connections.
- **Fix:** Declare `RestTemplate` as a `@Bean` in a configuration class with proper timeouts (`setConnectTimeout`, `setReadTimeout`) and connection pooling (`HttpComponentsClientHttpRequestFactory`).

### 10. No password reset / forgot password functionality
- **Files:** All auth-related files
- **Description:** There is no endpoint or UI flow for password recovery. If a user forgets their password, they cannot regain access to their account.
- **Fix:** Implement a `/api/auth/forgot-password` endpoint that sends a reset token via email, and `/api/auth/reset-password` to set a new password. Add corresponding frontend pages.

### 11. No email verification on registration
- **Files:** `AuthService.java`, `AuthController.java`
- **Description:** Users can register with any email address (including non-existent ones) without verification. This allows fake accounts and typo-based lockouts.
- **Fix:** Add email verification flow: send verification link on registration, add `emailVerificado` field to `Usuario`, and restrict login until verified.

### 12. No rate limiting on authentication endpoints
- **Files:** `AuthController.java`, `SecurityConfig.java`
- **Description:** Login and registration endpoints have no rate limiting. An attacker can brute-force passwords or spam registrations without restriction.
- **Fix:** Add rate limiting with Spring's `bucket4j` or a custom `HandlerInterceptor` that limits requests per IP (e.g., 5 login attempts per minute).

### 13. PlanoService loads all plans then filters in Java
- **File:** `backend/.../plan/PlanoService.java`
- **Description:** `listarAtivos()` calls `planoRepository.findAll()` and then `.stream().filter(Plano::isAtivo)` in Java memory. This fetches inactive plans from the database unnecessarily.
- **Fix:** Add `List<Plano> findByAtivoTrue()` to `PlanoRepository` and use it directly.

### 14. GlobalExceptionHandler has unused import and missing handlers
- **File:** `backend/.../config/GlobalExceptionHandler.java`
- **Description:** `NoHandlerFoundException` is imported but no `@ExceptionHandler` method exists for it. Also missing handlers for `EntityNotFoundException`, `NoSuchElementException`, and `DataIntegrityViolationException` (duplicate email, FK violations).
- **Fix:** Add handler methods for these exceptions. Remove unused import if not adding handler.

### 15. Subscription cancellation doesn't downgrade user plan
- **Files:** `backend/.../payment/AssinaturaService.java`, `backend/.../user/Usuario.java`
- **Description:** When `cancelarAssinatura()` is called, it sets the subscription status to `CANCELED` and records the cancellation date, but it **does not** update the `Usuario.plano` field back to `FREE`. The user retains their paid plan level indefinitely after cancellation.
- **Fix:** In `cancelarAssinatura()`, also call `usuario.setPlano("FREE")` and save the user entity.

### 16. WhatsApp feature is advertised but not implemented
- **Files:** `frontend/.../pages/login_page.dart` (feature list), `frontend/.../pages/os_form_page.dart` (toggle), `backend/src/main/resources/application.yml` (config placeholders)
- **Description:** Login page lists "Notificações via WhatsApp" as a feature. OS form has a WhatsApp notification toggle. But the backend has zero WhatsApp integration code — it's just config placeholders. Users enable a toggle that does nothing.
- **Fix:** Either implement WhatsApp integration (Twilio/Meta API) or remove the misleading feature from the login page and disable/hide the toggle with a "Disponível em breve" tooltip.

### 17. PricingPage doesn't use ApiClient for plan subscription
- **File:** `frontend/.../pages/pricing_page.dart`
- **Description:** `PricingPage._loadPlanos()` makes direct `http.get()` calls instead of using the centralized `ApiClient`. This bypasses the 401 auto-detection and `UnauthorizedException` handling. Also, `PricingPage` doesn't use `AuthErrorMixin`, so subscription errors won't trigger auto-logout.
- **Fix:** Use `ApiClient` for the subscription call (`_assinarPlano`). The plan listing can stay as direct HTTP since it's a public endpoint, but add `AuthErrorMixin` to the state class.

### 18. No input sanitization on OS fields
- **Files:** `OrdemServicoRequest.java`, `OrdemServicoService.java`
- **Description:** Text fields like `descricao`, `diagnostico`, `pecas` accept arbitrary input that is stored and returned without sanitization. While not directly an XSS risk in a Flutter app (no HTML rendering), the data could be used in email notifications or PDF reports in the future.
- **Fix:** Add input sanitization (strip HTML tags, limit length) in the service layer before persisting.

### 19. Financial transaction value validation
- **File:** `frontend/.../pages/transacao_form_page.dart`
- **Description:** The currency input uses a RegExp `[\d,.]` that allows inputs like `1.2.3.4` or `,,,,` which would fail parsing. The `double.parse()` in `_salvar()` with `.replaceAll('.', '').replaceAll(',', '.')` could produce incorrect values (e.g., `1.234,56` → `1234.56` is correct, but `1.234.567` → error).
- **Fix:** Use a proper currency input formatter (e.g., `CurrencyTextInputFormatter`) or validate the parsed value more rigorously before submission.

### 20. Missing `@Transactional` isolation on financial operations
- **Files:** `backend/.../finance/FinanceiroService.java`
- **Description:** Creating a transaction and updating the cash flow (`FluxoCaixa`) are done in the same `@Transactional` method, but without explicit isolation level. Concurrent transactions could read stale cash flow data and produce incorrect accumulated balances.
- **Fix:** Add `@Transactional(isolation = Isolation.SERIALIZABLE)` or use optimistic locking (`@Version`) on `FluxoCaixa` entity.

---

## MEDIUM Issues

### 21. Usuario entity uses String for role and plano
- **Files:** `backend/.../user/Usuario.java`
- **Description:** `role` and `plano` fields are plain `String` type. Any typo (e.g., "OFCINA" instead of "OFICINA") silently creates invalid data. No compile-time or schema-level protection.
- **Fix:** Create `Role` and `PlanoCodigo` enums and use `@Enumerated(EnumType.STRING)` on the entity fields.

### 22. No `@PrePersist` / `@PreUpdate` lifecycle hooks on entities
- **Files:** `Usuario.java`, `OrdemServico.java`, `TransacaoFinanceira.java`, etc.
- **Description:** `criadoEm`, `atualizadoEm` fields rely on `@Builder.Default` which only works when using the builder pattern, not when JPA persists/updates entities directly. If an entity is constructed via `new Usuario()`, `criadoEm` will be null.
- **Fix:** Add `@PrePersist` and `@PreUpdate` callback methods to set timestamp fields automatically, or use Spring Data's `@CreatedDate` / `@LastModifiedDate` with `@EnableJpaAuditing`.

### 23. Redundant exception handling in controllers
- **Files:** `AuthController.java`, `OrdemServicoController.java`, `FinanceiroController.java`
- **Description:** Controllers wrap service calls in try-catch for `IllegalArgumentException` and return 400 responses, but `GlobalExceptionHandler` already handles `IllegalArgumentException` globally. This creates duplicated error handling logic.
- **Fix:** Remove the try-catch blocks in controllers and let `GlobalExceptionHandler` handle exceptions uniformly.

### 24. OrdemServicoRequest status field accepts any string
- **File:** `backend/.../os/OrdemServicoRequest.java`
- **Description:** The `status` field has no validation annotation. While the service layer validates status transitions, the DTO accepts any string, potentially causing unclear error messages.
- **Fix:** Add `@Pattern(regexp = "ABERTA|EM_ANDAMENTO|AGUARDANDO_PECA|AGUARDANDO_APROVACAO|CONCLUIDA|CANCELADA")` or use the `StatusOS` enum directly with `@ValidEnum`.

### 25. DataSeeder doesn't update existing records
- **File:** `backend/.../config/DataSeeder.java`
- **Description:** The seeder checks if plans/categories are empty before seeding. If plan limits or prices need updating, existing records won't be changed, requiring manual DB updates.
- **Fix:** Use an upsert pattern (check existence by code, update if exists with different values, insert if not exists).

### 26. No audit logging or activity tracking
- **Files:** All service classes
- **Description:** There is no record of user actions (who created/edited/deleted what and when). Critical for a business application where financial transactions and service orders need traceability.
- **Fix:** Add a generic audit log table and use Spring AOP or JPA `EntityListener` to automatically log create/update/delete operations with user ID and timestamp.

### 27. OS form clienteTelefone required in frontend, optional in backend
- **Files:** `frontend/.../pages/os_form_page.dart`, `backend/.../os/OrdemServicoRequest.java`
- **Description:** The frontend marks `clienteTelefone` as `required: true` in the form, but the backend DTO doesn't have `@NotBlank` on this field. This inconsistency means the validation only exists on the client side and can be bypassed via direct API calls.
- **Fix:** Add `@NotBlank` to `clienteTelefone` in `OrdemServicoRequest` if it's truly required, or remove `required: true` from the frontend if it's optional.

### 28. StockMovementPage layout not responsive for narrow screens
- **File:** `frontend/.../pages/stock_movement_page.dart`
- **Description:** Uses a `Row` with `Expanded(flex: 2)` + `Expanded(flex: 3)` for form and history side-by-side. On narrow screens (mobile), both columns compress and become unusable. No `LayoutBuilder` breakpoint exists.
- **Fix:** Wrap in a `LayoutBuilder` and switch to `Column` layout when `constraints.maxWidth < 800`.

### 29. Dashboard stat grid has 5 cards but max crossAxisCount is 4
- **File:** `frontend/.../pages/dashboard_page.dart`
- **Description:** The GridView has `crossAxisCount: 4` (max) but 5 stat cards. The 5th card ("Concluídas") wraps to a new row alone, creating an asymmetric layout.
- **Fix:** Either add a 6th/7th/8th stat to fill the row, change `crossAxisCount` to 5, or use a different layout strategy (e.g., 3+2 or scrollable chips).

### 30. Mobile bottom navigation index mismatch
- **File:** `frontend/.../widgets/app_shell.dart`
- **Description:** `selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex` — when the user selects an item from the "More" drawer (index > 4), the bottom nav always highlights "Dashboard" (index 0) even though the user is on a different page. This confuses users about their current location.
- **Fix:** Track mobile navigation state separately, or use a different indicator strategy for pages not directly in the bottom nav.

### 31. Chat typing indicator doesn't animate properly
- **File:** `frontend/.../pages/chat_page.dart`
- **Description:** `TweenAnimationBuilder` runs the animation once (from 0.3 to 1.0 opacity) and then stops. It doesn't create the expected pulsing/bouncing dot effect for a typing indicator.
- **Fix:** Use an `AnimationController` with `repeat(reverse: true)` to create a continuous pulsing animation, or use a package like `flutter_spinkit`.

### 32. No data export functionality
- **Files:** All frontend pages
- **Description:** No ability to export OS lists, financial reports, stock inventory, or payment history to CSV, PDF, or Excel. This is essential for a business application (tax reporting, record-keeping).
- **Fix:** Add export endpoints on the backend (CSV/PDF generation) and download buttons on the frontend for each data table.

### 33. Inconsistent currency formatting
- **Files:** Multiple frontend pages
- **Description:** Currency is formatted as `R$ ${value.toStringAsFixed(2)}` throughout, but doesn't use thousand separators (e.g., `R$ 1234.56` instead of `R$ 1.234,56`). Also uses `.` as decimal separator instead of Brazilian `,`.
- **Fix:** Create a centralized `formatCurrency()` utility using `intl` package's `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`.

### 34. Financial summary uses `COALESCE` but no index on date columns
- **Files:** `TransacaoFinanceiraRepository.java`, `FluxoCaixaRepository.java`
- **Description:** Multiple queries filter by `dataMovimentacao` between dates, and by `usuario.id`. Without proper composite indexes on `(usuario_id, data_movimentacao)`, these queries will perform full table scans as data grows.
- **Fix:** Add `@Table(indexes = { @Index(columnList = "usuario_id, data_movimentacao") })` to entity annotations and corresponding DB indexes.

### 35. TransacaoFormPage value parsing handles Brazilian format inconsistently
- **File:** `frontend/.../pages/transacao_form_page.dart`
- **Description:** Value parsing does `.replaceAll('.', '').replaceAll(',', '.')` which assumes Brazilian number format (`,` as decimal, `.` as thousands). But the input allows both `.` and `,` characters without validation, leading to ambiguity (is `1.234` → `1234` or `1.234`?).
- **Fix:** Use a proper Brazilian currency input mask/formatter that enforces format as-you-type, and parse from a consistently formatted string.

---

## LOW Issues

### 36. OsListPage creates new OsService on every load
- **File:** `frontend/.../pages/os_list_page.dart`
- **Description:** `OsService(token: auth.token!)` is instantiated inside `_loadOrdens()`, creating a new `ApiClient` (including new `http.Client()`) on every data refresh.
- **Fix:** Create the service once in `initState()` or use a provider pattern. Same issue exists in most other pages.

### 37. No loading skeleton / shimmer effects
- **Files:** All page files
- **Description:** All pages show a plain `CircularProgressIndicator` while loading. Modern web apps typically show skeleton/shimmer placeholders that match the final layout shape for a better perceived performance experience.
- **Fix:** Add shimmer/skeleton widgets for the main data areas (e.g., `Shimmer` package or custom `Container` with gradient animation).

### 38. No pull-to-refresh on mobile
- **Files:** All list/dashboard pages
- **Description:** On mobile devices, users expect pull-to-refresh to reload data. Currently, the only way to refresh is via the "Atualizar" button in the header.
- **Fix:** Wrap scrollable content in `RefreshIndicator` widget on mobile layouts.

### 39. OsFormPage doesn't validate placa format
- **File:** `frontend/.../pages/os_form_page.dart`
- **Description:** The license plate field (`placa`) accepts any text. Brazilian plates follow specific patterns (ABC-1234 or ABC1D23 for Mercosul). No format validation exists on frontend or backend.
- **Fix:** Add a regex validator for Brazilian plate formats and an input mask.

### 40. No keyboard shortcuts for common actions
- **File:** `frontend/.../widgets/app_shell.dart`
- **Description:** No keyboard shortcuts exist for common operations like "New OS" (Ctrl+N), "Search" (Ctrl+F), "Save" (Ctrl+S), or sidebar navigation. This reduces efficiency for power users on web.
- **Fix:** Add `Shortcuts` and `Actions` widgets to `AppShell` for common operations.

### 41. Chat session history only loads the most recent session
- **File:** `frontend/.../pages/chat_page.dart`
- **Description:** `_initChat()` loads `sessoes.first` (most recent session) but provides no way to browse or select older sessions. The "Nova conversa" button starts a new session, but older ones are inaccessible from the UI.
- **Fix:** Add a session list panel (sidebar or drawer) that shows all sessions and allows switching between them.

### 42. No confirmation on financial transaction creation
- **File:** `frontend/.../pages/transacao_form_page.dart`
- **Description:** Submitting a financial transaction immediately creates it without a confirmation step. Users can accidentally create large transactions with a single click. There's no preview or "are you sure?" dialog for financial operations.
- **Fix:** Add a confirmation dialog showing the transaction summary before submission, especially for large amounts.

### 43. Subscription page shows empty state poorly when no subscription exists
- **File:** `frontend/.../pages/subscription_page.dart`
- **Description:** When `_assinatura` is null (no active subscription), the page shows "Sem plano" and `R$ 0.00/mês` in a large card with a null status color. It should show a clear "You have no active subscription" message with a CTA to the pricing page.
- **Fix:** Add a dedicated empty state with a "Ver Planos" button linking to the PricingPage (index 16).

### 44. No dark mode support
- **Files:** `frontend/.../theme/app_theme.dart`, `frontend/.../main.dart`
- **Description:** The app only has a light theme (despite using dark sidebar colors). There's no dark mode toggle or system theme detection. The `MaterialApp` only sets `theme` without `darkTheme`.
- **Fix:** Create a dark variant of `AppTheme` and add `darkTheme` + `themeMode: ThemeMode.system` to `MaterialApp`. Consider adding a manual toggle in the profile/settings page.

### 45. RegisterPage auto-login behavior unclear
- **File:** `frontend/.../pages/register_page.dart`
- **Description:** After successful registration, `auth.register()` returns null (no error) and the page calls `Navigator.pop(context)` to go back to login. But `AuthService.register()` calls `login()` internally which sets `isAuthenticated = true` and triggers `notifyListeners()`. The `main.dart` will rebuild and show `AppShell`, while `Navigator.pop` tries to pop the register page. This can cause a brief flash or unexpected behavior.
- **Fix:** After successful registration, don't pop — let the auth state change rebuild the widget tree naturally.

### 46. Backend controllers return inconsistent response formats
- **Files:** All controller files
- **Description:** Some endpoints return raw entities, some return DTO response objects, and error responses are sometimes `Map<String, String>` with key `"erro"` and sometimes just a string. The frontend has to handle multiple response formats.
- **Fix:** Standardize all responses with a wrapper: `{ "data": ..., "message": "...", "timestamp": "..." }` for success, and `{ "error": "...", "code": "...", "timestamp": "..." }` for errors.

### 47. No service health check endpoint
- **Files:** Backend (missing)
- **Description:** No `/health` or `/actuator/health` endpoint exists for monitoring. In a SaaS application, health checks are essential for load balancers, container orchestrators, and monitoring tools.
- **Fix:** Add Spring Boot Actuator dependency and expose health/info endpoints. Configure appropriate security for actuator endpoints.

---

## Architecture Recommendations (Non-Issue, Best Practices)

These are not bugs but recommendations for a production-ready SaaS:

1. **Add Spring Profiles** — Separate `application-dev.yml`, `application-prod.yml` for environment-specific configs.
2. **Add API versioning** — Prefix routes with `/api/v1/` for future backwards compatibility.
3. **Add request/response logging** — Use a filter to log request details for debugging.
4. **Add Swagger/OpenAPI docs** — Add `springdoc-openapi` for auto-generated API documentation.
5. **Add Flyway migrations** — Replace `ddl-auto: update` with versioned SQL migrations.
6. **Add unit and integration tests** — Both backend (JUnit + MockMvc) and frontend (widget tests).
7. **Add CI/CD pipeline** — GitHub Actions or similar for automated build, test, and deploy.
8. **Add multi-tenancy** — All data is already scoped by `usuario.id`, but a proper tenant isolation layer would be more robust.
9. **Use DTOs consistently** — Some controllers return raw entities exposing all fields including internal IDs and timestamps.
10. **Add WebSocket for real-time updates** — Dashboard stats, new OS notifications, chat could benefit from realtime.

---

## Priority Order for Fixes

**Phase 1 — Ship Blockers (CRITICAL):**
1. Fix password validation mismatch (#1)
2. Fix CORS configuration (#3)
3. Fix JWT secret fallback (#5)
4. Fix JPQL LIMIT syntax (#4)
5. Implement Flyway migrations (#6)
6. Call stock deduction on OS completion (#2)

**Phase 2 — Core Quality (HIGH):**
7. Add pagination (#7)
8. Cache JWT user lookups (#8)
9. Fix RestTemplate bean (#9)
10. Fix subscription cancellation plan downgrade (#15)
11. Remove/implement WhatsApp feature (#16)
12. Fix PricingPage API client usage (#17)
13. Add exception handlers (#14)
14. Fix PlanoService query (#13)

**Phase 3 — Security & Reliability (HIGH):**
15. Password reset flow (#10)
16. Rate limiting (#12)
17. Transaction isolation (#20)
18. Input sanitization (#18)
19. Currency input validation (#19)

**Phase 4 — Polish (MEDIUM + LOW):**
20. All remaining MEDIUM and LOW issues
21. Architecture recommendations
