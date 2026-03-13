# Azure Trusted Signing - Guía de Integración

## 🚨 Estado Actual

Azure Trusted Signing es un servicio MUY nuevo (2024-2025) y la integración con GitHub Actions aún está en desarrollo.

## 📋 Opciones disponibles:

### Opción 1: Usar SignTool.exe con dlib (Recomendado para producción)

Azure Trusted Signing funciona con el SignTool.exe nativo de Windows usando una DLL especial:

```yaml
- name: Sign with Azure Trusted Signing
  run: |
    # Descargar dlib de Azure Trusted Signing
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile nuget.exe
    ./nuget.exe install Microsoft.Trusted.Signing.Client -OutputDirectory .
    
    # Obtener ruta de dlib
    $dlibPath = (Get-ChildItem -Recurse -Filter "Azure.CodeSigning.Dlib.dll").FullName
    
    # Firmar con signtool.exe
    $files = Get-ChildItem -Path "release/*.exe" -Recurse
    foreach ($file in $files) {
      & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
        /v /debug `
        /fd SHA256 `
        /tr "http://timestamp.acs.microsoft.com" `
        /td SHA256 `
        /dlib $dlibPath `
        /dmdf metadata.json `
        $file.FullName
    }
  shell: pwsh
```

### Opción 2: Usar Azure DevOps Extension (Más fácil)

Microsoft tiene una extensión oficial para Azure DevOps que es más madura:
https://marketplace.visualstudio.com/items?itemName=securedevelopment.trusted-signing

**Migrar a Azure DevOps podría ser más sencillo para firma de código.**

### Opción 3: Firmar localmente antes de subir

1. Construye localmente con `npm run electron:build:win`
2. Firma localmente con las herramientas de Azure
3. Sube los binarios firmados manualmente a GitHub Releases

### Opción 4: Esperar a herramientas maduras

Azure Trusted Signing es muy nuevo. Considera:
- Usar DigiCert/Sectigo tradicional con AzureSignTool (más maduro)
- Esperar a que Microsoft lance herramientas oficiales para GitHub Actions
- Usar un certificado EV tradicional con signtool.exe

## 🔧 Configuración actual

Por ahora, el workflow:
- ✅ Compila la aplicación correctamente
- ✅ Genera los ejecutables
- ⚠️ **No firma** los ejecutables (pendiente de configuración)
- ✅ Sube los artefactos sin firmar

## 📝 Metadata.json necesario

Azure Trusted Signing requiere un archivo metadata.json:

```json
{
  "Endpoint": "https://eus.codesigning.azure.net/",
  "CodeSigningAccountName": "DASaudio2026",
  "CertificateProfileName": "NOMBRE_DEL_PERFIL"
}
```

## 🚀 Próximos pasos recomendados

1. **Obtén el nombre del perfil** del portal de Azure:
   - https://portal.azure.com
   - Busca "DASaudio2026"
   - Ve a "Certificate profiles"
   - Anota el nombre del perfil

2. **Decide el enfoque**:
   - Opción A: Implementar firma con dlib (más complejo, más automatizado)
   - Opción B: Firmar localmente (más simple, menos automatizado)
   - Opción C: Migrar a Azure DevOps (herramientas oficiales)

3. **Para testing**, puedes:
   - Distribuir ejecutables sin firmar (funcionan, pero Windows mostrará advertencias)
   - Firmar manualmente antes de distribuir versiones importantes

## 📚 Referencias

- [Azure Trusted Signing Docs](https://learn.microsoft.com/azure/trusted-signing/)
- [Signing with dlib](https://learn.microsoft.com/azure/trusted-signing/how-to-signing-integrations)
- [GitHub Discussion](https://github.com/microsoft/azure-pipelines-tasks/discussions)

---

## 💡 Recomendación

Para empezar rápido:
1. Usa el workflow actual para builds automáticos (sin firma)
2. Para releases importantes, firma manualmente con Azure Portal o localmente
3. Implementa firma automática cuando Microsoft lance herramientas estables
