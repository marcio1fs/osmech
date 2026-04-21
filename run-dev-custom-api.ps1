param(
    [string]$ApiUrl,
    [switch]$UseChrome
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
    Write-Host "Uso: .\run-dev-custom-api.ps1 -ApiUrl http://127.0.0.1:8081" -ForegroundColor Yellow
    exit 1
}

$root = $PSScriptRoot
$backendDir = Join-Path $root "backend"
$frontendDir = Join-Path $root "frontend"

function Start-Backend {
    Write-Host "`n[OSMECH] Iniciando backend em nova janela..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendDir'; .\run-dev.ps1"
}

function Start-Frontend {
    Write-Host "[OSMECH] Iniciando frontend em nova janela..." -ForegroundColor Cyan
    if ($UseChrome) {
        Write-Host "[OSMECH] Frontend em modo Chrome (pode falhar com AppConnectionException)." -ForegroundColor Yellow
        $cmd = "cd '$frontendDir'; flutter pub get; flutter run -d chrome --web-port 8083 --dart-define=API_URL=$ApiUrl"
    } else {
        Write-Host "[OSMECH] Frontend em modo web-server (mais estavel)." -ForegroundColor Green
        $cmd = "cd '$frontendDir'; flutter pub get; flutter run -d web-server --web-port 8083 --dart-define=API_URL=$ApiUrl"
    }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
}

Start-Backend
Start-Sleep -Seconds 3
Start-Frontend
Write-Host "`n[OSMECH] Backend: $ApiUrl" -ForegroundColor Green
Write-Host "[OSMECH] Frontend: http://localhost:8083" -ForegroundColor Green
Write-Host "`nPara cadastrar usuario: http://localhost:8083 -> Cadastre-se`n" -ForegroundColor Yellow

