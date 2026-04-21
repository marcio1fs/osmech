# Cofre de segredos local (HashiCorp Vault)

Passo a passo para rodar um Vault em modo dev e injetar os segredos da aplicação sem armazená-los em arquivos.

## Credenciais locais (`.env`)
- **Nunca faça commit** de `backend/.env` nem de `frontend/.env` — eles contêm segredos.
- O Git já está configurado para ignorar esses arquivos (`backend/.gitignore`).
- Use `backend/.env.example` como modelo: copie para `backend/.env` e preencha apenas localmente.

## 1) Subir o Vault (dev)
```bash
# Na raiz do repositório
docker compose -f devops/vault/docker-compose.vault.yml up -d
```
Credenciais padrão do modo dev:
- Endereço: `http://127.0.0.1:8200`
- Token root: `dev-root-token`

## 2) Gravar os segredos
Use o script em PowerShell (aceita valores via prompt, nada fica salvo em arquivo):
```powershell
pwsh scripts/vault/seed-vault.ps1
```
O script grava os valores em `secret/osmech/dev` no KV v2.

## 3) Executar o backend lendo do Vault
Defina o perfil `vault` junto com o perfil atual:
```powershell
$env:SPRING_PROFILES_ACTIVE="dev,vault"
mvn -pl backend spring-boot:run
```
Variáveis úteis (já possuem default):
- `VAULT_URI` (padrão `http://127.0.0.1:8200`)
- `VAULT_TOKEN` (padrão `dev-root-token`)

## 4) O que foi configurado
- Dependência `spring-cloud-starter-vault-config` adicionada ao backend.
- Perfil `vault` (`application-vault.yml`) importa `vault://` e busca os segredos em `secret/osmech/<perfil>`.
- Arquivo `devops/vault/docker-compose.vault.yml` sobe o Vault em modo dev (não usar em produção).

## 5) Produção / staging
- Substitua o Vault dev por uma instância segura (TLS, storage persistente, policies).
- Use tokens ou auth (Kubernetes/JWT/approle) específicos para cada ambiente.
- Ajuste `VAULT_URI` e o token/role no deploy. Não versionar segredos nem tokens.
