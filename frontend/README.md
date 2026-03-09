# OSMECH Frontend (Flutter Web)

Frontend web do OSMECH.

## Requisitos

- Flutter 3.16+
- Chrome (para `flutter run -d chrome`)

## Executar em desenvolvimento

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-port 8083 --dart-define=API_URL=http://localhost:8081/api
```

## Build de producao

```powershell
cd frontend
flutter pub get
flutter build web --release --dart-define=API_URL=https://SEU_BACKEND/api
```

Artefato gerado em:

- `frontend/build/web`

## Configuracao de API

A URL da API e controlada por `--dart-define`:

- chave: `API_URL`
- fallback no codigo: `http://localhost:8081/api`

Arquivo relacionado:

- `frontend/lib/services/api_config.dart`
- `frontend/.env.example` (referencia de valores)

## Comandos uteis

```powershell
flutter analyze
flutter test
```

## Observacoes

- Para deploy, publique apenas o conteudo de `build/web`.
- Garanta que o backend permita o dominio do frontend em `CORS_ORIGINS`.
