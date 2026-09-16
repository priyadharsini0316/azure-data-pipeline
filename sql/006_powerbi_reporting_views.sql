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
    (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest WHERE Status='APPROVED') AS ApprovedSchemaChanges,
    (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest WHERE Status='REJECTED') AS RejectedSchemaChanges,
    (SELECT COUNT_BIG(*) FROM audit.ReconciliationResult WHERE Result='FAIL') AS ReconciliationFailures,
    (SELECT COALESCE(SUM(Retries),0) FROM
      (SELECT COUNT_BIG(*)-1 AS Retries FROM audit.TableLoadAudit
       GROUP BY AdfPipelineRunId,ConfigId HAVING COUNT_BIG(*)>1) attempts) AS TotalRetryAttempts,
    (SELECT CAST(AVG(CAST(DATEDIFF(second,StartedUtc,CompletedUtc) AS decimal(18,2))) AS decimal(18,2))
       FROM audit.PipelineRunAudit WHERE CompletedUtc IS NOT NULL) AS AverageDurationSeconds;
GO

CREATE OR ALTER VIEW reporting.vw_SchemaChangeRequests AS
SELECT r.SchemaChangeRequestId AS RequestId,
       CONCAT(QUOTENAME(c.SourceSchema),'.',QUOTENAME(c.SourceTable)) AS SourceObject,
       r.DetectedUtc,r.ChangeSummary,r.Compatibility,r.Status,r.DecisionBy,r.DecisionUtc,r.DecisionNotes
FROM rfc.SchemaChangeRequest r JOIN ctl.PipelineConfiguration c ON c.ConfigId=r.ConfigId;
GO

CREATE OR ALTER VIEW reporting.vw_SchemaVersionHistory AS
SELECT CONCAT(QUOTENAME(c.SourceSchema),'.',QUOTENAME(c.SourceTable)) AS SourceObject,
       h.SchemaVersion,h.ApprovalStatus,h.ApprovedBy,h.ApprovedUtc,h.ColumnList
FROM rfc.SchemaHistory h JOIN ctl.PipelineConfiguration c ON c.ConfigId=h.ConfigId;
GO

CREATE OR ALTER VIEW reporting.vw_ReconciliationResults AS
SELECT t.AdfPipelineRunId,p.StartedUtc AS RunStartedUtc,t.SourceObject,
       CASE WHEN r.GateStage='GATE_1_PRE_PUBLISH' THEN 'Gate 1 - Source vs Dev/Test'
            WHEN r.GateStage='GATE_2_POST_PUBLISH' THEN 'Gate 2 - Dev/Test vs Integ/Prod'
            ELSE r.GateStage END AS GateLabel,
       r.CheckName,r.ExpectedValue,r.ActualValue,r.Result
FROM audit.ReconciliationResult r
JOIN audit.TableLoadAudit t ON t.TableLoadAuditId=r.TableLoadAuditId
LEFT JOIN audit.PipelineRunAudit p ON p.AdfPipelineRunId=t.AdfPipelineRunId;
GO

CREATE OR ALTER VIEW reporting.vw_TableLoadDetail AS
SELECT t.AdfPipelineRunId,p.StartedUtc AS RunStartedUtc,t.SourceObject,t.LoadType,
       t.IsFirstLoad,t.SchemaChangeDetected,t.SchemaApprovalStatus,
       ROW_NUMBER() OVER(PARTITION BY t.AdfPipelineRunId,t.ConfigId ORDER BY t.TableLoadAuditId) AS AttemptNumber,
       t.SourceRowCount,t.TargetRowCount,t.Status,t.ErrorMessage
FROM audit.TableLoadAudit t
LEFT JOIN audit.PipelineRunAudit p ON p.AdfPipelineRunId=t.AdfPipelineRunId;
GO

CREATE OR ALTER VIEW reporting.vw_NotificationEvents AS
SELECT n.AdfPipelineRunId,CONCAT(QUOTENAME(c.SourceSchema),'.',QUOTENAME(c.SourceTable)) AS SourceObject,
       n.EventType,n.DeliveryStatus,n.Message,n.CreatedUtc
FROM audit.NotificationAudit n
LEFT JOIN ctl.PipelineConfiguration c ON c.ConfigId=n.ConfigId;
GO

CREATE OR ALTER VIEW reporting.vw_PipelineHealth AS
SELECT pc.ConfigId,CONCAT(QUOTENAME(pc.SourceSchema),'.',QUOTENAME(pc.SourceTable)) AS SourceObject,
       CONCAT(QUOTENAME(pc.TargetSchema),'.',QUOTENAME(pc.TargetTable)) AS TargetObject,
       pc.[Load],pc.LoadType,
       CASE WHEN pc.[Load]='No' THEN 'Skipped (Load = No)' ELSE pc.LastRunStatus END AS LastRunStatus,
       pc.LastSuccessfulRunUtc,pc.ApprovedSchemaVersion,
       (SELECT COUNT_BIG(*) FROM rfc.SchemaChangeRequest r WHERE r.ConfigId=pc.ConfigId AND r.Status='PENDING') AS PendingSchemaChanges,
       (SELECT MAX(t.CompletedUtc) FROM audit.TableLoadAudit t WHERE t.ConfigId=pc.ConfigId AND t.Status='SUCCESS') AS LastCompletedUtc
FROM ctl.PipelineConfiguration pc;
GO
