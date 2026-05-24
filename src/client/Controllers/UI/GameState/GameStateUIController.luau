-- GameStateUIController.luau
-- Controlador específico para la UI del estado del juego
-- RESPONSABILIDAD: Manejar lógica de negocio del game state (countdown, eventos) y actualizar GameStateHUD

local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameStateUIController")

local GameStateUIController = {}
GameStateUIController.__index = GameStateUIController

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function GameStateUIController.new(gameStateHUD)
	local self = setmetatable({}, GameStateUIController)
	
	-- Referencias
	self.gameStateHUD = gameStateHUD
	self.countdownTask = nil
	
	-- Estado actual del game state
	self.currentState = {
		state = nil,
		timer = 0,
		round = nil,
		maxTimer = 0,
		endTimestamp = 0,
	}
	
	-- Para evitar spam de logs
	self.lastLoggedSecond = nil

	logger:Info("GameStateUIController initialized")
	return self
end

-- ============================================================================
-- LÓGICA DE NEGOCIO DEL GAME STATE
-- ============================================================================

-- Manejar cambio de estado desde el servidor (ahora recibe timestamp en lugar de timer)
function GameStateUIController:OnStateChanged(state: string, endTimestamp: number, round: number?)
	-- Obtener maxTimer desde GameConfig basado en el estado
	local maxTimer = GameConfig.PHASE_DURATIONS[state] or 0
	
	-- Calcular timer inicial basado en el timestamp del servidor
	local serverTime = workspace:GetServerTimeNow()
	local remainingTime = math.max(0, endTimestamp - serverTime)
	
	-- Actualizar estado interno
	self.currentState.state = state
	self.currentState.endTimestamp = endTimestamp
	self.currentState.round = round
	self.currentState.maxTimer = maxTimer
	
	logger:Debug("OnStateChanged - State: %s, EndTimestamp: %.2f, Remaining: %.1fs, MaxTimer: %d", 
		state, endTimestamp, remainingTime, maxTimer)

	-- Actualizar HUD con tiempo inicial
	self.gameStateHUD:UpdateState(state, math.ceil(remainingTime), round, maxTimer)
	
	-- Iniciar countdown basado en timestamp del servidor
	self:_startCountdown(endTimestamp, maxTimer)
end

-- Countdown preciso basado en timestamp del servidor
function GameStateUIController:_startCountdown(endTimestamp: number, maxTimer: number)
	-- Cancelar countdown anterior si existe
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end

	-- Iniciar nuevo countdown basado en tiempo del servidor
	self.countdownTask = task.spawn(function()
		while true do
			-- Actualizar cada 0.1 segundos para UI más fluida
			task.wait(0.1)
			
			-- Calcular tiempo restante basado en el servidor (fuente de verdad)
			local serverTime = workspace:GetServerTimeNow()
			local remaining = endTimestamp - serverTime
			
			-- Si el tiempo se acabó, detener
			if remaining <= 0 then
				self.gameStateHUD:UpdateTimer(0, maxTimer)
				logger:Debug("Countdown finished (server time reached)")
				break
			end
			
			-- Convertir a segundos enteros para la UI
			local secondsRemaining = math.ceil(remaining)
			
			-- Actualizar estado interno
			self.currentState.timer = secondsRemaining
			
			-- Actualizar HUD
			self.gameStateHUD:UpdateTimer(secondsRemaining, maxTimer)
			
			-- Log cada segundo (no cada 0.1s para no saturar)
			if secondsRemaining ~= self.lastLoggedSecond then
				logger:Debug("Countdown: %d seconds remaining (server-synced)", secondsRemaining)
				self.lastLoggedSecond = secondsRemaining
			end
		end
	end)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function GameStateUIController:Destroy()
	logger:Info("Destroying GameStateUIController")
	
	-- Cancelar countdown
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end
end

return GameStateUIController
