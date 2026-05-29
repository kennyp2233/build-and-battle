-- ProgressBar.luau
-- React function component: barra de progreso con fill coloreable.
-- Acepta `fillRef` para que el caller pueda tweenear el color del fill imperativamente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

local e = React.createElement

export type ProgressBarProps = {
	progress: number,
	color: Color3,
	height: number?,
	layoutOrder: number?,
	fillRef: any?, -- React.Ref<Frame>
}

local function ProgressBar(props: ProgressBarProps)
	local progress = math.clamp(props.progress, 0, 1)

	return e("Frame", {
		Name = "ProgressBar",
		BackgroundColor3 = Theme.Retro.InsetBG,
		Size = UDim2.new(1, 0, 0, props.height or 6),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder or 0,
	}, {
		Fill = e("Frame", {
			Name = "Fill",
			ref = props.fillRef,
			BackgroundColor3 = props.color,
			Size = UDim2.new(progress, 0, 1, 0),
			BorderSizePixel = 0,
		}),
	})
end

return ProgressBar
