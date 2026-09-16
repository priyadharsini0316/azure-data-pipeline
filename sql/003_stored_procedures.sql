SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE ctl.usp_StartPipelineRun
    @AdfPipelineRunId varchar(100),
    @PipelineName sysname
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM audit.PipelineRunAudit WHERE AdfPipelineRunId=@AdfPipelineRunId)
        INSERT audit.PipelineRunAudit(AdfPipelineRunId,PipelineName,Status,EnabledTableCount)
        SELECT @AdfPipelineRunId,@PipelineName,'RUNNING',COUNT(*)
        FROM ctl.PipelineConfiguration WHERE [Load]='Yes';
END;
GO

CREATE OR ALTER PROCEDURE ctl.usp_FinalizePipelineRun
    @AdfPipelineRunId varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    -- ADF retries create multiple audit attempts for the same configured table.
    -- Pipeline totals therefore use only the latest attempt per ConfigId.
    DECLARE @LatestOutcome TABLE (ConfigId int PRIMARY KEY, Status varchar(20));
    INSERT @LatestOutcome(ConfigId,Status)
    SELECT ConfigId,Status
    FROM
    (
        SELECT ConfigId,Status,
               ROW_NUMBER() OVER(PARTITION BY ConfigId ORDER BY TableLoadAuditId DESC) AS rn
        FROM audit.TableLoadAudit
        WHERE AdfPipelineRunId=@AdfPipelineRunId
    ) attempts
    WHERE rn=1;

    DECLARE @success int=(SELECT COUNT(*) FROM @LatestOutcome WHERE Status='SUCCESS');
    DECLARE @failed int=(SELECT COUNT(*) FROM @LatestOutcome WHERE Status='FAILURE');
    UPDATE audit.PipelineRunAudit
    SET CompletedUtc=SYSUTCDATETIME(), SuccessfulTableCount=@success, FailedTableCount=@failed,
        Status=CASE WHEN @failed=0 THEN 'SUCCESS' WHEN @success>0 THEN 'PARTIAL_SUCCESS' ELSE 'FAILURE' END,
        Message=CONCAT(@success,' table(s) succeeded; ',@failed,' table(s) failed.')
    WHERE AdfPipelineRunId=@AdfPipelineRunId;

    SELECT Status,Message FROM audit.PipelineRunAudit WHERE AdfPipelineRunId=@AdfPipelineRunId;

    -- Preserve the detailed PARTIAL_SUCCESS audit while surfacing a failed
    -- orchestration status to ADF monitoring and alerting.
    IF @failed>0
        THROW 50020,'One or more configured table loads failed. Review audit.PipelineRunAudit and audit.TableLoadAudit.',1;
END;
GO

CREATE OR ALTER PROCEDURE rfc.usp_DecideSchemaChange
    @SchemaChangeRequestId bigint,
    @Decision varchar(20),
    @DecisionBy nvarchar(256),
    @DecisionNotes nvarchar(2000)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @Decision NOT IN ('APPROVED','REJECTED') THROW 50001,'Decision must be APPROVED or REJECTED.',1;

    BEGIN TRAN;
    DECLARE @ConfigId int,@Hash varchar(64),@Columns nvarchar(max),@Definition nvarchar(max),@CurrentStatus varchar(20),@Version int;
    SELECT @ConfigId=ConfigId,@Hash=DetectedSchemaHash,@Columns=DetectedColumnList,@Definition=DetectedSchemaDefinition,@CurrentStatus=Status
    FROM rfc.SchemaChangeRequest WITH(UPDLOCK,HOLDLOCK) WHERE SchemaChangeRequestId=@SchemaChangeRequestId;
    IF @ConfigId IS NULL THROW 50002,'Schema change request not found.',1;
    IF @CurrentStatus<>'PENDING' THROW 50003,'Only PENDING requests can be decided.',1;

    UPDATE rfc.SchemaChangeRequest
    SET Status=@Decision,DecisionUtc=SYSUTCDATETIME(),DecisionBy=@DecisionBy,DecisionNotes=@DecisionNotes
    WHERE SchemaChangeRequestId=@SchemaChangeRequestId;

    IF @Decision='APPROVED'
    BEGIN
        SELECT @Version=ISNULL(MAX(SchemaVersion),0)+1 FROM rfc.SchemaHistory WHERE ConfigId=@ConfigId;
        INSERT rfc.SchemaHistory(ConfigId,SchemaVersion,SchemaHash,ColumnList,SchemaDefinition,ApprovalStatus,ApprovedBy,ApprovedUtc)
        VALUES(@ConfigId,@Version,@Hash,@Columns,@Definition,'APPROVED',@DecisionBy,SYSUTCDATETIME());
        UPDATE ctl.PipelineConfiguration
        SET ApprovedColumnList=@Columns,ApprovedSchemaHash=@Hash,ApprovedSchemaVersion=@Version,ModifiedUtc=SYSUTCDATETIME()
        WHERE ConfigId=@ConfigId;
    END;
    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE ctl.usp_ProcessConfiguredTable
    @ConfigId int,
    @AdfPipelineRunId varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SourceSchema sysname,@SourceTable sysname,@TargetSchema sysname,@TargetTable sysname,
            @LoadType varchar(12),@WatermarkColumn sysname,@PrimaryKey sysname,@Enabled varchar(3),
            @ApprovedColumns nvarchar(max),@ApprovedHash varchar(64),@ApprovedVersion int,@LastWatermark datetime2(7),
            @SourceObject nvarchar(517),@TargetObject nvarchar(517),@StageObject nvarchar(517),@WorkObject nvarchar(517),@CurrentColumns nvarchar(max),@SchemaDefinition nvarchar(max),
            @CurrentHash varchar(64),@IsFirst bit,@SchemaChanged bit=0,@ApprovalStatus varchar(20)=NULL,
            @TableLoadAuditId bigint,@Sql nvarchar(max),@Missing int,@SourceCount bigint,@TargetCount bigint,
            @DuplicateCount bigint,@NullKeyCount bigint,@StageCount bigint,@MissingPublished bigint,
            @NewWatermark datetime2(7),@Error nvarchar(4000),@Gate2Checked bit=0;
    DECLARE @Gate2Checks TABLE(CheckName varchar(50),ExpectedValue nvarchar(500),ActualValue nvarchar(500),Result varchar(10),Details nvarchar(2000));

    SELECT @SourceSchema=SourceSchema,@SourceTable=SourceTable,@TargetSchema=TargetSchema,@TargetTable=TargetTable,
           @LoadType=LoadType,@WatermarkColumn=WatermarkColumn,@PrimaryKey=PrimaryKeyColumn,@Enabled=[Load],
           @ApprovedColumns=ApprovedColumnList,@ApprovedHash=ApprovedSchemaHash,@ApprovedVersion=ApprovedSchemaVersion,
           @LastWatermark=LastWatermarkValue
    FROM ctl.PipelineConfiguration WHERE ConfigId=@ConfigId;

    IF @SourceTable IS NULL THROW 50010,'Configuration row not found.',1;
    IF @Enabled<>'Yes' THROW 50011,'Configuration row is not enabled.',1;
    SET @SourceObject=QUOTENAME(@SourceSchema)+'.'+QUOTENAME(@SourceTable);
    SET @TargetObject=QUOTENAME(@TargetSchema)+'.'+QUOTENAME(@TargetTable);
    SET @StageObject=QUOTENAME('stg')+'.'+QUOTENAME(@TargetTable);
    SET @IsFirst=CASE WHEN @ApprovedHash IS NULL THEN 1 ELSE 0 END;

    SELECT
      @CurrentColumns=STRING_AGG(QUOTENAME(name),',') WITHIN GROUP(ORDER BY column_id),
      @SchemaDefinition=STRING_AGG(CONCAT(name,':',type_name,':',max_length,':',precision_value,':',scale_value,':',is_nullable),'|') WITHIN GROUP(ORDER BY column_id)
    FROM (
      SELECT c.column_id,c.name,TYPE_NAME(c.user_type_id) type_name,c.max_length,c.precision precision_value,c.scale scale_value,c.is_nullable
      FROM sys.columns c
      WHERE c.object_id=OBJECT_ID(@SourceObject)
    ) d;
    IF @CurrentColumns IS NULL THROW 50012,'Configured source table does not exist.',1;
    SET @CurrentHash=CONVERT(varchar(64),HASHBYTES('SHA2_256',@SchemaDefinition),2);

    IF @IsFirst=1
    BEGIN
      SET @ApprovedColumns=@CurrentColumns; SET @ApprovedHash=@CurrentHash; SET @ApprovedVersion=1;
      UPDATE ctl.PipelineConfiguration SET ApprovedColumnList=@ApprovedColumns,ApprovedSchemaHash=@ApprovedHash,ApprovedSchemaVersion=1,ModifiedUtc=SYSUTCDATETIME() WHERE ConfigId=@ConfigId;
      IF NOT EXISTS(SELECT 1 FROM rfc.SchemaHistory WHERE ConfigId=@ConfigId AND SchemaVersion=1)
        INSERT rfc.SchemaHistory(ConfigId,SchemaVersion,SchemaHash,ColumnList,SchemaDefinition,ApprovalStatus,ApprovedBy,ApprovedUtc)
        VALUES(@ConfigId,1,@CurrentHash,@CurrentColumns,@SchemaDefinition,'APPROVED','INITIAL_LOAD',SYSUTCDATETIME());
    END
    ELSE IF @CurrentHash<>@ApprovedHash
    BEGIN
      SET @SchemaChanged=1;
      -- Reuse a decision already made for this exact detected schema. This makes
      -- reruns idempotent after a rejection and avoids creating duplicate RFCs.
      SELECT TOP (1) @ApprovalStatus=Status
      FROM rfc.SchemaChangeRequest
      WHERE ConfigId=@ConfigId AND DetectedSchemaHash=@CurrentHash
      ORDER BY SchemaChangeRequestId DESC;

      -- Only one unresolved schema decision is allowed per configured table.
      IF @ApprovalStatus IS NULL
        SELECT TOP (1) @ApprovalStatus=Status
        FROM rfc.SchemaChangeRequest
        WHERE ConfigId=@ConfigId AND Status='PENDING'
        ORDER BY SchemaChangeRequestId DESC;

      IF @ApprovalStatus IS NULL
      BEGIN
        INSERT rfc.SchemaChangeRequest(ConfigId,DetectedSchemaHash,PreviousSchemaHash,DetectedColumnList,DetectedSchemaDefinition,ChangeSummary,Compatibility,Status)
        VALUES(@ConfigId,@CurrentHash,@ApprovedHash,@CurrentColumns,@SchemaDefinition,
               'Source schema differs from the last approved version. Prototype requires human approval.',
               CASE WHEN NOT EXISTS(
                 SELECT 1 FROM STRING_SPLIT(REPLACE(REPLACE(@ApprovedColumns,'[',''),']',''),',') a
                 WHERE NOT EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=OBJECT_ID(@SourceObject) AND c.name=LTRIM(RTRIM(a.value)))
               ) THEN 'OLD_PROJECTION_SAFE' ELSE 'BREAKING' END,'PENDING');
        SET @ApprovalStatus='PENDING';
      END;
    END;

    SELECT @Missing=COUNT(*)
    FROM STRING_SPLIT(REPLACE(REPLACE(@ApprovedColumns,'[',''),']',''),',') a
    WHERE NOT EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=OBJECT_ID(@SourceObject) AND c.name=LTRIM(RTRIM(a.value)));

    INSERT audit.TableLoadAudit(AdfPipelineRunId,ConfigId,SourceObject,TargetObject,LoadType,IsFirstLoad,SchemaChangeDetected,SchemaApprovalStatus,Status)
    VALUES(@AdfPipelineRunId,@ConfigId,@SourceObject,@TargetObject,@LoadType,@IsFirst,@SchemaChanged,@ApprovalStatus,'RUNNING');
    SET @TableLoadAuditId=SCOPE_IDENTITY();

    BEGIN TRY
      IF @Missing>0
      BEGIN
        INSERT audit.ReconciliationResult(TableLoadAuditId,GateStage,CheckName,ExpectedValue,ActualValue,Result,Details)
        VALUES(@TableLoadAuditId,'GATE_1_PRE_PUBLISH','APPROVED_SCHEMA','0',CONVERT(varchar(30),@Missing),'FAIL',
               'Previously approved column missing or renamed; old projection cannot be loaded safely.');
        THROW 50013,'Previously approved column is missing or renamed; old projection cannot be loaded safely.',1;
      END;

      -- The high-water mark is fixed BEFORE staging. Later source writes are
      -- intentionally left for the next run, never silently skipped.
      IF @LoadType='WATERMARK'
      BEGIN
        SET @Sql=N'SELECT @wm=MAX('+QUOTENAME(@WatermarkColumn)+N') FROM '+@SourceObject+N';';
        EXEC sys.sp_executesql @Sql,N'@wm datetime2(7) OUTPUT',@wm=@NewWatermark OUTPUT;
      END;

      -- Only approved columns are copied. Schema changes never flow into
      -- curated until an RFC is approved and a subsequent run aligns columns.
      DECLARE @i int=0;
      WHILE @i<2
      BEGIN
        SET @WorkObject=CASE WHEN @i=0 THEN @StageObject ELSE @TargetObject END;
        IF OBJECT_ID(@WorkObject,'U') IS NULL
        BEGIN
          SET @Sql=N'SELECT TOP (0) '+@ApprovedColumns+N' INTO '+@WorkObject+N' FROM '+@SourceObject+N';';
          EXEC sys.sp_executesql @Sql;
        END
        ELSE
        BEGIN
          SELECT @Sql=STRING_AGG(CONVERT(nvarchar(max),CONCAT('ALTER TABLE ',@WorkObject,' ADD ',QUOTENAME(c.name),' ',
            CASE WHEN t.name IN('varchar','char','varbinary','binary') THEN CONCAT(t.name,'(',CASE WHEN c.max_length=-1 THEN 'max' ELSE CONVERT(varchar(10),c.max_length) END,')')
                 WHEN t.name IN('nvarchar','nchar') THEN CONCAT(t.name,'(',CASE WHEN c.max_length=-1 THEN 'max' ELSE CONVERT(varchar(10),c.max_length/2) END,')')
                 WHEN t.name IN('decimal','numeric') THEN CONCAT(t.name,'(',c.precision,',',c.scale,')')
                 WHEN t.name IN('datetime2','datetimeoffset','time') THEN CONCAT(t.name,'(',c.scale,')') ELSE t.name END,
            ' NULL;')),CHAR(10))
          FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
          WHERE c.object_id=OBJECT_ID(@SourceObject)
            AND CHARINDEX(','+QUOTENAME(c.name)+',',','+@ApprovedColumns+',')>0
            AND NOT EXISTS(SELECT 1 FROM sys.columns tc WHERE tc.object_id=OBJECT_ID(@WorkObject) AND tc.name=c.name);
          IF @Sql IS NOT NULL EXEC sys.sp_executesql @Sql;
        END;
        SET @i+=1;
      END;

      -- stg is per configured target table; each attempt replaces its contents.
      -- This prototype serializes runs for a ConfigId at ADF orchestration.
      SET @Sql=N'TRUNCATE TABLE '+@StageObject+N'; INSERT '+@StageObject+N'('+@ApprovedColumns+N') SELECT '+@ApprovedColumns+N' FROM '+@SourceObject;
      IF @LoadType='WATERMARK'
        SET @Sql+=N' WHERE (@last IS NULL OR '+QUOTENAME(@WatermarkColumn)+N'>@last) AND '+QUOTENAME(@WatermarkColumn)+N'<=@captured';
      EXEC sys.sp_executesql @Sql,N'@last datetime2(7),@captured datetime2(7)',@last=@LastWatermark,@captured=@NewWatermark;

      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@SourceObject;
      IF @LoadType='WATERMARK'
        SET @Sql+=N' WHERE (@last IS NULL OR '+QUOTENAME(@WatermarkColumn)+N'>@last) AND '+QUOTENAME(@WatermarkColumn)+N'<=@captured';
      EXEC sys.sp_executesql @Sql,N'@last datetime2(7),@captured datetime2(7),@n bigint OUTPUT',
        @last=@LastWatermark,@captured=@NewWatermark,@n=@SourceCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@StageObject;
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@StageCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM (SELECT '+QUOTENAME(@PrimaryKey)+N' FROM '+@StageObject+
        N' GROUP BY '+QUOTENAME(@PrimaryKey)+N' HAVING COUNT_BIG(*)>1)d';
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@DuplicateCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@StageObject+N' WHERE '+QUOTENAME(@PrimaryKey)+N' IS NULL';
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@NullKeyCount OUTPUT;

      INSERT audit.ReconciliationResult(TableLoadAuditId,GateStage,CheckName,ExpectedValue,ActualValue,Result,Details)
      VALUES
      (@TableLoadAuditId,'GATE_1_PRE_PUBLISH','SOURCE_STAGE_ROW_COUNT',CONVERT(varchar(30),@SourceCount),CONVERT(varchar(30),@StageCount),CASE WHEN @SourceCount=@StageCount THEN 'PASS' ELSE 'FAIL' END,'Source load window equals approved-column staging rows.'),
      (@TableLoadAuditId,'GATE_1_PRE_PUBLISH','DUPLICATE_PRIMARY_KEY','0',CONVERT(varchar(30),@DuplicateCount),CASE WHEN @DuplicateCount=0 THEN 'PASS' ELSE 'FAIL' END,'Stage key uniqueness.'),
      (@TableLoadAuditId,'GATE_1_PRE_PUBLISH','NULL_PRIMARY_KEY','0',CONVERT(varchar(30),@NullKeyCount),CASE WHEN @NullKeyCount=0 THEN 'PASS' ELSE 'FAIL' END,'Stage key completeness.'),
      (@TableLoadAuditId,'GATE_1_PRE_PUBLISH','APPROVED_SCHEMA','0',CONVERT(varchar(30),@Missing),CASE WHEN @Missing=0 THEN 'PASS' ELSE 'FAIL' END,'Approved source columns present.');
      IF EXISTS(SELECT 1 FROM audit.ReconciliationResult WHERE TableLoadAuditId=@TableLoadAuditId AND GateStage='GATE_1_PRE_PUBLISH' AND Result='FAIL')
        THROW 50014,'Gate 1 reconciliation failed; curated data was not touched.',1;

      -- Publish and Gate 2 are one transaction. Failed Gate 2 results are held
      -- in a table variable and persisted by CATCH after the rollback.
      BEGIN TRAN;
      IF @LoadType='FULL'
        SET @Sql=N'DELETE FROM '+@TargetObject+N'; INSERT '+@TargetObject+N'('+@ApprovedColumns+N') SELECT '+@ApprovedColumns+N' FROM '+@StageObject;
      ELSE
        SET @Sql=N'DELETE t FROM '+@TargetObject+N' t JOIN '+@StageObject+N' s ON t.'+QUOTENAME(@PrimaryKey)+N'=s.'+QUOTENAME(@PrimaryKey)+
          N'; INSERT '+@TargetObject+N'('+@ApprovedColumns+N') SELECT '+@ApprovedColumns+N' FROM '+@StageObject;
      EXEC sys.sp_executesql @Sql;

      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@TargetObject;
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@TargetCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM (SELECT '+QUOTENAME(@PrimaryKey)+N' FROM '+@TargetObject+
        N' GROUP BY '+QUOTENAME(@PrimaryKey)+N' HAVING COUNT_BIG(*)>1)d';
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@DuplicateCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@TargetObject+N' WHERE '+QUOTENAME(@PrimaryKey)+N' IS NULL';
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@NullKeyCount OUTPUT;
      SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@StageObject+N' s WHERE NOT EXISTS (SELECT 1 FROM '+@TargetObject+
        N' t WHERE t.'+QUOTENAME(@PrimaryKey)+N'=s.'+QUOTENAME(@PrimaryKey)+N')';
      EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@n=@MissingPublished OUTPUT;

      INSERT @Gate2Checks(CheckName,ExpectedValue,ActualValue,Result,Details)
      VALUES
      ('STAGE_KEYS_PUBLISHED','0',CONVERT(varchar(30),@MissingPublished),CASE WHEN @MissingPublished=0 THEN 'PASS' ELSE 'FAIL' END,'Each staged key appears in curated.'),
      ('DUPLICATE_PRIMARY_KEY','0',CONVERT(varchar(30),@DuplicateCount),CASE WHEN @DuplicateCount=0 THEN 'PASS' ELSE 'FAIL' END,'Curated key uniqueness.'),
      ('NULL_PRIMARY_KEY','0',CONVERT(varchar(30),@NullKeyCount),CASE WHEN @NullKeyCount=0 THEN 'PASS' ELSE 'FAIL' END,'Curated key completeness.');
      IF @LoadType='FULL'
        INSERT @Gate2Checks(CheckName,ExpectedValue,ActualValue,Result,Details)
        VALUES('FULL_ROW_COUNT',CONVERT(varchar(30),@StageCount),CONVERT(varchar(30),@TargetCount),
               CASE WHEN @StageCount=@TargetCount THEN 'PASS' ELSE 'FAIL' END,'Full curated count equals staging.');
      SET @Gate2Checked=1;
      IF EXISTS(SELECT 1 FROM @Gate2Checks WHERE Result='FAIL')
        THROW 50015,'Gate 2 reconciliation failed; curated publish was rolled back.',1;

      UPDATE ctl.PipelineConfiguration SET LastWatermarkValue=COALESCE(@NewWatermark,LastWatermarkValue),
        LastRunStatus='SUCCESS',LastSuccessfulRunUtc=SYSUTCDATETIME(),ModifiedUtc=SYSUTCDATETIME() WHERE ConfigId=@ConfigId;
      COMMIT;
      INSERT audit.ReconciliationResult(TableLoadAuditId,GateStage,CheckName,ExpectedValue,ActualValue,Result,Details)
        SELECT @TableLoadAuditId,'GATE_2_POST_PUBLISH',CheckName,ExpectedValue,ActualValue,Result,Details FROM @Gate2Checks;
      UPDATE audit.TableLoadAudit SET CompletedUtc=SYSUTCDATETIME(),SourceRowCount=@SourceCount,TargetRowCount=@TargetCount,Status='SUCCESS' WHERE TableLoadAuditId=@TableLoadAuditId;
      INSERT audit.NotificationAudit(AdfPipelineRunId,ConfigId,EventType,DeliveryStatus,Message)
      VALUES(@AdfPipelineRunId,@ConfigId,CASE WHEN @SchemaChanged=1 THEN 'SCHEMA_CHANGE' ELSE 'TABLE_SUCCESS' END,'PENDING',
             CASE WHEN @SchemaChanged=1 THEN 'Schema change recorded; load completed with the previously approved columns.' ELSE 'Table load and reconciliation succeeded.' END);
    END TRY
    BEGIN CATCH
      IF XACT_STATE()<>0 ROLLBACK;
      SET @Error=ERROR_MESSAGE();
      IF @Gate2Checked=1
        INSERT audit.ReconciliationResult(TableLoadAuditId,GateStage,CheckName,ExpectedValue,ActualValue,Result,Details)
          SELECT @TableLoadAuditId,'GATE_2_POST_PUBLISH',CheckName,ExpectedValue,ActualValue,Result,Details FROM @Gate2Checks;
      UPDATE ctl.PipelineConfiguration SET LastRunStatus='FAILURE',ModifiedUtc=SYSUTCDATETIME() WHERE ConfigId=@ConfigId;
      UPDATE audit.TableLoadAudit SET CompletedUtc=SYSUTCDATETIME(),Status='FAILURE',ErrorMessage=@Error WHERE TableLoadAuditId=@TableLoadAuditId;
      INSERT audit.NotificationAudit(AdfPipelineRunId,ConfigId,EventType,DeliveryStatus,Message) VALUES(@AdfPipelineRunId,@ConfigId,'TABLE_FAILURE','PENDING',@Error);
      THROW;
    END CATCH;

    SELECT @TableLoadAuditId AS TableLoadAuditId,@ConfigId AS ConfigId,@SchemaChanged AS SchemaChangeDetected,
           COALESCE(@ApprovalStatus,'NONE') AS SchemaApprovalStatus,'SUCCESS' AS Status;
END;
GO
