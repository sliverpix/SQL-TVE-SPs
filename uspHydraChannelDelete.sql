USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraChannelDelete]    Script Date: 5/22/2019 3:54:32 PM 	******/
-- Version 2.1

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
	DECLARE @AFSID VARCHAR (20),
	-- For Logs
	@IH bit = NULL,
	@OOH bit = NULL,
	@LiveTv bit = NULL,
	@IsRegular bit = NULL,
	@VMS bit = NULL,
	@IndexPosition int = NULL,
	@MobileUrlV1 varchar(500) = NULL,
	@MobileUrlV2 varchar(500) = NULL,
	@TabletUrlV1 varchar(500) = NULL,
	@TabletUrlV2 varchar(500) = NULL,
	@TypeV1 varchar (100) = NULL, 
	@TypeV2 varchar (100) = NULL


	
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
			select @AFSID = cs.strActualFIOSServiceID, @IH = cs.IH, @OOH = cs.OOH, @VMS = cs.VMS, @IsRegular = wn.IsRegular, @LiveTv = wn.LiveTV, @VMS = cs.VMS, @IndexPosition = cs.IndexPosition
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
		
	-- Log our Changes
	DECLARE @ChannelLineUpChangesParametersId int

	INSERT INTO FIOSCE.dbo.ChannelLineUpChangesParameters(Action, ChannelNumber, RegionId, IH, OOH, IsRegular, LiveTv, VMS, IndexPosition, MobileUrlV1, MobileUrlV2, TabletUrlV1, TabletUrlV2, TypeV1, TypeV2, IPURLV1, IPURLV2, NetworkIdV1, NetworkIdV2, TokenV1, TokenV2, intPlayModeV1, intPlayModeV2, dtCreated)
	SELECT 'DELETE' Action, @ChannelNumber ChannelNumber, @RegionId RegionId, @IH IH, @OOH OOH, @IsRegular IsRegular, @LiveTv LiveTv, @VMS VMS, @IndexPosition IndexPosition, @MobileUrlV1 MobileUrlV1, @MobileUrlV2 MobileUrlV2, @TabletUrlV1 TabletUrlV1, @TabletUrlV2 TabletUrlU2, @TypeV1 TypeV1, @TypeV2 TypeV2, @IPURLV1 IPURLV1, @IPURLV2 IPURLV2, @NetworkIdV1 NetworkIdV1, @NetworkIdV2 NetworkIdV2, @TokenV1 TokenV1, @TokenV2 TokenV2, @intPlayModeV1 intPlayModeV1, @intPlayModeV2 PlayModeV2, GETDATE() dtCreated

	SELECT @ChannelLineUpChangesParametersId = @@IDENTITY

	IF (@ChannelLineUpChangesParametersId IS NULL) 
	BEGIN
		raiserror('An error occured while recording parameters! Please review your parameters.', 20, 0) with log;
		RETURN;
	END
	
	
	
	INSERT INTO FIOSCE.dbo.ChannelLineUpChangesLog(ChannelLineUpChangesParametersId, Action, AFSID, ChannelNumber, RegionId, IH, OOH, IsRegular, LiveTv, VMS, IndexPosition, MobileUrlV1, MobileUrlV2, TabletUrlV1, TabletUrlV2, TypeV1, TypeV2, IPURLV1, IPURLV2, NetworkIdV1, NetworkIdV2, TokenV1, TokenV2, intPlayModeV1, intPlayModeV2, ChannelSubscriptionRows, TVEIhOhFlagsUpdatedRows, WatchNowChannelInfoRows, WatchNowChannelConfigV1Rows, WatchNowChannelConfigV2Rows, dtCreated)

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