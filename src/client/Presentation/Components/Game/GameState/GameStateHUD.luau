-- GameStateHUD.luau
-- React function component: HUD como NOTCH retro (Studio Grey 2010-2013).
--
-- Forma: pegado al top del screen, esquinas superiores rectas (off-screen),
-- esquinas inferiores redondeadas. Look "panel de Studio viejo" —
-- charcoal solid + bordes con bevel duro + sin gradiente.
--
-- Truco del notch sin 9-slice:
--   - Position.Y.Offset = -Radius (frame sube por encima del top edge)
--   - UICorner aplicado a las 4 esquinas, pero las superiores quedan fuera
--     del viewport y nadie las ve
--   - UIPadding.PaddingTop = Radius compensa para que el contenido empiece
--     en el visible top (Y=0 del screen)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local GameStateCard = require(script.Parent.GameStateCard)

local e = React.createElement

local CARD_WIDTH_SCALE = 0.42
local CARD_MIN_WIDTH = 380
local CARD_MAX_WIDTH = 560
local NOTCH_RADIUS = Theme.Radius.lg

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
		-- Y = -NOTCH_RADIUS: el frame sube por encima del screen top.
		-- Sus esquinas superiores (que UICorner redondea) quedan off-screen,
		-- resultado visible: top recto pegado al edge, bottom redondeado.
		Position = UDim2.new(0.5, 0, 0, -NOTCH_RADIUS),
		Size = UDim2.new(CARD_WIDTH_SCALE, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Retro.PanelBG,
		BorderSizePixel = 0,
		-- Clip para que los bevel strips sigan el contorno redondeado de la base
		ClipsDescendants = true,
	}, {
		SizeConstraint = e("UISizeConstraint", {
			MinSize = Vector2.new(CARD_MIN_WIDTH, 0),
			MaxSize = Vector2.new(CARD_MAX_WIDTH, math.huge),
		}),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, NOTCH_RADIUS),
		}),
		-- Borde exterior duro (1px) — característico de los paneles de Studio
		OuterStroke = e("UIStroke", {
			Color = Theme.Retro.BorderOuter,
			Thickness = 1,
			Transparency = 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		-- Compensa el offset negativo: contenido arranca en Y=0 del screen
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, NOTCH_RADIUS),
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
