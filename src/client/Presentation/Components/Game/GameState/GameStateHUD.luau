-- GameStateHUD.luau
-- HUD del estado del juego. Mantiene una sola GameStateCard y la mutates en vez de
-- destruirla y recrearla cada cambio de fase — preserva animaciones, hover, y el
-- estado del toggle de visibilidad.

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStateCard = require(script.Parent.GameStateCard)

local GameStateHUD = {}
GameStateHUD.__index = GameStateHUD

local VISIBLE_POSITION = UDim2.new(0.5, 0, 0.02, 0)
local HIDDEN_POSITION = UDim2.new(0.5, 0, 0, -180)

local DEFAULT_LOW_TIME_THRESHOLD = 10

function GameStateHUD.new(parent: Instance)
	local self = setmetatable({}, GameStateHUD)

	self.state = {
		state = "Intermission",
		timer = 30,
		round = nil :: number?,
		maxTimer = 30,
		lowTimeThreshold = DEFAULT_LOW_TIME_THRESHOLD,
		visible = true,
	}

	self:_createUI(parent)
	return self
end

function GameStateHUD:_createUI(parent: Instance)
	-- Card con refs (no se destruye en updates)
	self.card = GameStateCard.new({
		state = self.state.state,
		timer = self.state.timer,
		maxTimer = self.state.maxTimer,
		round = self.state.round,
		lowTimeThreshold = self.state.lowTimeThreshold,
	})

	-- Frame externo que posiciona la card
	self.cardFrame = RoUI.Frame({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 124),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		children = {
			RoUI.sizeConstraint(Vector2.new(300, 0)),
			self.card.root,
		},
	})

	-- Toggle button
	self.toggleButton = RoUI.TextButton({
		Name = "ToggleButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 124),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Text = self.state.visible and "▲" or "▼",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = Theme.TextSize.lg,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		children = {
			RoUI.stroke(Theme.Stroke.thin, Theme.CardStroke, 0.2),
			RoUI.corner(Theme.Radius.md),
		},
	})

	self.toggleButton.MouseEnter:Connect(function()
		RoUI.animate(self.toggleButton, {
			BackgroundColor3 = Theme.Primary,
			Size = UDim2.new(0, 44, 0, 44),
		}, {
			duration = 0.2,
		}):play()
	end)

	self.toggleButton.MouseLeave:Connect(function()
		RoUI.animate(self.toggleButton, {
			BackgroundColor3 = Theme.Card,
			Size = UDim2.new(0, 40, 0, 40),
		}, {
			duration = 0.2,
		}):play()
	end)

	self.toggleButton.Activated:Connect(function()
		self:Toggle()
	end)

	self.container = RoUI.Frame({
		Name = "GameStateHUD",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 172),
		Position = VISIBLE_POSITION,
		BackgroundTransparency = 1,
		children = {
			self.cardFrame,
			self.toggleButton,
		},
	})

	self.container.Parent = parent
end

-- ============================================================================
-- INTERACTION
-- ============================================================================

function GameStateHUD:Toggle()
	self.state.visible = not self.state.visible
	local target = self.state.visible and VISIBLE_POSITION or HIDDEN_POSITION

	RoUI.animate(self.container, { Position = target }, {
		duration = 0.4,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	}):play()

	self.toggleButton.Text = self.state.visible and "▲" or "▼"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function GameStateHUD:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.state.state = newState
	self.state.timer = timer
	self.state.round = round
	self.state.maxTimer = maxTimer or timer

	-- Actualización parcial — no destruye el container ni el toggle state
	self.card:UpdateState(newState, timer, round, self.state.maxTimer)
end

function GameStateHUD:UpdateTimer(timer: number, maxTimer: number?)
	self.state.timer = timer
	if maxTimer then
		self.state.maxTimer = maxTimer
	end
	self.card:UpdateTimer(timer, self.state.maxTimer)
end

function GameStateHUD:Destroy()
	if self.card then
		self.card:Destroy()
		self.card = nil
	end
	if self.container then
		self.container:Destroy()
		self.container = nil
	end
end

return GameStateHUD
