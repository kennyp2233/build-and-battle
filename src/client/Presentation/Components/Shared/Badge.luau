-- Badge.luau
-- React function component: etiqueta tipo botón retro Roblox (~2010 Studio).
-- BG sólido + bevel 3D duro (highlight top/left + shadow bottom/right) + borde
-- exterior dark 1px + esquinas cuadradas. Acepta `labelRef` para tweens
-- imperativos del bgColor/textColor por el caller.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)

local e = React.createElement

export type BadgeProps = {
	text: string,
	bgColor: Color3?,
	textColor: Color3?,
	size: UDim2?,
	automaticSize: Enum.AutomaticSize?,
	layoutOrder: number?,
	labelRef: any?, -- React.Ref<TextLabel>
}

local function Badge(props: BadgeProps)
	return e("TextLabel", {
		Name = "Badge",
		ref = props.labelRef,
		Text = props.text,
		Size = props.size or UDim2.new(0, 0, 1, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.X,
		BackgroundColor3 = props.bgColor or Theme.ProgressBG,
		TextColor3 = props.textColor or Theme.TextMain,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 0.2,
		Font = Theme.Font,
		TextSize = Theme.TextSize.md,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = props.layoutOrder or 0,
		BorderSizePixel = 0,
	}, {
		-- Sin UICorner — old Roblox UI era pixel-square
		Stroke = e("UIStroke", {
			Color = Theme.Retro.BorderOuter,
			Thickness = 1,
			Transparency = 0,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 3),
			PaddingBottom = UDim.new(0, 3),
		}),
	})
end

return Badge
