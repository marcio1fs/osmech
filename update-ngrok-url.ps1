param(
    [string]$NgrokUrl,
    [string]$FrontendUrl,
    [string]$BackendUrl,
    [switch]$SkipFrontend,
    [switch]$SkipBrowser
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($FrontendUrl) -and [string]::IsNullOrWhiteSpace($BackendUrl)) {
    if ([string]::IsNullOrWhiteSpace($NgrokUrl)) {
        Write-Host "Uso: .\\update-ngrok-url.ps1 -FrontendUrl https://xxx.ngrok-free.dev -BackendUrl https://yyy.ngrok-free.dev" -ForegroundColor Yellow
        Write-Host "Ou:  .\\update-ngrok-url.ps1 -NgrokUrl https://xxx.ngrok-free.dev" -ForegroundColor Yellow
        exit 1
    }
    $FrontendUrl = $NgrokUrl
    $BackendUrl = $NgrokUrl
}

if (-not $FrontendUrl.StartsWith("https://") -or -not $BackendUrl.StartsWith("https://")) {
    Write-Host "Use URLs https do ngrok, por exemplo: https://xxxx.ngrok-free.dev" -ForegroundColor Yellow
    exit 1
}

$envPath = Join-Path $PSScriptRoot "backend\.env"
if (-not (Test-Path $envPath)) {
    Write-Host "Arquivo .env nao encontrado em: $envPath" -ForegroundColor Red
    exit 1
}

$lines = Get-Content $envPath

function Set-EnvLine {
    param(
        [string[]]$content,
        [string]$key,
        [string]$value
    )
    $pattern = "^$key="
    $updated = $false
    $result = $content | ForEach-Object {
        if ($_ -match $pattern) {
            $updated = $true
            return "$key=$value"
        }
        return $_
    }
    if (-not $updated) {
        $result += "$key=$value"
    }
    return $result
}

$corsValue = "http://localhost:8083,http://localhost:3000,$FrontendUrl"
$lines = Set-EnvLine -content $lines -key "CORS_ORIGINS" -value $corsValue
$lines = Set-EnvLine -content $lines -key "MERCADOPAGO_SUCCESS_URL" -value "$FrontendUrl/assinatura/sucesso"
$lines = Set-EnvLine -content $lines -key "MERCADOPAGO_PENDING_URL" -value "$FrontendUrl/assinatura/pendente"
$lines = Set-EnvLine -content $lines -key "MERCADOPAGO_FAILURE_URL" -value "$FrontendUrl/assinatura/falha"
$lines = Set-EnvLine -content $lines -key "MERCADOPAGO_NOTIFICATION_URL" -value "$BackendUrl/api/mercadopago/webhook"

$lines | Set-Content $envPath

Write-Host "Atualizado backend/.env com URLs do ngrok:" -ForegroundColor Green
Write-Host "  Frontend: $FrontendUrl" -ForegroundColor Green
Write-Host "  Backend:  $BackendUrl" -ForegroundColor Green

Write-Host "Reiniciando backend..." -ForegroundColor Cyan
$backendDir = Join-Path $PSScriptRoot "backend"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "cd '$backendDir'; .\\run-dev.ps1"

Write-Host "Backend iniciado em nova janela." -ForegroundColor Green

if (-not $SkipFrontend) {
    Write-Host "Iniciando frontend..." -ForegroundColor Cyan
    $frontendDir = Join-Path $PSScriptRoot "frontend"
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "cd '$frontendDir'; flutter pub get; flutter run -d web-server --web-port 8083 --dart-define=API_URL=$BackendUrl"
    Write-Host "Frontend iniciado em nova janela." -ForegroundColor Green
}

if (-not $SkipBrowser) {
    Write-Host "Abrindo navegador..." -ForegroundColor Cyan
    Start-Process $FrontendUrl
}
