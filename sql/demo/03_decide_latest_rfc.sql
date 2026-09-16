DECLARE @RequestId bigint=(SELECT TOP(1) SchemaChangeRequestId FROM rfc.SchemaChangeRequest WHERE Status='PENDING' ORDER BY SchemaChangeRequestId DESC);
IF @RequestId IS NULL THROW 52001,'No pending schema-change request found.',1;
EXEC rfc.usp_DecideSchemaChange @SchemaChangeRequestId=@RequestId,@Decision='APPROVED',@DecisionBy='Priya',@DecisionNotes='Approved during KPMG prototype demonstration.';

