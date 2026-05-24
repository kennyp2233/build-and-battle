-- GameStateCard.luau
-- Card con state badge + round + timer + state display + progress bar.
-- Clase con refs internas para hacer actualizaciones parciales sin destruir y recrear.
--
-- API:
--   local card = GameStateCard.new({ state, timer, maxTimer, round, lowTimeThreshold })
--   card:UpdateState(state, timer, round, maxTimer)  -- cambio de fase
--   card:UpdateTimer(timer, maxTimer)                -- cada segundo
--   card.root                                         -- la instancia para parentear

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local UIHelpers = require(script.Parent.Parent.Parent.Parent.Utils.UIHelpers)
local Badge = require(script.Parent.Parent.Parent.Shared.Badge)
local Timer = require(script.Parent.Parent.Parent.Shared.Timer)
local ProgressBar = require(script.Parent.Parent.Parent.Shared.ProgressBar)
local GameStateDisplay = require(script.Parent.GameStateDisplay)

export type GameStateCardProps = {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number,
}

local GameStateCard = {}
GameStateCard.__index = GameStateCard

local function progressColorForState(state: string): Color3
	if state == "Intermission" then
		return Theme.GradientA
	elseif state == "Building" then
		return Theme.Success
	elseif state == "Battle" then
		return Theme.Danger
	end
	return Theme.Neutral
end

function GameStateCard.new(props: GameStateCardProps)
	local self = setmetatable({}, GameStateCard)

	self.lowTimeThreshold = props.lowTimeThreshold

	local timerText = UIHelpers.formatTime(props.timer)
	local timerColor = props.timer <= props.lowTimeThreshold and Theme.LowTime or Theme.Info
	local progress = math.clamp(props.timer / math.max(props.maxTimer, 1), 0, 1)
	local fillColor = progressColorForState(props.state)

	self.badge = Badge({
		text = props.state,
		bgColor = Theme.ProgressBG,
		layoutOrder = 1,
	})

	self.roundLabel = RoUI.TextLabel({
		Name = "Round",
		Text = props.round and ("Round " .. props.round) or "",
		Size = UDim2.new(0.25, 0, 1, 0),
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		TextColor3 = Theme.TextSub,
		Font = Theme.FontCondensed,
		TextSize = Theme.TextSize.sm,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	self.timer = Timer({
		text = timerText,
		textColor = timerColor,
		layoutOrder = 3,
	})

	self.stateDisplay = GameStateDisplay({ state = props.state })

	-- ProgressBar es una función, retorna un Frame. Necesitamos guardar el Fill interno.
	self.progressBar = ProgressBar({
		progress = progress,
		color = fillColor,
	})
	self.progressFill = self.progressBar:FindFirstChild("Fill")

	local statusRow = RoUI.Frame({
		Name = "StatusRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 1,
		children = {
			RoUI.listLayout(Enum.FillDirection.Horizontal, Theme.Spacing.sm),
			self.badge,
			self.roundLabel,
			self.timer,
		},
	})
	self.stateDisplay.LayoutOrder = 2
	self.progressBar.LayoutOrder = 3

	self.root = RoUI.Frame({
		Name = "CardContent",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		children = {
			RoUI.stroke(Theme.Stroke.thin, Theme.CardStroke, 0.2),
			RoUI.corner(Theme.Radius.lg),
			RoUI.padding(Theme.Spacing.lg),
			RoUI.listLayout(Enum.FillDirection.Vertical, Theme.Spacing.sm),
			statusRow,
			self.stateDisplay,
			self.progressBar,
		},
	})

	return self
end

-- Cambio de fase (state nuevo, timer reset, posiblemente nueva round)
function GameStateCard:UpdateState(state: string, timer: number, round: number?, maxTimer: number)
	self.badge.Text = state
	self.stateDisplay.Text = state:upper()
	self.roundLabel.Text = round and ("Round " .. round) or ""

	if self.progressFill then
		self.progressFill.BackgroundColor3 = progressColorForState(state)
	end

	self:UpdateTimer(timer, maxTimer)
end

-- Tick del countdown (sin animación: el countdown del controller actualiza cada 0.1s,
-- animar cada cambio causa solapamiento visual)
function GameStateCard:UpdateTimer(timer: number, maxTimer: number)
	self.timer.Text = UIHelpers.formatTime(timer)
	self.timer.TextColor3 = timer <= self.lowTimeThreshold and Theme.LowTime or Theme.Info

	if self.progressFill then
		local progress = math.clamp(timer / math.max(maxTimer, 1), 0, 1)
		self.progressFill.Size = UDim2.new(progress, 0, 1, 0)
	end
end

function GameStateCard:Destroy()
	if self.root then
		self.root:Destroy()
		self.root = nil
	end
end

return GameStateCard
