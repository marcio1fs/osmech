param(
    [string]$ApiBase = "http://localhost:8081/api",
    [string]$Email = "admintest@test.com",
    [string]$Senha = "admin12345",
    [string]$PlanoCodigo = "PRO",
    [int]$TimeoutSec = 180,
    [int]$PollSec = 5,
    [string]$BackendLogPath = ".\backend-live-out.log"
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n--- $msg ---" -ForegroundColor Cyan }
function Write-Pass($msg) { Write-Host "PASS: $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "INFO: $msg" -ForegroundColor Yellow }

function Try-InvokeRestJson {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers,
        [object]$Body
    )
    try {
        if ($null -ne $Body) {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30
        }
        return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -TimeoutSec 30
    } catch {
        return $null
    }
}

$results = [ordered]@{
    "API healthy" = $false
    "Login OK" = $false
    "Checkout criado" = $false
    "Webhook processado (indireto)" = $false
    "Pagamento aprovado" = $false
    "Assinatura ativa" = $false
    "Plano usuario atualizado" = $false
}

Write-Host "========================================="
Write-Host " TESTE POS-PAGAMENTO MERCADO PAGO"
Write-Host "========================================="

Write-Step "1) Health"
try {
    $health = Invoke-RestMethod -Uri "$ApiBase/../actuator/health" -TimeoutSec 15
    if ($health.status -eq "UP") {
        $results["API healthy"] = $true
        Write-Pass "Backend UP"
    } else {
        Write-Fail "Backend respondeu, mas nao esta UP"
    }
} catch {
    Write-Fail "Backend indisponivel em $ApiBase"
}

if (-not $results["API healthy"]) {
    Write-Host "`nEncerrado: backend fora do ar." -ForegroundColor Red
    exit 1
}

Write-Step "2) Login"
$login = Try-InvokeRestJson -Uri "$ApiBase/auth/login" -Method "POST" -Body @{
    email = $Email
    senha = $Senha
}

if ($null -eq $login -or [string]::IsNullOrWhiteSpace($login.token)) {
    Write-Fail "Falha no login com $Email"
    exit 1
}

$results["Login OK"] = $true
Write-Pass "Login realizado"
$headers = @{ Authorization = "Bearer $($login.token)" }

Write-Step "3) Criar checkout da assinatura ($PlanoCodigo)"
$assinaturaInit = Try-InvokeRestJson -Uri "$ApiBase/v1/assinaturas/iniciar" -Method "POST" -Headers $headers -Body @{
    planoCodigo = $PlanoCodigo
}

if ($null -eq $assinaturaInit) {
    Write-Fail "Nao foi possivel criar assinatura/checkout"
} else {
    $checkout = $assinaturaInit.checkoutUrl
    if (-not [string]::IsNullOrWhiteSpace($checkout)) {
        $results["Checkout criado"] = $true
        Write-Pass "Checkout criado"
        Write-Info "AssinaturaId=$($assinaturaInit.id) PreferenceId=$($assinaturaInit.preferenceId)"
        Write-Host "URL: $checkout"
    } else {
        Write-Fail "Resposta sem checkoutUrl"
    }
}

if (-not $results["Checkout criado"]) {
    Write-Host "`nEncerrado: nao foi possivel iniciar checkout." -ForegroundColor Red
    exit 1
}

Write-Step "4) Aguardando webhook/status (timeout ${TimeoutSec}s)"
Write-Info "Finalize o pagamento no checkout e volte para acompanhar."

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$lastPayment = $null
$lastAssinatura = $null

while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSec) {
    $pagamentos = Try-InvokeRestJson -Uri "$ApiBase/pagamento" -Method "GET" -Headers $headers
    if ($pagamentos) {
        $lastPayment = $pagamentos |
            Where-Object { $_.tipo -eq "ASSINATURA" -and $_.referenciaId -eq $assinaturaInit.id } |
            Select-Object -First 1
    }

    $lastAssinatura = Try-InvokeRestJson -Uri "$ApiBase/v1/assinaturas/ativa" -Method "GET" -Headers $headers
    if ($null -eq $lastAssinatura) {
        $historico = Try-InvokeRestJson -Uri "$ApiBase/v1/assinaturas/historico" -Method "GET" -Headers $headers
        if ($historico -and $historico.Count -gt 0) {
            $lastAssinatura = $historico | Select-Object -First 1
        }
    }

    $paymentStatus = if ($lastPayment) { $lastPayment.status } else { "N/A" }
    $assinaturaStatus = if ($lastAssinatura) { $lastAssinatura.status } else { "N/A" }
    Write-Host ("Status atual -> Pagamento: {0} | Assinatura: {1}" -f $paymentStatus, $assinaturaStatus)

    if ($paymentStatus -eq "PAGO") {
        $results["Pagamento aprovado"] = $true
    }
    if ($assinaturaStatus -eq "ACTIVE") {
        $results["Assinatura ativa"] = $true
    }
    if ($results["Pagamento aprovado"] -and $results["Assinatura ativa"]) {
        break
    }

    Start-Sleep -Seconds $PollSec
}

if ($results["Pagamento aprovado"] -or $results["Assinatura ativa"]) {
    $results["Webhook processado (indireto)"] = $true
}

Write-Step "5) Validar plano do usuario"
$perfil = Try-InvokeRestJson -Uri "$ApiBase/usuario/perfil" -Method "GET" -Headers $headers
if ($perfil) {
    Write-Info "Perfil: email=$($perfil.email) plano=$($perfil.plano) ativo=$($perfil.ativo)"
    if (($perfil.plano -eq $PlanoCodigo) -and ($perfil.ativo -eq $true)) {
        $results["Plano usuario atualizado"] = $true
        Write-Pass "Plano/ativo alinhados com assinatura"
    } else {
        Write-Fail "Plano/ativo ainda nao refletiram o pagamento"
    }
} else {
    Write-Fail "Nao foi possivel consultar /usuario/perfil"
}

Write-Step "6) Evidencia de webhook em log (opcional)"
if (Test-Path $BackendLogPath) {
    $match = Select-String -Path $BackendLogPath -Pattern "Webhook Mercado Pago processado" -SimpleMatch | Select-Object -Last 1
    if ($match) {
        Write-Pass "Encontrado no log: $($match.Line)"
    } else {
        Write-Info "Nenhuma linha de webhook encontrada em $BackendLogPath"
    }
} else {
    Write-Info "Log nao encontrado em $BackendLogPath"
}

Write-Host "`n========================================="
Write-Host " RESUMO"
Write-Host "========================================="

$allPass = $true
foreach ($k in $results.Keys) {
    $v = $results[$k]
    if ($v) {
        Write-Host ("[PASS] {0}" -f $k) -ForegroundColor Green
    } else {
        Write-Host ("[FAIL] {0}" -f $k) -ForegroundColor Red
        $allPass = $false
    }
}

if ($lastPayment) {
    Write-Host "`nPagamento final:"
    $lastPayment | Select-Object id, tipo, referenciaId, status, transacaoExternaId, pagoEm | Format-List
}

if ($lastAssinatura) {
    Write-Host "Assinatura final:"
    $lastAssinatura | Select-Object id, planoCodigo, status, proximaCobranca | Format-List
}

if ($perfil) {
    Write-Host "Usuario final:"
    $perfil | Select-Object id, email, plano, ativo | Format-List
}

if ($allPass) {
    Write-Host "`nTeste concluido com SUCESSO." -ForegroundColor Green
    exit 0
}

Write-Host "`nTeste concluido com pendencias. Revise os itens FAIL." -ForegroundColor Yellow
exit 2
