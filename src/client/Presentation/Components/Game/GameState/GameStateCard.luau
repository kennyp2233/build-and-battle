-- GameStateCard.luau
-- React function component: contenido del notch HUD (retro Studio Grey).
--
-- Layout single-row:
--   ┌──────────────────────────────────────────────────┐
--   │ [🔨 BUILDING]      02:32          ROUND 1         │
--   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░                │
--   └──────────────────────────────────────────────────┘
--
-- BG transparente — el wrapper (GameStateHUD) provee el panel charcoal.
-- Font SourceSansBold + Code para el timer (mono, vibe terminal/Studio).

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
	local timerColor = isLowTime and Theme.LowTime or Theme.Retro.TextMain
	local progress = math.clamp(props.timer / math.max(props.maxTimer, 1), 0, 1)

	local badgeRef = React.useRef(nil :: TextLabel?)
	local fillRef = React.useRef(nil :: Frame?)
	local timerScaleRef = React.useRef(nil :: UIScale?)

	-- Tween de colores al cambiar fase (badge + progress fill)
	React.useEffect(function()
		local p = Theme.getPhase(props.state)
		local info = TweenInfo.new(TRANSITION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
		-- Padding lateral = 16px > radio del notch (14px): la progress bar
		-- nunca entra en la zona de curvatura de los corners inferiores.
		-- PaddingBottom = 6 para idéntico cálculo vertical (seguro en z=córner).
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.Spacing.sm),
			PaddingBottom = UDim.new(0, 6),
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
					-- Solo texto — old Roblox no usaba emojis en UI.
					-- Si querés cue visual por fase, usar un sprite/ImageLabel.
					text = props.state:upper(),
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
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0.2,
				Font = Theme.FontMono,
				TextSize = Theme.TextSize.xl,
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
				Size = UDim2.new(0, 90, 0, 22),
				BackgroundTransparency = 1,
				-- Amarillo Robux-style + outline negro nativo: signature
				-- retro de leaderstats/chat names del Roblox viejo
				TextColor3 = Theme.Retro.TextAccent,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0.2,
				Font = Theme.Font,
				TextSize = Theme.TextSize.sm,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),

		Progress = e(ProgressBar, {
			progress = progress,
			color = phase.accent,
			height = 8,
			layoutOrder = 2,
			fillRef = fillRef,
		}),
	})
end

return GameStateCard
