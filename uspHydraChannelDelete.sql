USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraChannelDelete]    Script Date: 5/22/2019 3:54:32 PM ******/
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
		raiserror('ChannelNumber and RegionId are required!', 20, 0) with log;
		RETURN;
	END

	Print 'Verifying parameters for removal...'

	--Channel Identifier
	DECLARE @AFSID VARCHAR (20)
	-- main logic for AFSID
	SELECT @AFSID = cs.strActualFIOSServiceID
	FROM (SELECT TOP 1 * 
		  FROM FIOSCE.dbo.tfiosChannel_Subscription 
		  WHERE intChannel = @ChannelNumber 
				AND strFiosRegionId = @RegionId) cs
		 LEFT JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo wn ON cs.strActualFIOSServiceID = wn.strActualFiosServiceId
															 AND cs.strFiosRegionId = wn.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSLineup l ON cs.strActualFIOSServiceID = l.strActualFIOSServiceID 
										   AND cs.strFiosRegionId = l.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSStation s on l.strFiosServiceId = s.strFiosServiceId
	WHERE l.intChannelPosition = @ChannelNumber 
		  AND cs.strFiosRegionId = @RegionId


	Print 'Verifying AFSID parameter...'
	IF (@AFSID IS NULL) 
		BEGIN
			print 'Parameter @AFSID returned NULL. Trying something else...'
			-- secondary logic for AFSID/FSID if mismatched to lineup table:
			-- does AFSID match between channelSub and Watchnow?
			-- does FSID match between channelSub and Station?
			-- if both are TRUE.. we can use the AFSID/FSID from channelsub to properly remove the channel
			select @AFSID = cs.strActualFIOSServiceID
			from (select top 1 * 
				from FIOSCE.dbo.tfiosChannel_Subscription 
				where intChannel= @ChannelNumber 
					and strFiosRegionId=@RegionId) cs
				LEFT JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo wn on cs.strActualFIOSServiceID = wn.strActualFiosServiceId
																	and cs.strFiosRegionId = wn.strFiosRegionId
				JOIN FIOSApp_DC.dbo.tFIOSStation s on cs.strFIOSServiceId = s.strFIOSServiceId
				where wn.intChannel = @ChannelNumber and wn.strFiosRegionId = @RegionId
		END
	
	IF (@AFSID is null)
		BEGIN
		raiserror ('Parameters @ChannelNumber and @RegionId do not return a channel. @AFSID is still NULL!',20,0) with log
		return;
		END
	ELSE
		BEGIN
		print 'GOT IT!';
		print @AFSID
		END

	-------------------------------------------------------------------------------
	--Processing delete
	-------------------------------------------------------------------------------
	DELETE 
--	SELECT * FROM 
	FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE 
--	SELECT * FROM 
	FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE 
--	SELECT * 
	FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo
	WHERE strActualFiosServiceId = @AFSID	
			AND strFiosRegionId = @RegionId

	DELETE 
--	SELECT * FROM 
	FIOSApp_DC_CE.dbo.TVEIHOHFlags 
	WHERE regionID = @RegionId 
		  AND channelPosn = @ChannelNumber

	DELETE p
--	SELECT p.* 
	FROM VideoSubscriber.dbo.PackagetoServiceMapping p
		 JOIN FIOSCE.dbo.tfiosChannel_Subscription s on p.BSG_HANDLE = s.strServiceName
														AND p.region = s.strFiosRegionId
	WHERE s.strActualFIOSServiceID = @AFSID
		  AND s.strFiosRegionId = @RegionId

	DELETE 
--	SELECT * FROM 
	FIOSCE.dbo.tfiosChannel_Subscription
	WHERE strActualFIOSServiceID = @AFSID
		  AND strFiosRegionId = @RegionId

END 