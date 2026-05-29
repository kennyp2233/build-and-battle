--!strict
-- Theme.luau
-- Tokens visuales centralizados: colores, espaciado, radios, tamaños de texto.
-- Si quieres cambiar la densidad visual del juego, edita aquí — no toques los componentes.

local Theme = {
	-- Tipografía
	Font = Enum.Font.SourceSansBold,
	FontCondensed = Enum.Font.SourceSansSemibold,
	FontMono = Enum.Font.Code,

	-- Colores semánticos
	Card = Color3.fromRGB(16, 17, 20),
	CardStroke = Color3.fromRGB(40, 42, 48),
	CardShadow = Color3.fromRGB(0, 0, 0),
	TextMain = Color3.fromRGB(235, 238, 243),
	TextSub = Color3.fromRGB(180, 186, 194),

	-- Retro Studio Grey palette (HUD notch) — flavor 2010-2013
	-- Panel charcoal solid + bevel duro (light top/left, dark bottom/right).
	-- Pensado para el HUD notch; el resto de UI puede seguir usando Card/TextMain.
	Retro = {
		PanelBG = Color3.fromRGB(46, 46, 46),       -- charcoal sólido (sin gradiente)
		PanelBGAlt = Color3.fromRGB(38, 38, 38),    -- variante más oscura
		BorderOuter = Color3.fromRGB(14, 14, 14),   -- borde exterior duro (2px)
		BevelLight = Color3.fromRGB(96, 96, 96),    -- highlight top/left
		BevelDark = Color3.fromRGB(20, 20, 20),     -- shadow bottom/right
		InsetBG = Color3.fromRGB(22, 22, 22),       -- bg hundido (progressbar track)
		InsetBorder = Color3.fromRGB(8, 8, 8),      -- borde del inset
		TextMain = Color3.fromRGB(242, 242, 242),
		TextDim = Color3.fromRGB(170, 170, 170),
		TextAccent = Color3.fromRGB(255, 213, 60),  -- amarillo Robux-style (acento opcional)
	},

	-- Estados / intent
	Primary = Color3.fromRGB(80, 140, 255),
	Info = Color3.fromRGB(255, 208, 48),
	Success = Color3.fromRGB(0, 220, 130),
	Danger = Color3.fromRGB(255, 77, 91),
	Neutral = Color3.fromRGB(120, 126, 134),
	LowTime = Color3.fromRGB(255, 120, 60),

	-- Progreso
	ProgressBG = Color3.fromRGB(45, 48, 54),

	-- Gradientes
	GradientA = Color3.fromRGB(80, 140, 255),
	GradientB = Color3.fromRGB(32, 220, 200),

	-- Design tokens — escala consistente para spacing/radius/textSize
	Radius = {
		sm = 6,
		md = 10,
		lg = 14,
		pill = 999,
	},

	Spacing = {
		xs = 4,
		sm = 8,
		md = 12,
		lg = 16,
		xl = 24,
	},

	TextSize = {
		xs = 12,
		sm = 14,
		md = 18,
		lg = 22,
		xl = 28,
		xxl = 36,
		huge = 52,
	},

	Stroke = {
		thin = 1,
		medium = 2,
		thick = 3,
	},

	-- Paleta por fase — colores BrickColor-style (Roblox 2008-2013).
	-- Más mate y saturado de forma "plástica", no neón ni gradient-vivo.
	-- Referencias: "Bright blue" 13/105/172, "Br. yellowish green" 164/189/71,
	-- "Bright red" 196/40/28.
	Phase = {
		Intermission = {
			accent = Color3.fromRGB(13, 105, 172),       -- Bright blue
			accentGlow = Color3.fromRGB(40, 130, 200),
			badgeBg = Color3.fromRGB(13, 105, 172),
			badgeText = Color3.fromRGB(245, 245, 245),
			icon = "⏳",
			subtitle = "Get ready for the next round",
		},
		Building = {
			accent = Color3.fromRGB(164, 189, 71),       -- Br. yellowish green
			accentGlow = Color3.fromRGB(190, 215, 100),
			badgeBg = Color3.fromRGB(75, 151, 75),       -- Bright green (más saturado)
			badgeText = Color3.fromRGB(245, 245, 245),
			icon = "🔨",
			subtitle = "Place blocks to defend your base",
		},
		Battle = {
			accent = Color3.fromRGB(196, 40, 28),        -- Bright red
			accentGlow = Color3.fromRGB(230, 80, 60),
			badgeBg = Color3.fromRGB(196, 40, 28),
			badgeText = Color3.fromRGB(245, 245, 245),
			icon = "⚔️",
			subtitle = "Eliminate your opponents",
		},
	},
}

-- Devuelve la paleta de Phase para un state dado, con fallback a Intermission.
function Theme.getPhase(state: string)
	return Theme.Phase[state] or Theme.Phase.Intermission
end

return Theme
