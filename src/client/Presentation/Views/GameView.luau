-- GameView.luau
-- Vista principal del HUD del juego - Responsable de renderizar y actualizar la UI

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RoUI = require(script.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Core.Theme)
local HUD = require(script.Parent.Parent.Components.Game.HUD)

local GameView = {}
GameView.__index = GameView

-- ============================================================================
-- CLASE GAMEVIEW
-- ============================================================================

function GameView.new()
	local self = setmetatable({}, GameView)

	-- Estado
	self.state = {
		state = "Intermission",
		timer = 30,
		round = nil,
		maxTimer = 30,
		lowTimeThreshold = 10,
		hudVisible = true, -- Controla la visibilidad del HUD
	}

	-- Tarea de countdown
	self.countdownTask = nil

	-- Crear ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "GameHUD"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.IgnoreGuiInset = true
	self.screenGui.Parent = playerGui

	-- Renderizar UI inicial
	self:_render()

	return self
end

-- Renderizar UI completa
function GameView:_render()
	self.screenGui:ClearAllChildren()

	local hud = HUD({
		state = self.state.state,
		timer = self.state.timer,
		maxTimer = self.state.maxTimer,
		round = self.state.round,
		lowTimeThreshold = self.state.lowTimeThreshold,
		visible = self.state.hudVisible,
		onToggle = function()
			self:ToggleHUD()
		end
	})

	hud.Parent = self.screenGui
	self.currentHUD = hud
	self.currentContainer = hud
	self.currentCard = hud:FindFirstChild("Card")
	self.toggleButton = hud:FindFirstChild("ToggleButton")
end

-- Actualizar solo el timer (optimizado, no recrea toda la UI)
function GameView:_updateTimerOnly()
	if not self.currentCard then return end

	local timer = self.state.timer
	local maxTimer = self.state.maxTimer
	local progress = math.clamp(timer / maxTimer, 0, 1)
	local timerText = string.format("%02d:%02d", math.floor(timer / 60), timer % 60)
	local timerColor = timer <= self.state.lowTimeThreshold and Theme.LowTime or Theme.Info

	-- Buscar StatusRow
	local statusRow = self.currentCard:FindFirstChild("StatusRow")
	if statusRow then
		-- Actualizar texto del timer
		for _, child in ipairs(statusRow:GetChildren()) do
			if child:IsA("TextLabel") then
				local hasGradient = child:FindFirstChildOfClass("UIGradient")
				if hasGradient then
					-- Es el timer
					RoUI.updateProps(child, {
						Text = timerText,
						TextColor3 = timerColor
					})
				end
			end
		end
	end

	-- Actualizar barra de progreso con animación usando RoUI.animate
	local progressBar = self.currentCard:FindFirstChild("ProgressBar")
	if progressBar then
		local fill = progressBar:FindFirstChild("Fill")
		if fill then
			RoUI.animate(fill, {
				Size = UDim2.new(progress, 0, 1, 0)
			}, {
				duration = 0.8,
				style = Enum.EasingStyle.Linear,
				direction = Enum.EasingDirection.Out,
			}):play()
		end
	end
end

-- API pública: Toggle visibilidad del HUD
function GameView:ToggleHUD()
	self.state.hudVisible = not self.state.hudVisible
	
	-- Animar el contenedor completo (card + botón juntos) usando RoUI
	if self.currentContainer then
		local visiblePosition = UDim2.new(0.5, 0, 0.06, 0)
		local hiddenPosition = UDim2.new(0.5, 0, -0.25, 0)
		
		local targetPosition = self.state.hudVisible and visiblePosition or hiddenPosition
		
		RoUI.animate(self.currentContainer, {
			Position = targetPosition
		}, {
			duration = 0.4,
			style = Enum.EasingStyle.Back,
			direction = Enum.EasingDirection.Out,
		}):play()
	end
	
	-- Actualizar el texto del botón
	if self.toggleButton then
		self.toggleButton.Text = self.state.hudVisible and "▼" or "▲"
	end
end

-- API pública: Actualizar estado del juego
function GameView:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.state.state = newState
	self.state.timer = timer
	self.state.round = round
	-- Actualizar maxTimer si se proporciona, si no, usar el timer como maxTimer
	self.state.maxTimer = maxTimer or timer

	-- Cambio de estado requiere re-render completo (color de barra cambia)
	self:_render()
	self:StartCountdown(timer)
end

-- API pública: Actualizar solo timer
function GameView:UpdateTimer(timer: number, maxTimer: number?)
	self.state.timer = timer
	if maxTimer then
		self.state.maxTimer = maxTimer
	end

	self:StartCountdown(timer)
end

-- Iniciar countdown interno
function GameView:StartCountdown(initialTime: number)
	-- Cancelar countdown anterior
	if self.countdownTask then
		task.cancel(self.countdownTask)
	end

	self.state.timer = initialTime

	-- Iniciar nuevo countdown
	self.countdownTask = task.spawn(function()
		local current = initialTime
		while current > 0 do
			task.wait(1)
			current = current - 1
			self.state.timer = current
			-- Actualización eficiente: solo el timer
			self:_updateTimerOnly()
		end
	end)
end

-- Destruir
function GameView:Destroy()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end

	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return GameView
