-- GameStateCard.luau
-- React function component. Layout premium con time XL centrado, badge+round arriba,
-- progress bar fino, subtitle de fase.
--
-- Animaciones imperativas via useEffect:
-- - Low-time pulse: UIScale tweenea infinito mientras timer <= threshold
-- - Phase transitions: tween de colores en badge/glow/progress al cambiar de state

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
local PULSE_TARGET_SCALE = 1.12

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

	-- Refs para animaciones imperativas (tween de propiedades sin perder identidad)
	local glowRef = React.useRef(nil :: UIStroke?)
	local badgeRef = React.useRef(nil :: TextLabel?)
	local fillRef = React.useRef(nil :: Frame?)
	local timerScaleRef = React.useRef(nil :: UIScale?)

	-- Phase transition: tween colores al cambiar state
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

	-- Low-time pulse infinito mientras isLowTime sea true; cleanup automático al cambiar
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
			-1, -- infinite
			true, -- reverses
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
			Thickness = 3,
			Transparency = 0.3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.Spacing.xl),
			PaddingBottom = UDim.new(0, Theme.Spacing.xl),
			PaddingLeft = UDim.new(0, Theme.Spacing.xl),
			PaddingRight = UDim.new(0, Theme.Spacing.xl),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, Theme.Spacing.md),
		}),

		-- ── Header: badge izq + round der (absolute positioning interno) ──────
		Header = e("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			BadgeWrapper = e("Frame", {
				Name = "BadgeWrapper",
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

		-- ── TIME XL centrado, monospaced ─────────────────────────────────────
		Time = e("TextLabel", {
			Name = "Time",
			Text = UIHelpers.formatTime(props.timer),
			Size = UDim2.new(1, 0, 0, 64),
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			TextColor3 = timerColor,
			Font = Enum.Font.RobotoMono,
			TextSize = Theme.TextSize.huge,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, {
			Scale = e("UIScale", { ref = timerScaleRef, Scale = 1 }),
		}),

		-- ── Progress fino bajo el time ───────────────────────────────────────
		Progress = e(ProgressBar, {
			progress = progress,
			color = phase.accent,
			height = 5,
			layoutOrder = 3,
			fillRef = fillRef,
		}),

		-- ── Subtitle ─────────────────────────────────────────────────────────
		Subtitle = e("TextLabel", {
			Name = "Subtitle",
			Text = phase.subtitle or "",
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = 4,
			BackgroundTransparency = 1,
			TextColor3 = Theme.TextSub,
			Font = Theme.FontCondensed,
			TextSize = Theme.TextSize.sm,
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})
end

return GameStateCard
