-- Timer.luau
-- Componente reutilizable de temporizador

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

local function Timer(props: {text: string, textColor: Color3?})
	return RoUI.TextLabel({
		Text = props.text,
		Size = UDim2.new(0.32, 0, 1, 0),
		BackgroundColor3 = Theme.ProgressBG,
		TextColor3 = props.textColor or Theme.Info,
		Font = Theme.Font,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		children = {
			RoUI.corner(10),
			RoUI.stroke(1, Theme.CardStroke, 0.4),
			RoUI.gradient(Theme.GradientA, Theme.GradientB, 0),
		}
	})
end

return Timer
