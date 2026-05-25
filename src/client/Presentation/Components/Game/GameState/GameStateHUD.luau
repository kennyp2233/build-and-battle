-- GameStateHUD.luau
-- Wrapper de posicionamiento del GameStateCard. Sin toggle (premium siempre visible).
-- Si más adelante quieres ocultar el HUD, mejor con keybind/settings que con un botón pegado.

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStateCard = require(script.Parent.GameStateCard)

local GameStateHUD = {}
GameStateHUD.__index = GameStateHUD

local POSITION = UDim2.new(0.5, 0, 0.02, 0)
local CARD_WIDTH_SCALE = 0.42
local CARD_MIN_WIDTH = 380
local CARD_MAX_WIDTH = 560

local DEFAULT_LOW_TIME_THRESHOLD = 10

function GameStateHUD.new(parent: Instance)
	local self = setmetatable({}, GameStateHUD)

	self.state = {
		state = "Intermission",
		timer = 30,
		round = nil :: number?,
		maxTimer = 30,
		lowTimeThreshold = DEFAULT_LOW_TIME_THRESHOLD,
	}

	self:_createUI(parent)
	return self
end

function GameStateHUD:_createUI(parent: Instance)
	self.card = GameStateCard.new({
		state = self.state.state,
		timer = self.state.timer,
		maxTimer = self.state.maxTimer,
		round = self.state.round,
		lowTimeThreshold = self.state.lowTimeThreshold,
	})

	-- BackgroundColor3 = white para que el UIGradient defina los colores reales
	-- (UIGradient MULTIPLICA el BackgroundColor3 — si no pones blanco, los colores
	-- del gradient se aplastan contra el bg y el efecto de profundidad se pierde).
	self.cardFrame = RoUI.Frame({
		Name = "GameStateHUD",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(CARD_WIDTH_SCALE, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = POSITION,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		children = {
			RoUI.sizeConstraint(
				Vector2.new(CARD_MIN_WIDTH, 0),
				Vector2.new(CARD_MAX_WIDTH, math.huge)
			),
			RoUI.corner(Theme.Radius.lg),
			-- Gradient vertical sutil que sí se ve (bg white permite que el gradient gane)
			RoUI.gradientMulti({
				{ offset = 0, color = Color3.fromRGB(28, 30, 36) },
				{ offset = 0.5, color = Color3.fromRGB(20, 22, 26) },
				{ offset = 1, color = Color3.fromRGB(14, 16, 20) },
			}, 90),
			self.card.root,
		},
	})

	-- El card.root necesita auto-size también para que el cardFrame conozca su altura
	self.card.root.AutomaticSize = Enum.AutomaticSize.Y
	self.card.root.Size = UDim2.new(1, 0, 0, 0)

	self.cardFrame.Parent = parent
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function GameStateHUD:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.state.state = newState
	self.state.timer = timer
	self.state.round = round
	self.state.maxTimer = maxTimer or timer

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
	if self.cardFrame then
		self.cardFrame:Destroy()
		self.cardFrame = nil
	end
end

return GameStateHUD
