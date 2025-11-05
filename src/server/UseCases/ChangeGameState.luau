-- ChangeGameState.luau (Caso de uso para cambiar el estado del juego)
-- Lógica de negocio pura con validación y logging

local GameState = require(game.ReplicatedStorage.Shared.Entities.GameState)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("ChangeGameState")

local ChangeGameState = {}
ChangeGameState.__index = ChangeGameState

function ChangeGameState.new(gameStateService)
	local self = setmetatable({}, ChangeGameState)
	self.gameStateService = gameStateService
	logger:Info("ChangeGameState use case initialized")
	return self
end

function ChangeGameState:Execute(currentGameState, newStateType: GameState.GameStateType, newTimer: number?)
	-- Validar que el estado actual existe
	if not currentGameState then
		logger:Error("Attempted to change nil game state")
		return
	end

	-- Validar que el nuevo estado es válido
	local validStates = { "Intermission", "Building", "Battle", "Ended" }
	local isValidState = false
	for _, state in ipairs(validStates) do
		if state == newStateType then
			isValidState = true
			break
		end
	end

	if not isValidState then
		logger:Error("Invalid game state type: %s", tostring(newStateType))
		return
	end

	local previousState = currentGameState.currentState

	-- Actualizar el estado
	currentGameState:setState(newStateType)
	if newTimer then
		currentGameState:setTimer(newTimer)
	end

	-- Incrementar ronda cuando entramos a Intermission
	if newStateType == "Intermission" then
		currentGameState:incrementRound()
		logger:Info("Round incremented to %d", currentGameState.round)
	end

	-- Broadcast el nuevo estado
	self.gameStateService:UpdateState(currentGameState)

	logger:Info("Game state changed: %s -> %s (Timer: %d)", previousState, newStateType, currentGameState.timer)
end

return ChangeGameState