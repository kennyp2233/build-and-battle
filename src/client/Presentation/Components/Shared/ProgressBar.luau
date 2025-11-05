-- ProgressBar.luau
-- Componente reutilizable de barra de progreso con animación

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

export type ProgressBarProps = {
	progress: number,
	color: Color3,
	animated: boolean?,
	duration: number?,
	style: Enum.EasingStyle?,
}

local function ProgressBar(props: ProgressBarProps)
	-- Valores por defecto
	local animated = if props.animated ~= nil then props.animated else true
	local duration = props.duration or 0.8
	local style = props.style or Enum.EasingStyle.Linear
	
	local fillFrame = RoUI.Frame({
		Name = "Fill",
		BackgroundColor3 = props.color,
		Size = UDim2.new(props.progress, 0, 1, 0),
		BorderSizePixel = 0,
		children = {
			RoUI.corner(8),
			RoUI.gradient(Theme.GradientA, Theme.GradientB, 0),
		}
	})

	return RoUI.Frame({
		Name = "ProgressBar",
		BackgroundColor3 = Theme.ProgressBG,
		Size = UDim2.new(1, 0, 0, 16),
		BorderSizePixel = 0,
		children = {
			RoUI.corner(8),
			RoUI.stroke(1, Theme.CardStroke, 0.4),
			fillFrame,
		}
	})
end

return ProgressBar
