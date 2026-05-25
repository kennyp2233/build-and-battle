-- Badge.luau
-- React function component: etiqueta con texto. Acepta `labelRef` para tweens
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
		Font = Theme.Font,
		TextSize = Theme.TextSize.md,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = props.layoutOrder or 0,
		BorderSizePixel = 0,
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.md),
		}),
		Stroke = e("UIStroke", {
			Color = Theme.CardStroke,
			Thickness = Theme.Stroke.thin,
			Transparency = 0.4,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	})
end

return Badge
