# Script para obtener los valores para GitHub Secrets
# Ejecuta este archivo línea por línea

Write-Host "=== OBTENIENDO VALORES PARA GITHUB SECRETS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Tenant ID
Write-Host "1. Obteniendo AZURE_TENANT_ID..." -ForegroundColor Yellow
$TENANT_ID = az account show --query tenantId -o tsv
Write-Host "   AZURE_TENANT_ID: $TENANT_ID" -ForegroundColor Green
Write-Host ""

# 2. Subscription ID (necesario para crear el SP)
$SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Host "2. Subscription ID: $SUBSCRIPTION_ID" -ForegroundColor Gray
Write-Host ""

# 3. Account Name y Resource Group  
$ACCOUNT_NAME = "DASaudio2026"
$RESOURCE_GROUP = "FirmaDAS"
Write-Host "3. Trusted Signing Account:" -ForegroundColor Yellow
Write-Host "   AZURE_TRUSTED_SIGNING_ACCOUNT: $ACCOUNT_NAME" -ForegroundColor Green
Write-Host ""

# 4. Listar perfiles de certificado disponibles
Write-Host "4. Obteniendo nombre del perfil de certificado..." -ForegroundColor Yellow
Write-Host "   Ejecutando: az trustedsigning certificate-profile list..." -ForegroundColor Gray

# Nota: Si este comando falla, ve al portal de Azure:
# https://portal.azure.com -> DASaudio2026 -> Certificate profiles
# Y anota el nombre del perfil

try {
    $profiles = az trustedsigning certificate-profile list `
        --account-name $ACCOUNT_NAME `
        --resource-group $RESOURCE_GROUP `
        --query "[].name" -o tsv
    
    Write-Host "   AZURE_CERT_PROFILE_NAME: $profiles" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: No se pudo obtener. Ve al portal de Azure:" -ForegroundColor Red
    Write-Host "   https://portal.azure.com -> DASaudio2026 -> Certificate profiles" -ForegroundColor Yellow
}
Write-Host ""

# 5. Crear Service Principal (necesario para autenticación desde GitHub)
Write-Host "5. Creando Service Principal para GitHub Actions..." -ForegroundColor Yellow
Write-Host "   Nombre: github-electroncdci-$(Get-Date -Format 'yyyyMMdd')" -ForegroundColor Gray

$SP_NAME = "github-electroncdci-$(Get-Date -Format 'yyyyMMdd')"
$scope = "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CodeSigning/codeSigningAccounts/$ACCOUNT_NAME"

Write-Host ""
Write-Host "   Ejecutando az ad sp create-for-rbac..." -ForegroundColor Gray
Write-Host "   (Esto puede tardar unos segundos)" -ForegroundColor Gray

try {
    $SP_JSON = az ad sp create-for-rbac `
        --name $SP_NAME `
        --role "Trusted Signing Certificate Profile Signer" `
        --scopes $scope `
        --sdk-auth 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # Intentar con rol genérico si el rol específico no existe
        Write-Host "   Intentando con rol 'Contributor'..." -ForegroundColor Yellow
        $SP_JSON = az ad sp create-for-rbac `
            --name $SP_NAME `
            --role "Contributor" `
            --scopes $scope `
            --sdk-auth
    }
    
    $SP = $SP_JSON | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "   Service Principal creado exitosamente!" -ForegroundColor Green
    Write-Host "   AZURE_CLIENT_ID: $($SP.clientId)" -ForegroundColor Green
    Write-Host "   AZURE_CLIENT_SECRET: $($SP.clientSecret)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "   JSON completo para AZURE_CREDENTIALS:" -ForegroundColor Yellow
    Write-Host $SP_JSON -ForegroundColor Gray
    
} catch {
    Write-Host "   ERROR al crear Service Principal" -ForegroundColor Red
    Write-Host "   Puedes crearlo manualmente en:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com -> Azure Active Directory -> App registrations" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== RESUMEN DE SECRETS PARA GITHUB ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copia estos valores en GitHub (Settings > Secrets and variables > Actions):" -ForegroundColor Yellow
Write-Host ""
Write-Host "AZURE_TENANT_ID:" -ForegroundColor White
Write-Host $TENANT_ID -ForegroundColor Green
Write-Host ""
Write-Host "AZURE_CLIENT_ID:" -ForegroundColor White
Write-Host $($SP.clientId) -ForegroundColor Green
Write-Host ""
Write-Host "AZURE_CLIENT_SECRET:" -ForegroundColor White
Write-Host $($SP.clientSecret) -ForegroundColor Green
Write-Host ""
Write-Host "AZURE_TRUSTED_SIGNING_ACCOUNT:" -ForegroundColor White
Write-Host $ACCOUNT_NAME -ForegroundColor Green
Write-Host ""
Write-Host "AZURE_CERT_PROFILE_NAME:" -ForegroundColor White
Write-Host "(Obtenlo del comando anterior o del portal de Azure)" -ForegroundColor Yellow
Write-Host ""
Write-Host "AZURE_CREDENTIALS (JSON completo):" -ForegroundColor White
Write-Host $SP_JSON -ForegroundColor Green
Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Cyan
