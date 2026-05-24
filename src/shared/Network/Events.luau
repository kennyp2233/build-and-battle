-- Events.luau
-- Single source of truth for RemoteEvent names + payload contracts.
--
-- Direction tag:
--   S→C : server fires, clients listen
--   C→S : client fires, server listens
--
-- GameStateChanged (S→C)
--   args: (state: string, endTimestamp: number, round: number)
--
-- PlaceBlockRequest (C→S)
--   args: (position: Vector3, blockType: string)
--
-- BlockPlaced (S→C)
--   args: (id: string, position: Vector3, blockType: string, owner: string)

local Events = {
	GameStateChanged = "GameStateChanged",
	PlaceBlockRequest = "PlaceBlockRequest",
	BlockPlaced = "BlockPlaced",
}

-- All defined event names as a list, used by Server/Client wrappers to register/wait.
Events.All = {
	Events.GameStateChanged,
	Events.PlaceBlockRequest,
	Events.BlockPlaced,
}

return Events
