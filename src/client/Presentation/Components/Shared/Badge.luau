-- Badge.luau
-- Etiqueta visual con borde y texto. Size override-able vía prop.

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

export type BadgeProps = {
	text: string,
	bgColor: Color3?,
	textColor: Color3?,
	size: UDim2?,
	layoutOrder: number?,
	name: string?,
}

local function Badge(props: BadgeProps): TextLabel
	return RoUI.TextLabel({
		Name = props.name or "Badge",
		Text = props.text,
		Size = props.size or UDim2.new(0.38, 0, 1, 0),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = props.bgColor or Theme.ProgressBG,
		TextColor3 = props.textColor or Theme.TextMain,
		Font = Theme.Font,
		TextSize = Theme.TextSize.md,
		TextXAlignment = Enum.TextXAlignment.Center,
		children = {
			RoUI.corner(Theme.Radius.md),
			RoUI.stroke(Theme.Stroke.thin, Theme.CardStroke, 0.4),
		},
	})
end

return Badge
