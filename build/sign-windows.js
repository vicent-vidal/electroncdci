const { execSync } = require('child_process');
const path = require('path');

exports.default = async function(configuration) {
  const filePath = configuration.path;
  
  console.log(`Signing ${filePath} with Azure...`);
  
  const azureKeyVaultUrl = process.env.AZURE_KEY_VAULT_URL;
  const azureClientId = process.env.AZURE_CLIENT_ID;
  const azureTenantId = process.env.AZURE_TENANT_ID;
  const azureClientSecret = process.env.AZURE_CLIENT_SECRET;
  const azureCertName = process.env.AZURE_CERT_NAME;
  
  if (!azureKeyVaultUrl) {
    console.log('Azure signing not configured, skipping...');
    return;
  }
  
  const command = `AzureSignTool sign \
    --azure-key-vault-url "${azureKeyVaultUrl}" \
    --azure-key-vault-client-id "${azureClientId}" \
    --azure-key-vault-tenant-id "${azureTenantId}" \
    --azure-key-vault-client-secret "${azureClientSecret}" \
    --azure-key-vault-certificate "${azureCertName}" \
    --file-digest sha256 \
    --timestamp-rfc3161 http://timestamp.digicert.com \
    --verbose \
    "${filePath}"`;
  
  try {
    execSync(command, { stdio: 'inherit' });
    console.log('Signed successfully!');
  } catch (error) {
    console.error('Signing failed:', error);
    throw error;
  }
};
