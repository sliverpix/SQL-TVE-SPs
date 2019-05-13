USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraChannelDelete]    Script Date: 5/13/2019 11:06:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[uspHydraChannelDelete] 
(
	-------------------------------------------------------------------------------
	--Always specify a value for ChannelNumber and RegionId to determine the
	--channel to update. 
	-------------------------------------------------------------------------------
	@ChannelNumber INT = NULL, --Required
	@RegionId varchar(20) = NULL --Required
)
AS
BEGIN
	Print 'Verifying required parameters...'
	IF (@ChannelNumber IS NULL OR @RegionId IS NULL) 
	BEGIN
		raiserror('ChannelNumber and RegionId is required!', 20, 0) with log;
		RETURN;
	END

	Print 'Verifying parameters for updates...'

	--Channel Identifier
	DECLARE @AFSID VARCHAR (20)

	SELECT 	@AFSID = cs.strActualFIOSServiceID
	FROM (SELECT TOP 1 * 
		  FROM FIOSCE.dbo.tfiosChannel_Subscription 
		  WHERE intChannel = @ChannelNumber 
				AND strFiosRegionId = @RegionId) cs
		 JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo wn ON cs.strActualFIOSServiceID = wn.strActualFiosServiceId
															 AND cs.strFiosRegionId = wn.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSLineup l ON cs.strActualFIOSServiceID = l.strActualFIOSServiceID 
										   AND cs.strFiosRegionId = l.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSStation s on l.strFiosServiceId = s.strFiosServiceId
	WHERE l.intChannelPosition = @ChannelNumber 
		  AND cs.strFiosRegionId = @RegionId

	Print 'Verifying AFSID parameters...'
	IF (@AFSID IS NULL) 
	BEGIN
		raiserror('Parameters @ChannelNumber and @RegionId do not return a channel!', 20, 0) with log;
		RETURN;
	END

	-------------------------------------------------------------------------------
	--Processing delete
	-------------------------------------------------------------------------------
	DELETE FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE FIOSApp_DC_CE.dbo.TVEIHOHFlags 
	WHERE regionID = @RegionId 
		  AND channelPosn = @ChannelNumber

	DELETE p
	FROM VideoSubscriber.dbo.PackagetoServiceMapping p
		 JOIN FIOSCE.dbo.tfiosChannel_Subscription s on p.BSG_HANDLE = s.strServiceName
														AND p.region = s.strFiosRegionId
	WHERE s.strActualFIOSServiceID = @AFSID
		  AND s.strFiosRegionId = @RegionId

	DELETE FIOSCE.dbo.tfiosChannel_Subscription
	WHERE strActualFIOSServiceID = @AFSID
		  AND strFiosRegionId = @RegionId

	Print 'Done! - No red text - No Issues for channel ' + CAST(@ChannelNumber AS VARCHAR)
END 