USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspRemovePackagefromChannel]    Script Date: 5/13/2019 11:15:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[uspRemovePackagefromChannel](
	@VhoId VARCHAR(20),	-- Required
	@ChanNumber Varchar(20),	-- Required
	@PackageId VARCHAR(20)	-- Required
)
AS
BEGIN
DECLARE @ErrorMsg VARCHAR(50);
	Print 'Verifying required parameters...'
	IF (@VhoId IS NULL OR @ChanNumber IS NULL OR @PackageId IS NULL) 
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @VhoId + ' ChanNumber: ' + @ChanNumber + ' and PackageId: ' + @PackageId + ' are required!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
	-- print 'VhoId, ChanNumber and PackageID are present.'
		
	IF (RTRIM(@VhoId) = '' OR RTRIM(@ChanNumber) = '' OR RTRIM(@PackageId) = '') 
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @VhoId + ' ChanNumber: ' + @ChanNumber + ' and PackageId: ' + @PackageId + ' can NOT be EMPTY!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
	-- print 'VhoId, ChanNumber and PackageID have value.'

	Print 'Verifying parameters for updates...'
	IF NOT EXISTS (SELECT 1 FROM FIOSApp_DC.dbo.tFIOSRegion WHERE strFIOSRegionId = @VhoId)
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @VhoId + ' is invalid or does not exist!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
	-- print ('VhoId: ' + @VhoId + ' is present in tFIOSRegion')

	-- check for channel number in region id and fail out if not
	-- otherwise print good message and continue
	IF NOT EXISTS (SELECT 1 FROM FIOSCE.dbo.tfiosChannel_Subscription cs 
		JOIN FIOSApp_DC.dbo.tFIOSLineup l ON cs.strFiosRegionId = l.strFIOSRegionId 
												AND cs.strFIOSServiceId = l.strFIOSServiceId
												AND cs.strActualFIOSServiceID = l.strActualFIOSServiceID
		WHERE cs.intChannel = @ChanNumber
			AND cs.strFiosRegionId = @VhoId)
	BEGIN
		SET @ErrorMsg = 'Channel Number ' + @ChanNumber + ' was not found in region ID ' + @VhoId
		raiserror(@ErrorMsg,20,0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
	print('Channel Number ' + @ChanNumber + ' found in region ID ' + @VhoID)

	-- check that package ID exists on service THEN remove package
	IF NOT EXISTS (Select 1 from VideoSubscriber.dbo.PackagetoServiceMapping where
						region = @VhoId
						AND CHANNEL_NUMBER = @ChanNumber
						AND PACKAGE_ID = @PackageId)
	BEGIN
		SET @ErrorMsg = 'PackageID: ' + @PackageId + ' not found for Channel: ' + @ChanNumber
		raiserror(@ErrorMsg,20,0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
	print('Found packageID')

	-- remove package
	DELETE p FROM VideoSubscriber.dbo.PackagetoServiceMapping p
		JOIN FIOSCE.dbo.tfiosChannel_Subscription cs ON p.region = cs.strFiosRegionId AND p.BSG_HANDLE = cs.strServiceName
		JOIN FIOSApp_DC.dbo.tFIOSLineup l ON l.strFIOSRegionId = cs.strFiosRegionId AND l.strFIOSServiceId = cs.strFIOSServiceId
	WHERE l.strFIOSRegionId = @VhoId
		AND l.intChannelPosition = @ChanNumber
		AND p.PACKAGE_ID = @PackageId
	Print 'Done! - No red text - No Issues'
END	  
