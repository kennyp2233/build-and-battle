--!strict
-- Theme.luau
-- Tokens visuales centralizados: colores, espaciado, radios, tamaños de texto.
-- Si quieres cambiar la densidad visual del juego, edita aquí — no toques los componentes.

local Theme = {
	-- Tipografía
	Font = Enum.Font.GothamBold,
	FontCondensed = Enum.Font.Gotham,

	-- Colores semánticos
	Card = Color3.fromRGB(16, 17, 20),
	CardStroke = Color3.fromRGB(40, 42, 48),
	CardShadow = Color3.fromRGB(0, 0, 0),
	TextMain = Color3.fromRGB(235, 238, 243),
	TextSub = Color3.fromRGB(180, 186, 194),

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

	-- Paleta por fase del juego — usada para teñir el accent del HUD
	-- (border glow, badge bg, banner subtitle) según la fase actual.
	Phase = {
		Intermission = {
			accent = Color3.fromRGB(80, 140, 255),
			accentGlow = Color3.fromRGB(120, 170, 255),
			badgeBg = Color3.fromRGB(30, 50, 100),
			badgeText = Color3.fromRGB(200, 220, 255),
			icon = "⏳",
			subtitle = "Get ready for the next round",
		},
		Building = {
			accent = Color3.fromRGB(0, 220, 130),
			accentGlow = Color3.fromRGB(60, 240, 160),
			badgeBg = Color3.fromRGB(20, 70, 50),
			badgeText = Color3.fromRGB(200, 250, 220),
			icon = "🔨",
			subtitle = "Place blocks to defend your base",
		},
		Battle = {
			accent = Color3.fromRGB(255, 77, 91),
			accentGlow = Color3.fromRGB(255, 120, 130),
			badgeBg = Color3.fromRGB(80, 30, 35),
			badgeText = Color3.fromRGB(255, 210, 210),
			icon = "⚔️",
			subtitle = "Eliminate your opponents",
		},
		Ended = {
			accent = Color3.fromRGB(120, 126, 134),
			accentGlow = Color3.fromRGB(160, 166, 174),
			badgeBg = Color3.fromRGB(40, 42, 48),
			badgeText = Color3.fromRGB(220, 222, 226),
			icon = "🏁",
			subtitle = "Round complete",
		},
	},
}

-- Devuelve la paleta de Phase para un state dado, con fallback a Intermission.
function Theme.getPhase(state: string)
	return Theme.Phase[state] or Theme.Phase.Intermission
end

return Theme
