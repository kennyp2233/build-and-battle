-- GameStateService.luau
-- Servidor-only. Broadcastea el estado actual del juego a clientes vía ServerNetwork.
-- Lee endTimestamp directamente de la entidad GameState — no recalcula tiempo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Network.Events)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameStateService")

local GameStateService = {}
GameStateService.__index = GameStateService

function GameStateService.new(network)
	assert(network, "GameStateService requires a ServerNetwork instance")
	local self = setmetatable({}, GameStateService)
	self.network = network
	self.currentState = nil
	return self
end

function GameStateService:BroadcastState(gameState)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState")
		return
	end

	self.network:FireAll(
		Events.GameStateChanged,
		gameState.currentState,
		gameState.endTimestamp,
		gameState.round
	)
end

function GameStateService:BroadcastStateToPlayer(gameState, player: Player)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState to player %s", player.Name)
		return
	end

	self.network:FireClient(
		Events.GameStateChanged,
		player,
		gameState.currentState,
		gameState.endTimestamp,
		gameState.round
	)
end

function GameStateService:UpdateState(gameState)
	if not gameState then
		logger:Error("Attempted to update with nil gameState")
		return
	end
	self.currentState = gameState
	self:BroadcastState(gameState)
end

function GameStateService:GetCurrentState()
	return self.currentState
end

return GameStateService
