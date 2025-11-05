-- StatusRow.luau
-- Componente que muestra el estado, round y timer en una fila

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)
local Badge = require(script.Parent.Parent.Shared.Badge)
local Timer = require(script.Parent.Parent.Shared.Timer)

local function StatusRow(props: {
	state: string,
	round: number?,
	timerText: string,
	timerColor: Color3
})
	local roundText = props.round and ("Round " .. props.round) or ""

	return RoUI.Frame({
		Name = "StatusRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		children = {
			RoUI.listLayout(Enum.FillDirection.Horizontal, 8),
			Badge({ text = props.state, bgColor = Theme.ProgressBG }),
			RoUI.TextLabel({
				Text = roundText,
				Size = UDim2.new(0.25, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Theme.TextSub,
				Font = Theme.FontCondensed,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
			Timer({ text = props.timerText, textColor = props.timerColor }),
		}
	})
end

return StatusRow
