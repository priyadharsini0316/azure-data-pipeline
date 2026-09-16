SET NOCOUNT ON;

IF NOT EXISTS(SELECT 1 FROM ctl.PipelineConfiguration WHERE [Load]='Yes') THROW 51001,'No enabled configurations.',1;
IF NOT EXISTS(SELECT 1 FROM ctl.PipelineConfiguration WHERE [Load]='No') THROW 51002,'No disabled configuration for exclusion demo.',1;
IF EXISTS(SELECT 1 FROM ctl.PipelineConfiguration WHERE LoadType='WATERMARK' AND WatermarkColumn IS NULL) THROW 51003,'Invalid watermark configuration.',1;

SELECT 'Configuration' AS Evidence,* FROM ctl.PipelineConfiguration ORDER BY ConfigId;
SELECT 'PipelineAudit' AS Evidence,* FROM audit.PipelineRunAudit ORDER BY PipelineRunAuditId DESC;
SELECT 'TableAudit' AS Evidence,* FROM audit.TableLoadAudit ORDER BY TableLoadAuditId DESC;
SELECT 'Reconciliation' AS Evidence,* FROM audit.ReconciliationResult ORDER BY ReconciliationResultId DESC;
SELECT 'SchemaRFC' AS Evidence,* FROM rfc.SchemaChangeRequest ORDER BY SchemaChangeRequestId DESC;

