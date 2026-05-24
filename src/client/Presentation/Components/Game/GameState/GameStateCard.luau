-- GameStateCard.luau
-- Tarjeta del HUD que muestra el estado del juego, timer y progreso

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStatusRow = require(script.Parent.GameStatusRow)
local GameStateDisplay = require(script.Parent.GameStateDisplay)
local ProgressBar = require(script.Parent.Parent.Parent.Shared.ProgressBar)

local function GameStateCard(props: {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number
})
	local progress = math.clamp(props.timer / props.maxTimer, 0, 1)
	local timerColor = props.timer <= props.lowTimeThreshold and Theme.LowTime or Theme.Info
	local timerText = string.format("%02d:%02d", math.floor(props.timer / 60), props.timer % 60)

	-- Color de progreso según estado
	local progressColor = Theme.Neutral
	if props.state == "Intermission" then
		progressColor = Theme.GradientA
	elseif props.state == "Building" then
		progressColor = Theme.Success
	elseif props.state == "Battle" then
		progressColor = Theme.Danger
	end

	return {
		RoUI.stroke(1, Theme.CardStroke, 0.2),
		RoUI.corner(14),
		RoUI.padding(16),
		RoUI.listLayout(Enum.FillDirection.Vertical, 8),
		GameStatusRow({
			state = props.state,
			round = props.round,
			timerText = timerText,
			timerColor = timerColor,
		}),
		GameStateDisplay({ state = props.state }),
		ProgressBar({ progress = progress, color = progressColor }),
	}
end

return GameStateCard
