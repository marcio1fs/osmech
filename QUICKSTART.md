# 🚀 OSMECH - Guia Rápido de Início

## ⚡ Start Rápido (5 minutos)

### 1️⃣ Clone o Projeto
```bash
git clone https://github.com/marcio1fs/osmech.git
cd osmech
```

### 2️⃣ Configure o PostgreSQL
```bash
# Criar banco de dados
psql -U postgres
CREATE DATABASE oficina_db;
\q
```

### 3️⃣ Inicie o Backend
```bash
cd backend
mvn spring-boot:run
```

✅ Backend rodando em: http://localhost:8080

### 4️⃣ Inicie o Frontend (opcional)
```bash
cd frontend
flutter pub get
flutter run
```

---

## 📋 Checklist Pré-Instalação

Antes de começar, verifique se você tem:

- [ ] Java 17+ instalado (`java -version`)
- [ ] Maven 3.8+ instalado (`mvn -version`)
- [ ] PostgreSQL instalado e rodando
- [ ] (Opcional) Flutter 3.0+ para o app mobile

---

## 🧪 Teste Rápido da API

### 1. Listar Planos (sem autenticação)
```bash
curl http://localhost:8080/api/plans
```

### 2. Registrar Usuário
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Teste",
    "email": "teste@email.com",
    "password": "senha123"
  }'
```

### 3. Fazer Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@email.com",
    "password": "senha123"
  }'
```

**Copie o token da resposta!**

### 4. Criar Ordem de Serviço
```bash
curl -X POST http://localhost:8080/api/service-orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{
    "customerName": "João Silva",
    "vehiclePlate": "ABC-1234",
    "description": "Troca de óleo"
  }'
```

---

## 🐛 Resolução de Problemas

### Erro: "Connection refused" ao PostgreSQL
```bash
# Verificar se PostgreSQL está rodando
sudo service postgresql status

# Iniciar PostgreSQL
sudo service postgresql start
```

### Erro: "Port 8080 already in use"
```bash
# Encontrar processo usando a porta
lsof -i :8080

# Matar o processo
kill -9 PID
```

### Erro: "JAVA_HOME not set"
```bash
# Linux/Mac
export JAVA_HOME=/path/to/java
export PATH=$JAVA_HOME/bin:$PATH

# Windows
set JAVA_HOME=C:\path\to\java
set PATH=%JAVA_HOME%\bin;%PATH%
```

### Backend não inicia
```bash
# Limpar e recompilar
cd backend
mvn clean install
mvn spring-boot:run
```

---

## 📱 Acessar o App

### Via Flutter (desenvolvimento)
```bash
cd frontend
flutter run
```

### Via Web
```bash
cd frontend
flutter run -d chrome
```

### Via Android (emulador)
```bash
flutter run
```

---

## 🎯 Próximos Passos

1. ✅ Projeto rodando localmente
2. 📖 Leia o [README.md](README.md) completo
3. 💻 Explore os [exemplos de API](API_EXAMPLES.md)
4. 🛠️ Veja o [guia de desenvolvimento](DESENVOLVIMENTO.md)
5. 🚀 Comece a desenvolver!

---

## 📞 Precisa de Ajuda?

- 📖 **Documentação:** Veja README.md
- 🐛 **Issues:** https://github.com/marcio1fs/osmech/issues
- 💬 **Discussões:** https://github.com/marcio1fs/osmech/discussions

---

## 📊 Estrutura do Projeto

```
osmech/
├── backend/          # API REST Spring Boot
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       └── resources/
│   └── pom.xml
│
├── frontend/         # App Flutter
│   ├── lib/
│   │   ├── pages/
│   │   ├── services/
│   │   └── models/
│   └── pubspec.yaml
│
└── docs/            # Documentação
    ├── README.md
    ├── API_EXAMPLES.md
    └── DESENVOLVIMENTO.md
```

---

## ✨ Features Implementadas

✅ Autenticação JWT  
✅ CRUD de Ordens de Serviço  
✅ Sistema de Planos (PRO, PRO+, PREMIUM)  
✅ Interface Mobile (Flutter)  
✅ API REST completa  
✅ Validações e segurança  

## 🚧 Em Desenvolvimento

🔄 Integração WhatsApp  
🔄 IA para diagnósticos  
🔄 Gateway de pagamento  
🔄 Relatórios avançados  

---

**Última atualização:** 21/01/2026

**Boa sorte com o desenvolvimento! 🚀**
