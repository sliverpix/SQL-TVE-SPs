-------------------------------------------------------------------------------
-- All of the parameters are required
-- If you use invalid parameters/enter an unintended value on accident that's ok,
-- the SP will catch empty values and checks that vlaues cross-index across
-- three tables.

-- none the less, we can re-add the package to the channel with SPs

-- Currently only targets FIOS well!
--		-- TODO: create MR/Vantage switch
--		-- TODO: add variable to hold BSG code/service handle ID

-------------------------------------------------------------------------------

EXEC FIOSCE.dbo.uspRemovePackagefromChannel
	@VhoId = '91567', 
	@ChanNumber = '123', 
	@PackageId = '47110'
	
--------------------------------------------------------------------------------
-- T/S Queries 
--------------------------------------------------------------------------------

select top 100 * from VideoSubscriber.dbo.PackagetoServiceMapping (nolock) where
 --region = '91081' and
-- CHANNEL_NAME = '641' and 
 CHANNEL_NAME like '%show%'

select top 100 * FROM FIOSApp_DC.dbo.tFIOSLineup (nolock) where

 select top 100 * from FIOSCE.dbo.tfiosChannel_Subscription (nolock) where

-- how is this table used?
select top 100 * FROM VideoSubscriber.dbo.Connecticut_ChannelLineup (nolock) where

-- to check region# vs VHO ID#
SELECT 1 FROM FIOSApp_DC.dbo.tFIOSRegion WHERE strFIOSRegionId = @VhoId


--------------------------------------------------------------------------------
-- Stored Procedure Code
-- updated 04-11-2019
--------------------------------------------------------------------------------
USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspRemovePackagefromChannel]    Script Date: 5/23/2018 5:48:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[uspRemovePackagefromChannel](
	@VhoId VARCHAR(20),
	@ChanNumber Varchar(20),
	@PackageId VARCHAR(20)
)
AS
BEGIN
DECLARE @ErrorMsg VARCHAR(50)
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
	
	
	-- determine market and use proper CASE
	Print 'Determine market type...'
	DECLARE @marketType varchar(20) = ''
	SELECT @marketType = CASE WHEN n.ServiceRegion IS NULL THEN 'Vantage' ELSE 'Fios' END
	FROM VideoSubscriber.dbo.ServiceMaps s
		 LEFT OUTER JOIN VideoSubscriber.dbo.NspInHomeRegions n ON s.ServiceRegionId = n.ServiceRegion
	WHERE s.ServiceRegionId = @vhoid -- change VhoId to ServiceRegionId


	Print 'Verifying market type...'
	IF (@marketType != 'Fios' AND @marketType != 'Vantage')
		BEGIN
			raiserror('Parameter @marketType is invalid or does not exists!', 20, 0) with log;
			RETURN;
		END
	
	END IF;
	
	Print 'Done! - No red text - No Issues'
	
END	  
