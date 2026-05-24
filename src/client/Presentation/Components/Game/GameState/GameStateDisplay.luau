-- GameStateDisplay.luau
-- Componente para mostrar el estado actual del juego

local RoUI = require(script.Parent.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)

local function GameStateDisplay(props: {state: string})
	return RoUI.TextLabel({
		Name = "StateDisplay",
		Text = props.state:upper(),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		TextColor3 = Theme.TextMain,
		Font = Theme.Font,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
	})
end

return GameStateDisplay
