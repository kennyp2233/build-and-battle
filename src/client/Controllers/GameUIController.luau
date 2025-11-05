-- GameUIController.luau
-- Controlador para manejar la lógica de la UI del cliente
-- Escucha eventos del servidor y actualiza la vista

local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameUIController")

local GameUIController = {}
GameUIController.__index = GameUIController

function GameUIController.new(gameView)
	local self = setmetatable({}, GameUIController)
	self.gameView = gameView

	-- Escuchar cambios de estado desde el servidor
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local gameStateEvent = ReplicatedStorage:WaitForChild(GameConfig.EVENTS.GAME_STATE_CHANGED)

	gameStateEvent.OnClientEvent:Connect(function(state: string, timer: number, round: number)
		logger:Info("Received state update: %s, Timer: %d, Round: %d", state, timer, round or 0)
		self:OnStateChanged(state, timer, round)
	end)

	logger:Info("GameUIController initialized")
	return self
end

function GameUIController:OnStateChanged(state: string, timer: number, round: number?)
	-- Obtener maxTimer desde GameConfig basado en el estado
	local maxTimer = GameConfig.PHASE_DURATIONS[state] or timer
	logger:Debug("OnStateChanged - State: %s, Timer: %d, MaxTimer: %d", state, timer, maxTimer)

	self.gameView:UpdateState(state, timer, round, maxTimer)
end

-- Cleanup
function GameUIController:Destroy()
	logger:Info("Destroying GameUIController")

	if self.gameView then
		self.gameView:Destroy()
	end
end

return GameUIController
