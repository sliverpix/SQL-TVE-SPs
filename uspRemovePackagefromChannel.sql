--------------------------------------------------------------------------------
-- Stored Procedure Code
-- updated 05-21-2019
--------------------------------------------------------------------------------
USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspRemovePackagefromChannel]    Script Date: 5/23/2018 5:48:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[uspRemovePackagefromChannel](
	@ServiceRegionID VARCHAR(20),
	@ChanNumber Varchar(20),
	@PackageId VARCHAR(50)
)
AS
BEGIN
-- check required parameters
DECLARE @ErrorMsg VARCHAR(50)
	Print 'Verifying required parameters...'
	IF (@ServiceRegionID IS NULL OR @ChanNumber IS NULL OR @PackageId IS NULL) 
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @ServiceRegionID + ' ChanNumber: ' + @ChanNumber + ' and PackageId: ' + @PackageId + ' are required!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END
		
	IF (RTRIM(@ServiceRegionID) = '' OR RTRIM(@ChanNumber) = '' OR RTRIM(@PackageId) = '') 
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @ServiceRegionID + ' ChanNumber: ' + @ChanNumber + ' and PackageId: ' + @PackageId + ' can NOT be EMPTY!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END

	Print 'Verifying parameters for updates...'
	IF NOT EXISTS (SELECT 1 FROM FIOSApp_DC.dbo.tFIOSRegion WHERE strFIOSRegionId = @ServiceRegionID)
	BEGIN
		SET @ErrorMsg = 'VhoId: ' + @ServiceRegionID + ' is invalid or does not exist!'
		raiserror(@ErrorMsg, 20, 0, 'uspRemovePackagefromChannel') with log;
		RETURN;
	END

	
	-- check for channel number in region id and fail out if not
	-- detect FSID mismatch in tables
	IF NOT EXISTS (SELECT 1 FROM FIOSCE.dbo.tfiosChannel_Subscription cs 
		JOIN FIOSApp_DC.dbo.tFIOSLineup l ON cs.strFiosRegionId = l.strFIOSRegionId AND cs.strFIOSServiceId = l.strFIOSServiceId
		WHERE cs.intChannel = @ChanNumber
			  AND cs.strFiosRegionId = @ServiceRegionID)
		BEGIN
			SET @ErrorMsg = 'Channel Number ' + @ChanNumber + ' wasnt found in region ID ' + @ServiceRegionID
			print('Possible FSID mismatch between tFIOSLineup & tfiosChannel_Subscription')
			raiserror(@ErrorMsg,20,0, 'uspRemovePackagefromChannel') with log;
			RETURN;
		END
	print('Channel Number ' + @ChanNumber + ' found in region ID ' + @ServiceRegionID)


	-- determine market type for case switch later
	Print 'Determine market type...'
	DECLARE @marketType varchar(20) = ''
	SELECT @marketType = CASE WHEN n.ServiceRegion IS NULL THEN 'Vantage' ELSE 'Fios' END
	FROM VideoSubscriber.dbo.ServiceMaps s
		 LEFT OUTER JOIN VideoSubscriber.dbo.NspInHomeRegions n ON s.ServiceRegionId = n.ServiceRegion
	WHERE s.ServiceRegionId = @ServiceRegionID
	IF (@marketType != 'Fios' AND @marketType != 'Vantage')
		BEGIN
			raiserror('Parameter @marketType is invalid or does not exists!', 20, 0) with log;
			RETURN;
		END
	Print 'Found ' + @marketType


	-- check that package ID exists on service THEN remove package
	IF NOT EXISTS (Select 1 from VideoSubscriber.dbo.PackagetoServiceMapping where
						region = @ServiceRegionID
						AND CHANNEL_NUMBER = @ChanNumber
						AND CASE @marketType
								WHEN 'Fios' THEN PACKAGE_ID
								WHEN 'Vantage' THEN BSG_HANDLE
							END
						 = @packageID)
		BEGIN
			SET @ErrorMsg = @PackageId + ' not found for Channel ' + @ChanNumber
			raiserror(@ErrorMsg,20,0, 'uspRemovePackagefromChannel') with log;
			RETURN;
		END
	print('Found packageID')


	-- remove FIOS/Mediaroom package from service
	DELETE p
	--SELECT p.* 
	FROM VideoSubscriber.dbo.PackagetoServiceMapping p
		JOIN FIOSCE.dbo.tfiosChannel_Subscription cs ON p.region = cs.strFiosRegionId AND p.CHANNEL_NUMBER = cs.intChannel
		JOIN FIOSApp_DC.dbo.tFIOSLineup l ON l.strFIOSRegionId = cs.strFiosRegionId AND l.strFIOSServiceId = cs.strFIOSServiceId
	WHERE l.strFIOSRegionId = @ServiceRegionID
		AND l.intChannelPosition = @ChanNumber
		AND CASE @marketType
				WHEN 'Fios' THEN p.PACKAGE_ID
				WHEN 'Vantage' THEN p.BSG_HANDLE
			END
			 = @packageID

	-- if its mediaroom(vantage) remove from channelSub by bsg_handle, channel number and region
	-- we dont need to do this if its a FIOS market
	IF (@marketType = 'Vantage')
		BEGIN
			Print 'Removing ' + @ChanNumber + ' with package ' +@packageID + ' in region ' + @ServiceRegionID + ' from tfiosChannel_Subscription'
			DELETE
			--SELECT *
			 from FIOSCE.dbo.tfiosChannel_Subscription
			WHERE	strFiosRegionId = @ServiceRegionID
				AND	intChannel = @ChanNumber
				AND strServiceName = @packageID
		END
END
