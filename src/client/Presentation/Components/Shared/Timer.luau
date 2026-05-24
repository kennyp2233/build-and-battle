-- Timer.luau
-- TextLabel para tiempo. Tiene Name="Timer" estable para que callers lo encuentren por ref.

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

export type TimerProps = {
	text: string,
	textColor: Color3?,
	size: UDim2?,
	layoutOrder: number?,
	withGradient: boolean?,
}

local function Timer(props: TimerProps): TextLabel
	local children = {
		RoUI.corner(Theme.Radius.md),
		RoUI.stroke(Theme.Stroke.thin, Theme.CardStroke, 0.4),
	}
	-- El gradient era opcional pero antes era forzado: lo movemos a opt-in.
	if props.withGradient then
		table.insert(children, RoUI.gradient(Theme.GradientA, Theme.GradientB, 0))
	end

	return RoUI.TextLabel({
		Name = "Timer",
		Text = props.text,
		Size = props.size or UDim2.new(0.32, 0, 1, 0),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = Theme.ProgressBG,
		TextColor3 = props.textColor or Theme.Info,
		Font = Theme.Font,
		TextSize = Theme.TextSize.lg,
		TextXAlignment = Enum.TextXAlignment.Center,
		children = children,
	})
end

return Timer
