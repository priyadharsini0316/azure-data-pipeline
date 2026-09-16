/*
Run with sqlcmd variables after ADF exists:
  -v ADF_NAME="actual-adf-name"
The deployment script replaces the variable safely and runs with an Entra access token.
*/
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='$(ADF_NAME)')
    EXEC('CREATE USER [' + '$(ADF_NAME)' + '] FROM EXTERNAL PROVIDER');
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='db_kpmg_pipeline_executor')
    CREATE ROLE db_kpmg_pipeline_executor;
GO

GRANT SELECT ON SCHEMA::ctl TO db_kpmg_pipeline_executor;
GRANT SELECT ON SCHEMA::reporting TO db_kpmg_pipeline_executor;
GRANT EXECUTE ON SCHEMA::ctl TO db_kpmg_pipeline_executor;
GRANT INSERT,UPDATE,SELECT ON SCHEMA::audit TO db_kpmg_pipeline_executor;
GRANT INSERT,UPDATE,SELECT ON SCHEMA::rfc TO db_kpmg_pipeline_executor;
GRANT SELECT ON SCHEMA::src TO db_kpmg_pipeline_executor;
GRANT SELECT,INSERT,UPDATE,DELETE,ALTER ON SCHEMA::stg TO db_kpmg_pipeline_executor;
GRANT SELECT,INSERT,UPDATE,DELETE,ALTER ON SCHEMA::curated TO db_kpmg_pipeline_executor;
GRANT CREATE TABLE TO db_kpmg_pipeline_executor;
ALTER ROLE db_kpmg_pipeline_executor ADD MEMBER [$(ADF_NAME)];
IF IS_ROLEMEMBER('db_datareader','$(ADF_NAME)')=1 ALTER ROLE db_datareader DROP MEMBER [$(ADF_NAME)];
IF IS_ROLEMEMBER('db_datawriter','$(ADF_NAME)')=1 ALTER ROLE db_datawriter DROP MEMBER [$(ADF_NAME)];
GO
