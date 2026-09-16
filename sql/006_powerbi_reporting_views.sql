SET NOCOUNT ON;
GO

CREATE OR ALTER VIEW reporting.vw_RecentPipelineRuns
AS
SELECT
    PipelineRunAuditId,
    AdfPipelineRunId,
    PipelineName,
    StartedUtc,
    CompletedUtc,
    DATEDIFF(second,StartedUtc,CompletedUtc) AS DurationSeconds,
    Status,
    EnabledTableCount,
    SuccessfulTableCount,
    FailedTableCount,
    Message
FROM audit.PipelineRunAudit;
GO

CREATE OR ALTER VIEW reporting.vw_RecentTableLoads
AS
SELECT
    TableLoadAuditId,
    AdfPipelineRunId,
    ConfigId,
    SourceObject,
    TargetObject,
    LoadType,
    IsFirstLoad,
    SchemaChangeDetected,
    SchemaApprovalStatus,
    StartedUtc,
    CompletedUtc,
    DATEDIFF(second,StartedUtc,CompletedUtc) AS DurationSeconds,
    SourceRowCount,
    TargetRowCount,
    RowsInserted,
    RowsUpdated,
    Status,
    ErrorMessage
FROM audit.TableLoadAudit;
GO

CREATE OR ALTER VIEW reporting.vw_PipelineDashboardSummary
AS
SELECT
    (SELECT COUNT_BIG(*) FROM ctl.PipelineConfiguration) AS TotalConfiguredTables,
    (SELECT COUNT_BIG(*) FROM ctl.PipelineConfiguration WHERE [Load]='Yes') AS EnabledTables,
    (SELECT COUNT_BIG(*) FROM audit.PipelineRunAudit WHERE Status='SUCCESS') AS SuccessfulRuns,
    (SELECT COUNT_BIG(*) FROM audit.PipelineRunAudit WHERE Status IN ('FAILURE','PARTIAL_SUCCESS')) AS FailedOrPartialRuns,
    (SELECT COALESCE(SUM(COALESCE(SourceRowCount,0)),0) FROM audit.TableLoadAudit WHERE Status='SUCCESS') AS RowsProcessed,
    (SELECT MAX(CompletedUtc) FROM audit.PipelineRunAudit WHERE Status='SUCCESS') AS LastSuccessfulRunUtc,
    (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest) AS SchemaChangesDetected,
    (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest WHERE Status='PENDING') AS PendingSchemaChanges,
    (SELECT COUNT_BIG(*) FROM audit.ReconciliationResult WHERE Result='FAIL') AS ReconciliationFailures,
    (SELECT CAST(AVG(CAST(DATEDIFF(second,StartedUtc,CompletedUtc) AS decimal(18,2))) AS decimal(18,2))
       FROM audit.PipelineRunAudit WHERE CompletedUtc IS NOT NULL) AS AverageDurationSeconds;
GO
