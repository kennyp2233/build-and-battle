-- Events.luau
-- Single source of truth for RemoteEvent names + payload contracts.
--
-- Direction tag:
--   S→C : server fires, clients listen
--   C→S : client fires, server listens
--
-- GameStateChanged (S→C, all)
--   args: (state: string, endTimestamp: number, round: number)
--
-- PlaceBlockRequest (C→S)
--   args: (position: Vector3, blockType: string)
--
-- BlockPlaced (S→C, all)
--   args: (id: string, position: Vector3, blockType: string, ownerId: number)
--
-- BlocksCleared (S→C, all)
--   args: ()
--
-- PlaceBlockRejected (S→C, requesting player only)
--   args: (reason: string)

local Events = {
	GameStateChanged = "GameStateChanged",
	PlaceBlockRequest = "PlaceBlockRequest",
	BlockPlaced = "BlockPlaced",
	BlocksCleared = "BlocksCleared",
	PlaceBlockRejected = "PlaceBlockRejected",
}

Events.All = {
	Events.GameStateChanged,
	Events.PlaceBlockRequest,
	Events.BlockPlaced,
	Events.BlocksCleared,
	Events.PlaceBlockRejected,
}

return Events
