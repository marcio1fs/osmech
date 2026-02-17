$ErrorActionPreference = "Continue"

Write-Host "========================================="
Write-Host "   TESTE API OSMECH - CORRECAO 403->401"
Write-Host "========================================="
Write-Host ""

# 1. Health Check
Write-Host "--- 1. HEALTH CHECK ---"
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8081/actuator/health" -TimeoutSec 30
    Write-Host "PASS: Backend UP ($($health.status))"
} catch {
    Write-Host "FAIL: Backend indisponivel"
    exit 1
}

# 2. Teste SEM token (esperado 401)
Write-Host ""
Write-Host "--- 2. SEM TOKEN (esperado 401) ---"
try {
    Invoke-WebRequest -Uri "http://localhost:8081/api/os/dashboard" -UseBasicParsing -TimeoutSec 30
    Write-Host "FAIL: Deveria ter retornado erro"
} catch {
    $code = [int]$_.Exception.Response.StatusCode
    if ($code -eq 401) {
        Write-Host "PASS: Retornou 401 (correto!)"
    } else {
        Write-Host "FAIL: Retornou $code (esperado 401)"
    }
}

# 3. Teste com token INVALIDO (esperado 401)
Write-Host ""
Write-Host "--- 3. TOKEN INVALIDO (esperado 401) ---"
try {
    Invoke-WebRequest -Uri "http://localhost:8081/api/os/dashboard" -Headers @{"Authorization"="Bearer token.invalido.aqui"} -UseBasicParsing -TimeoutSec 30
    Write-Host "FAIL: Deveria ter retornado erro"
} catch {
    $code = [int]$_.Exception.Response.StatusCode
    if ($code -eq 401) {
        Write-Host "PASS: Retornou 401 (correto!)"
    } else {
        Write-Host "FAIL: Retornou $code (esperado 401)"
    }
}

# 4. Login
Write-Host ""
Write-Host "--- 4. LOGIN ---"
try {
    $loginResp = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/login" -Method POST -Body '{"email":"admintest@test.com","senha":"admin12345"}' -ContentType "application/json" -TimeoutSec 30
    $token = $loginResp.token
    Write-Host "PASS: Login OK (email: $($loginResp.email), role: $($loginResp.role))"
} catch {
    Write-Host "FAIL: Login falhou - $($_.Exception.Message)"
    exit 1
}

$headers = @{"Authorization"="Bearer $token"}

# 5. Dashboard
Write-Host ""
Write-Host "--- 5. DASHBOARD ---"
try {
    $dash = Invoke-RestMethod -Uri "http://localhost:8081/api/os/dashboard" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Dashboard OK (totalOS: $($dash.totalOS))"
} catch {
    Write-Host "FAIL: Dashboard - $($_.Exception.Message)"
}

# 6. Perfil
Write-Host ""
Write-Host "--- 6. PERFIL ---"
try {
    $perfil = Invoke-RestMethod -Uri "http://localhost:8081/api/usuario/perfil" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Perfil OK (nome: $($perfil.nome), email: $($perfil.email))"
} catch {
    Write-Host "FAIL: Perfil - $($_.Exception.Message)"
}

# 7. Lista OS
Write-Host ""
Write-Host "--- 7. LISTA OS ---"
try {
    $os = Invoke-RestMethod -Uri "http://localhost:8081/api/os" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: OS listadas ($($os.Count) registros)"
} catch {
    Write-Host "FAIL: Lista OS - $($_.Exception.Message)"
}

# 8. Estoque
Write-Host ""
Write-Host "--- 8. ESTOQUE ---"
try {
    $stock = Invoke-RestMethod -Uri "http://localhost:8081/api/stock" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Estoque listado ($($stock.Count) itens)"
} catch {
    Write-Host "FAIL: Estoque - $($_.Exception.Message)"
}

# 9. Financeiro Summary
Write-Host ""
Write-Host "--- 9. FINANCEIRO ---"
try {
    $fin = Invoke-RestMethod -Uri "http://localhost:8081/api/finance/summary" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Financeiro OK"
} catch {
    Write-Host "FAIL: Financeiro - $($_.Exception.Message)"
}

# 10. Categorias
Write-Host ""
Write-Host "--- 10. CATEGORIAS ---"
try {
    $cats = Invoke-RestMethod -Uri "http://localhost:8081/api/finance/category" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Categorias ($($cats.Count) registros)"
} catch {
    Write-Host "FAIL: Categorias - $($_.Exception.Message)"
}

# 11. Planos (publico)
Write-Host ""
Write-Host "--- 11. PLANOS (publico) ---"
try {
    $planos = Invoke-RestMethod -Uri "http://localhost:8081/api/planos" -TimeoutSec 30
    Write-Host "PASS: Planos ($($planos.Count) planos)"
} catch {
    Write-Host "FAIL: Planos - $($_.Exception.Message)"
}

# 12. Chat
Write-Host ""
Write-Host "--- 12. CHAT ---"
try {
    $sessions = Invoke-RestMethod -Uri "http://localhost:8081/api/chat/sessions" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Chat sessions OK ($($sessions.Count) sessoes)"
} catch {
    Write-Host "FAIL: Chat - $($_.Exception.Message)"
}

# 13. Pagamentos
Write-Host ""
Write-Host "--- 13. PAGAMENTOS ---"
try {
    $pag = Invoke-RestMethod -Uri "http://localhost:8081/api/pagamento" -Headers $headers -TimeoutSec 30
    Write-Host "PASS: Pagamentos ($($pag.Count) registros)"
} catch {
    Write-Host "FAIL: Pagamentos - $($_.Exception.Message)"
}

# 14. CORS preflight
Write-Host ""
Write-Host "--- 14. CORS PREFLIGHT ---"
try {
    $corsResp = Invoke-WebRequest -Uri "http://localhost:8081/api/os/dashboard" -Method OPTIONS -Headers @{"Origin"="http://localhost:8083";"Access-Control-Request-Method"="GET";"Access-Control-Request-Headers"="Authorization"} -UseBasicParsing -TimeoutSec 30
    $code = $corsResp.StatusCode
    $acaoHeader = $corsResp.Headers["Access-Control-Allow-Origin"]
    Write-Host "PASS: CORS OPTIONS $code (Allow-Origin: $acaoHeader)"
} catch {
    Write-Host "FAIL: CORS - $($_.Exception.Message)"
}

Write-Host ""
Write-Host "========================================="
Write-Host "   TESTES CONCLUIDOS"
Write-Host "========================================="
