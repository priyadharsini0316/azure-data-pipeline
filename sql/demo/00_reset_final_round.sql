-- Destructive only to this prototype's synthetic demo rows and two configured
-- sources. Run intentionally before the final eight-scenario demonstration.
SET XACT_ABORT ON;
BEGIN TRAN;
IF EXISTS (SELECT 1 FROM ctl.PipelineConfiguration WHERE ConfigId IN (1,2)
           GROUP BY ConfigId HAVING COUNT(*)>1)
    THROW 50100,'Unexpected configuration state.',1;
IF (SELECT COUNT(*) FROM ctl.PipelineConfiguration WHERE ConfigId IN (1,2) AND SourceTable IN
    ('Asset_Generation_PI_Data_T','CSD_Assets_T'))<>2
    THROW 50101,'Demo configuration IDs do not match expected source objects.',1;

DELETE FROM rfc.SchemaChangeRequest WHERE ConfigId IN (1,2);
DELETE FROM rfc.SchemaHistory WHERE ConfigId IN (1,2);
UPDATE ctl.PipelineConfiguration
SET ApprovedColumnList=NULL,ApprovedSchemaHash=NULL,ApprovedSchemaVersion=NULL,
    LastWatermarkValue=NULL,LastRunStatus=NULL,LastSuccessfulRunUtc=NULL,ModifiedUtc=SYSUTCDATETIME()
WHERE ConfigId IN (1,2);
DELETE FROM src.Asset_Generation_PI_Data_T WHERE AssetGenerationId=4;
UPDATE src.Asset_Generation_PI_Data_T
SET GenerationMWh=342.125,LastModifiedUtc=CONVERT(datetime2,'2026-09-14T10:00:00')
WHERE AssetGenerationId=2;
COMMIT;

-- The following two fields were added solely by earlier schema-drift demos.
IF COL_LENGTH('src.CSD_Assets_T','RegionCode') IS NOT NULL
    ALTER TABLE src.CSD_Assets_T DROP COLUMN RegionCode;
IF COL_LENGTH('src.CSD_Assets_T','TemporaryNote') IS NOT NULL
    ALTER TABLE src.CSD_Assets_T DROP COLUMN TemporaryNote;
IF COL_LENGTH('stg.CSD_Assets_T','RegionCode') IS NOT NULL
    ALTER TABLE stg.CSD_Assets_T DROP COLUMN RegionCode;
IF COL_LENGTH('stg.CSD_Assets_T','TemporaryNote') IS NOT NULL
    ALTER TABLE stg.CSD_Assets_T DROP COLUMN TemporaryNote;
IF COL_LENGTH('curated.CSD_Assets_T','RegionCode') IS NOT NULL
    ALTER TABLE curated.CSD_Assets_T DROP COLUMN RegionCode;
IF COL_LENGTH('curated.CSD_Assets_T','TemporaryNote') IS NOT NULL
    ALTER TABLE curated.CSD_Assets_T DROP COLUMN TemporaryNote;
