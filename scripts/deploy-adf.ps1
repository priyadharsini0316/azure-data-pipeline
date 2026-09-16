param(
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$FactoryName,
    [Parameter(Mandatory=$true)][string]$SqlServerFqdn,
    [Parameter(Mandatory=$true)][string]$SqlDatabaseName,
    [Parameter(Mandatory=$true)][string]$KeyVaultName
)
$ErrorActionPreference='Stop'
$Az='C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'
$Api='2018-06-01'

function Publish-AdfArtifact {
    param([string]$Collection,[string]$Name,[string]$File)
    $body=(Get-Content -Raw $File).Replace('__SQL_SERVER_FQDN__',$SqlServerFqdn).Replace('__SQL_DATABASE_NAME__',$SqlDatabaseName).Replace('__KEY_VAULT_NAME__',$KeyVaultName)
    $temp=[System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $temp -Value $body -NoNewline
        $url="https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DataFactory/factories/$FactoryName/$Collection/$Name`?api-version=$Api"
        & $Az rest --method put --url $url --headers 'Content-Type=application/json' --body "@$temp" --output none
        if($LASTEXITCODE -ne 0){throw "Failed to publish ADF $Collection/$Name"}
    } finally { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}

Publish-AdfArtifact 'linkedservices' 'AzureSqlPrototype' 'adf/linkedService_AzureSqlPrototype.json'
Publish-AdfArtifact 'linkedservices' 'KeyVaultPrototype' 'adf/linkedService_KeyVaultPrototype.json'
Publish-AdfArtifact 'datasets' 'DynamicAzureSqlTable' 'adf/dataset_DynamicAzureSqlTable.json'
Publish-AdfArtifact 'pipelines' 'ProcessConfiguredTable' 'adf/pipeline_ProcessConfiguredTable.json'
Publish-AdfArtifact 'pipelines' 'MasterMetadataDriven' 'adf/pipeline_MasterMetadataDriven.json'

