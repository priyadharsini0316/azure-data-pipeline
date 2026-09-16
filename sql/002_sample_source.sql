SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('src.Asset_Generation_PI_Data_T','U') IS NULL
BEGIN
    CREATE TABLE src.Asset_Generation_PI_Data_T
    (
        AssetGenerationId int NOT NULL CONSTRAINT PK_AssetGeneration PRIMARY KEY,
        AssetCode varchar(20) NOT NULL,
        GenerationMWh decimal(18,3) NULL,
        ReadingDate date NOT NULL,
        LastModifiedUtc datetime2(7) NOT NULL
    );
END;

IF OBJECT_ID('src.CSD_Assets_T','U') IS NULL
BEGIN
    CREATE TABLE src.CSD_Assets_T
    (
        AssetId int NOT NULL CONSTRAINT PK_CSD_Assets PRIMARY KEY,
        AssetName nvarchar(100) NOT NULL,
        AssetType varchar(30) NOT NULL,
        IsActive bit NOT NULL,
        LastModifiedUtc datetime2(7) NOT NULL
    );
END;

IF OBJECT_ID('src.Asset_Gen_PI_Data_T_STG','U') IS NULL
BEGIN
    CREATE TABLE src.Asset_Gen_PI_Data_T_STG
    (
        StageId int NOT NULL CONSTRAINT PK_AssetGenStage PRIMARY KEY,
        Payload nvarchar(200) NULL,
        LastModifiedUtc datetime2(7) NOT NULL
    );
END;
GO

MERGE src.Asset_Generation_PI_Data_T AS t
USING (VALUES
    (1,'SOLAR-01',125.500,CONVERT(date,'2026-09-13'),CONVERT(datetime2,'2026-09-13T10:00:00Z')),
    (2,'WIND-01',342.125,CONVERT(date,'2026-09-14'),CONVERT(datetime2,'2026-09-14T10:00:00Z')),
    (3,'HYDRO-01',510.750,CONVERT(date,'2026-09-15'),CONVERT(datetime2,'2026-09-15T10:00:00Z'))
) s(AssetGenerationId,AssetCode,GenerationMWh,ReadingDate,LastModifiedUtc)
ON t.AssetGenerationId=s.AssetGenerationId
WHEN MATCHED THEN UPDATE SET AssetCode=s.AssetCode,GenerationMWh=s.GenerationMWh,ReadingDate=s.ReadingDate,LastModifiedUtc=s.LastModifiedUtc
WHEN NOT MATCHED THEN INSERT VALUES(s.AssetGenerationId,s.AssetCode,s.GenerationMWh,s.ReadingDate,s.LastModifiedUtc);

MERGE src.CSD_Assets_T AS t
USING (VALUES
    (101,N'Solar Farm North','Solar',1,CONVERT(datetime2,'2026-09-13T08:00:00Z')),
    (102,N'Wind Park East','Wind',1,CONVERT(datetime2,'2026-09-14T08:00:00Z')),
    (103,N'Hydro Station West','Hydro',1,CONVERT(datetime2,'2026-09-15T08:00:00Z'))
) s(AssetId,AssetName,AssetType,IsActive,LastModifiedUtc)
ON t.AssetId=s.AssetId
WHEN MATCHED THEN UPDATE SET AssetName=s.AssetName,AssetType=s.AssetType,IsActive=s.IsActive,LastModifiedUtc=s.LastModifiedUtc
WHEN NOT MATCHED THEN INSERT VALUES(s.AssetId,s.AssetName,s.AssetType,s.IsActive,s.LastModifiedUtc);
GO

IF NOT EXISTS (SELECT 1 FROM ctl.PipelineConfiguration WHERE SourceSchema='src' AND SourceTable='Asset_Generation_PI_Data_T')
    INSERT ctl.PipelineConfiguration(SourceSchema,SourceTable,TargetSchema,TargetTable,[Load],LoadType,WatermarkColumn,PrimaryKeyColumn)
    VALUES('src','Asset_Generation_PI_Data_T','curated','Asset_Generation_PI_Data_T','Yes','WATERMARK','LastModifiedUtc','AssetGenerationId');

IF NOT EXISTS (SELECT 1 FROM ctl.PipelineConfiguration WHERE SourceSchema='src' AND SourceTable='CSD_Assets_T')
    INSERT ctl.PipelineConfiguration(SourceSchema,SourceTable,TargetSchema,TargetTable,[Load],LoadType,WatermarkColumn,PrimaryKeyColumn)
    VALUES('src','CSD_Assets_T','curated','CSD_Assets_T','Yes','FULL',NULL,'AssetId');

IF NOT EXISTS (SELECT 1 FROM ctl.PipelineConfiguration WHERE SourceSchema='src' AND SourceTable='Asset_Gen_PI_Data_T_STG')
    INSERT ctl.PipelineConfiguration(SourceSchema,SourceTable,TargetSchema,TargetTable,[Load],LoadType,WatermarkColumn,PrimaryKeyColumn)
    VALUES('src','Asset_Gen_PI_Data_T_STG','curated','Asset_Gen_PI_Data_T_STG','No','FULL',NULL,'StageId');
GO

