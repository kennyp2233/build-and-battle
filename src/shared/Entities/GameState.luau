-- GameState.luau (Entidad para representar el estado del juego)
-- Esta es una entidad pura, independiente de Roblox

export type GameStateType = "Intermission" | "Building" | "Battle" | "Ended"

export type GameState = {
    currentState: GameStateType,
    timer: number,  -- Tiempo restante en segundos
    round: number,  -- Número de ronda
}

local GameState = {}

GameState.__index = GameState

function GameState.new(initialState: GameStateType, initialTimer: number, initialRound: number): GameState
    local instance = {
        currentState = initialState,
        timer = initialTimer,
        round = initialRound,
    }
    setmetatable(instance, GameState)
    return instance
end

function GameState:setState(newState: GameStateType)
    self.currentState = newState
end

function GameState:setTimer(newTimer: number)
    self.timer = newTimer
end

function GameState:incrementRound()
    self.round += 1
end

return GameState