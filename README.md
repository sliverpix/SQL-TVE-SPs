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

| --- | --- | --- |
| `@ServiceRegionId` | VARCHAR(10) | (REQUIRED) Region ID as defined by TVE Region maps |
| `@Channel_Number` | int | (Required) The channel number to be assigned to the channel |
| `@Service_Bsg_Handle` | VARCHAR(50) | Billing Service ID (integer for FIOS / varchar for Mediaroom) |
| `@BandId` | int | Defaults to '0' and is used to link channel to Band ID from bandid.cfg on secure media. This linke the channel encryption to the media KEY necessary for decryption. Set to '0' for channels only to be shown in the Channel GUIDE.|



## ToDo:
- [X] placeholder
- [ ] placeholder


## History

* 05/13/2019 - Initial creation and upload
