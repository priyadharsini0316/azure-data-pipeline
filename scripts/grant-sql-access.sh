#!/bin/bash
# Grant Azure SQL data-plane access to the App Service / Container App managed identity.
set -e

while IFS= read -r line; do
  [ -n "$line" ] || continue
  key=${line%%=*}
  value=${line#*=}
  case "$value" in
    \"*\") value=${value#\"}; value=${value%\"} ;;
    \'*\') value=${value#\'}; value=${value%\'} ;;
  esac
  export "$key=$value"
done < <(azd env get-values)

APP_NAME=${SERVICE_WEB_NAME:-$SERVICE_API_NAME}
if [ -z "$APP_NAME" ]; then
  echo "ERROR: Neither SERVICE_WEB_NAME nor SERVICE_API_NAME is set in azd environment." >&2
  exit 1
fi

SQL_QUERIES="
  IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$APP_NAME')
    CREATE USER [$APP_NAME] FROM EXTERNAL PROVIDER;
  IF NOT EXISTS (SELECT 1 FROM sys.database_role_members drm JOIN sys.database_principals r ON drm.role_principal_id=r.principal_id JOIN sys.database_principals m ON drm.member_principal_id=m.principal_id WHERE r.name='db_datareader' AND m.name='$APP_NAME')
    ALTER ROLE db_datareader ADD MEMBER [$APP_NAME];
  IF NOT EXISTS (SELECT 1 FROM sys.database_role_members drm JOIN sys.database_principals r ON drm.role_principal_id=r.principal_id JOIN sys.database_principals m ON drm.member_principal_id=m.principal_id WHERE r.name='db_datawriter' AND m.name='$APP_NAME')
    ALTER ROLE db_datawriter ADD MEMBER [$APP_NAME];"

sqlcmd -S "${SQL_SERVER}.database.windows.net" -d "$SQL_DATABASE" --authentication-method ActiveDirectoryDefault -Q "$SQL_QUERIES"

