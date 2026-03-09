param(
    [string]$EnvFile = ".env",
    [string]$Profile = "dev"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-DotEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "[run-dev] Arquivo '$Path' nao encontrado. Continuando com variaveis atuais..." -ForegroundColor Yellow
        return
    }

    Write-Host "[run-dev] Carregando variaveis de $Path"
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            return
        }

        $idx = $line.IndexOf("=")
        if ($idx -lt 1) {
            return
        }

        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()

        if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        Set-Item -Path "Env:$key" -Value $value
    }
}

$backendDir = $PSScriptRoot
Set-Location $backendDir

Import-DotEnv -Path (Join-Path $backendDir $EnvFile)

if (-not $env:SPRING_PROFILES_ACTIVE) {
    $env:SPRING_PROFILES_ACTIVE = $Profile
}

Write-Host "[run-dev] SPRING_PROFILES_ACTIVE=$($env:SPRING_PROFILES_ACTIVE)"
Write-Host "[run-dev] Iniciando backend..."

mvn spring-boot:run
exit $LASTEXITCODE
