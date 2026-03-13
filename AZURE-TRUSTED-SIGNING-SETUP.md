# Configuración de Azure Trusted Signing para GitHub Actions

## ✅ Recursos que tienes:
- **Account Name**: DASaudio2026
- **Resource Group**: FirmaDAS  
- **Location**: eastus

---

## 🔑 Secrets necesarios para GitHub Actions

Necesitas configurar estos 5 secrets en GitHub:

### 1. AZURE_TENANT_ID
**Valor actual:**
```powershell
$TENANT_ID = az account show --query tenantId -o tsv
Write-Host $TENANT_ID
```

### 2. AZURE_CLIENT_ID
El Client ID del Service Principal. Créalo con:

```powershell
$SUBSCRIPTION_ID = az account show --query id -o tsv

# Crear Service Principal
$SP_JSON = az ad sp create-for-rbac `
  --name "github-electroncdci" `
  --role "Trusted Signing Certificate Profile Signer" `
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/FirmaDAS/providers/Microsoft.CodeSigning/codeSigningAccounts/DASaudio2026" `
  --sdk-auth

# Mostrar resultado
$SP_JSON

# Extraer Client ID
$SP = $SP_JSON | ConvertFrom-Json
Write-Host "AZURE_CLIENT_ID: $($SP.clientId)"
Write-Host "AZURE_CLIENT_SECRET: $($SP.clientSecret)"
```

### 3. AZURE_CLIENT_SECRET
Sale del comando anterior (dentro del JSON del Service Principal)

### 4. AZURE_TRUSTED_SIGNING_ACCOUNT
```
DASaudio2026
```

### 5. AZURE_CERT_PROFILE_NAME
Necesitas obtener el nombre del perfil de certificado. Ejecuta:

```powershell
az trustedsigning certificate-profile list `
  --account-name DASaudio2026 `
  --resource-group FirmaDAS `
  --query "[].name" -o table
```

---

## 📝 Resumen de secrets

Una vez ejecutes los comandos arriba, tendrás estos valores:

| Secret Name | Ejemplo de Valor |
|------------|------------------|
| `AZURE_TENANT_ID` | `12345678-1234-1234-1234-123456789012` |
| `AZURE_CLIENT_ID` | `abcdefgh-abcd-abcd-abcd-abcdefghijkl` |
| `AZURE_CLIENT_SECRET` | `~secretvalue123` |
| `AZURE_TRUSTED_SIGNING_ACCOUNT` | `DASaudio2026` |
| `AZURE_CERT_PROFILE_NAME` | `nombredelperfil` (obtenido del comando de arriba) |

---

## 🚀 Próximos pasos

1. Ejecuta los comandos de PowerShell arriba para obtener los valores
2. Ve a tu repositorio de GitHub > Settings > Secrets and variables > Actions
3. Crea los 5 secrets con los valores obtenidos
4. Yo actualizaré tu workflow para usar Azure Trusted Signing

---

## 📚 Diferencias con Key Vault

Azure Trusted Signing es más simple que Key Vault tradicional:
- ✅ No necesitas gestionar certificados manualmente
- ✅ Firma directamente desde la nube
- ✅ Cumplimiento automático con estándares de seguridad
- ✅ Más económico
- ✅ Integración nativa con CI/CD
