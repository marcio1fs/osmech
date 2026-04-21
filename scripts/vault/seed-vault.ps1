param(
  [string]$VaultAddr = "",
  [string]$Token = "",
  [string]$Context = "osmech",
  [string]$Profile = "dev"
)

if ([string]::IsNullOrWhiteSpace($VaultAddr)) {
  $VaultAddr = $env:VAULT_URI
}
if ([string]::IsNullOrWhiteSpace($VaultAddr)) {
  $VaultAddr = "http://127.0.0.1:8200"
}

if ([string]::IsNullOrWhiteSpace($Token)) {
  $Token = $env:VAULT_TOKEN
}
if ([string]::IsNullOrWhiteSpace($Token)) {
  $Token = "dev-root-token"
}

function Get-EnvValue {
  param([string]$Name)
  $item = Get-Item -Path "Env:$Name" -ErrorAction SilentlyContinue
  if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace($item.Value)) {
    return $item.Value
  }
  return $null
}

function Add-Secret {
  param(
    [hashtable]$Bag,
    [string]$Key,
    [string]$Prompt,
    [string]$Default = "",
    [bool]$Required = $false,
    [string]$EnvVar = ""
  )

  $input = $null
  if (-not [string]::IsNullOrWhiteSpace($EnvVar)) {
    $input = Get-EnvValue -Name $EnvVar
  }

  if ([string]::IsNullOrWhiteSpace($input)) {
    $input = Read-Host $Prompt
  }

  if ([string]::IsNullOrWhiteSpace($input)) {
    if (-not [string]::IsNullOrWhiteSpace($Default)) {
      $input = $Default
    } elseif ($Required) {
      Write-Error "$Key é obrigatório. Forneça um valor via prompt ou variável de ambiente $EnvVar." -ErrorAction Stop
    } else {
      return
    }
  }

  $Bag[$Key] = $input
}

$secrets = @{}

Add-Secret -Bag $secrets -Key "DB_URL" -Prompt "DB_URL (enter para padrão jdbc:postgresql://localhost:5432/oficina_db)" -Default "jdbc:postgresql://localhost:5432/oficina_db" -EnvVar "DB_URL"
Add-Secret -Bag $secrets -Key "DB_USERNAME" -Prompt "DB_USERNAME (enter para padrão postgres)" -Default "postgres" -EnvVar "DB_USERNAME"
Add-Secret -Bag $secrets -Key "DB_PASSWORD" -Prompt "DB_PASSWORD (obrigatório)" -Required $true -EnvVar "DB_PASSWORD"
Add-Secret -Bag $secrets -Key "JWT_SECRET" -Prompt "JWT_SECRET (>=32 bytes, obrigatório)" -Required $true -EnvVar "JWT_SECRET"
Add-Secret -Bag $secrets -Key "MERCADOPAGO_ACCESS_TOKEN" -Prompt "MERCADOPAGO_ACCESS_TOKEN (opcional)" -EnvVar "MERCADOPAGO_ACCESS_TOKEN"
Add-Secret -Bag $secrets -Key "MERCADOPAGO_PUBLIC_KEY" -Prompt "MERCADOPAGO_PUBLIC_KEY (opcional)" -EnvVar "MERCADOPAGO_PUBLIC_KEY"
Add-Secret -Bag $secrets -Key "MERCADOPAGO_WEBHOOK_SECRET" -Prompt "MERCADOPAGO_WEBHOOK_SECRET (opcional)" -EnvVar "MERCADOPAGO_WEBHOOK_SECRET"
Add-Secret -Bag $secrets -Key "AI_OPENAI_API_KEY" -Prompt "AI_OPENAI_API_KEY (opcional)" -EnvVar "AI_OPENAI_API_KEY"

$body = @{ data = $secrets } | ConvertTo-Json -Depth 4
$endpoint = "$VaultAddr/v1/secret/data/$Context/$Profile"

Write-Host "Gravando segredos em $endpoint ..."
Invoke-RestMethod -Method Post -Uri $endpoint -Headers @{ "X-Vault-Token" = $Token } -Body $body -ContentType "application/json"
Write-Host "Pronto. Verifique com: Invoke-RestMethod -Method Get -Uri $endpoint -Headers @{`\"X-Vault-Token`\"=`\"$Token`\"}"
