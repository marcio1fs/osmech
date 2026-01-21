#!/bin/bash

echo "🚀 OSMECH - Script de Inicialização"
echo "===================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verifica PostgreSQL
echo -e "${YELLOW}📊 Verificando PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL não encontrado. Instale primeiro!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ PostgreSQL encontrado${NC}"
echo ""

# Verifica Java
echo -e "${YELLOW}☕ Verificando Java...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java não encontrado. Instale Java 17+!${NC}"
    exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo -e "${GREEN}✅ Java encontrado: $JAVA_VERSION${NC}"
echo ""

# Verifica Maven
echo -e "${YELLOW}📦 Verificando Maven...${NC}"
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven não encontrado. Instale Maven 3.8+!${NC}"
    exit 1
fi
MVN_VERSION=$(mvn -version | head -n 1)
echo -e "${GREEN}✅ Maven encontrado: $MVN_VERSION${NC}"
echo ""

# Cria banco de dados se não existir
echo -e "${YELLOW}🗄️  Configurando banco de dados...${NC}"
PGPASSWORD=3782 psql -U postgres -h localhost -tc "SELECT 1 FROM pg_database WHERE datname = 'oficina_db'" | grep -q 1 || \
PGPASSWORD=3782 psql -U postgres -h localhost -c "CREATE DATABASE oficina_db;"
echo -e "${GREEN}✅ Banco de dados configurado${NC}"
echo ""

# Compila o backend
echo -e "${YELLOW}🔨 Compilando backend...${NC}"
cd backend
mvn clean install -DskipTests
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro ao compilar backend!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Backend compilado com sucesso${NC}"
echo ""

# Inicia o backend
echo -e "${YELLOW}🚀 Iniciando backend na porta 8080...${NC}"
mvn spring-boot:run &
BACKEND_PID=$!
echo -e "${GREEN}✅ Backend iniciado (PID: $BACKEND_PID)${NC}"
echo ""

# Aguarda backend inicializar
echo -e "${YELLOW}⏳ Aguardando backend inicializar (30s)...${NC}"
sleep 30

# Verifica se backend está rodando
if curl -s http://localhost:8080/api/plans > /dev/null; then
    echo -e "${GREEN}✅ Backend está respondendo!${NC}"
else
    echo -e "${RED}⚠️  Backend pode não estar respondendo corretamente${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ OSMECH Backend iniciado com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📍 Backend API: http://localhost:8080"
echo -e "📍 Documentação: Veja README.md"
echo ""
echo -e "Para parar o backend: ${YELLOW}kill $BACKEND_PID${NC}"
echo ""
