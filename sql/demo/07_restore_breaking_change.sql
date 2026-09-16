IF COL_LENGTH('src.CSD_Assets_T','AssetCategory') IS NOT NULL AND COL_LENGTH('src.CSD_Assets_T','AssetType') IS NULL
  EXEC sys.sp_rename 'src.CSD_Assets_T.AssetCategory','AssetType','COLUMN';

