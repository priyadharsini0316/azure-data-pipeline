IF COL_LENGTH('src.CSD_Assets_T','TemporaryNote') IS NULL
  ALTER TABLE src.CSD_Assets_T ADD TemporaryNote nvarchar(50) NULL;
GO
UPDATE src.CSD_Assets_T SET TemporaryNote=N'Not approved for curated use';

