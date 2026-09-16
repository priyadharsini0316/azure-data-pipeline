/* Rename one previously approved column to demonstrate safe failure. */
IF COL_LENGTH('src.CSD_Assets_T','AssetType') IS NOT NULL AND COL_LENGTH('src.CSD_Assets_T','AssetCategory') IS NULL
  EXEC sys.sp_rename 'src.CSD_Assets_T.AssetType','AssetCategory','COLUMN';

