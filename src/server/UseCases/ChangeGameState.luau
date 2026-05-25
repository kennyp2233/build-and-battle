-- ChangeGameState.luau
-- Función que aplica la transición de fase: muta el GameState, broadcastea
-- via GameStateService. No mantiene estado propio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.Entities.GameState)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local GameStateService = require(script.Parent.Parent.Services.GameStateService)

local logger = Logger.new("ChangeGameState")

local VALID_STATES = {
	Intermission = true,
	Building = true,
	Battle = true,
}

local function ChangeGameState(
	network,
	currentGameState,
	newStateType: GameState.GameStateType,
	duration: number
)
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
	currentGameState:setDuration(duration)

	if newStateType == "Intermission" then
		currentGameState:incrementRound()
	end

	GameStateService.Broadcast(network, currentGameState)

	logger:Info("Game state: %s -> %s (duration: %ds)", previousState, newStateType, duration)
end

return ChangeGameState
