# Configuración de Secrets en GitHub

## 📍 Ubicación
1. Ve a tu repositorio en GitHub: https://github.com/[TU_USUARIO]/angular-electron
2. Click en **Settings** (arriba a la derecha)
3. En el menú lateral: **Secrets and variables** > **Actions**
4. Click en **New repository secret**

---

## 🔑 Secrets Requeridos

### 1. AZURE_CREDENTIALS
**Tipo:** JSON completo del Service Principal

```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx"
}
```

**Cómo obtenerlo:**
- Ejecuta el script `azure-setup-commands.ps1` 
- Copia el JSON que aparece después de crear el Service Principal

---

### 2. AZURE_KEY_VAULT_URL
**Tipo:** URL completa

**Ejemplo:** `https://dasaudio2026.vault.azure.net/`

**Cómo obtenerlo:**
```powershell
az keyvault show --name DASaudio2026 --resource-group FirmaDAS --query properties.vaultUri -o tsv
```

---

### 3. AZURE_CLIENT_ID
**Tipo:** GUID

**Ejemplo:** `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

**Cómo obtenerlo:**
- Está dentro del JSON de `AZURE_CREDENTIALS` bajo la key `clientId`

---

### 4. AZURE_CLIENT_SECRET
**Tipo:** String secreto

**Cómo obtenerlo:**
- Está dentro del JSON de `AZURE_CREDENTIALS` bajo la key `clientSecret`

---

### 5. AZURE_TENANT_ID
**Tipo:** GUID

**Ejemplo:** `z9y8x7w6-v5u4-3210-zyxw-vut987654321`

**Cómo obtenerlo:**
```powershell
az account show --query tenantId -o tsv
```

---

### 6. AZURE_CERT_NAME
**Tipo:** Nombre del certificado en Key Vault

**Ejemplo:** `DASaudio2026` o `code-signing-cert`

**Cómo obtenerlo:**
```powershell
az keyvault certificate list --vault-name DASaudio2026 --query "[].name" -o tsv
```

---

## ✅ Verificación

Después de agregar todos los secrets:

1. Los secrets aparecerán listados (el valor estará oculto)
2. Deberías tener 6 secrets en total para Windows signing
3. Haz un commit y push a la rama `cdci` para probar el workflow

---

## 🔍 Troubleshooting

### "Secret not found"
→ Verifica que el nombre del secret esté escrito exactamente como se indica (mayúsculas)

### "Invalid JSON"
→ En AZURE_CREDENTIALS, asegúrate de que el JSON esté en una sola línea o bien formateado

### "Access denied to Key Vault"
→ Verifica que ejecutaste el comando `az keyvault set-policy` para dar permisos al Service Principal

---

## 📸 Captura de ejemplo

Tu lista de secrets debería verse así:

```
AZURE_CERT_NAME              ✅
AZURE_CLIENT_ID              ✅
AZURE_CLIENT_SECRET          ✅
AZURE_CREDENTIALS            ✅
AZURE_KEY_VAULT_URL          ✅
AZURE_TENANT_ID              ✅
GITHUB_TOKEN                 ✅ (Ya existe por defecto)
```
