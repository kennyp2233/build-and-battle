-- GameStateHUD.luau
-- Componente visual del HUD del estado del juego
-- RESPONSABILIDAD: Renderizar UI, manejar animaciones y toggle de visibilidad
-- NO contiene lógica de negocio (countdown, eventos del servidor)

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStateCard = require(script.Parent.GameStateCard)

local GameStateHUD = {}
GameStateHUD.__index = GameStateHUD

-- ============================================================================
-- CONSTANTES
-- ============================================================================

local VISIBLE_POSITION = UDim2.new(0.5, 0, 0.02, 0)
local HIDDEN_POSITION = UDim2.new(0.5, 0, 0, -180)

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function GameStateHUD.new(parent: Instance)
	local self = setmetatable({}, GameStateHUD)
	
	-- Estado visual interno (NO lógica de negocio)
	self.state = {
		state = "Intermission",
		timer = 30,
		round = nil,
		maxTimer = 30,
		lowTimeThreshold = 10,
		visible = true,
	}
	
	-- Referencias a elementos UI
	self.container = nil
	self.card = nil
	self.toggleButton = nil
	
	-- Crear UI inicial
	self:_createUI(parent)
	
	return self
end

-- ============================================================================
-- CREACIÓN DE UI
-- ============================================================================

function GameStateHUD:_createUI(parent: Instance)
	-- Crear children del card
	local hudCardChildren = GameStateCard({
		state = self.state.state,
		timer = self.state.timer,
		maxTimer = self.state.maxTimer,
		round = self.state.round,
		lowTimeThreshold = self.state.lowTimeThreshold,
	})
	
	-- Agregar UISizeConstraint
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(300, 0)
	table.insert(hudCardChildren, sizeConstraint)
	
	-- Crear card
	self.card = RoUI.Frame({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 124),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		children = hudCardChildren
	})
	
	-- Crear botón de toggle
	self.toggleButton = RoUI.TextButton({
		Name = "ToggleButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 124),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Text = self.state.visible and "▲" or "▼",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		children = {
			RoUI.stroke(1, Theme.CardStroke, 0.2),
			RoUI.corner(10),
		}
	})
	
	-- Animación hover del botón
	self.toggleButton.MouseEnter:Connect(function()
		RoUI.animate(self.toggleButton, {
			BackgroundColor3 = Theme.Primary,
			Size = UDim2.new(0, 44, 0, 44)
		}, {
			duration = 0.2,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out,
		}):play()
	end)
	
	self.toggleButton.MouseLeave:Connect(function()
		RoUI.animate(self.toggleButton, {
			BackgroundColor3 = Theme.Card,
			Size = UDim2.new(0, 40, 0, 40)
		}, {
			duration = 0.2,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out,
		}):play()
	end)
	
	-- Conectar toggle
	self.toggleButton.Activated:Connect(function()
		self:Toggle()
	end)
	
	-- Crear contenedor
	self.container = RoUI.Frame({
		Name = "GameStateHUD",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 172),
		Position = VISIBLE_POSITION,
		BackgroundTransparency = 1,
		children = {
			self.card,
			self.toggleButton,
		}
	})
	
	self.container.Parent = parent
end

-- ============================================================================
-- INTERACCIONES DE USUARIO
-- ============================================================================

-- Toggle visibilidad del HUD (animación)
function GameStateHUD:Toggle()
	self.state.visible = not self.state.visible
	
	local targetPosition = self.state.visible and VISIBLE_POSITION or HIDDEN_POSITION
	
	RoUI.animate(self.container, {
		Position = targetPosition
	}, {
		duration = 0.4,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	}):play()
	
	-- Actualizar texto del botón
	self.toggleButton.Text = self.state.visible and "▲" or "▼"
end

-- ============================================================================
-- API PÚBLICA - Actualización desde Controller
-- ============================================================================

-- Actualizar estado del juego completo (re-renderiza toda la UI)
function GameStateHUD:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.state.state = newState
	self.state.timer = timer
	self.state.round = round
	self.state.maxTimer = maxTimer or timer
	
	-- Re-render completo
	if self.container then
		local parent = self.container.Parent
		self.container:Destroy()
		self:_createUI(parent)
	end
end

-- Actualizar solo el timer (optimizado, no re-renderiza todo)
function GameStateHUD:UpdateTimer(timer: number, maxTimer: number?)
	self.state.timer = timer
	if maxTimer then
		self.state.maxTimer = maxTimer
	end
	
	self:_updateTimerOnly()
end

-- ============================================================================
-- MÉTODOS PRIVADOS - Actualización optimizada
-- ============================================================================

-- Actualización rápida solo del timer y progress bar
function GameStateHUD:_updateTimerOnly()
	if not self.card then return end
	
	local timer = self.state.timer
	local maxTimer = self.state.maxTimer
	local progress = math.clamp(timer / maxTimer, 0, 1)
	local timerText = string.format("%02d:%02d", math.floor(timer / 60), timer % 60)
	local timerColor = timer <= self.state.lowTimeThreshold and Theme.LowTime or Theme.Info
	
	-- Buscar StatusRow
	local statusRow = self.card:FindFirstChild("StatusRow")
	if statusRow then
		for _, child in ipairs(statusRow:GetChildren()) do
			if child:IsA("TextLabel") then
				local hasGradient = child:FindFirstChildOfClass("UIGradient")
				if hasGradient then
					RoUI.updateProps(child, {
						Text = timerText,
						TextColor3 = timerColor
					})
				end
			end
		end
	end
	
	-- Actualizar barra de progreso
	local progressBar = self.card:FindFirstChild("ProgressBar")
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

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Destruir componente y liberar recursos
function GameStateHUD:Destroy()
	if self.container then
		self.container:Destroy()
	end
end

return GameStateHUD
