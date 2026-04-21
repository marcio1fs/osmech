# OSMECH local runner: starts backend + frontend in separate cmd windows.
# Usage (PowerShell): .\run-local.ps1
# If policy blocks: powershell -ExecutionPolicy Bypass -File .\run-local.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'backend'
$frontendWeb = Join-Path $root 'frontend\build\web'

$backendCmd = 'cd /d ' + $backend + ' ^& set MAVEN_SKIP_RC=on ^& for /f "usebackq tokens=1,* delims==" %A in (`type .env ^| findstr /r "^[A-Za-z_]"`) do set %A=%B ^& mvn spring-boot:run'
$frontendCmd = 'cd /d ' + $frontendWeb + ' ^& python -m http.server 8083'

Start-Process cmd -ArgumentList '/k', $backendCmd
Start-Process cmd -ArgumentList '/k', $frontendCmd
Start-Process "http://localhost:8083"
