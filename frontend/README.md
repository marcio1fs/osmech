# OSMECH Frontend - Flutter

Sistema de gestão para oficinas mecânicas - Aplicativo móvel/web desenvolvido em Flutter.

## Estrutura do Projeto

```
lib/
├── main.dart                          # Ponto de entrada da aplicação
├── models/                            # Modelos de dados
│   ├── usuario.dart                   # Modelo Usuario e AuthResponse
│   └── ordem_servico.dart             # Modelo OrdemServico e StatusOS enum
├── services/                          # Serviços de comunicação com API
│   ├── auth_service.dart              # Autenticação (login/register)
│   └── os_service.dart                # CRUD de Ordens de Serviço
└── pages/                             # Telas da aplicação
    ├── login_page.dart                # Tela de login
    ├── cadastro_page.dart             # Tela de cadastro
    ├── dashboard_page.dart            # Dashboard principal
    ├── ordens_servico_page.dart       # Lista de Ordens de Serviço
    ├── form_os_page.dart              # Formulário de criação/edição de OS
    └── configuracoes_page.dart        # Tela de configurações e perfil
```

## Funcionalidades Implementadas

### ✅ Autenticação
- **Login** com e-mail e senha
- **Cadastro** com nome da oficina, e-mail e senha
- Validação de formulários
- Armazenamento seguro de token JWT com `flutter_secure_storage`
- Persistência de sessão

### ✅ Dashboard
- Exibição do nome da oficina
- Contador de Ordens de Serviço abertas
- Contador de Ordens de Serviço concluídas
- Ações rápidas para navegação
- Pull-to-refresh

### ✅ Ordens de Serviço
- **Listagem** de todas as OS com cards detalhados
- **Filtros** por status (Todas, Abertas, Em Andamento, Concluídas)
- **Criação** de novas OS
- **Edição** de OS existentes
- **Exclusão** de OS com confirmação
- Exibição de todos os campos:
  - Nome do cliente
  - Telefone
  - Placa e modelo do veículo
  - Descrição do problema
  - Serviços realizados
  - Valor formatado (R$)
  - Status com ícone e cor
  - Data de criação

### ✅ Formulário de OS
- Campos para todos os dados obrigatórios
- Validações completas:
  - Nome do cliente (obrigatório)
  - Telefone (obrigatório)
  - Placa (obrigatório, convertida para maiúsculas)
  - Modelo (obrigatório)
  - Descrição do problema (obrigatório)
  - Serviços realizados (obrigatório)
  - Valor (obrigatório, numérico, maior que 0)
  - Status (dropdown com 3 opções)
- Modo de criação e edição no mesmo componente
- Loading states e feedback visual

### ✅ Configurações
- Exibição do perfil da oficina
- Logout com confirmação
- Opções para funcionalidades futuras

## Tecnologias Utilizadas

### Dependências
- **http ^1.1.0**: Requisições HTTP para a API
- **flutter_secure_storage ^9.0.0**: Armazenamento seguro de tokens
- **provider ^6.1.1**: Gerenciamento de estado (preparado para uso)
- **intl ^0.18.1**: Formatação de datas e valores monetários

### Padrões de Design
- **Material Design 3**: Interface moderna e consistente
- **Separação de responsabilidades**: Models, Services, Pages
- **Validação de formulários**: GlobalKey<FormState>
- **Async/Await**: Operações assíncronas
- **Error handling**: Try-catch com feedback ao usuário
- **Loading states**: Indicadores de carregamento

## API Backend

O frontend se comunica com o backend em `http://localhost:8080/api`:

### Endpoints de Autenticação
- `POST /auth/register` - Cadastro de nova oficina
- `POST /auth/login` - Login com e-mail e senha

### Endpoints de Ordem de Serviço
- `GET /os` - Listar todas as OS (requer autenticação)
- `POST /os` - Criar nova OS (requer autenticação)
- `PUT /os/{id}` - Atualizar OS (requer autenticação)
- `DELETE /os/{id}` - Excluir OS (requer autenticação)

## Como Executar

### Pré-requisitos
- Flutter SDK 3.0.0 ou superior
- Dart SDK
- Backend OSMECH rodando em http://localhost:8080

### Instalação
```bash
cd frontend
flutter pub get
```

### Execução
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Validações Implementadas

### Login
- E-mail obrigatório e formato válido (@)
- Senha obrigatória (mínimo 6 caracteres)

### Cadastro
- Nome da oficina obrigatório (mínimo 3 caracteres)
- E-mail obrigatório e formato válido (@)
- Senha obrigatória (mínimo 6 caracteres)
- Confirmação de senha (deve coincidir)

### Ordem de Serviço
- Nome do cliente obrigatório
- Telefone obrigatório
- Placa obrigatória
- Modelo obrigatório
- Descrição do problema obrigatória
- Serviços realizados obrigatório
- Valor obrigatório e numérico (> 0)
- Status obrigatório (enum)

## Estados de Loading

Todas as operações assíncronas exibem:
- CircularProgressIndicator durante o carregamento
- Desabilitação de botões durante operações
- Feedback visual com SnackBar (sucesso/erro)

## Tratamento de Erros

- Mensagens de erro amigáveis ao usuário
- SnackBars coloridos (vermelho para erros, verde para sucesso)
- Validação antes de enviar dados ao servidor
- Proteção contra navegação durante carregamento

## Formatação

- **Valores monetários**: R$ 1.234,56 (locale pt_BR)
- **Datas**: dd/MM/yyyy HH:mm
- **Placa**: Convertida para maiúsculas automaticamente

## Navegação

Rotas implementadas:
- `/login` - Tela de login
- `/cadastro` - Tela de cadastro
- `/dashboard` - Dashboard principal (rota protegida)
- `/ordens_servico` - Lista de OS (rota protegida)
- `/form_os` - Formulário de OS (rota protegida)
- `/configuracoes` - Configurações (rota protegida)

## Segurança

- Tokens JWT armazenados de forma segura com `flutter_secure_storage`
- Header `Authorization: Bearer {token}` em todas as requisições protegidas
- Validação de token na inicialização (AuthGate)
- Logout limpa todos os dados armazenados

## Próximas Melhorias

- [ ] Provider para gerenciamento de estado global
- [ ] Testes unitários e de widget
- [ ] Testes de integração
- [ ] Suporte offline
- [ ] Sincronização em background
- [ ] Notificações push
- [ ] Relatórios e gráficos
- [ ] Exportação de dados
- [ ] Tema escuro

## Observações

Este é o MVP (Minimum Viable Product) do OSMECH, focado nas funcionalidades essenciais para gestão de ordens de serviço em oficinas mecânicas.
