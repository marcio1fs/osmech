# =========================
# OSMECH - Executar em modo desenvolvimento
# =========================
# Este script inicia backend e frontend em janelas separadas.
# Pré-requisitos: PostgreSQL rodando, Java 17+, Flutter instalado, Maven
#
# Uso (execute na raiz do projeto):
#   .\run-dev.ps1              # Inicia backend + frontend
#   .\run-dev.ps1 -BackendOnly # Apenas backend
#   .\run-dev.ps1 -FrontendOnly # Apenas frontend
#   .\run-dev.ps1 -UseChrome   # Frontend via Chrome (debug DWDS)

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$UseChrome
)

$ErrorActionPreference = "Stop"
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
        $cmd = "cd '$frontendDir'; flutter pub get; flutter run -d chrome --web-port 8083 --dart-define=API_URL=http://localhost:8081"
    } else {
        Write-Host "[OSMECH] Frontend em modo web-server (mais estável)." -ForegroundColor Green
        $cmd = "cd '$frontendDir'; flutter pub get; flutter run -d web-server --web-port 8083 --dart-define=API_URL=http://localhost:8081"
    }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
}

if (-not $BackendOnly -and -not $FrontendOnly) {
    Start-Backend
    Start-Sleep -Seconds 3
    Start-Frontend
    Write-Host "`n[OSMECH] Backend: http://localhost:8081" -ForegroundColor Green
    Write-Host "[OSMECH] Frontend: http://localhost:8083" -ForegroundColor Green
    Write-Host "`nPara cadastrar usuario: http://localhost:8083 -> Cadastre-se`n" -ForegroundColor Yellow
} elseif ($BackendOnly) {
    Start-Backend
    Write-Host "`n[OSMECH] Backend: http://localhost:8081`n" -ForegroundColor Green
} elseif ($FrontendOnly) {
    Start-Frontend
    Write-Host "`n[OSMECH] Frontend: http://localhost:8083`n" -ForegroundColor Green
}
