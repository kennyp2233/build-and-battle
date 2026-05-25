-- GameStateService.luau
-- Funciones de broadcast del GameState. Sin estado propio — GameController es el
-- único owner del currentGameState (single source of truth).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Network.Events)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameStateService")

local GameStateService = {}

function GameStateService.Broadcast(network, gameState)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState")
		return
	end
	network:FireAll(
		Events.GameStateChanged,
		gameState.currentState,
		gameState.endTimestamp,
		gameState.round
	)
end

function GameStateService.BroadcastToPlayer(network, gameState, player: Player)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState to player %s", player.Name)
		return
	end
	network:FireClient(
		Events.GameStateChanged,
		player,
		gameState.currentState,
		gameState.endTimestamp,
		gameState.round
	)
end

return GameStateService
