# Repo Title
SQL Stored Proceures for TVE (Hydra/MSV)

## Description
Collection of stored procedures and/or tools for TVE's Live Streaming and VOD services. (Hydra/MSV)


## Inventory


* __Filename:__	uspHydraAddChanneltoRegion
* __Created:__		1/6/2017 2:37 PM
* __Modified:__	12/18/2017
* __Author:__		Stacy Web
* __Version:__		2.3

Exists in the DB FIOSCE. Adds a NEW channel to specified TVE Region. Accepts the following variables.

| Variable | Type | Description |
| --- | --- | --- |
| `@ServiceRegionId` | VARCHAR(10) | (REQUIRED) Region ID as defined by TVE Region maps |
| `@Channel_Number` | int | (Required) The channel number to be assigned to the channel |
| `@Service_Bsg_Handle` | VARCHAR(50) | Billing Service ID (integer for FIOS / varchar for Mediaroom) |
| `@BandId` | int | Defaults to '0' and is used to link channel to Band ID from bandid.cfg on secure media. This linke the channel encryption to the media KEY necessary for decryption. Set to '0' for channels only to be shown in the Channel GUIDE.|


* __Filename:__	uspHydraChannelDelete
* __Created:__		12/30/2016 1:55 PM
* __Modified:__	
* __Author:__		Stacy Web
* __Version:__		1.0

Exists in the DB FIOSCE. Removes a channel by channel number and TVE region. This removes all data in all related tables for the targetted channel. In other words, package data, config flags and URL data, are all removed as well. (Note: if a more surgical affect is needed, dont use this procedure)

Accepts the following variables:

| Variable | Type | Description |
| --- | --- | --- |
| `@ChannelNumber` | INT | (Required) Number of the channel to be targeted in the region following |
| `@RegionId` | varchar(20) | (Required) Region ID as defined by TVE Region maps |


* __Filename:__	uspHydraAddPackageServiceMaptoRegion
* __Created:__		3/31/2017 3:49 PM
* __Modified:__	
* __Author:__		Stacy Web
* __Version:__		1.0

Exists in the DB FIOSCE. Add service package to by region. This will attach a package to any channel number with a matching Service ID (Service_BSG_Handle) inthe targetted region. Thus it is possible to add packages to multiple channels/service in the same region.

Accepts the following variables.

| Variable | Type | Description |
| --- | --- | --- |
| `@VhoId` | VARCHAR(20) | (REQUIRED) use region number instead of VHOID |
| `@PackageName` | VARCHAR(50) | (REQUIRED) Name of the package to be Added. This variable is trimmed, ie removing white space from the end of the strings and any part of that matches the package handle ID. |
| `@Package_BSG_Handle` | VARCHAR(50) | (REQUIRED) This is the package ID number (FIOS) or "GRP_" ID (Mediaroom) of the package to be applied. |
| `@Service_BSG_Handle` | VARCHAR(50) | (REQUIRED) This is the service ID number (FIOS) or Package name (Mediaroom) |


* __Filename:__	uspRemovePackagefromChannel
* __Created:__		4/11/2019 5:23 PM
* __Modified:__	
* __Author:__		James Griffith
* __Version:__		1.0

(in Testing / works well for FIOS channels) Exists in the DB FIOSCE. Surgically target packages assigned to targetted channel/region and remove them ONLY from that channel in the specified region.

Accepts the following variables:

| Variable | Type | Description |
| --- | --- | --- |
| @VhoId | VARCHAR(20) | (Required) Region ID as defined by TVE Region maps |
| @ChanNumber | Varchar(20) | (Required) Number of the channel to be targetted in the region following |
| @PackageId | VARCHAR(20) | (Required) Package number to be targetted.


* __Filename:__	uspHydraConfigChange
* __Created:__		8/24/2016 12:16 AM
* __Modified:__	
* __Author:__		Stacy Web
* __Version:__		1.0

Exists in the DB FIOSCE. This Stored Procedure allows for the setting/changing of spcified flags, and variables that change how the channel operates. See the table below for details about this settings.

Always specify a value for ChannelNumber and RegionId to determine the channel to update. Specify additional parameters to be changed or updated. Parameters equal to null will not be used to perform updates, removals, or inserts on Hydra tables. Specification of one of the Watch Now V1, or V2 fields will create a record if one does not exists.

| Variable | Type | Description |
| --- | --- | --- |
| `@ChannelNumber` | INT | (Required) Number of the channel to be targetted in the region following |
| `@RegionId` | varchar(20) | (Required) Region ID as defined by TVE Region maps |
| `@IH` | bit | ("1" = on/set & "0" = off/unset)
| `@OOH` | bit | ("1" = on/set & "0" = off/unset)
| `@LiveTv` | bit | ("1" = on/set & "0" = off/unset)
| `@IsRegular` | bit | ("1" = on/set & "0" = off/unset)
| `@VMS` | bit | ("1" = on/set & "0" = off/unset)
| `@IndexPosition` | int | ("1" = on/set & "0" = off/unset)
| `@MobileUrlV1` | varchar(500) | The URL to the video stream. This variable affects "mobile" devices such as cell phones. Uses HTTP protocol to the form of "http://<path to stream>/out/u/<manifest name>.m3u8"
| `@MobileUrlV2` | varchar(500) | same as `MobileUrlV1` above.
| `@TabletUrlV1` | varchar(500) | The URL to the video stream. This variable affects "tablet" devices such as iTabs. Uses HTTP protocol to the form of "http://<path to stream>/out/u/<manifest name>.m3u8"
| `@TabletUrlV2` | varchar(500) | same as `TabletUrlV1` above.
| `@TypeV1` | varchar (100) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@TypeV2` | varchar (100) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over. 
| `@IPURLV1` | varchar (500) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@IPURLV2` | varchar (500) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@NetworkIdV1` | varchar (50) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@NetworkIdV2` | varchar (50) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@TokenV1` | varchar (100) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@TokenV2` | varchar (100) | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@intPlayModeV1` | int | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.
| `@intPlayModeV2` | int | Unused in TVE's current environment (as far as we know). This is left over from Verizon switch over.


## ToDo:
- [X]  all SPs need to be adjusted to accept numeric region ID rather than alphanumeric VHO ID's.
- [ ]  uspRemovePackagefromChannel - add logic/mechanism for targetting MEDIAROOM channels/packages.
- [ ]  uspHydraChannelDelete - add logic/mechanism to address FSID mismatches that commonly occur when Gracenote/FYI change/remove channel data from the tfioslineup table.
- [ ]  Create SP to handle adding zip codes to targetted TVE regions. currently we are manualy inserting them without any kind of error/duplication checks.


## History

* 05/13/2019 - Initial creation and upload
