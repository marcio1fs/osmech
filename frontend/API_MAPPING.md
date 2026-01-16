# OSMECH Frontend - Backend API Mapping

This document shows how the Flutter frontend maps to the backend API.

## Backend URL
```
http://localhost:8080/api
```

## Authentication Endpoints

### Register
**Frontend:** `auth_service.dart` → `register()`
```dart
POST /auth/register
Headers: Content-Type: application/json
Body: {
  "nomeOficina": String,
  "email": String,
  "senha": String
}
Response: {
  "token": String,
  "tipo": String,
  "usuarioId": int,
  "nomeOficina": String,
  "email": String
}
```

### Login
**Frontend:** `auth_service.dart` → `login()`
```dart
POST /auth/login
Headers: Content-Type: application/json
Body: {
  "email": String,
  "senha": String
}
Response: {
  "token": String,
  "tipo": String,
  "usuarioId": int,
  "nomeOficina": String,
  "email": String
}
```

## Ordem de Serviço Endpoints

### List All OS
**Frontend:** `os_service.dart` → `getOrdens()`
```dart
GET /os
Headers: 
  Content-Type: application/json
  Authorization: Bearer {token}
Response: [{
  "id": int,
  "clienteId": int,
  "nomeCliente": String,
  "telefone": String,
  "veiculoId": int,
  "placa": String,
  "modelo": String,
  "descricaoProblema": String,
  "servicosRealizados": String,
  "valor": double,
  "status": String, // ABERTA, EM_ANDAMENTO, CONCLUIDA
  "createdAt": String (ISO 8601),
  "updatedAt": String (ISO 8601)
}]
```

### Create OS
**Frontend:** `os_service.dart` → `createOrdem()`
```dart
POST /os
Headers: 
  Content-Type: application/json
  Authorization: Bearer {token}
Body: {
  "nomeCliente": String,
  "telefone": String,
  "placa": String,
  "modelo": String,
  "descricaoProblema": String,
  "servicosRealizados": String,
  "valor": double,
  "status": String
}
Response: {
  // Same as GET /os response
}
```

### Update OS
**Frontend:** `os_service.dart` → `updateOrdem(id, ordem)`
```dart
PUT /os/{id}
Headers: 
  Content-Type: application/json
  Authorization: Bearer {token}
Body: {
  "nomeCliente": String,
  "telefone": String,
  "placa": String,
  "modelo": String,
  "descricaoProblema": String,
  "servicosRealizados": String,
  "valor": double,
  "status": String
}
Response: {
  // Same as GET /os response
}
```

### Delete OS
**Frontend:** `os_service.dart` → `deleteOrdem(id)`
```dart
DELETE /os/{id}
Headers: 
  Content-Type: application/json
  Authorization: Bearer {token}
Response: 200 OK or 204 No Content
```

## Model Mapping

### Frontend Models → Backend DTOs

#### Usuario (Frontend)
```dart
class Usuario {
  int? usuarioId
  String nomeOficina
  String email
}
```

#### AuthResponse (Frontend)
```dart
class AuthResponse {
  String token
  String tipo
  int usuarioId
  String nomeOficina
  String email
}
```
↕️ Maps to Backend's `AuthResponse` DTO

#### OrdemServico (Frontend)
```dart
class OrdemServico {
  int? id
  int? clienteId
  String nomeCliente
  String telefone
  int? veiculoId
  String placa
  String modelo
  String descricaoProblema
  String servicosRealizados
  double valor
  String status
  DateTime? createdAt
  DateTime? updatedAt
}
```
↕️ Maps to Backend's `OrdemServico` Entity

#### StatusOS Enum (Frontend)
```dart
enum StatusOS {
  aberta('ABERTA'),
  emAndamento('EM_ANDAMENTO'),
  concluida('CONCLUIDA')
}
```
↕️ Maps to Backend's enum values

## Data Flow Examples

### User Registration Flow
1. User fills `cadastro_page.dart` form
2. Form validation passes
3. `auth_service.dart.register()` called
4. POST to `/api/auth/register`
5. Backend returns `AuthResponse`
6. Token stored in `flutter_secure_storage`
7. Navigate to `dashboard_page.dart`

### Create OS Flow
1. User clicks FAB on dashboard
2. Navigate to `form_os_page.dart`
3. User fills all required fields
4. Form validation passes
5. `os_service.dart.createOrdem()` called
6. POST to `/api/os` with Bearer token
7. Backend returns created OS
8. Success message shown
9. Navigate back to OS list
10. List refreshed automatically

### Edit OS Flow
1. User clicks Edit on OS card
2. Navigate to `form_os_page.dart` with OS data
3. Form pre-populated with existing data
4. User modifies fields
5. Form validation passes
6. `os_service.dart.updateOrdem()` called
7. PUT to `/api/os/{id}` with Bearer token
8. Backend returns updated OS
9. Success message shown
10. Navigate back to OS list
11. List refreshed automatically

### Delete OS Flow
1. User clicks Delete on OS card
2. Confirmation dialog shown
3. User confirms
4. `os_service.dart.deleteOrdem()` called
5. DELETE to `/api/os/{id}` with Bearer token
6. Backend returns 200/204
7. Success message shown
8. List refreshed automatically

## Error Handling

### Frontend Error Messages
- "Token não encontrado. Faça login novamente." → No JWT token
- "Não autorizado. Faça login novamente." → 401 response
- "Erro ao buscar ordens de serviço" → General GET error
- "Erro ao cadastrar OS" → POST error
- "Erro ao editar OS" → PUT error
- "Erro ao excluir OS" → DELETE error

### HTTP Status Codes Handled
- 200 OK → Success
- 201 Created → Success (alternative)
- 204 No Content → Success (delete)
- 401 Unauthorized → Re-login required
- 4xx/5xx → Generic error with backend message

## Token Management

### Storage
- Token stored in: `flutter_secure_storage`
- Key: `jwt_token`
- Also stored: `usuario_id`, `nome_oficina`, `email`

### Usage
- Every protected endpoint includes:
  ```dart
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  }
  ```

### Validation
- Token checked on app startup via `AuthGate`
- Token retrieved before each API call
- Missing token → redirect to login

## Date/Time Handling

### Backend → Frontend
```dart
createdAt: "2024-01-16T10:30:00"
↓
DateTime.parse(json['createdAt'])
↓
DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
↓
"16/01/2024 10:30"
```

### Frontend → Backend
- Dates are read-only from frontend
- Backend sets `createdAt` and `updatedAt`

## Currency Handling

### Backend → Frontend
```dart
valor: 1234.56 (double)
↓
NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)
↓
"R$ 1.234,56"
```

### Frontend → Backend
```dart
"1234.56" (TextField input)
↓
double.parse(value.replaceAll(',', '.'))
↓
1234.56 (double)
```

## Complete Request/Response Examples

### Example: Create OS

**Request from Frontend:**
```http
POST http://localhost:8080/api/os HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "nomeCliente": "João Silva",
  "telefone": "(11) 98765-4321",
  "placa": "ABC-1234",
  "modelo": "Gol 1.0",
  "descricaoProblema": "Motor falhando",
  "servicosRealizados": "Troca de velas e filtro",
  "valor": 350.00,
  "status": "ABERTA"
}
```

**Response from Backend:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 1,
  "clienteId": 123,
  "nomeCliente": "João Silva",
  "telefone": "(11) 98765-4321",
  "veiculoId": 456,
  "placa": "ABC-1234",
  "modelo": "Gol 1.0",
  "descricaoProblema": "Motor falhando",
  "servicosRealizados": "Troca de velas e filtro",
  "valor": 350.00,
  "status": "ABERTA",
  "createdAt": "2024-01-16T10:30:00",
  "updatedAt": "2024-01-16T10:30:00"
}
```

## Summary

✅ All backend endpoints properly mapped
✅ All required fields included in requests
✅ All response fields properly parsed
✅ Authentication flow complete
✅ CRUD operations complete
✅ Error handling comprehensive
✅ Data formatting appropriate
✅ Token management secure

The frontend is fully aligned with the backend API specification.
