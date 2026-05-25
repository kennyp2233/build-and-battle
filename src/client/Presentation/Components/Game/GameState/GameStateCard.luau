-- GameStateCard.luau
-- React function component: HUD compacto en una sola fila.
--
-- Estructura:
--   ┌──────────────────────────────────────────────────┐
--   │ 🔨 BUILDING       02:32           ROUND 1         │  ← una fila
--   │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░       │  ← progress fino
--   └──────────────────────────────────────────────────┘
--
-- El time queda prominente sin convertirse en banner. La fase se identifica
-- por el badge tinted + glow de color. El subtítulo se eliminó: si lo querés
-- de vuelta, hace falta un overlay separado que aparezca solo al cambio de fase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Parent.Parent.Core.Theme)
local UIHelpers = require(script.Parent.Parent.Parent.Parent.Utils.UIHelpers)
local Badge = require(script.Parent.Parent.Parent.Shared.Badge)
local ProgressBar = require(script.Parent.Parent.Parent.Shared.ProgressBar)

local e = React.createElement

local TRANSITION_DURATION = 0.35
local PULSE_DURATION = 0.6
local PULSE_TARGET_SCALE = 1.15

local ROW_HEIGHT = 40

export type GameStateCardProps = {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number,
}

local function GameStateCard(props: GameStateCardProps)
	local phase = Theme.getPhase(props.state)
	local isLowTime = props.timer <= props.lowTimeThreshold and props.timer > 0
	local timerColor = isLowTime and Theme.LowTime or Theme.TextMain
	local progress = math.clamp(props.timer / math.max(props.maxTimer, 1), 0, 1)

	local glowRef = React.useRef(nil :: UIStroke?)
	local badgeRef = React.useRef(nil :: TextLabel?)
	local fillRef = React.useRef(nil :: Frame?)
	local timerScaleRef = React.useRef(nil :: UIScale?)

	-- Tween de colores al cambiar fase
	React.useEffect(function()
		local p = Theme.getPhase(props.state)
		local info = TweenInfo.new(TRANSITION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if glowRef.current then
			TweenService:Create(glowRef.current, info, { Color = p.accentGlow }):Play()
		end
		if badgeRef.current then
			TweenService:Create(badgeRef.current, info, {
				BackgroundColor3 = p.badgeBg,
				TextColor3 = p.badgeText,
			}):Play()
		end
		if fillRef.current then
			TweenService:Create(fillRef.current, info, { BackgroundColor3 = p.accent }):Play()
		end
	end, { props.state } :: { any })

	-- Pulse infinito mientras isLowTime
	React.useEffect(function()
		if not isLowTime then
			return
		end
		local scale = timerScaleRef.current
		if not scale then
			return
		end
		local info = TweenInfo.new(
			PULSE_DURATION,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true,
			0
		)
		local tween = TweenService:Create(scale, info, { Scale = PULSE_TARGET_SCALE })
		tween:Play()
		return function()
			tween:Cancel()
			if scale and scale.Parent then
				scale.Scale = 1
			end
		end
	end, { isLowTime } :: { any })

	return e("Frame", {
		Name = "CardContent",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.lg) }),
		Glow = e("UIStroke", {
			ref = glowRef,
			Color = phase.accentGlow,
			Thickness = 2,
			Transparency = 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.Spacing.md),
			PaddingBottom = UDim.new(0, Theme.Spacing.md),
			PaddingLeft = UDim.new(0, Theme.Spacing.lg),
			PaddingRight = UDim.new(0, Theme.Spacing.lg),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, Theme.Spacing.sm),
		}),

		-- ── Fila única: badge izq | TIME centro | round der ─────────────────
		Row = e("Frame", {
			Name = "Row",
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			BadgeWrapper = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
			}, {
				Badge = e(Badge, {
					text = phase.icon .. "  " .. props.state:upper(),
					bgColor = phase.badgeBg,
					textColor = phase.badgeText,
					labelRef = badgeRef,
				}),
			}),

			Time = e("TextLabel", {
				Name = "Time",
				Text = UIHelpers.formatTime(props.timer),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 140, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = timerColor,
				Font = Enum.Font.RobotoMono,
				TextSize = Theme.TextSize.xxl,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, {
				Scale = e("UIScale", { ref = timerScaleRef, Scale = 1 }),
			}),

			Round = e("TextLabel", {
				Name = "Round",
				Text = props.round and ("ROUND " .. props.round) or "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 80, 0, 22),
				BackgroundTransparency = 1,
				TextColor3 = Theme.TextSub,
				Font = Theme.FontCondensed,
				TextSize = Theme.TextSize.xs,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),

		Progress = e(ProgressBar, {
			progress = progress,
			color = phase.accent,
			height = 4,
			layoutOrder = 2,
			fillRef = fillRef,
		}),
	})
end

return GameStateCard
