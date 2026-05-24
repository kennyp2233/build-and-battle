-- ProgressBar.luau
-- Barra de progreso. El color se aplica al Fill (visible). El gradient theme es opt-in
-- vía `withGradient` — antes era forzado y tapaba el `color`.

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

export type ProgressBarProps = {
	progress: number,
	color: Color3,
	withGradient: boolean?,
	height: number?,
}

local function ProgressBar(props: ProgressBarProps): Frame
	local fillChildren: { Instance } = {
		RoUI.corner(Theme.Radius.sm),
	}
	if props.withGradient then
		table.insert(fillChildren, RoUI.gradient(Theme.GradientA, Theme.GradientB, 0))
	end

	local fillFrame = RoUI.Frame({
		Name = "Fill",
		BackgroundColor3 = props.color,
		Size = UDim2.new(math.clamp(props.progress, 0, 1), 0, 1, 0),
		BorderSizePixel = 0,
		children = fillChildren,
	})

	return RoUI.Frame({
		Name = "ProgressBar",
		BackgroundColor3 = Theme.ProgressBG,
		Size = UDim2.new(1, 0, 0, props.height or 16),
		BorderSizePixel = 0,
		children = {
			RoUI.corner(Theme.Radius.sm),
			RoUI.stroke(Theme.Stroke.thin, Theme.CardStroke, 0.4),
			fillFrame,
		},
	})
end

return ProgressBar
