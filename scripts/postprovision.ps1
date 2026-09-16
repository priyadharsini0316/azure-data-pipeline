$ErrorActionPreference='Stop'

$azdCandidates=@('C:\Program Files\Azure Dev CLI\azd.exe',"$env:LOCALAPPDATA\Programs\Azure Dev CLI\azd.exe")
$azd=$azdCandidates|Where-Object{Test-Path -LiteralPath $_}|Select-Object -First 1
if(-not $azd){throw 'azd executable not found.'}

& $azd env get-values | ForEach-Object {
    $name,$value=$_.Split('=',2)
    Set-Item "env:$name" $value.Trim('"')
}

$sqlcmd=(Get-Command sqlcmd -ErrorAction SilentlyContinue).Source
if(-not $sqlcmd){
    $sqlcmd=Get-ChildItem "$env:ProgramFiles\sqlcmd" -Filter sqlcmd.exe -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1 -ExpandProperty FullName
}
if(-not $sqlcmd){throw 'sqlcmd was not found after installation.'}

$env:PATH="$(Split-Path $azd);$(Split-Path $sqlcmd);$env:PATH"
$env:SERVICE_API_NAME=$env:ADF_NAME
$env:SQL_SERVER=$env:SQL_SERVER_NAME
$env:SQL_DATABASE=$env:SQL_DATABASE_NAME
$env:SQL_GRANT_DDLADMIN='false'
& ./scripts/grant-sql-access.ps1

$Az='C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'
$callback=& $Az rest --method post --url "https://management.azure.com/subscriptions/$($env:AZURE_SUBSCRIPTION_ID)/resourceGroups/$($env:AZURE_RESOURCE_GROUP)/providers/Microsoft.Logic/workflows/$($env:LOGIC_APP_NAME)/triggers/manual/listCallbackUrl?api-version=2019-05-01" --query value -o tsv
if($LASTEXITCODE -ne 0 -or -not $callback){throw 'Unable to retrieve the Logic App callback URL.'}
$secretSet=$false
$secretFile=[System.IO.Path]::GetTempFileName()
try {
    Set-Content -LiteralPath $secretFile -Value $callback -NoNewline
    for($attempt=1;$attempt -le 6 -and -not $secretSet;$attempt++){
        & $Az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name logic-app-notification-endpoint --file $secretFile --output none
        if($LASTEXITCODE -eq 0){$secretSet=$true}else{Start-Sleep -Seconds (5*$attempt)}
    }
    if(-not $secretSet){throw 'Unable to store Logic App callback URL in Key Vault after RBAC propagation retries.'}
} finally {
    Remove-Item -LiteralPath $secretFile -Force -ErrorAction SilentlyContinue
}

$server="$($env:SQL_SERVER_NAME).database.windows.net"
$db=$env:SQL_DATABASE_NAME
foreach($file in @('sql/001_create_framework.sql','sql/002_sample_source.sql','sql/003_stored_procedures.sql')){
    & $sqlcmd -S $server -d $db --authentication-method ActiveDirectoryDefault -b -i $file
    if($LASTEXITCODE -ne 0){throw "SQL deployment failed: $file"}
}

$security=(Get-Content -Raw 'sql/004_security_template.sql').Replace('$(ADF_NAME)',$env:ADF_NAME)
$temp=[System.IO.Path]::GetTempFileName()+'.sql'
try {
    Set-Content -LiteralPath $temp -Value $security -NoNewline
    & $sqlcmd -S $server -d $db --authentication-method ActiveDirectoryDefault -b -i $temp
    if($LASTEXITCODE -ne 0){throw 'ADF SQL permission deployment failed.'}
} finally { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }

& ./scripts/deploy-adf.ps1 -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -ResourceGroup $env:AZURE_RESOURCE_GROUP -FactoryName $env:ADF_NAME -SqlServerFqdn $env:SQL_SERVER_FQDN -SqlDatabaseName $db -KeyVaultName $env:KEY_VAULT_NAME
