$ErrorActionPreference='Stop'
$failures=[System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition,[string]$Message){if(-not $Condition){$failures.Add($Message)}}

$required=@(
  'azure.yaml','infra/main.bicep','infra/resources.bicep',
  'sql/001_create_framework.sql','sql/002_sample_source.sql','sql/003_stored_procedures.sql','sql/004_security_template.sql',
  'sql/005_reporting_identity.sql','sql/006_powerbi_reporting_views.sql',
  'adf/pipeline_MasterMetadataDriven.json','adf/pipeline_ProcessConfiguredTable.json',
  'adf/dataset_DynamicAzureSqlTable.json','scripts/postprovision.ps1',
  'powerbi/KPMG Pipeline Health.pbip','powerbi/KPMG Pipeline Health.Report/definition/report.json',
  'docs/IMPLEMENTATION_GUIDE.md','docs/PRIYA_LEARNING_GUIDE.md','docs/INTERVIEW_QA.md',
  'docs/REQUIREMENTS_TRACEABILITY_MATRIX.md'
)
foreach($path in $required){Assert-True (Test-Path -LiteralPath $path) "Missing required artifact: $path"}

foreach($json in Get-ChildItem adf -Filter *.json){
  try{Get-Content -Raw $json.FullName|ConvertFrom-Json|Out-Null}catch{$failures.Add("Invalid JSON $($json.Name): $($_.Exception.Message)")}
}

$infra=(Get-Content -Raw infra/main.bicep,infra/resources.bicep) -join "`n"
foreach($pattern in @('Microsoft.Network/privateEndpoints','privateDnsZones','Microsoft.OperationalInsights/workspaces','Microsoft.Storage/storageAccounts','Microsoft.Fabric/capacities')){
  Assert-True (-not ($infra -match [regex]::Escape($pattern))) "Forbidden resource type found: $pattern"
}
Assert-True (-not ($infra -match 'administratorLogin|administratorLoginPassword')) 'Prohibited SQL password authentication property found.'
Assert-True ($infra -match "useFreeLimit: true") 'Azure SQL free-offer guard is missing.'
Assert-True ($infra -match "freeLimitExhaustionBehavior: 'AutoPause'") 'Azure SQL free-limit AutoPause guard is missing.'
Assert-True ($infra -match "capacity: 1") 'GP_S_Gen5_1 capacity is not present.'

$master=Get-Content -Raw adf/pipeline_MasterMetadataDriven.json
foreach($term in @('Lookup enabled configuration','ForEach enabled table','Execute table framework','Finalize pipeline audit')){Assert-True ($master.Contains($term)) "Master pipeline missing: $term"}
$child=Get-Content -Raw adf/pipeline_ProcessConfiguredTable.json
Assert-True ($child -match '"retry": 3') 'Child pipeline retry count must be 3.'
Assert-True ($child.Contains('Get notification endpoint')) 'Key Vault notification endpoint retrieval is missing.'

$sql=(Get-Content -Raw sql/001_create_framework.sql,sql/003_stored_procedures.sql) -join "`n"
foreach($term in @('PipelineConfiguration','PipelineRunAudit','TableLoadAudit','SchemaHistory','SchemaChangeRequest','ReconciliationResult','PENDING','APPROVED','REJECTED')){Assert-True ($sql.Contains($term)) "SQL framework missing: $term"}
Assert-True ($sql.Contains('DetectedSchemaHash=@CurrentHash')) 'Exact-schema RFC decision reuse is missing.'
Assert-True ($sql.Contains('ROW_NUMBER() OVER(PARTITION BY ConfigId')) 'Retry-aware latest table outcome aggregation is missing.'
Assert-True ($sql.Contains("THROW 50020,'One or more configured table loads failed")) 'Master failure propagation is missing.'

if($failures.Count){$failures|ForEach-Object{Write-Error $_}; exit 1}
Write-Host 'Static implementation checks passed.'
