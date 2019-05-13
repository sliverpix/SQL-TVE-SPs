USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraConfigChange]    Script Date: 5/13/2019 12:08:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[uspHydraConfigChange] 
(
	-------------------------------------------------------------------------------
	--Always specify a value for ChannelNumber and RegionId to determine the
	--channel to update. Specify additional parameters to be changed or updated.
	--Parameters equal to null will not be used to perform updates, removals, or 
	--inserts on Hydra tables. Specification of one of the Watch Now V1, or V2 
	--fields will create a record if one does not exists.
	-------------------------------------------------------------------------------
	@ChannelNumber INT = NULL, --Required
	@RegionId varchar(20) = NULL, --Required
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
	@TypeV2 varchar (100) = NULL, 
	@IPURLV1 varchar (500) = NULL,
	@IPURLV2 varchar (500) = NULL,
	@NetworkIdV1 varchar (50) = NULL,
	@NetworkIdV2 varchar (50) = NULL,
	@TokenV1 varchar (100) = NULL,
	@TokenV2 varchar (100) = NULL,
	@intPlayModeV1 int = NULL,
	@intPlayModeV2 int = NULL
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

	IF (@IH IS NULL AND @OOH IS NULL AND 
		@LiveTv IS NULL AND 
		@IsRegular IS NULL AND 
		@VMS IS NULL AND 
		@IndexPosition IS NULL AND 
		@MobileUrlV1 IS NULL AND 
		@MobileUrlV2 IS NULL AND 
		@TabletUrlV1 IS NULL AND 
		@TabletUrlV2 IS NULL AND 
		@TypeV1 IS NULL AND 
		@TypeV2 IS NULL AND 
		@IPURLV1 IS NULL AND 
		@IPURLV2 IS NULL AND 
		@NetworkIdV1 IS NULL AND 
		@NetworkIdV2 IS NULL AND 
		@TokenV1 IS NULL AND 
		@TokenV2 IS NULL AND 
		@intPlayModeV1 IS NULL AND 
		@intPlayModeV2 IS NULL)
	BEGIN
		raiserror('Specify a value for the parameters to be updated!', 20, 0) with log;
		RETURN;
	END

	--BandName Identifier
	DECLARE @BandName VARCHAR (20)

	IF (@IndexPosition IS NOT NULL) 
	BEGIN
		Print 'Verifying IndexPosition parameters...'
		IF @IndexPosition = 0 SELECT @BandName=''
		ELSE
		BEGIN
			SELECT @BandName = BandName
			FROM VideoSubscriber.dbo.Band
			WHERE BandId = @IndexPosition
		END
		IF (@BandName IS NULL)
		BEGIN
			raiserror('Parameter @IndexPosistion is invalid or does not exists!', 20, 0) with log;
			RETURN;
		END
	END

	DECLARE @ChannelLineUpChangesParametersId int

	INSERT INTO FIOSCE.dbo.ChannelLineUpChangesParameters(Action, ChannelNumber, RegionId, IH, OOH, IsRegular, LiveTv, VMS, IndexPosition, MobileUrlV1, MobileUrlV2, TabletUrlV1, TabletUrlV2, TypeV1, TypeV2, IPURLV1, IPURLV2, NetworkIdV1, NetworkIdV2, TokenV1, TokenV2, intPlayModeV1, intPlayModeV2, dtCreated)
	SELECT 'UPDATE' Action, @ChannelNumber ChannelNumber, @RegionId RegionId, @IH IH, @OOH OOH, @IsRegular IsRegular, @LiveTv LiveTv, @VMS VMS, @IndexPosition IndexPosition, @MobileUrlV1 MobileUrlV1, @MobileUrlV2 MobileUrlV2, @TabletUrlV1 TabletUrlV1, @TabletUrlV2 TabletUrlU2, @TypeV1 TypeV1, @TypeV2 TypeV2, @IPURLV1 IPURLV1, @IPURLV2 IPURLV2, @NetworkIdV1 NetworkIdV1, @NetworkIdV2 NetworkIdV2, @TokenV1 TokenV1, @TokenV2 TokenV2, @intPlayModeV1 intPlayModeV1, @intPlayModeV2 PlayModeV2, GETDATE() dtCreated

	SELECT @ChannelLineUpChangesParametersId = @@IDENTITY

	IF (@ChannelLineUpChangesParametersId IS NULL) 
	BEGIN
		raiserror('An error occured while recording parameters! Please review your parameters.', 20, 0) with log;
		RETURN;
	END

	--Channel Identifier
	DECLARE @AFSID VARCHAR (20)

	SELECT 	@AFSID = cs.strActualFIOSServiceID,
			@IH = ISNULL(@IH,cs.IH),
			@OOH = ISNULL(@OOH,cs.OOH),
			@LiveTv = ISNULL(@LiveTv,cs.Mobility),
			@IsRegular = ISNULL(@IsRegular,wn.IsRegular),
			@VMS = ISNULL(@VMS,cs.VMS),
			@IndexPosition = ISNULL(@IndexPosition,cs.IndexPosition),
			@BandName = CASE WHEN ISNULL(@IndexPosition,cs.IndexPosition) = 0 
							 THEN CASE WHEN ISNULL(@BandName, '') = '' 
									   THEN s.strStationCallSign
									   ELSE ISNULL(@BandName,wn.strBandName) END
							 ELSE ISNULL(@BandName,wn.strBandName) END,
			@MobileUrlV1 = ISNULL(@MobileUrlV1,wn1.strDrmMobileURL),
			@MobileUrlV2 = ISNULL(@MobileUrlV2,wn2.strDrmMobileURL),
			@TabletUrlV1 = ISNULL(@TabletUrlV1,wn1.strDrmTabletURL),
			@TabletUrlV2 = ISNULL(@TabletUrlV2,wn2.strDrmTabletURL),
			@TypeV1 = ISNULL(@TypeV1,wn1.strType),
			@TypeV2 = ISNULL(@TypeV2,wn2.strType),
			@IPURLV1 = ISNULL(@IPURLV1,wn1.strIPURL),
			@IPURLV2 = ISNULL(@IPURLV2,wn2.strIPURL),
			@NetworkIdV1 = ISNULL(@NetworkIdV1,wn1.strNetworkId),
			@NetworkIdV2 = ISNULL(@NetworkIdV2,wn2.strNetworkId),
			@TokenV1 = ISNULL(@TokenV1,wn1.strToken),
			@TokenV2 = ISNULL(@TokenV2,wn2.strToken),
			@intPlayModeV1 = ISNULL(@intPlayModeV1,wn1.intPlaymode),
			@intPlayModeV2 = ISNULL(@intPlayModeV2,wn2.intPlaymode)
	FROM (SELECT TOP 1 * 
		  FROM FIOSCE.dbo.tfiosChannel_Subscription 
		  WHERE intChannel = @ChannelNumber 
				AND strFiosRegionId = @RegionId) cs
-- add left join 2-22-2018 jgg
		 LEFT JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo wn ON cs.strActualFIOSServiceID = wn.strActualFiosServiceId
															 AND cs.strFiosRegionId = wn.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSLineup l ON cs.strActualFIOSServiceID = l.strActualFIOSServiceID 
										   AND cs.strFiosRegionId = l.strFiosRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSStation s on l.strFiosServiceId = s.strFiosServiceId
		 LEFT JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1 wn1 ON cs.strActualFIOSServiceID = wn1.strActualFiosServiceId
																		AND cs.strFiosRegionId = wn1.strFiosRegionId
		 LEFT JOIN FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2 wn2 ON cs.strActualFIOSServiceID = wn2.strActualFiosServiceId
																		AND cs.strFiosRegionId = wn2.strFiosRegionId
	WHERE l.intChannelPosition = @ChannelNumber 
		  AND cs.strFiosRegionId = @RegionId

	Print 'Verifying AFSID parameters...'
	IF (@AFSID IS NULL) 
	BEGIN
		raiserror('Parameters @ChannelNumber and @RegionId do not return a channel!', 20, 0) with log;
		RETURN;
	END

	-------------------------------------------------------------------------------
	--Processing changes
	-------------------------------------------------------------------------------

	DECLARE @ChannelSubscriptionRows int,
			@TVEIhOhFlagsUpdatedRows int,
			@WatchNowChannelInfoRows int,
			@WatchNowChannelConfigV1Rows int,
			@WatchNowChannelConfigV2Rows int


	UPDATE FIOSCE.dbo.tfiosChannel_Subscription
	SET IH = @IH,
		OOH = @OOH,
		Mobility = @LiveTv,
		VMS = @VMS,
		IndexPosition = @IndexPosition
	WHERE strActualFIOSServiceID = @AFSID
		  AND strFiosRegionId = @RegionId

	SELECT @ChannelSubscriptionRows = @@ROWCOUNT

	UPDATE FIOSApp_DC_CE.dbo.TVEIHOHFlags
	SET isIH = @IH,
		isOOH = @OOH
	WHERE regionID = @RegionId 
		  AND channelPosn = @ChannelNumber

	SELECT @TVEIhOhFlagsUpdatedRows = @@ROWCOUNT

	UPDATE FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo
	SET IsIH = @IH,
		IsOOH = @OOH,
		LiveTV = @LiveTv,
		IsRegular = @IsRegular,
		VMS = @VMS,
		intIndexPosition = @IndexPosition,
		strBandName = @BandName
	WHERE strFiosRegionId = @RegionId
		  AND strActualFiosServiceId = @AFSID

	SELECT @WatchNowChannelInfoRows = @@ROWCOUNT

	UPDATE FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1
	SET IsIH = @IH,
		IsOOH = @OOH,
		strDrmMobileURL = @MobileUrlV1,
		strDrmTabletURL = @TabletUrlV1,
		strType = @TypeV1,
		strIPURL = @IPURLV1,
		strNetworkId = @NetworkIdV1,
		strToken = @TokenV1,
		intPlaymode = @intPlayModeV1
	WHERE strActualFiosServiceId = @AFSID
		  AND strFiosRegionId = @RegionId

	SELECT @WatchNowChannelConfigV1Rows = @@ROWCOUNT

	IF (@WatchNowChannelConfigV1Rows = 0 
		AND @WatchNowChannelInfoRows = 1
		AND (@MobileUrlV1 IS NOT NULL 
			 OR @TabletUrlV1 IS NOT NULL 
			 OR @TypeV1 IS NOT NULL 
			 OR @IPURLV1 IS NOT NULL 
			 OR @NetworkIdV1 IS NOT NULL 
			 OR @TokenV1 IS NOT NULL 
			 OR @intPlayModeV1 IS NOT NULL)
		) 
	BEGIN	
		DECLARE @deviceList1 VARCHAR(500)
		SET @deviceList1=''
		SELECT @deviceList1 += CAST(intDeviceTypeID AS VARCHAR(10)) + ','
		FROM [FIOSCE].[dbo].[tFIOSCEDeviceTypeMaster]
		SELECT @deviceList1 = SUBSTRING(@deviceList1, 0, LEN(@deviceList1));

		INSERT INTO FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1 (strActualFiosServiceId, strFiosRegionId, strDrmMobileURL, strDrmTabletURL, strType, strIPURL, strNetworkId, strToken, intPlaymode, IsIH, IsOOH, IsEA, IsDMA, strDevices)
		SELECT ci.strActualFiosServiceId, 
			   ci.strFiosRegionId, 
			   @MobileUrlV1, 
			   @TabletUrlV1, 
			   ci.strType, 
			   @IPURLV1, 
			   @NetworkIdV1, 
			   @TokenV1, 
			   @intPlayModeV1, 
			   ci.IsIH, 
			   ci.IsOOH, 
			   ci.IsEA, 
			   ci.IsDMA, 
			   @deviceList1
		FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo ci
		WHERE ci.strActualFiosServiceId = @AFSID
			  AND ci.strFiosRegionId = @RegionId

		SELECT @WatchNowChannelConfigV1Rows = @@ROWCOUNT
	END

	UPDATE FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2
	SET IsIH = @IH,
		IsOOH = @OOH,
		strDrmMobileURL = @MobileUrlV2,
		strDrmTabletURL = @TabletUrlV2,
		strType = @TypeV2,
		strIPURL = @IPURLV2,
		strNetworkId = @NetworkIdV2,
		strToken = @TokenV2,
		intPlaymode = @intPlayModeV2
	WHERE strActualFiosServiceId = @AFSID
		  AND strFiosRegionId = @RegionId

	SELECT @WatchNowChannelConfigV2Rows = @@ROWCOUNT

	IF (@WatchNowChannelConfigV2Rows = 0 
		AND @WatchNowChannelInfoRows = 1
		AND (@MobileUrlV2 IS NOT NULL 
			 OR @TabletUrlV2 IS NOT NULL 
			 OR @TypeV2 IS NOT NULL 
			 OR @IPURLV2 IS NOT NULL 
			 OR @NetworkIdV2 IS NOT NULL 
			 OR @TokenV2 IS NOT NULL 
			 OR @intPlayModeV2 IS NOT NULL)
		) 
	BEGIN	
		DECLARE @deviceList2 VARCHAR(500)
		SET @deviceList2=''
		SELECT @deviceList2 += CAST(intDeviceTypeID AS VARCHAR(10)) + ','
		FROM [FIOSCE].[dbo].[tFIOSCEDeviceTypeMaster]
		SELECT @deviceList2 = SUBSTRING(@deviceList2, 0, LEN(@deviceList2));

		INSERT INTO FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2 (strActualFiosServiceId, strFiosRegionId, strDrmMobileURL, strDrmTabletURL, strType, strIPURL, strNetworkId, strToken, intPlaymode, IsIH, IsOOH, IsEA, IsDMA, strDevices)
		SELECT ci.strActualFiosServiceId, 
			   ci.strFiosRegionId, 
			   @MobileUrlV2, 
			   @TabletUrlV2, 
			   ci.strType, 
			   @IPURLV2, 
			   @NetworkIdV2, 
			   @TokenV2, 
			   @intPlayModeV2, 
			   ci.IsIH, 
			   ci.IsOOH, 
			   ci.IsEA, 
			   ci.IsDMA, 
			   @deviceList2
		FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo ci
		WHERE ci.strActualFiosServiceId = @AFSID
			  AND ci.strFiosRegionId = @RegionId

		SELECT @WatchNowChannelConfigV1Rows = @@ROWCOUNT
	END


	INSERT INTO FIOSCE.dbo.ChannelLineUpChangesLog(ChannelLineUpChangesParametersId, Action, AFSID, ChannelNumber, RegionId, IH, OOH, IsRegular, LiveTv, VMS, IndexPosition, MobileUrlV1, MobileUrlV2, TabletUrlV1, TabletUrlV2, TypeV1, TypeV2, IPURLV1, IPURLV2, NetworkIdV1, NetworkIdV2, TokenV1, TokenV2, intPlayModeV1, intPlayModeV2, ChannelSubscriptionRows, TVEIhOhFlagsUpdatedRows, WatchNowChannelInfoRows, WatchNowChannelConfigV1Rows, WatchNowChannelConfigV2Rows, dtCreated)
	SELECT @ChannelLineUpChangesParametersId ChannelLineUpChangesParametersId, 'UPDATE' Action, @AFSID AFSID, @ChannelNumber ChannelNumber, @RegionId RegionId, @IH IH, @OOH OOH, @IsRegular IsRegular, @LiveTv LiveTv, @VMS VMS, @IndexPosition IndexPosition, @MobileUrlV1 MobileUrlV1, @MobileUrlV2 MobileUrlV2, @TabletUrlV1 TabletUrlV1, @TabletUrlV2 TabletUrlU2, @TypeV1 TypeV1, @TypeV2 TypeV2, @IPURLV1 IPURLV1, @IPURLV2 IPURLV2, @NetworkIdV1 NetworkIdV1, @NetworkIdV2 NetworkIdV2, @TokenV1 TokenV1, @TokenV2 TokenV2, @intPlayModeV1 intPlayModeV1, @intPlayModeV2 PlayModeV2,@ChannelSubscriptionRows ChannelSubscriptionRows,@TVEIhOhFlagsUpdatedRows TVEIhOhFlagsUpdatedRows, @WatchNowChannelInfoRows WatchNowChannelInfoRows, @WatchNowChannelConfigV1Rows WatchNowChannelConfigV1Rows, @WatchNowChannelConfigV2Rows WatchNowChannelConfigV2Rows, GETDATE() dtCreated

	SELECT 'Results:' Results, @ChannelLineUpChangesParametersId ChannelLineUpChangesParametersId, 'UPDATE' Action, @AFSID AFSID, @ChannelNumber ChannelNumber, @RegionId RegionId, @IH IH, @OOH OOH, @LiveTv LiveTv, @IsRegular IsRegular, @VMS VMS, @IndexPosition IndexPosition, @BandName BandName, @MobileUrlV1 MobileUrlV1, @MobileUrlV2 MobileUrlV2, @TabletUrlV1 TabletUrlV1, @TabletUrlV2 TabletUrlU2, @TypeV1 TypeV1, @TypeV2 TypeV2, @IPURLV1 IPURLV1, @IPURLV2 IPURLV2, @NetworkIdV1 NetworkIdV1, @NetworkIdV2 NetworkIdV2, @TokenV1 TokenV1, @TokenV2 TokenV2, @intPlayModeV1 intPlayModeV1, @intPlayModeV2 intPlayModeV2,@ChannelSubscriptionRows ChannelSubscriptionRows,@TVEIhOhFlagsUpdatedRows TVEIhOhFlagsUpdatedRows, @WatchNowChannelInfoRows WatchNowChannelInfoRows, @WatchNowChannelConfigV1Rows WatchNowChannelConfigV1Rows, @WatchNowChannelConfigV2Rows WatchNowChannelConfigV2Rows

	SELECT 'tFIOS_Channel_Subscription' [Table], * 
	FROM FIOSCE.dbo.tfiosChannel_Subscription
	WHERE strFiosRegionId = @RegionId 
		  AND strActualFIOSServiceID = @AFSID

	SELECT 'TVEIHOHFlags' [Table], * 
	FROM FIOSApp_DC_CE.dbo.TVEIHOHFlags
	WHERE RegionId = @RegionId 
		  AND channelPosn = @ChannelNumber

	SELECT 'tfiosWatchNow_Channelinfo' [Table], * 
	FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo
	WHERE strFiosRegionId = @RegionId 
		  AND strActualFIOSServiceID = @AFSID

	SELECT 'tfiosWatchNow_ChannelConfig_V1' [Table], * 
	FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V1
	WHERE strFiosRegionId = @RegionId 
		  AND strActualFIOSServiceID = @AFSID

	SELECT 'tfiosWatchNow_ChannelConfig_V2' [Table], * 
	FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_ChannelConfig_V2
	WHERE strFiosRegionId = @RegionId 
		  AND strActualFIOSServiceID = @AFSID
END
