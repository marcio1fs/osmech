# =================================================================
# OSMECH — Deploy fix: Recibo para impressora Bematec MP-20 (76 mm)
# Execute: .\deploy_recibo_fix.ps1
# =================================================================

$VPS      = "148.230.79.103"
$USER     = "root"
$REMOTE   = "${USER}@${VPS}"
$SSH      = "C:\Windows\System32\OpenSSH\ssh.exe"
$SCP      = "C:\Windows\System32\OpenSSH\scp.exe"
$SSH_OPTS = "-o StrictHostKeyChecking=no"

$BuildSrc  = ".\frontend\build\web\*"
$RemoteApp = "/var/www/osmech.com.br/app"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OSMECH — Fix Recibo Impressora MP-20  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Correcao aplicada:" -ForegroundColor White
Write-Host "  - PDF gerado agora em 76 mm (papel do MP-20)" -ForegroundColor White
Write-Host "  - Fonte Courier 9pt calibrada para 76 mm" -ForegroundColor White
Write-Host "  - Altura continua (modo bobina)" -ForegroundColor White
Write-Host "  - Linhas de total em negrito" -ForegroundColor White
Write-Host ""

# Verifica se o build existe
if (-not (Test-Path ".\frontend\build\web\index.html")) {
    Write-Host "ERRO: Build nao encontrado em .\frontend\build\web\" -ForegroundColor Red
    Write-Host "Execute primeiro: flutter build web --release" -ForegroundColor Yellow
    Write-Host "  (dentro da pasta frontend)" -ForegroundColor Yellow
    exit 1
}

# ── 1. Envia o build Flutter ──────────────────────────────────────
Write-Host "[1/2] Enviando build Flutter para o VPS..." -ForegroundColor Yellow
Write-Host "      (pode demorar alguns minutos)" -ForegroundColor Gray
& $SCP $SSH_OPTS -r $BuildSrc "${REMOTE}:${RemoteApp}/"
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO no envio do build Flutter" -ForegroundColor Red; exit 1 }
Write-Host "   Build enviado!" -ForegroundColor Green

# ── 2. Ajusta permissoes ─────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Ajustando permissoes no VPS..." -ForegroundColor Yellow
& $SSH $SSH_OPTS $REMOTE "chown -R www-data:www-data ${RemoteApp} 2>/dev/null || true ; chmod -R 755 ${RemoteApp}"
if ($LASTEXITCODE -ne 0) { Write-Host "AVISO: erro nas permissoes (nao critico)" -ForegroundColor Yellow }
Write-Host "   Permissoes ajustadas!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deploy concluido com sucesso!         " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Teste o recibo em:" -ForegroundColor White
Write-Host "  https://www.osmech.com.br/app/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  DICA: Ao imprimir, configure a impressora" -ForegroundColor Yellow
Write-Host "  MP-20 com papel 76 mm e sem escalonamento." -ForegroundColor Yellow
Write-Host ""
