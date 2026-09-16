UPDATE src.Asset_Generation_PI_Data_T
SET GenerationMWh=350.250,LastModifiedUtc=SYSUTCDATETIME()
WHERE AssetGenerationId=2;

IF NOT EXISTS(SELECT 1 FROM src.Asset_Generation_PI_Data_T WHERE AssetGenerationId=4)
  INSERT src.Asset_Generation_PI_Data_T(AssetGenerationId,AssetCode,GenerationMWh,ReadingDate,LastModifiedUtc)
  VALUES(4,'SOLAR-02',88.125,CONVERT(date,SYSUTCDATETIME()),SYSUTCDATETIME());

