# Azure Key Vault Secrets

GitHub Action composite pour récupérer des secrets depuis Azure Key Vault et les exposer comme variables d'environnement ou step outputs.

## Prérequis

- **Azure Service Principal** avec un JSON contenant `clientId`, `clientSecret`, `tenantId`, `subscriptionId`
- **RBAC** : le Service Principal doit avoir le rôle `Key Vault Secrets User` (ou `Key Vault Reader` + access policy `Get` sur les secrets) sur le Key Vault cible
- **jq** installé sur le runner (présent par défaut sur les runners GitHub)

## Inputs

| Input | Requis | Default | Description |
|-------|--------|---------|-------------|
| `keyvault-name` | oui | — | Nom du Azure Key Vault |
| `secret-names` | oui | — | Liste de secrets séparés par virgule (ex: `DB-PASSWORD,API-KEY`) |
| `azure-credentials` | oui | — | JSON credentials du Service Principal |
| `export-as` | non | `env` | `env` pour variables d'environnement, `output` pour step outputs |
| `mask-values` | non | `true` | Masquer les valeurs dans les logs avec `::add-mask::` |

## Outputs

| Output | Description |
|--------|-------------|
| `secrets-json` | Objet JSON des secrets (clés en UPPER_SNAKE_CASE). Disponible uniquement avec `export-as: output` |

Les noms de secrets sont convertis : les tirets deviennent des underscores et le nom passe en majuscules (`DB-PASSWORD` devient `DB_PASSWORD`).

## Utilisation

### Export en variables d'environnement (par défaut)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fetch secrets
        uses: ./actions/azure-keyvault
        with:
          keyvault-name: my-keyvault
          secret-names: 'DB-PASSWORD,API-KEY,JWT-SECRET'
          azure-credentials: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Use secrets
        run: |
          echo "DB password is available as \$DB_PASSWORD"
          # $DB_PASSWORD, $API_KEY, $JWT_SECRET sont disponibles
```

### Export en step outputs

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fetch secrets
        id: secrets
        uses: ./actions/azure-keyvault
        with:
          keyvault-name: my-keyvault
          secret-names: 'DB-PASSWORD,API-KEY'
          azure-credentials: ${{ secrets.AZURE_CREDENTIALS }}
          export-as: output

      - name: Use secrets
        run: |
          echo "DB: ${{ steps.secrets.outputs.DB_PASSWORD }}"
          echo "API: ${{ steps.secrets.outputs.API_KEY }}"
```

### Format du JSON credentials

Le secret `AZURE_CREDENTIALS` doit contenir :

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Généré via :

```bash
az ad sp create-for-rbac --name "github-actions" --role "Key Vault Secrets User" \
  --scopes /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault-name}
```
