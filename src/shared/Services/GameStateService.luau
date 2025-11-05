-- GameStateService.luau (Servicio para manejar y broadcast el estado del juego)
-- Usa NetworkManager para comunicar con el cliente
-- Implementa el patrón Repository para el estado del juego

local GameConfig = require(script.Parent.Parent.Config.GameConfig)
local NetworkManager = require(script.Parent.Parent.Utils.NetworkManager)
local Logger = require(script.Parent.Parent.Utils.Logger)

local logger = Logger.new("GameStateService")

local GameStateService = {}
GameStateService.__index = GameStateService

function GameStateService.new(networkManager: any?)
	local self = setmetatable({}, GameStateService)
	self.networkManager = networkManager or NetworkManager.new()
	self.currentState = nil
	logger:Info("GameStateService initialized")
	return self
end

-- Broadcast del estado a todos los clientes
function GameStateService:BroadcastState(gameState)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState")
		return
	end

	logger:Info("Broadcasting game state: %s, Timer: %d, Round: %d", gameState.currentState, gameState.timer, gameState.round)

	self.networkManager:FireAllClients(
		GameConfig.EVENTS.GAME_STATE_CHANGED,
		gameState.currentState,
		gameState.timer,
		gameState.round
	)
end

-- Broadcast del estado a un cliente específico (útil para jugadores que se unen tarde)
function GameStateService:BroadcastStateToPlayer(gameState, player: Player)
	if not gameState then
		logger:Error("Attempted to broadcast nil gameState to player %s", player.Name)
		return
	end

	logger:Info("Broadcasting state to player %s: %s", player.Name, gameState.currentState)

	self.networkManager:FireClient(
		GameConfig.EVENTS.GAME_STATE_CHANGED,
		player,
		gameState.currentState,
		gameState.timer,
		gameState.round
	)
end

-- Actualizar y persistir el estado
function GameStateService:UpdateState(gameState)
	if not gameState then
		logger:Error("Attempted to update with nil gameState")
		return
	end

	self.currentState = gameState
	-- Aquí podrías agregar persistencia con DataStore en el futuro
	self:BroadcastState(gameState)
end

-- Obtener el estado actual
function GameStateService:GetCurrentState()
	return self.currentState
end

-- Cleanup
function GameStateService:Destroy()
	logger:Info("Destroying GameStateService")
	if self.networkManager then
		self.networkManager:Destroy()
	end
end

return GameStateService