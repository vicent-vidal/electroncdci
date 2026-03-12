# CI/CD Configuration Guide

## 📋 Configuración Completa de Azure Artifact Signing

### 🔐 GitHub Secrets Requeridos

#### Para Windows (Azure Signing):
1. **`AZURE_CREDENTIALS`**: JSON del Service Principal
   ```json
   {
     "clientId": "your-client-id",
     "clientSecret": "your-client-secret",
     "subscriptionId": "your-subscription-id",
     "tenantId": "your-tenant-id"
   }
   ```

2. **`AZURE_KEY_VAULT_URL`**: URL de tu Key Vault
   - Ejemplo: `https://kv-electroncdci.vault.azure.net/`

3. **`AZURE_CLIENT_ID`**: Client ID del Service Principal

4. **`AZURE_CLIENT_SECRET`**: Secret del Service Principal

5. **`AZURE_TENANT_ID`**: Tenant ID de Azure AD

6. **`AZURE_CERT_NAME`**: Nombre del certificado en Key Vault
   - Ejemplo: `code-signing-cert`

#### Para macOS (Opcional):
1. **`APPLE_ID`**: Tu Apple ID
2. **`APPLE_APP_PASSWORD`**: App-specific password
3. **`APPLE_TEAM_ID`**: Team ID de Apple Developer
4. **`APPLE_CERTIFICATE_BASE64`**: Certificado .p12 en base64
5. **`APPLE_CERTIFICATE_PASSWORD`**: Contraseña del certificado

---

## ☁️ Configuración de Azure (Paso a Paso)

### 1. Crear recursos en Azure Portal

```bash
# Login en Azure
az login

# Crear Resource Group
az group create --name rg-codesigning --location westeurope

# Crear Key Vault
az keyvault create \
  --name kv-electroncdci \
  --resource-group rg-codesigning \
  --location westeurope \
  --enable-rbac-authorization false

# Crear Service Principal
az ad sp create-for-rbac \
  --name "github-electroncdci" \
  --role contributor \
  --scopes /subscriptions/{YOUR_SUBSCRIPTION_ID}/resourceGroups/rg-codesigning \
  --sdk-auth
```

**Guarda el JSON resultante** en el secret `AZURE_CREDENTIALS` de GitHub.

### 2. Obtener certificado de firma de código

Opciones:
- **DigiCert**: https://www.digicert.com/signing/code-signing-certificates
- **Sectigo**: https://sectigo.com/ssl-certificates-tls/code-signing
- **GlobalSign**: https://www.globalsign.com/en/code-signing-certificate

Necesitas un certificado **EV Code Signing** (Extended Validation).

### 3. Importar certificado al Key Vault

```bash
# Importar certificado PFX
az keyvault certificate import \
  --vault-name kv-electroncdci \
  --name code-signing-cert \
  --file /path/to/certificate.pfx \
  --password "CERTIFICADO_PASSWORD"
```

### 4. Dar permisos al Service Principal

```bash
# Obtener el Client ID del Service Principal
CLIENT_ID=$(az ad sp list --display-name "github-electroncdci" --query "[0].appId" -o tsv)

# Dar permisos en Key Vault
az keyvault set-policy \
  --name kv-electroncdci \
  --spn $CLIENT_ID \
  --certificate-permissions get list \
  --secret-permissions get list \
  --key-permissions get list sign
```

---

## 🍎 Configuración de Apple (macOS Signing)

### 1. Unirse al Apple Developer Program
- Costo: $99 USD/año
- Link: https://developer.apple.com/programs/

### 2. Crear Certificados

1. Ve a https://developer.apple.com/account/resources/certificates/list
2. Crea un certificado **Developer ID Application**
3. Descarga el certificado
4. Importa en Keychain Access
5. Exporta como `.p12` con contraseña

### 3. Generar App-Specific Password

1. Ve a https://appleid.apple.com
2. Sign in > Security > App-Specific Passwords
3. Genera nueva contraseña
4. Guárdala en `APPLE_APP_PASSWORD`

### 4. Codificar certificado en Base64

```bash
# En macOS/Linux
base64 -i certificate.p12 -o certificate-base64.txt

# En PowerShell (Windows)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Out-File certificate-base64.txt
```

---

## 🚀 Uso del Pipeline

### Desarrollo Normal
```bash
git add .
git commit -m "Nueva funcionalidad"
git push origin cdci
```
→ Ejecuta tests + builds en las 3 plataformas

### Crear Release
```bash
# 1. Actualizar versión en package.json
npm version patch  # o minor, major

# 2. Crear tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# 3. Push con tags
git push origin cdci --tags
```

### Crear GitHub Release Manualmente
1. Ve a tu repositorio en GitHub
2. Releases > Draft a new release
3. Elige el tag (ej: v1.0.0)
4. Click "Publish release"
→ Automáticamente se ejecuta el pipeline completo

---

## 📝 Actualizar `electron-builder.json`

Reemplaza en el archivo:
- `YOUR_GITHUB_USERNAME` con tu usuario de GitHub
- `your-email@example.com` con tu email

---

## ✅ Verificar Configuración

### Verificar Azure
```bash
# Verificar acceso al Key Vault
az keyvault certificate show \
  --vault-name kv-electroncdci \
  --name code-signing-cert

# Verificar permisos del SP
az keyvault show --name kv-electroncdci --query properties.accessPolicies
```

### Verificar GitHub Secrets
1. Ve a tu repositorio en GitHub
2. Settings > Secrets and variables > Actions
3. Verifica que todos los secrets estén configurados

---

## 🐛 Troubleshooting

### Error: "AzureSignTool not found"
→ El dotnet tool no se instaló correctamente. Verifica .NET SDK en el runner.

### Error: "Certificate not found in Key Vault"
→ Verifica que `AZURE_CERT_NAME` coincida con el nombre en Key Vault.

### Error: "Access denied to Key Vault"
→ Verifica los permisos del Service Principal con `az keyvault show`.

### Error de firma en macOS: "No identity found"
→ El certificado no se importó correctamente. Verifica el base64 y la contraseña.

---

## 💰 Costos Estimados

- **Azure Key Vault**: ~$0.03/10,000 operaciones
- **GitHub Actions**: 2,000 min/mes gratis (cuenta pública)
- **Certificado Code Signing**: $100-$500/año
- **Apple Developer Program**: $99/año

---

## 📚 Referencias

- [Azure Key Vault Docs](https://docs.microsoft.com/azure/key-vault/)
- [AzureSignTool GitHub](https://github.com/vcsjones/AzureSignTool)
- [Electron Builder Docs](https://www.electron.build/)
- [Apple Code Signing](https://developer.apple.com/support/code-signing/)
