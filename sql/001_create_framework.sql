SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ctl') EXEC('CREATE SCHEMA ctl');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit') EXEC('CREATE SCHEMA audit');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rfc') EXEC('CREATE SCHEMA rfc');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'src') EXEC('CREATE SCHEMA src');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'curated') EXEC('CREATE SCHEMA curated');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reporting') EXEC('CREATE SCHEMA reporting');
GO

IF OBJECT_ID('ctl.PipelineConfiguration','U') IS NULL
BEGIN
    CREATE TABLE ctl.PipelineConfiguration
    (
        ConfigId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_PipelineConfiguration PRIMARY KEY,
        SourceSchema sysname NOT NULL CONSTRAINT DF_PC_SourceSchema DEFAULT('src'),
        SourceTable sysname NOT NULL,
        TargetSchema sysname NOT NULL CONSTRAINT DF_PC_TargetSchema DEFAULT('curated'),
        TargetTable sysname NOT NULL,
        [Load] varchar(3) NOT NULL CONSTRAINT CK_PC_Load CHECK ([Load] IN ('Yes','No')),
        LoadType varchar(12) NOT NULL CONSTRAINT CK_PC_LoadType CHECK (LoadType IN ('FULL','WATERMARK')),
        WatermarkColumn sysname NULL,
        PrimaryKeyColumn sysname NOT NULL,
        ConnectionReference varchar(100) NOT NULL CONSTRAINT DF_PC_Connection DEFAULT('AzureSqlPrototype'),
        RetryCount tinyint NOT NULL CONSTRAINT DF_PC_Retry DEFAULT(3),
        RetryIntervalSeconds smallint NOT NULL CONSTRAINT DF_PC_RetryInterval DEFAULT(15),
        ApprovedColumnList nvarchar(max) NULL,
        ApprovedSchemaHash varchar(64) NULL,
        ApprovedSchemaVersion int NULL,
        LastWatermarkValue datetime2(7) NULL,
        LastRunStatus varchar(20) NULL,
        LastSuccessfulRunUtc datetime2(7) NULL,
        CreatedUtc datetime2(7) NOT NULL CONSTRAINT DF_PC_Created DEFAULT SYSUTCDATETIME(),
        ModifiedUtc datetime2(7) NOT NULL CONSTRAINT DF_PC_Modified DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_PC_Source UNIQUE(SourceSchema, SourceTable),
        CONSTRAINT CK_PC_Watermark CHECK (LoadType <> 'WATERMARK' OR WatermarkColumn IS NOT NULL)
    );
END;
GO

IF OBJECT_ID('audit.PipelineRunAudit','U') IS NULL
BEGIN
    CREATE TABLE audit.PipelineRunAudit
    (
        PipelineRunAuditId bigint IDENTITY(1,1) PRIMARY KEY,
        AdfPipelineRunId varchar(100) NOT NULL,
        PipelineName sysname NOT NULL,
        StartedUtc datetime2(7) NOT NULL CONSTRAINT DF_PRA_Start DEFAULT SYSUTCDATETIME(),
        CompletedUtc datetime2(7) NULL,
        Status varchar(20) NOT NULL,
        EnabledTableCount int NULL,
        SuccessfulTableCount int NULL,
        FailedTableCount int NULL,
        Message nvarchar(2000) NULL,
        CONSTRAINT UQ_PRA_Run UNIQUE(AdfPipelineRunId)
    );
END;
GO

IF OBJECT_ID('audit.TableLoadAudit','U') IS NULL
BEGIN
    CREATE TABLE audit.TableLoadAudit
    (
        TableLoadAuditId bigint IDENTITY(1,1) PRIMARY KEY,
        AdfPipelineRunId varchar(100) NOT NULL,
        ConfigId int NOT NULL,
        SourceObject nvarchar(261) NOT NULL,
        TargetObject nvarchar(261) NOT NULL,
        LoadType varchar(12) NOT NULL,
        IsFirstLoad bit NOT NULL,
        SchemaChangeDetected bit NOT NULL CONSTRAINT DF_TLA_SchemaChange DEFAULT(0),
        SchemaApprovalStatus varchar(20) NULL,
        StartedUtc datetime2(7) NOT NULL CONSTRAINT DF_TLA_Start DEFAULT SYSUTCDATETIME(),
        CompletedUtc datetime2(7) NULL,
        SourceRowCount bigint NULL,
        TargetRowCount bigint NULL,
        RowsInserted bigint NULL,
        RowsUpdated bigint NULL,
        Status varchar(20) NOT NULL,
        ErrorMessage nvarchar(4000) NULL,
        CONSTRAINT FK_TLA_Config FOREIGN KEY(ConfigId) REFERENCES ctl.PipelineConfiguration(ConfigId)
    );
    CREATE INDEX IX_TLA_Run ON audit.TableLoadAudit(AdfPipelineRunId, ConfigId);
END;
GO

IF OBJECT_ID('audit.ReconciliationResult','U') IS NULL
BEGIN
    CREATE TABLE audit.ReconciliationResult
    (
        ReconciliationResultId bigint IDENTITY(1,1) PRIMARY KEY,
        TableLoadAuditId bigint NOT NULL,
        GateStage varchar(30) NOT NULL,
        CheckName varchar(50) NOT NULL,
        ExpectedValue nvarchar(500) NULL,
        ActualValue nvarchar(500) NULL,
        Result varchar(10) NOT NULL CONSTRAINT CK_RR_Result CHECK(Result IN ('PASS','WARNING','FAIL')),
        Details nvarchar(2000) NULL,
        CheckedUtc datetime2(7) NOT NULL CONSTRAINT DF_RR_Checked DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_RR_TableLoad FOREIGN KEY(TableLoadAuditId) REFERENCES audit.TableLoadAudit(TableLoadAuditId)
    );
END;
GO

IF OBJECT_ID('audit.NotificationAudit','U') IS NULL
BEGIN
    CREATE TABLE audit.NotificationAudit
    (
        NotificationAuditId bigint IDENTITY(1,1) PRIMARY KEY,
        AdfPipelineRunId varchar(100) NOT NULL,
        ConfigId int NULL,
        EventType varchar(40) NOT NULL,
        DeliveryStatus varchar(20) NOT NULL,
        Message nvarchar(2000) NOT NULL,
        CreatedUtc datetime2(7) NOT NULL CONSTRAINT DF_NA_Created DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID('rfc.SchemaHistory','U') IS NULL
BEGIN
    CREATE TABLE rfc.SchemaHistory
    (
        SchemaHistoryId bigint IDENTITY(1,1) PRIMARY KEY,
        ConfigId int NOT NULL,
        SchemaVersion int NOT NULL,
        SchemaHash varchar(64) NOT NULL,
        ColumnList nvarchar(max) NOT NULL,
        SchemaDefinition nvarchar(max) NOT NULL,
        ApprovalStatus varchar(20) NOT NULL,
        ApprovedBy nvarchar(256) NULL,
        ApprovedUtc datetime2(7) NULL,
        EffectiveUtc datetime2(7) NOT NULL CONSTRAINT DF_SH_Effective DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_SH_Version UNIQUE(ConfigId, SchemaVersion),
        CONSTRAINT FK_SH_Config FOREIGN KEY(ConfigId) REFERENCES ctl.PipelineConfiguration(ConfigId)
    );
END;
GO

IF OBJECT_ID('rfc.SchemaChangeRequest','U') IS NULL
BEGIN
    CREATE TABLE rfc.SchemaChangeRequest
    (
        SchemaChangeRequestId bigint IDENTITY(1,1) PRIMARY KEY,
        ConfigId int NOT NULL,
        DetectedSchemaHash varchar(64) NOT NULL,
        PreviousSchemaHash varchar(64) NULL,
        DetectedColumnList nvarchar(max) NOT NULL,
        DetectedSchemaDefinition nvarchar(max) NOT NULL,
        ChangeSummary nvarchar(2000) NOT NULL,
        Compatibility varchar(20) NOT NULL,
        Status varchar(20) NOT NULL CONSTRAINT CK_SCR_Status CHECK(Status IN ('PENDING','APPROVED','REJECTED')),
        DetectedUtc datetime2(7) NOT NULL CONSTRAINT DF_SCR_Detected DEFAULT SYSUTCDATETIME(),
        DecisionUtc datetime2(7) NULL,
        DecisionBy nvarchar(256) NULL,
        DecisionNotes nvarchar(2000) NULL,
        CONSTRAINT FK_SCR_Config FOREIGN KEY(ConfigId) REFERENCES ctl.PipelineConfiguration(ConfigId)
    );
    CREATE UNIQUE INDEX UX_SCR_Pending ON rfc.SchemaChangeRequest(ConfigId) WHERE Status='PENDING';
END;
GO

CREATE OR ALTER VIEW reporting.vw_PipelineHealth
AS
SELECT
    pc.ConfigId,
    CONCAT(QUOTENAME(pc.SourceSchema),'.',QUOTENAME(pc.SourceTable)) AS SourceObject,
    CONCAT(QUOTENAME(pc.TargetSchema),'.',QUOTENAME(pc.TargetTable)) AS TargetObject,
    pc.[Load], pc.LoadType, pc.LastRunStatus, pc.LastSuccessfulRunUtc,
    pc.ApprovedSchemaVersion,
    (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest r WHERE r.ConfigId=pc.ConfigId AND r.Status='PENDING') AS PendingSchemaChanges,
    (SELECT MAX(t.CompletedUtc) FROM audit.TableLoadAudit t WHERE t.ConfigId=pc.ConfigId AND t.Status='SUCCESS') AS LastCompletedUtc
FROM ctl.PipelineConfiguration pc;
GO

CREATE OR ALTER VIEW reporting.vw_ReconciliationSummary
AS
SELECT t.AdfPipelineRunId, t.ConfigId, t.SourceObject, t.TargetObject, t.Status AS LoadStatus,
       r.GateStage, r.CheckName, r.Result, r.ExpectedValue, r.ActualValue, r.Details, r.CheckedUtc
FROM audit.TableLoadAudit t
JOIN audit.ReconciliationResult r ON r.TableLoadAuditId=t.TableLoadAuditId;
GO

