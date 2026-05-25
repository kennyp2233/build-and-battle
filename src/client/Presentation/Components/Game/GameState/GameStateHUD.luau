-- GameStateHUD.luau
-- React function component: el wrapper visual completo del HUD.
-- BackgroundColor3 = white para que el UIGradient defina los colores reales
-- (UIGradient multiplica con el BG — si pones dark × dark, no se nota).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStateCard = require(script.Parent.GameStateCard)

local e = React.createElement

local CARD_WIDTH_SCALE = 0.42
local CARD_MIN_WIDTH = 380
local CARD_MAX_WIDTH = 560

export type GameStateHUDProps = {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number?,
}

local function GameStateHUD(props: GameStateHUDProps)
	return e("Frame", {
		Name = "GameStateHUD",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(CARD_WIDTH_SCALE, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.02, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, {
		SizeConstraint = e("UISizeConstraint", {
			MinSize = Vector2.new(CARD_MIN_WIDTH, 0),
			MaxSize = Vector2.new(CARD_MAX_WIDTH, math.huge),
		}),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.lg),
		}),
		Gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 30, 36)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 22, 26)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 20)),
			}),
			Rotation = 90,
		}),
		Card = e(GameStateCard, {
			state = props.state,
			timer = props.timer,
			maxTimer = props.maxTimer,
			round = props.round,
			lowTimeThreshold = props.lowTimeThreshold or 10,
		}),
	})
end

return GameStateHUD
