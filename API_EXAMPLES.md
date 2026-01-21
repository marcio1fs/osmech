# OSMECH API - Exemplos de Uso

Este arquivo contém exemplos práticos de como consumir a API do OSMECH usando `curl`, Postman ou qualquer cliente HTTP.

---

## 🔐 Autenticação

### 1. Registrar Novo Usuário

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@email.com",
    "password": "senha123",
    "phone": "(11) 98765-4321",
    "planId": 1
  }'
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "userId": 1,
  "email": "joao@email.com",
  "name": "João Silva",
  "role": "OFICINA",
  "plan": {
    "id": 1,
    "name": "PRO",
    "subscriptionEnd": "2026-02-21T00:00:00"
  }
}
```

### 2. Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@email.com",
    "password": "senha123"
  }'
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "userId": 1,
  "email": "joao@email.com",
  "name": "João Silva",
  "role": "OFICINA",
  "plan": {
    "id": 1,
    "name": "PRO",
    "subscriptionEnd": "2026-02-21T00:00:00"
  }
}
```

**⚠️ Salve o token! Você precisará dele para as próximas requisições.**

---

## 💳 Planos

### 3. Listar Todos os Planos

```bash
curl -X GET http://localhost:8080/api/plans
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "PRO",
    "price": 49.90,
    "maxServiceOrders": 50,
    "whatsappEnabled": false,
    "aiEnabled": false,
    "maxUsers": 1,
    "description": "Plano ideal para oficinas iniciantes. Até 50 OS/mês, 1 usuário."
  },
  {
    "id": 2,
    "name": "PRO+",
    "price": 79.90,
    "maxServiceOrders": 150,
    "whatsappEnabled": true,
    "aiEnabled": false,
    "maxUsers": 3,
    "description": "Plano intermediário com WhatsApp. Até 150 OS/mês, até 3 usuários."
  },
  {
    "id": 3,
    "name": "PREMIUM",
    "price": 149.90,
    "maxServiceOrders": null,
    "whatsappEnabled": true,
    "aiEnabled": true,
    "maxUsers": 10,
    "description": "Plano completo com IA e WhatsApp. OS ilimitadas, até 10 usuários."
  }
]
```

### 4. Buscar Plano por ID

```bash
curl -X GET http://localhost:8080/api/plans/2
```

**Response (200 OK):**
```json
{
  "id": 2,
  "name": "PRO+",
  "price": 79.90,
  "maxServiceOrders": 150,
  "whatsappEnabled": true,
  "aiEnabled": false,
  "maxUsers": 3,
  "description": "Plano intermediário com WhatsApp. Até 150 OS/mês, até 3 usuários."
}
```

---

## 🔧 Ordens de Serviço

**⚠️ Todas as rotas abaixo requerem autenticação JWT!**

Use o header: `Authorization: Bearer {seu-token-aqui}`

### 5. Criar Nova Ordem de Serviço

```bash
curl -X POST http://localhost:8080/api/service-orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "customerName": "Maria Santos",
    "customerPhone": "(11) 91234-5678",
    "customerEmail": "maria@email.com",
    "vehiclePlate": "XYZ-9876",
    "vehicleBrand": "Toyota",
    "vehicleModel": "Corolla",
    "vehicleYear": "2022",
    "description": "Revisão completa + troca de óleo",
    "diagnostics": "Necessário trocar filtros de ar e óleo",
    "estimatedCost": 450.00
  }'
```

**Response (201 Created):**
```json
{
  "id": 1,
  "osNumber": "OS-2026-0001",
  "customerName": "Maria Santos",
  "customerPhone": "(11) 91234-5678",
  "customerEmail": "maria@email.com",
  "vehiclePlate": "XYZ-9876",
  "vehicleBrand": "Toyota",
  "vehicleModel": "Corolla",
  "vehicleYear": "2022",
  "description": "Revisão completa + troca de óleo",
  "diagnostics": "Necessário trocar filtros de ar e óleo",
  "estimatedCost": 450.00,
  "finalCost": null,
  "status": "ABERTA",
  "createdAt": "2026-01-21T10:30:00",
  "updatedAt": "2026-01-21T10:30:00",
  "finishedAt": null
}
```

### 6. Listar Todas as OS do Usuário

```bash
curl -X GET http://localhost:8080/api/service-orders \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "osNumber": "OS-2026-0001",
    "customerName": "Maria Santos",
    "customerPhone": "(11) 91234-5678",
    "customerEmail": "maria@email.com",
    "vehiclePlate": "XYZ-9876",
    "vehicleBrand": "Toyota",
    "vehicleModel": "Corolla",
    "vehicleYear": "2022",
    "description": "Revisão completa + troca de óleo",
    "diagnostics": "Necessário trocar filtros de ar e óleo",
    "estimatedCost": 450.00,
    "finalCost": null,
    "status": "ABERTA",
    "createdAt": "2026-01-21T10:30:00",
    "updatedAt": "2026-01-21T10:30:00",
    "finishedAt": null
  }
]
```

### 7. Buscar OS por ID

```bash
curl -X GET http://localhost:8080/api/service-orders/1 \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Response (200 OK):**
```json
{
  "id": 1,
  "osNumber": "OS-2026-0001",
  "customerName": "Maria Santos",
  "customerPhone": "(11) 91234-5678",
  "customerEmail": "maria@email.com",
  "vehiclePlate": "XYZ-9876",
  "vehicleBrand": "Toyota",
  "vehicleModel": "Corolla",
  "vehicleYear": "2022",
  "description": "Revisão completa + troca de óleo",
  "diagnostics": "Necessário trocar filtros de ar e óleo",
  "estimatedCost": 450.00,
  "finalCost": null,
  "status": "ABERTA",
  "createdAt": "2026-01-21T10:30:00",
  "updatedAt": "2026-01-21T10:30:00",
  "finishedAt": null
}
```

### 8. Atualizar OS

```bash
curl -X PUT http://localhost:8080/api/service-orders/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "status": "EM_ANDAMENTO",
    "diagnostics": "Iniciado serviço de troca de óleo e filtros",
    "finalCost": 480.00
  }'
```

**Response (200 OK):**
```json
{
  "id": 1,
  "osNumber": "OS-2026-0001",
  "customerName": "Maria Santos",
  "customerPhone": "(11) 91234-5678",
  "customerEmail": "maria@email.com",
  "vehiclePlate": "XYZ-9876",
  "vehicleBrand": "Toyota",
  "vehicleModel": "Corolla",
  "vehicleYear": "2022",
  "description": "Revisão completa + troca de óleo",
  "diagnostics": "Iniciado serviço de troca de óleo e filtros",
  "estimatedCost": 450.00,
  "finalCost": 480.00,
  "status": "EM_ANDAMENTO",
  "createdAt": "2026-01-21T10:30:00",
  "updatedAt": "2026-01-21T11:45:00",
  "finishedAt": null
}
```

### 9. Concluir OS

```bash
curl -X PUT http://localhost:8080/api/service-orders/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "status": "CONCLUIDA",
    "diagnostics": "Serviço concluído com sucesso. Todos os filtros trocados.",
    "finalCost": 480.00
  }'
```

**Response (200 OK):**
```json
{
  "id": 1,
  "osNumber": "OS-2026-0001",
  "customerName": "Maria Santos",
  "customerPhone": "(11) 91234-5678",
  "customerEmail": "maria@email.com",
  "vehiclePlate": "XYZ-9876",
  "vehicleBrand": "Toyota",
  "vehicleModel": "Corolla",
  "vehicleYear": "2022",
  "description": "Revisão completa + troca de óleo",
  "diagnostics": "Serviço concluído com sucesso. Todos os filtros trocados.",
  "estimatedCost": 450.00,
  "finalCost": 480.00,
  "status": "CONCLUIDA",
  "createdAt": "2026-01-21T10:30:00",
  "updatedAt": "2026-01-21T14:20:00",
  "finishedAt": "2026-01-21T14:20:00"
}
```

### 10. Deletar OS

```bash
curl -X DELETE http://localhost:8080/api/service-orders/1 \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Response (204 No Content)**

---

## 📊 Status de OS Disponíveis

| Status | Descrição |
|--------|-----------|
| `ABERTA` | Ordem de serviço criada |
| `EM_ANALISE` | Mecânico está analisando o veículo |
| `EM_ANDAMENTO` | Serviço está sendo executado |
| `AGUARDANDO_PECAS` | Aguardando chegada de peças |
| `CONCLUIDA` | Serviço finalizado |
| `CANCELADA` | Ordem cancelada |
| `ENTREGUE` | Veículo entregue ao cliente |

---

## ❌ Tratamento de Erros

### Erro de Autenticação (401)

```bash
curl -X GET http://localhost:8080/api/service-orders
```

**Response (401 Unauthorized):**
```json
{
  "timestamp": "2026-01-21T10:30:00",
  "status": 401,
  "error": "Unauthorized",
  "message": "Token não fornecido",
  "path": "/api/service-orders"
}
```

### Erro de Validação (400)

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jo",
    "email": "invalido",
    "password": "123"
  }'
```

**Response (400 Bad Request):**
```json
{
  "timestamp": "2026-01-21T10:30:00",
  "status": 400,
  "errors": [
    "Nome deve ter no mínimo 3 caracteres",
    "Email inválido",
    "Senha deve ter no mínimo 6 caracteres"
  ]
}
```

### Recurso Não Encontrado (404)

```bash
curl -X GET http://localhost:8080/api/service-orders/999 \
  -H "Authorization: Bearer token..."
```

**Response (404 Not Found):**
```json
{
  "timestamp": "2026-01-21T10:30:00",
  "status": 404,
  "error": "Not Found",
  "message": "Ordem de serviço não encontrada"
}
```

---

## 🔗 Testando com Postman

### 1. Importar Collection

Crie uma nova Collection no Postman e adicione estas variáveis:

- `baseUrl`: `http://localhost:8080`
- `token`: (será preenchido após login)

### 2. Configurar Autorização

Para rotas protegidas:
1. Vá em **Authorization**
2. Type: **Bearer Token**
3. Token: `{{token}}`

### 3. Script de Login Automático

No request de Login, adicione este script em **Tests**:

```javascript
if (pm.response.code === 200) {
    const jsonData = pm.response.json();
    pm.collectionVariables.set("token", jsonData.token);
    pm.collectionVariables.set("userId", jsonData.userId);
}
```

---

## 🧪 Testes de Integração

### Script Completo de Teste

```bash
#!/bin/bash

BASE_URL="http://localhost:8080/api"

echo "1. Testando registro..."
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@email.com",
    "password": "test123"
  }')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')
echo "Token obtido: $TOKEN"

echo "2. Criando ordem de serviço..."
OS_RESPONSE=$(curl -s -X POST $BASE_URL/service-orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "customerName": "Cliente Teste",
    "vehiclePlate": "ABC-1234",
    "description": "Teste de integração",
    "estimatedCost": 100.00
  }')

OS_ID=$(echo $OS_RESPONSE | jq -r '.id')
echo "OS criada com ID: $OS_ID"

echo "3. Listando ordens de serviço..."
curl -s -X GET $BASE_URL/service-orders \
  -H "Authorization: Bearer $TOKEN" | jq

echo "Testes concluídos!"
```

---

## 📖 Próximos Endpoints (Roadmap)

### Clientes
- `GET /api/customers` - Listar clientes
- `POST /api/customers` - Criar cliente
- `GET /api/customers/{id}` - Buscar cliente
- `PUT /api/customers/{id}` - Atualizar cliente
- `DELETE /api/customers/{id}` - Deletar cliente

### Veículos
- `GET /api/vehicles` - Listar veículos
- `POST /api/vehicles` - Cadastrar veículo
- `GET /api/vehicles/{id}` - Buscar veículo
- `PUT /api/vehicles/{id}` - Atualizar veículo

### Relatórios
- `GET /api/reports/dashboard` - Dashboard analítico
- `GET /api/reports/revenue` - Relatório de faturamento
- `GET /api/reports/os-by-status` - OS por status

---

**Última atualização:** 21/01/2026
