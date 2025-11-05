-- Badge.luau
-- Componente reutilizable de badge/etiqueta

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

local function Badge(props: {text: string, bgColor: Color3?, textColor: Color3?})
	return RoUI.TextLabel({
		Text = props.text,
		Size = UDim2.new(0.38, 0, 1, 0),
		BackgroundColor3 = props.bgColor or Theme.ProgressBG,
		TextColor3 = props.textColor or Theme.TextMain,
		Font = Theme.Font,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		children = {
			RoUI.corner(10),
			RoUI.stroke(1, Theme.CardStroke, 0.4),
		}
	})
end

return Badge
