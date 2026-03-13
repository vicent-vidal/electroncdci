# Script para configurar Azure Code Signing
# Ejecuta este archivo línea por línea

# 1. Login en Azure
az login

# 2. Verificar tu subscription
$SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Host "Subscription ID: $SUBSCRIPTION_ID"

# 3. Verificar tu Tenant ID
$TENANT_ID = az account show --query tenantId -o tsv
Write-Host "Tenant ID: $TENANT_ID"

# 4. Verificar si existe el Key Vault
az keyvault list --query "[].{Name:name, Location:location}" -o table

# 5. Verificar el nombre del Key Vault (ajusta el nombre según lo que tengas)
$KV_NAME = "DASaudio2026"  # O el nombre que uses
$RG_NAME = "FirmaDAS"       # O tu resource group

# 6. Obtener la URL del Key Vault
$KV_URL = az keyvault show --name $KV_NAME --resource-group $RG_NAME --query properties.vaultUri -o tsv
Write-Host "Key Vault URL: $KV_URL"

# 7. Listar certificados en el Key Vault
Write-Host "`nCertificados disponibles:"
az keyvault certificate list --vault-name $KV_NAME --query "[].{Name:name, Enabled:attributes.enabled}" -o table

# 8. Crear o verificar Service Principal para GitHub Actions
$SP_NAME = "github-electroncdci-$(Get-Date -Format 'yyyyMMdd')"

Write-Host "`nCreando Service Principal..."
$SP_JSON = az ad sp create-for-rbac `
  --name $SP_NAME `
  --role contributor `
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" `
  --sdk-auth

Write-Host "`n=== IMPORTANTE: Guarda este JSON como secret AZURE_CREDENTIALS en GitHub ==="
$SP_JSON | ConvertFrom-Json | ConvertTo-Json -Depth 10
$SP_JSON_OBJ = $SP_JSON | ConvertFrom-Json

# 9. Extraer valores individuales
$CLIENT_ID = $SP_JSON_OBJ.clientId
$CLIENT_SECRET = $SP_JSON_OBJ.clientSecret

Write-Host "`n=== SECRETS PARA GITHUB ==="
Write-Host "AZURE_CREDENTIALS: (JSON completo arriba)"
Write-Host "AZURE_KEY_VAULT_URL: $KV_URL"
Write-Host "AZURE_CLIENT_ID: $CLIENT_ID"
Write-Host "AZURE_CLIENT_SECRET: $CLIENT_SECRET"
Write-Host "AZURE_TENANT_ID: $TENANT_ID"
Write-Host "AZURE_CERT_NAME: (nombre del certificado que listamos arriba)"

# 10. Dar permisos al Service Principal en el Key Vault
Write-Host "`nAsignando permisos al Service Principal..."
az keyvault set-policy `
  --name $KV_NAME `
  --spn $CLIENT_ID `
  --certificate-permissions get list `
  --secret-permissions get list `
  --key-permissions get list sign

Write-Host "`n✅ Configuración completada!"
Write-Host "`nPróximos pasos:"
Write-Host "1. Ve a tu repositorio en GitHub"
Write-Host "2. Settings > Secrets and variables > Actions"
Write-Host "3. Agrega cada secret con los valores mostrados arriba"
