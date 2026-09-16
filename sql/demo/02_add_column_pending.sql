IF COL_LENGTH('src.CSD_Assets_T','RegionCode') IS NULL
  ALTER TABLE src.CSD_Assets_T ADD RegionCode varchar(10) NULL;
GO
UPDATE src.CSD_Assets_T SET RegionCode=CASE AssetId WHEN 101 THEN 'NORTH' WHEN 102 THEN 'EAST' ELSE 'WEST' END;
