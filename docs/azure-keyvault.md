# Azure Key Vault Integration Guide

The `azure-keyvault` custom action fetches secrets from an Azure Key Vault and exposes them as environment variables or step outputs in your GitHub Actions workflow.

## Prerequisites

- An **Azure subscription**
- An **Azure Key Vault** with secrets stored in it
- An **Azure Service Principal** (SP) with access to the Key Vault
- **jq** on the runner (pre-installed on GitHub-hosted runners)

## Setup

### Step 1: Create a Key Vault (if you don't have one)

```bash
# Create a resource group
az group create --name my-rg --location westeurope

# Create the Key Vault
az keyvault create --name my-keyvault --resource-group my-rg --location westeurope

# Add secrets
az keyvault secret set --vault-name my-keyvault --name "DB-PASSWORD" --value "s3cret"
az keyvault secret set --vault-name my-keyvault --name "API-KEY" --value "abc123"
```

### Step 2: Create a Service Principal

```bash
az ad sp create-for-rbac --name "github-actions" \
  --role "Key Vault Secrets User" \
  --scopes /subscriptions/{subscription-id}/resourceGroups/my-rg/providers/Microsoft.KeyVault/vaults/my-keyvault
```

This outputs a JSON object:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Save this entire JSON -- you will store it as a GitHub secret.

### Step 3: Assign RBAC Role

If you created the SP with `--role "Key Vault Secrets User"` in Step 2, this is already done. Otherwise, assign the role manually:

```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/{subscription-id}/resourceGroups/my-rg/providers/Microsoft.KeyVault/vaults/my-keyvault
```

The `Key Vault Secrets User` role grants read-only access to secret values. Do not use broader roles like `Contributor` or `Owner`.

### Step 4: Configure GitHub Secrets

1. Go to your repository on GitHub.
2. Navigate to **Settings > Secrets and variables > Actions**.
3. Click **New repository secret**.
4. Name: `AZURE_CREDENTIALS`
5. Value: paste the full JSON from Step 2.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `keyvault-name` | yes | -- | Name of the Azure Key Vault |
| `secret-names` | yes | -- | Comma-separated list of secret names (e.g., `DB-PASSWORD,API-KEY,JWT-SECRET`) |
| `azure-credentials` | yes | -- | Azure SP credentials JSON (`clientId`, `clientSecret`, `tenantId`, `subscriptionId`) |
| `export-as` | no | `env` | Export mode: `env` for environment variables, `output` for step outputs |
| `mask-values` | no | `true` | Mask secret values in workflow logs with `::add-mask::` |

## Outputs

| Output | Description |
|--------|-------------|
| `secrets-json` | JSON object mapping secret names (UPPER_SNAKE_CASE) to their values. Only available when `export-as: output`. |

### Name Conversion

Secret names are transformed for use as env vars / outputs:
- Hyphens become underscores
- Letters are uppercased

Examples: `DB-PASSWORD` becomes `DB_PASSWORD`, `api-key` becomes `API_KEY`.

## Usage Examples

### Export as Environment Variables (default)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fetch secrets
        uses: MeteorFactory/Pipelines/actions/azure-keyvault@main
        with:
          keyvault-name: my-keyvault
          secret-names: "DB-PASSWORD,API-KEY,JWT-SECRET"
          azure-credentials: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Use secrets
        run: |
          echo "DB_PASSWORD, API_KEY, JWT_SECRET are now available as env vars"
          my-deploy-script --db-password "$DB_PASSWORD"
```

### Export as Step Outputs

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fetch secrets
        id: secrets
        uses: MeteorFactory/Pipelines/actions/azure-keyvault@main
        with:
          keyvault-name: my-keyvault
          secret-names: "DB-PASSWORD,API-KEY"
          azure-credentials: ${{ secrets.AZURE_CREDENTIALS }}
          export-as: output

      - name: Use secrets
        run: |
          echo "DB: ${{ steps.secrets.outputs.DB_PASSWORD }}"
          echo "API: ${{ steps.secrets.outputs.API_KEY }}"
```

### Combined with CI Template

```yaml
name: CI + Deploy

on:
  push:
    branches: [main]

jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      node-version: "22"

  deploy:
    needs: ci
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fetch secrets from Key Vault
        uses: MeteorFactory/Pipelines/actions/azure-keyvault@main
        with:
          keyvault-name: prod-keyvault
          secret-names: "DATABASE-URL,REDIS-URL,JWT-SECRET"
          azure-credentials: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy
        run: npm run deploy
```

## How It Works

1. **Validates inputs** -- checks that required fields are present and `export-as` is either `env` or `output`.
2. **Installs Azure CLI** -- if `az` is not found on the runner, installs it automatically (Linux and macOS).
3. **Logs in** -- authenticates with the Service Principal credentials using `az login --service-principal`.
4. **Fetches secrets** -- iterates over the comma-separated secret names, fetches each from the vault using `az keyvault secret show`.
5. **Exports** -- depending on `export-as`, writes to `$GITHUB_ENV` (env vars) or `$GITHUB_OUTPUT` (step outputs). Optionally masks values in logs.
6. **Logs out** -- always runs `az logout` in a cleanup step.

## Troubleshooting

### "Forbidden" or 403 error when fetching secrets

The Service Principal does not have the `Key Vault Secrets User` role on the vault. Verify:

```bash
az role assignment list --assignee {sp-client-id} --scope /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault-name}
```

If using Key Vault access policies (legacy model) instead of RBAC, ensure the SP has `Get` permission on secrets.

### "SecretNotFound" error

The secret name does not exist in the vault. Secret names are case-insensitive but must match exactly (including hyphens). Verify:

```bash
az keyvault secret list --vault-name my-keyvault --query "[].name" -o tsv
```

### "Invalid azure-credentials JSON"

The `AZURE_CREDENTIALS` secret must be valid JSON with all four keys: `clientId`, `clientSecret`, `tenantId`, `subscriptionId`. Common issues:
- Trailing whitespace or newlines in the GitHub secret value
- Missing quotes around the JSON when pasting
- Expired Service Principal credentials (rotate with `az ad sp credential reset`)

### Azure CLI not found

On self-hosted runners, the action attempts auto-install on Linux and macOS. For Windows runners or air-gapped environments, pre-install Azure CLI as a setup step.

### Secret values appear in logs

Ensure `mask-values` is `true` (the default). If a value was already printed before masking, it cannot be retroactively hidden. Always fetch secrets before any step that might log them.
