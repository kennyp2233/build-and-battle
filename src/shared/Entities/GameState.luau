-- GameState.luau (Entidad para representar el estado del juego)
-- Almacena un endTimestamp absoluto (workspace:GetServerTimeNow()) en lugar de un
-- timer decreciente, para que los late-joiners reciban el tiempo restante correcto.

export type GameStateType = "Intermission" | "Building" | "Battle" | "Ended"

export type GameState = {
	currentState: GameStateType,
	endTimestamp: number,
	round: number,
}

local GameState = {}
GameState.__index = GameState

function GameState.new(initialState: GameStateType, initialDuration: number, initialRound: number): GameState
	local instance = {
		currentState = initialState,
		endTimestamp = workspace:GetServerTimeNow() + initialDuration,
		round = initialRound,
	}
	setmetatable(instance, GameState)
	return instance
end

function GameState:setState(newState: GameStateType)
	self.currentState = newState
end

function GameState:setDuration(seconds: number)
	self.endTimestamp = workspace:GetServerTimeNow() + seconds
end

function GameState:getRemaining(): number
	return math.max(0, self.endTimestamp - workspace:GetServerTimeNow())
end

function GameState:incrementRound()
	self.round += 1
end

return GameState
