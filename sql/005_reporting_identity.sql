/*
Run after creating the Entra service principal:
  sqlcmd ... -v REPORT_READER_NAME="sp-kpmg-report-reader-<suffix>" -i sql/005_reporting_identity.sql

The credential is never stored in SQL or source control. Store the short-lived
prototype secret in Key Vault; prefer certificate or workload identity in production.
*/
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='$(REPORT_READER_NAME)')
    EXEC('CREATE USER [' + '$(REPORT_READER_NAME)' + '] FROM EXTERNAL PROVIDER');
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='db_kpmg_reporting_reader')
    CREATE ROLE db_kpmg_reporting_reader;
GO

GRANT SELECT ON SCHEMA::reporting TO db_kpmg_reporting_reader;
ALTER ROLE db_kpmg_reporting_reader ADD MEMBER [$(REPORT_READER_NAME)];
GO
