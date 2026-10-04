# ============================================================
# OSMECH — Deploy: Recuperacao de Senha
# Usa PuTTY pscp/plink para envio sem interacao manual.
# Execute: .\deploy_recuperacao_senha.ps1
# ============================================================

$vpsUser  = "root"
$vpsHost  = "148.230.79.103"
$vpsPass  = "Actionlistener369#"
$hostKey  = "SHA256:n5CcptafnQnm0OMRz6PpGRizj/1jf83ngS90/5t40ro"
$baseDir  = "/opt/osmech"
$plink    = "C:\Program Files\PuTTY\plink.exe"
$pscp     = "C:\Program Files\PuTTY\pscp.exe"
$remote   = "${vpsUser}@${vpsHost}"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  OSMECH - Deploy: Recuperacao de Senha" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Envia os arquivos do backend ───────────────────────────
Write-Host "[1/5] Enviando arquivos do backend para o VPS..." -ForegroundColor Yellow

$backendFiles = @(
    @{ src = "backend\src\main\java\com\osmech\user\entity\Usuario.java";
       dst = "$baseDir/backend/src/main/java/com/osmech/user/entity/" },
    @{ src = "backend\src\main\java\com\osmech\user\repository\UsuarioRepository.java";
       dst = "$baseDir/backend/src/main/java/com/osmech/user/repository/" },
    @{ src = "backend\src\main\java\com\osmech\auth\service\AuthService.java";
       dst = "$baseDir/backend/src/main/java/com/osmech/auth/service/" },
    @{ src = "backend\src\main\java\com\osmech\notification\service\EmailService.java";
       dst = "$baseDir/backend/src/main/java/com/osmech/notification/service/" },
    @{ src = "backend\src\main\resources\application.yml";
       dst = "$baseDir/backend/src/main/resources/" }
)

foreach ($f in $backendFiles) {
    Write-Host "  -> $($f.src)"
    & $pscp -pw "Actionlistener369#" -batch -hostkey $hostKey $f.src "${remote}:$($f.dst)"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERRO] Falha ao enviar $($f.src)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  OK - arquivos do backend enviados!" -ForegroundColor Green
Write-Host ""

# ── 2. Envia o .env.prod ──────────────────────────────────────
Write-Host "[2/5] Enviando .env.prod com configuracoes de e-mail..." -ForegroundColor Yellow
& $pscp -pw "Actionlistener369#" -batch -hostkey $hostKey ".env.prod" "${remote}:${baseDir}/"
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha ao enviar .env.prod" -ForegroundColor Red; exit 1 }
Write-Host "  OK" -ForegroundColor Green
Write-Host ""

# ── 3. Envia e executa o rebuild do backend ────────────────────
Write-Host "[3/5] Enviando script de rebuild..." -ForegroundColor Yellow
& $pscp -pw "Actionlistener369#" -batch -hostkey $hostKey "rebuild_backend.sh" "${remote}:${baseDir}/"
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha ao enviar rebuild_backend.sh" -ForegroundColor Red; exit 1 }

Write-Host "  Reconstruindo backend no VPS (aguarde ~3-5 min)..." -ForegroundColor Yellow
& $plink -ssh -pw "Actionlistener369#" -batch -hostkey $hostKey $remote "chmod +x $baseDir/rebuild_backend.sh && $baseDir/rebuild_backend.sh"
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha no rebuild do backend" -ForegroundColor Red; exit 1 }
Write-Host "  OK - Backend reconstruido!" -ForegroundColor Green
Write-Host ""

# ── 4. Envia arquivos do frontend e faz build no VPS ──────────
Write-Host "[4/5] Enviando arquivos do frontend..." -ForegroundColor Yellow

$frontendFiles = @(
    @{ src = "frontend\lib\main.dart";
       dst = "$baseDir/frontend/lib/" },
    @{ src = "frontend\lib\pages\login_page.dart";
       dst = "$baseDir/frontend/lib/pages/" },
    @{ src = "frontend\lib\pages\forgot_password_page.dart";
       dst = "$baseDir/frontend/lib/pages/" },
    @{ src = "frontend\lib\pages\reset_password_page.dart";
       dst = "$baseDir/frontend/lib/pages/" }
)

foreach ($f in $frontendFiles) {
    Write-Host "  -> $($f.src)"
    & $pscp -pw "Actionlistener369#" -batch -hostkey $hostKey $f.src "${remote}:$($f.dst)"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERRO] Falha ao enviar $($f.src)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  OK - arquivos do frontend enviados!" -ForegroundColor Green

Write-Host "  Compilando Flutter Web no VPS (aguarde ~2-3 min)..." -ForegroundColor Yellow
$flutterBuild = "cd $baseDir/frontend && export PATH=`$PATH:/opt/flutter/bin && flutter pub get && flutter build web --release --base-href /app/ --dart-define=API_URL=https://www.osmech.com.br && rm -rf /var/www/osmech.com.br/app/* && cp -r build/web/* /var/www/osmech.com.br/app/"
& $plink -ssh -pw "Actionlistener369#" -batch -hostkey $hostKey $remote $flutterBuild
if ($LASTEXITCODE -ne 0) { Write-Host "  [ERRO] Falha no build Flutter" -ForegroundColor Red; exit 1 }
Write-Host "  OK - Frontend atualizado!" -ForegroundColor Green
Write-Host ""

# ── 5. Reinicia o Nginx ────────────────────────────────────────
Write-Host "[5/5] Reiniciando Nginx..." -ForegroundColor Yellow
& $plink -ssh -pw "Actionlistener369#" -batch -hostkey $hostKey $remote "docker restart osmech-nginx"
Write-Host "  OK - Nginx reiniciado!" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Deploy de Recuperacao de Senha CONCLUIDO!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  O que foi atualizado:" -ForegroundColor White
Write-Host "  - Backend: forgot-password e reset-password funcionando" -ForegroundColor White
Write-Host "  - E-mail:  SMTP Hostinger (suporte@osmech.com.br)" -ForegroundColor White
Write-Host "  - Frontend: botao 'Esqueci minha senha' na tela de login" -ForegroundColor White
Write-Host ""
Write-Host "  Acesse: https://www.osmech.com.br/app/" -ForegroundColor Cyan
Write-Host ""
