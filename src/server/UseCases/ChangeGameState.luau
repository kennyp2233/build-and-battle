-- ChangeGameState.luau (Caso de uso para cambiar la fase del juego)
-- Mueve el endTimestamp de la entidad usando duration en segundos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.Entities.GameState)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("ChangeGameState")

local VALID_STATES = {
	Intermission = true,
	Building = true,
	Battle = true,
	Ended = true,
}

local ChangeGameState = {}
ChangeGameState.__index = ChangeGameState

function ChangeGameState.new(gameStateService)
	local self = setmetatable({}, ChangeGameState)
	self.gameStateService = gameStateService
	return self
end

function ChangeGameState:Execute(currentGameState, newStateType: GameState.GameStateType, duration: number?)
	if not currentGameState then
		logger:Error("Attempted to change nil game state")
		return
	end

	if not VALID_STATES[newStateType] then
		logger:Error("Invalid game state type: %s", tostring(newStateType))
		return
	end

	local previousState = currentGameState.currentState

	currentGameState:setState(newStateType)
	if duration then
		currentGameState:setDuration(duration)
	end

	if newStateType == "Intermission" then
		currentGameState:incrementRound()
	end

	self.gameStateService:UpdateState(currentGameState)

	logger:Info("Game state: %s -> %s (duration: %s)", previousState, newStateType, tostring(duration))
end

return ChangeGameState
