# Script para encontrar tus recursos de Azure existentes

Write-Host "=== VERIFICANDO RECURSOS DE AZURE ===" -ForegroundColor Cyan

# 1. Verificar login
Write-Host ""
Write-Host "1. Verificando login en Azure..." -ForegroundColor Yellow
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "OK Logueado como: $($account.user.name)" -ForegroundColor Green
    Write-Host "  Subscription: $($account.name)" -ForegroundColor Gray
} catch {
    Write-Host "ERROR No estas logueado. Ejecuta: az login" -ForegroundColor Red
    exit
}

# 2. Listar todos los Resource Groups
Write-Host ""
Write-Host "2. Resource Groups disponibles:" -ForegroundColor Yellow
$resourceGroups = az group list --query '[].{Name:name, Location:location}' -o json | ConvertFrom-Json
$resourceGroups | Format-Table -AutoSize

# 3. Listar todos los Key Vaults
Write-Host ""
Write-Host "3. Key Vaults disponibles:" -ForegroundColor Yellow
$keyVaults = az keyvault list --query '[].{Name:name, ResourceGroup:resourceGroup, Location:location}' -o json | ConvertFrom-Json

if ($keyVaults.Count -eq 0) {
    Write-Host "ERROR No se encontraron Key Vaults en tu subscription" -ForegroundColor Red
    Write-Host ""
    Write-Host "Necesitas crear uno? Ejecuta:" -ForegroundColor Yellow
    Write-Host "  az keyvault create --name kv-electroncdci --resource-group [NOMBRE_RG] --location westeurope" -ForegroundColor Cyan
} else {
    $keyVaults | Format-Table -AutoSize
    
    # 4. Para cada Key Vault, listar certificados
    Write-Host ""
    Write-Host "4. Certificados en cada Key Vault:" -ForegroundColor Yellow
    foreach ($kv in $keyVaults) {
        Write-Host ""
        Write-Host "  Key Vault: $($kv.Name)" -ForegroundColor Cyan
        Write-Host "  URL: https://$($kv.Name).vault.azure.net/" -ForegroundColor Gray
        
        $certs = az keyvault certificate list --vault-name $kv.Name --query '[].{Name:name, Enabled:attributes.enabled, Expires:attributes.expires}' -o json 2>$null | ConvertFrom-Json
        
        if ($certs.Count -eq 0) {
            Write-Host "    ERROR No hay certificados" -ForegroundColor Red
        } else {
            $certs | Format-Table -AutoSize
        }
    }
}

# 5. Buscar servicios de firma de Azure (Trusted Signing)
Write-Host ""
Write-Host "5. Azure Trusted Signing accounts:" -ForegroundColor Yellow
$trustedSigning = az resource list --resource-type 'Microsoft.CodeSigning/codeSigningAccounts' --query '[].{Name:name, ResourceGroup:resourceGroup, Location:location}' -o json 2>$null | ConvertFrom-Json

if ($trustedSigning.Count -eq 0) {
    Write-Host "ERROR No se encontraron cuentas de Azure Trusted Signing" -ForegroundColor Red
} else {
    $trustedSigning | Format-Table -AutoSize
    
    # Listar perfiles de firma
    foreach ($ts in $trustedSigning) {
        Write-Host ""
        Write-Host "  Perfiles en $($ts.Name):" -ForegroundColor Cyan
        az trustedsigning show --name $ts.Name --resource-group $ts.ResourceGroup 2>$null
    }
}

# 6. Resumen de lo que necesitas
Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para configurar GitHub Actions necesitas:" -ForegroundColor Yellow
Write-Host ""

if ($keyVaults.Count -gt 0) {
    Write-Host "Opción 1: Usar Key Vault existente" -ForegroundColor Green
    Write-Host "  - Key Vault: $($keyVaults[0].Name)"
    Write-Host "  - Resource Group: $($keyVaults[0].ResourceGroup)"
    Write-Host "  - URL: https://$($keyVaults[0].Name).vault.azure.net/"
} else {
    Write-Host "Opción 1: Crear un Key Vault" -ForegroundColor Yellow
    Write-Host "  az keyvault create --name kv-electroncdci --resource-group [NOMBRE_RG] --location westeurope"
}

Write-Host ""
if ($trustedSigning.Count -gt 0) {
    Write-Host "Opción 2: Usar Azure Trusted Signing (recomendado)" -ForegroundColor Green
    Write-Host "  - Account: $($trustedSigning[0].Name)"
    Write-Host "  - Resource Group: $($trustedSigning[0].ResourceGroup)"
} else {
    Write-Host "Opción 2: Usar Azure Trusted Signing" -ForegroundColor Yellow
    Write-Host "  Más info: https://learn.microsoft.com/azure/trusted-signing/"
}

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Cyan
