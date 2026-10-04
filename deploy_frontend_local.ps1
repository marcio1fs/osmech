# ============================================================
# OSMECH — Deploy: Frontend Local (Recuperacao de Senha)
# Compila o Flutter Web localmente e envia o resultado para o VPS.
# ============================================================

$vpsUser  = "root"
$vpsHost  = "148.230.79.103"
$vpsPass  = "Actionlistener369#"
$hostKey  = "SHA256:n5CcptafnQnm0OMRz6PpGRizj/1jf83ngS90/5t40ro"
$baseDir  = "/var/www/osmech.com.br/app"
$plink    = "C:\Program Files\PuTTY\plink.exe"
$pscp     = "C:\Program Files\PuTTY\pscp.exe"
$remote   = "${vpsUser}@${vpsHost}"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  OSMECH - Deploy Frontend (Build Local)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Build Local ──────────────────────────────────────────────
Write-Host "[1/3] Compilando Flutter Web localmente (pode levar alguns minutos)..." -ForegroundColor Yellow
Set-Location -Path ".\frontend"

# Executa o build
& flutter build web --release --base-href "/app/" --dart-define=API_URL=https://www.osmech.com.br

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERRO] Falha no build local do Flutter." -ForegroundColor Red
    exit 1
}
Write-Host "  OK - Build local concluido!" -ForegroundColor Green
Write-Host ""

# Volta pra raiz
Set-Location -Path ".."

# ── 2. Limpa o diretorio remoto e envia arquivos ────────────────
Write-Host "[2/3] Limpando diretorio antigo no VPS e enviando novos arquivos..." -ForegroundColor Yellow

# Limpa tudo dentro de /app no VPS
& $plink -ssh -pw "Actionlistener369#" -batch -hostkey $hostKey $remote "rm -rf $baseDir/*"
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha ao limpar diretorio remoto." -ForegroundColor Red; exit 1 }

# Envia o diretorio todo com -r
Write-Host "  Enviando build/web/* para o VPS (aguarde)..." -ForegroundColor Yellow
& $pscp -pw "Actionlistener369#" -batch -r -hostkey $hostKey "frontend\build\web\*" "${remote}:${baseDir}/"
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha ao enviar arquivos do frontend." -ForegroundColor Red; exit 1 }

Write-Host "  OK - Arquivos enviados com sucesso!" -ForegroundColor Green
Write-Host ""

# ── 3. Ajusta permissoes e reinicia Nginx ───────────────────────
Write-Host "[3/3] Ajustando permissoes e reiniciando Nginx..." -ForegroundColor Yellow

& $plink -ssh -pw "Actionlistener369#" -batch -hostkey $hostKey $remote "chown -R www-data:www-data $baseDir 2>/dev/null || true; chmod -R 755 $baseDir; docker restart osmech-nginx"
Write-Host "  OK - Permissoes ajustadas e Nginx reiniciado!" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Deploy do Frontend CONCLUIDO!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  O backend ja estava no ar, agora o frontend atualizado tb foi!" -ForegroundColor White
Write-Host "  Acesse: https://www.osmech.com.br/app/" -ForegroundColor Cyan
Write-Host ""
