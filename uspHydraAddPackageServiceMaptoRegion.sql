USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraAddPackageServiceMaptoRegion]    Script Date: 5/13/2019 11:49:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- TVE Ops Modify to be able to add package to specific region for multi-region VHOs/DMA
-- editor: James G

ALTER PROCEDURE [dbo].[uspHydraAddPackageServiceMaptoRegion](
	@VhoId VARCHAR(20),	-- use region number instead of VHOID
	@PackageName VARCHAR(50),
	@Package_BSG_Handle VARCHAR(50),
	@Service_BSG_Handle VARCHAR(50)
)
AS
BEGIN
	Print 'Verifying required parameters...'
	IF (@VhoId IS NULL OR @PackageName IS NULL OR @Package_BSG_Handle IS NULL OR RTRIM(@Package_BSG_Handle) = '' OR @Service_BSG_Handle IS NULL OR RTRIM(@Service_BSG_Handle) = '') 
	BEGIN
		raiserror('VhoId, @PackageName, @Package_BSG_Handle and Service_Bsg_Handle are required!', 20, 0) with log;
		RETURN;
	END

	Print 'Verifying parameters for updates...'
	IF NOT EXISTS (SELECT 1 FROM FIOSApp_DC.dbo.tFIOSRegion WHERE strFIOSRegionId = @VhoId)	-- change VhoID to ServiceRegionId
	BEGIN
		raiserror('VhoId is invalid and does not exist', 20, 0) with log;
		RETURN;
	END

	INSERT INTO VideoSubscriber.dbo.PackagetoServiceMapping (PACKAGE_ID, GE_NAME, BSG_HANDLE, CHANNEL_NUMBER, CHANNEL_NAME, region)
	SELECT @Package_BSG_Handle PACKAGE_ID,
		   LTRIM(REPLACE(@PackageName, @Package_BSG_Handle, '')) GE_NAME,
		   @Service_BSG_Handle BSG_HANDLE,
		   t.intChannel CHANNEL_NUMBER,
		   s.strStationName,
		   t.strFiosRegionId
	FROM FIOSApp_DC.dbo.tFIOSLineup l
			JOIN FIOSApp_DC.dbo.tFiosStation s ON l.strFIOSServiceId = s.strFIOSServiceId
			JOIN FIOSApp_DC.dbo.tFIOSRegion r ON l.strFIOSRegionId = r.strFIOSRegionId
			JOIN FIOSCE.dbo.tfiosChannel_Subscription t ON l.strFIOSRegionId = t.strFIOSRegionId
														AND l.strActualFIOSServiceID = t.strActualFIOSServiceID
	WHERE r.strFIOSRegionId = @VhoId	-- change VhoId to ServiceRegionId
		  AND t.strServiceName = @Service_BSG_Handle
		  AND NOT EXISTS (SELECT 1
						  FROM VideoSubscriber.dbo.PackagetoServiceMapping
						  WHERE PACKAGE_ID = @Package_BSG_Handle
								AND BSG_HANDLE = @Service_BSG_Handle
								AND region = r.strFIOSRegionId)

	Print 'Done! - No red text - No Issues for Service BSG Handle ' + CAST(@Service_BSG_Handle AS VARCHAR)
END	  
