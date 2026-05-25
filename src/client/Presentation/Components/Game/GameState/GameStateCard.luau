-- GameStateCard.luau
-- Layout premium para el HUD de estado del juego.
--
-- Estructura:
--   ┌─────────────────────────────────────┐
--   │ 🔨 BUILDING                  ROUND 1│  ← header (badge | round)
--   │                                     │
--   │             02:32                   │  ← TIME XL (mono, centered)
--   │ ━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░░    │  ← progress fino
--   │                                     │
--   │      Place blocks to defend         │  ← subtitle (sub-color)
--   └─────────────────────────────────────┘
--
-- API:
--   local card = GameStateCard.new({ state, timer, maxTimer, round, lowTimeThreshold })
--   card:UpdateState(state, timer, round, maxTimer)
--   card:UpdateTimer(timer, maxTimer)
--   card.root           -- frame para parentear

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local UIHelpers = require(script.Parent.Parent.Parent.Parent.Utils.UIHelpers)
local Badge = require(script.Parent.Parent.Parent.Shared.Badge)
local ProgressBar = require(script.Parent.Parent.Parent.Shared.ProgressBar)

export type GameStateCardProps = {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number,
}

local GameStateCard = {}
GameStateCard.__index = GameStateCard

local TRANSITION_DURATION = 0.35

function GameStateCard.new(props: GameStateCardProps)
	local self = setmetatable({}, GameStateCard)

	self.lowTimeThreshold = props.lowTimeThreshold
	self._lowTimePulseTween = nil

	local phase = Theme.getPhase(props.state)
	local timerText = UIHelpers.formatTime(props.timer)
	local timerColor = props.timer <= props.lowTimeThreshold and Theme.LowTime or Theme.TextMain
	local progress = math.clamp(props.timer / math.max(props.maxTimer, 1), 0, 1)

	-- ── HEADER ROW ──────────────────────────────────────────────────────────
	-- Badge a la izquierda (icon + state), round pill a la derecha.
	-- Sin listLayout en el row: posicionamos absoluto para no pelearnos con flex.
	self.badge = Badge({
		text = phase.icon .. "  " .. props.state:upper(),
		bgColor = phase.badgeBg,
		textColor = phase.badgeText,
		size = UDim2.new(0, 0, 1, 0),
	})
	self.badge.AnchorPoint = Vector2.new(0, 0.5)
	self.badge.Position = UDim2.new(0, 0, 0.5, 0)
	self.badge.AutomaticSize = Enum.AutomaticSize.X
	self.badge.TextSize = Theme.TextSize.md

	self.roundLabel = RoUI.TextLabel({
		Name = "Round",
		Text = props.round and ("ROUND " .. props.round) or "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 72, 0, 22),
		BackgroundTransparency = 1,
		TextColor3 = Theme.TextSub,
		Font = Theme.FontCondensed,
		TextSize = Theme.TextSize.xs,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local headerRow = RoUI.Frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		children = {
			self.badge,
			self.roundLabel,
		},
	})

	-- ── TIME XL ─────────────────────────────────────────────────────────────
	-- Monospaced (RobotoMono) para que los dígitos no salten de ancho.
	-- UIScale dentro para que el low-time pulse no afecte el layout vertical.
	self.timer = RoUI.TextLabel({
		Name = "Time",
		Text = timerText,
		Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		TextColor3 = timerColor,
		Font = Enum.Font.RobotoMono,
		TextSize = Theme.TextSize.huge,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	self.timerScale = Instance.new("UIScale")
	self.timerScale.Scale = 1
	self.timerScale.Parent = self.timer

	-- ── PROGRESS BAR FINO ───────────────────────────────────────────────────
	self.progressBar = ProgressBar({
		progress = progress,
		color = phase.accent,
		height = 5,
	})
	self.progressBar.LayoutOrder = 3
	self.progressFill = self.progressBar:FindFirstChild("Fill") :: Frame

	-- ── SUBTITLE ────────────────────────────────────────────────────────────
	self.subtitleLabel = RoUI.TextLabel({
		Name = "Subtitle",
		Text = phase.subtitle or "",
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 4,
		BackgroundTransparency = 1,
		TextColor3 = Theme.TextSub,
		Font = Theme.FontCondensed,
		TextSize = Theme.TextSize.sm,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- ── GLOW + CARD ROOT ────────────────────────────────────────────────────
	-- Glow más prominente (3px, 0.3 transparency) que el anterior — corona
	-- la card con el accent color de la fase, tweenable en cambios.
	self.glow = RoUI.glow(phase.accentGlow, 3, 0.3)

	self.root = RoUI.Frame({
		Name = "CardContent",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		children = {
			RoUI.corner(Theme.Radius.lg),
			self.glow,
			RoUI.padding(Theme.Spacing.xl),
			RoUI.listLayout(Enum.FillDirection.Vertical, Theme.Spacing.md),
			headerRow,
			self.timer,
			self.progressBar,
			self.subtitleLabel,
		},
	})

	return self
end

function GameStateCard:UpdateState(state: string, timer: number, round: number?, maxTimer: number)
	local phase = Theme.getPhase(state)

	self.badge.Text = phase.icon .. "  " .. state:upper()
	self.roundLabel.Text = round and ("ROUND " .. round) or ""
	self.subtitleLabel.Text = phase.subtitle or ""

	-- Transiciones suaves de color en badge + glow + progress fill
	RoUI.colorTo(self.badge, "BackgroundColor3", phase.badgeBg, TRANSITION_DURATION):play()
	RoUI.colorTo(self.badge, "TextColor3", phase.badgeText, TRANSITION_DURATION):play()
	RoUI.colorTo(self.glow, "Color", phase.accentGlow, TRANSITION_DURATION):play()
	if self.progressFill then
		RoUI.colorTo(self.progressFill, "BackgroundColor3", phase.accent, TRANSITION_DURATION):play()
	end

	self:UpdateTimer(timer, maxTimer)
end

function GameStateCard:UpdateTimer(timer: number, maxTimer: number)
	self.timer.Text = UIHelpers.formatTime(timer)

	local isLowTime = timer <= self.lowTimeThreshold and timer > 0
	self.timer.TextColor3 = isLowTime and Theme.LowTime or Theme.TextMain

	if self.progressFill then
		local progress = math.clamp(timer / math.max(maxTimer, 1), 0, 1)
		self.progressFill.Size = UDim2.new(progress, 0, 1, 0)
	end

	if isLowTime then
		self:_startLowTimePulse()
	else
		self:_stopLowTimePulse()
	end
end

function GameStateCard:_startLowTimePulse()
	if self._lowTimePulseTween then
		return
	end
	local TweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(
		0.6,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- infinite repeat
		true, -- reverses
		0
	)
	local tween = TweenService:Create(self.timerScale, tweenInfo, { Scale = 1.12 })
	tween:Play()
	self._lowTimePulseTween = tween
end

function GameStateCard:_stopLowTimePulse()
	if self._lowTimePulseTween then
		self._lowTimePulseTween:Cancel()
		self._lowTimePulseTween = nil
		self.timerScale.Scale = 1
	end
end

function GameStateCard:Destroy()
	self:_stopLowTimePulse()
	if self.root then
		self.root:Destroy()
		self.root = nil
	end
end

return GameStateCard
