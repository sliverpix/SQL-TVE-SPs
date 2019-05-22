USE [FIOSCE]
GO
/****** Object:  StoredProcedure [dbo].[uspHydraAddChanneltoRegion]    Script Date: 5/13/2019 10:14:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
-- TVE Ops Modify to be able to add channel to specific region for multi-region VHOs/DMA
-- modified: James G

-- TVE Ops Modified @Service_Bsg_Handle VARCHAR(20) to @Service_Bsg_Handle VARCHAR(50) to account for Subscriber groups 
-- in Vantage markets
-- Modified: Russ N 12/15/2017

-- TVE Ops Modified @BandId from VARCHAR (20) to VARCHAR (50). Apparently there are some bandids longer than 20 characters.
-- Modified: Russ N 12/18/2017


*/

ALTER PROCEDURE [dbo].[uspHydraAddChanneltoRegion](
	@ServiceRegionId VARCHAR(10),
	@Channel_Number int,
	@Service_Bsg_Handle VARCHAR(50),
	@BandId int = 0
	
)
AS
BEGIN

	Print 'Verifying required parameters...'
	IF (@ServiceRegionId IS NULL OR @Channel_Number IS NULL OR @Service_Bsg_Handle IS NULL OR RTRIM(@Service_Bsg_Handle) = '') 
	BEGIN
		raiserror('ServiceRegionId, Channel_Number and Service_Bsg_Handle are required!', 20, 0) with log;
		RETURN;
	END
	
	Print 'Verifying parameters for updates...'
	IF NOT EXISTS (SELECT 1 FROM VideoSubscriber.dbo.ServiceMaps WHERE ServiceRegionId = @ServiceRegionId) -- change VhoID to ServiceRegionId
	BEGIN
		raiserror('ServiceRegionId is invalid and does not exist', 20, 0) with log;
		RETURN;
	END

	--BandName Identifier
	DECLARE @BandName VARCHAR (50)

	IF (@BandId IS NOT NULL) 
	BEGIN
		Print 'Verifying IndexPosition parameters...'
		IF @BandId = 0 SELECT @BandName=''
		ELSE
		BEGIN
			SELECT @BandName = BandName
			FROM VideoSubscriber.dbo.Band
			WHERE BandId = @BandId
		END
		IF (@BandName IS NULL)
		BEGIN
			raiserror('Parameter @BandId is invalid or does not exists!', 20, 0) with log;
			RETURN;
		END
	END

	--Market type identification
	Print 'Determine market type...'
	DECLARE @marketType varchar(20) = ''
	SELECT @marketType = CASE WHEN n.ServiceRegion IS NULL THEN 'Vantage' ELSE 'Fios' END
	FROM VideoSubscriber.dbo.ServiceMaps s
		 LEFT OUTER JOIN VideoSubscriber.dbo.NspInHomeRegions n ON s.ServiceRegionId = n.ServiceRegion
	WHERE s.ServiceRegionId = @ServiceRegionId -- change VhoId to ServiceRegionId


	Print 'Verifying market type...'
	IF (@marketType != 'Fios' AND @marketType != 'Vantage')
	BEGIN
		raiserror('Parameter @marketType is invalid or does not exists!', 20, 0) with log;
		RETURN;
	END
	Print 'Market Type:' + @marketType

	--Starting Inserts
	INSERT INTO tfiosChannel_Subscription (intChannel, strServiceName, strFiosRegionId, strFiosServiceId, strActualFIOSServiceID, IndexPosition, IH, OOH, EA, Ispremium, Mobility, VMS)
	SELECT l.intChannelPosition,
		   @Service_Bsg_Handle,
		   r.ServiceRegionId,
		   l.strFIOSServiceId,
		   l.strActualFIOSServiceID, 
		   @BandId BandId,
		   0 IH,
		   0 OOH,
		   0 EA,
		   0 IsPremium,
		   0 LiveTv,
		   0 VMS
	FROM FIOSApp_DC.dbo.tFIOSLineup l
		 JOIN FIOSApp_DC.dbo.tFiosStation s ON l.strFIOSServiceId = s.strFIOSServiceId
		 JOIN VideoSubscriber.dbo.ServiceMaps r ON l.strFIOSRegionId = r.ServiceRegionId
	WHERE r.ServiceRegionId = @ServiceRegionId -- change VhoId to ServiceRegionId 
		  AND l.intChannelPosition = @Channel_Number
		  AND ((@marketType = 'Fios' 
				AND NOT EXISTS (SELECT 1
						        FROM FIOSCE.dbo.tfiosChannel_Subscription
						        WHERE intChannel = l.intChannelPosition 
								      AND strActualFIOSServiceID = l.strActualFIOSServiceID
								      AND strFiosRegionId = l.strFIOSRegionId))
			OR (@marketType = 'Vantage'
				AND	NOT EXISTS (SELECT 1
							    FROM FIOSCE.dbo.tfiosChannel_Subscription
							    WHERE intChannel = l.intChannelPosition 
								      AND strActualFIOSServiceID = l.strActualFIOSServiceID
								      AND strFiosRegionId = l.strFIOSRegionId
									  AND strServiceName = @Service_Bsg_Handle)))

	INSERT INTO FIOSApp_DC_CE.dbo.TVEIHOHFlags(Network, RegionId, ChannelPosn, isIH, isOOH, strVCN)
	SELECT s.strStationName,
		   r.ServiceRegionId,
		   l.intChannelPosition,
		   0 IH,
		   0 OOH,
		   t.strVirtualChannelPosition
	FROM FIOSApp_DC.dbo.tFIOSLineup l
		 JOIN FIOSApp_DC.dbo.tFiosStation s ON l.strFIOSServiceId = s.strFIOSServiceId
		 JOIN VideoSubscriber.dbo.ServiceMaps r ON l.strFIOSRegionId = r.ServiceRegionId
		 JOIN FIOSApp_DC.dbo.tFIOSRegion t ON r.ServiceRegionId = t.strFIOSRegionId
	WHERE r.ServiceRegionId = @ServiceRegionId -- change VhoId to ServiceRegionId
		  AND l.intChannelPosition = @Channel_Number
		  AND NOT EXISTS (SELECT 1
						  FROM FIOSApp_DC_CE.dbo.TVEIHOHFlags
						  WHERE channelPosn = l.intChannelPosition 
								AND regionID = l.strFIOSRegionId)


	INSERT INTO FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo (strActualFiosServiceId, strFiosRegionId, intChannel, strType, intIndexPosition, strShortName, strBandName, IsIH, IsOOH, IsEA, IsDMA, IsRegular, LiveTV, SCheck, V1, V2, VMS, dtCreated, dtUpdated)
	SELECT l.strActualFIOSServiceID,
		r.ServiceRegionId,
		l.intChannelPosition,
	   CASE WHEN g.strStationGenre LIKE '%LOCAL%' OR g.strStationGenre LIKE '%HD BROADCAST%' THEN 'Local' ELSE 'National' END ChannelType,
	   @BandId intIndexPosition,
	   s.strStationCallSign,
	   CASE @BandName WHEN '' THEN s.strStationCallSign ELSE @BandName END BandName,
	   0 isIH,
	   0 isOOH,
	   0 isEA,
	   0 isDMA,
	   0 isRegular,
	   0 live,
	   0 scheck,
	   1 V1,
	   1 V2,
	   0 VMS,
	   GETDATE() dtCreated,
	   GETDATE() dtUpdated
	FROM FIOSApp_DC.dbo.tFIOSLineup l
		 JOIN FIOSApp_DC.dbo.tFiosStation s ON l.strFIOSServiceId = s.strFIOSServiceId
		 JOIN VideoSubscriber.dbo.ServiceMaps r ON l.strFIOSRegionId = r.ServiceRegionId
		 LEFT JOIN FIOSApp_DC.dbo.tfiosStationGenre g ON l.iStationGenreID = g.iStationGenreId
	WHERE r.ServiceRegionId = @ServiceRegionId -- change VhoId to ServiceRegionId
		  AND l.intChannelPosition = @Channel_Number
		  AND NOT EXISTS (SELECT 1
						  FROM FIOSApp_DC_CE.dbo.tfiosWatchNow_Channelinfo
						  WHERE intChannelPosition = l.intChannelPosition 
								AND strActualFIOSServiceID = l.strActualFIOSServiceID
								AND strFiosRegionId = l.strFIOSRegionId)

	
	Print 'Done! - No red text - No Issues for channel ' + CAST(@Channel_Number AS VARCHAR)
END

