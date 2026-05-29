-- WorldMockup.luau
-- Mockup escala "épica": arena 200x200 con torres, totems, anillos concéntricos,
-- pilares laterales, plataformas de spawn elevadas y almenas decorativas en los
-- muros. Hardcodeado a propósito — es validación visual, no producción.

local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")

-- ── CONSTANTES ───────────────────────────────────────────────────────────────
local MAP_SIZE_X = 200
local MAP_SIZE_Z = 200
local GROUND_THICKNESS = 4
local GROUND_TOP_Y = 0

local NEUTRAL_HALF_WIDTH = 15 -- franja central de combate de 30 studs
local TERRITORY_DEPTH = (MAP_SIZE_Z / 2) - NEUTRAL_HALF_WIDTH -- 85

local RED_COLOR = Color3.fromRGB(230, 60, 70)
local BLUE_COLOR = Color3.fromRGB(60, 130, 230)
local NEUTRAL_COLOR = Color3.fromRGB(255, 240, 200)
local GROUND_COLOR = Color3.fromRGB(32, 34, 42)
local STONE_LIGHT = Color3.fromRGB(110, 100, 92)
local STONE_DARK = Color3.fromRGB(60, 56, 52)
local WALL_COLOR = Color3.fromRGB(28, 30, 36)

local WorldMockup = {}

-- ── HELPERS ──────────────────────────────────────────────────────────────────
local function makePart(parent: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(part :: any)[k] = v
	end
	part.Parent = parent
	return part
end

local function addPointLight(parent: Instance, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light.Parent = parent
	return light
end

local function addFire(parent: Instance, size: number, primary: Color3, secondary: Color3)
	local fire = Instance.new("Fire")
	fire.Heat = 8
	fire.Size = size
	fire.Color = primary
	fire.SecondaryColor = secondary
	fire.Parent = parent
	return fire
end

-- ── LIGHTING / ATMOSPHERE ────────────────────────────────────────────────────
local function setupLighting()
	Lighting.Ambient = Color3.fromRGB(55, 45, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 90, 120)
	Lighting.Brightness = 2.2
	Lighting.ColorShift_Top = Color3.fromRGB(255, 170, 130)
	Lighting.ColorShift_Bottom = Color3.fromRGB(50, 50, 90)
	Lighting.ClockTime = 17.8
	Lighting.GeographicLatitude = 30
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.6

	local existing = Lighting:FindFirstChildOfClass("Atmosphere")
	if existing then
		existing:Destroy()
	end
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.4
	atmo.Offset = 0.3
	atmo.Color = Color3.fromRGB(199, 170, 140)
	atmo.Decay = Color3.fromRGB(82, 70, 110)
	atmo.Glare = 0.8
	atmo.Haze = 2.5
	atmo.Parent = Lighting

	for _, name in ipairs({ "Bloom", "DepthOfField", "ColorCorrection", "SunRays" }) do
		local old = Lighting:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.2
	cc.Contrast = 0.12
	cc.TintColor = Color3.fromRGB(255, 230, 210)
	cc.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.22
	rays.Spread = 0.7
	rays.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.FarIntensity = 0.1
	dof.FocusDistance = 60
	dof.InFocusRadius = 80
	dof.NearIntensity = 0
	dof.Parent = Lighting
end

-- ── SUELO ────────────────────────────────────────────────────────────────────
local function buildGround(mapFolder: Folder)
	-- Losa principal
	makePart(mapFolder, {
		Name = "Ground",
		Size = Vector3.new(MAP_SIZE_X, GROUND_THICKNESS, MAP_SIZE_Z),
		Position = Vector3.new(0, GROUND_TOP_Y - GROUND_THICKNESS / 2, 0),
		Color = GROUND_COLOR,
		Material = Enum.Material.Slate,
	})

	-- Escalón exterior decorativo (marco de piedra alrededor del suelo)
	local rimThickness = 4
	local rimHeight = 1
	local rimY = GROUND_TOP_Y - rimHeight / 2
	for _, offset in ipairs({
		{ x = 0, z = -MAP_SIZE_Z / 2 - rimThickness / 2, sx = MAP_SIZE_X + rimThickness * 2, sz = rimThickness },
		{ x = 0, z = MAP_SIZE_Z / 2 + rimThickness / 2, sx = MAP_SIZE_X + rimThickness * 2, sz = rimThickness },
		{ x = -MAP_SIZE_X / 2 - rimThickness / 2, z = 0, sx = rimThickness, sz = MAP_SIZE_Z },
		{ x = MAP_SIZE_X / 2 + rimThickness / 2, z = 0, sx = rimThickness, sz = MAP_SIZE_Z },
	}) do
		makePart(mapFolder, {
			Name = "GroundRim",
			Size = Vector3.new(offset.sx, rimHeight, offset.sz),
			Position = Vector3.new(offset.x, rimY, offset.z),
			Color = STONE_DARK,
			Material = Enum.Material.Cobblestone,
		})
	end
end

-- ── MARCADORES DE TERRITORIO ─────────────────────────────────────────────────
local function buildTerritoryMarker(mapFolder: Folder, name: string, color: Color3, zCenter: number, facingZ: number)
	-- Placa luminosa principal
	makePart(mapFolder, {
		Name = name,
		Size = Vector3.new(MAP_SIZE_X - 8, 0.2, TERRITORY_DEPTH),
		Position = Vector3.new(0, GROUND_TOP_Y + 0.1, zCenter),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.78,
		CanCollide = false,
	})

	-- Banda densa en el borde frontal (cerca de zona neutral)
	makePart(mapFolder, {
		Name = name .. "_FrontEdge",
		Size = Vector3.new(MAP_SIZE_X - 8, 0.4, 1.5),
		Position = Vector3.new(0, GROUND_TOP_Y + 0.2, facingZ),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CanCollide = false,
	})

	-- Runas/bandas internas (4 líneas paralelas decorativas)
	for i = 1, 4 do
		local zOffset = (i - 2.5) * (TERRITORY_DEPTH / 5)
		makePart(mapFolder, {
			Name = name .. "_Rune_" .. i,
			Size = Vector3.new(MAP_SIZE_X - 30, 0.3, 0.5),
			Position = Vector3.new(0, GROUND_TOP_Y + 0.15, zCenter + zOffset),
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.55,
			CanCollide = false,
		})
	end
end

local function buildNeutralZone(mapFolder: Folder)
	-- Franja central
	makePart(mapFolder, {
		Name = "NeutralZone",
		Size = Vector3.new(MAP_SIZE_X - 8, 0.2, NEUTRAL_HALF_WIDTH * 2),
		Position = Vector3.new(0, GROUND_TOP_Y + 0.05, 0),
		Color = NEUTRAL_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.88,
		CanCollide = false,
	})

	-- Línea fina central (separador exacto Z=0)
	makePart(mapFolder, {
		Name = "CenterLine",
		Size = Vector3.new(MAP_SIZE_X - 8, 0.6, 0.4),
		Position = Vector3.new(0, GROUND_TOP_Y + 0.3, 0),
		Color = NEUTRAL_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0,
		CanCollide = false,
	})

	-- 3 anillos concéntricos en el centro
	local rings = { { r = 8, t = 0.3 }, { r = 14, t = 0.5 }, { r = 22, t = 0.7 } }
	for i, ring in ipairs(rings) do
		-- Roblox no tiene torus nativo — simulamos con un disco delgado encima de
		-- otro más grande para crear "anillos" como bandas concéntricas finas.
		makePart(mapFolder, {
			Name = "CenterRing_" .. i,
			Size = Vector3.new(ring.r * 2, 0.25 + (i * 0.05), ring.r * 2),
			Position = Vector3.new(0, GROUND_TOP_Y + 0.4 - (i * 0.05), 0),
			Color = NEUTRAL_COLOR,
			Material = Enum.Material.Neon,
			Transparency = ring.t,
			CanCollide = false,
		})
	end

	-- Pilar central neutral (referencia visual del medio)
	makePart(mapFolder, {
		Name = "CenterBeacon",
		Size = Vector3.new(2, 40, 2),
		Position = Vector3.new(0, GROUND_TOP_Y + 20, 0),
		Color = NEUTRAL_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
	})

	-- Light en lo alto del beacon
	local beaconLight = Instance.new("PointLight")
	beaconLight.Color = NEUTRAL_COLOR
	beaconLight.Brightness = 4
	beaconLight.Range = 60
	beaconLight.Shadows = true
	beaconLight.Parent = mapFolder:FindFirstChild("CenterBeacon")
end

-- ── PILARES / TORRES / TOTEMS ────────────────────────────────────────────────
local function buildTorch(mapFolder: Folder, name: string, position: Vector3, color: Color3, flameSize: number, lightRange: number)
	local flame = makePart(mapFolder, {
		Name = name .. "_Flame",
		Size = Vector3.new(2.5, 2.5, 2.5),
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
	})
	addFire(flame, flameSize, color, Color3.new(color.R * 0.4, color.G * 0.2, 0))
	addPointLight(flame, color, 3.5, lightRange)
	return flame
end

local function buildCornerTower(mapFolder: Folder, position: Vector3, name: string)
	-- Base ancha
	makePart(mapFolder, {
		Name = name .. "_Base",
		Size = Vector3.new(10, 2, 10),
		Position = position + Vector3.new(0, 1, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Cobblestone,
	})

	-- Cuerpo principal (alto)
	makePart(mapFolder, {
		Name = name .. "_Body",
		Size = Vector3.new(7, 30, 7),
		Position = position + Vector3.new(0, 17, 0),
		Color = STONE_LIGHT,
		Material = Enum.Material.Marble,
	})

	-- Anillo decorativo a media altura
	makePart(mapFolder, {
		Name = name .. "_Ring",
		Size = Vector3.new(9, 1.5, 9),
		Position = position + Vector3.new(0, 22, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Slate,
	})

	-- Almena superior (la "corona" de la torre)
	makePart(mapFolder, {
		Name = name .. "_Crown",
		Size = Vector3.new(9, 2, 9),
		Position = position + Vector3.new(0, 33, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Cobblestone,
	})

	-- Cuenco de antorcha
	makePart(mapFolder, {
		Name = name .. "_Bowl",
		Size = Vector3.new(3.5, 1.2, 3.5),
		Position = position + Vector3.new(0, 34.7, 0),
		Color = Color3.fromRGB(35, 30, 28),
		Material = Enum.Material.Metal,
	})

	-- Antorcha grande
	buildTorch(
		mapFolder,
		name,
		position + Vector3.new(0, 36.5, 0),
		Color3.fromRGB(255, 150, 60),
		8,
		60
	)
end

local function buildSidePillar(mapFolder: Folder, position: Vector3, name: string)
	makePart(mapFolder, {
		Name = name .. "_Base",
		Size = Vector3.new(6, 1.5, 6),
		Position = position + Vector3.new(0, 0.75, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Cobblestone,
	})

	makePart(mapFolder, {
		Name = name,
		Size = Vector3.new(4, 20, 4),
		Position = position + Vector3.new(0, 11, 0),
		Color = STONE_LIGHT,
		Material = Enum.Material.Marble,
	})

	makePart(mapFolder, {
		Name = name .. "_Capital",
		Size = Vector3.new(5, 1, 5),
		Position = position + Vector3.new(0, 21.5, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Slate,
	})

	-- Antorcha mediana arriba
	buildTorch(
		mapFolder,
		name,
		position + Vector3.new(0, 23, 0),
		Color3.fromRGB(255, 140, 60),
		6,
		45
	)
end

local function buildTeamTotem(mapFolder: Folder, position: Vector3, color: Color3, name: string)
	-- Plataforma elevada de la base
	makePart(mapFolder, {
		Name = name .. "_Platform",
		Size = Vector3.new(20, 1.5, 20),
		Position = position + Vector3.new(0, 0.75, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Cobblestone,
	})

	-- Pedestal central
	makePart(mapFolder, {
		Name = name .. "_Pedestal",
		Size = Vector3.new(5, 3, 5),
		Position = position + Vector3.new(0, 3, 0),
		Color = STONE_LIGHT,
		Material = Enum.Material.Marble,
	})

	-- Tótem luminoso (cristal vertical)
	makePart(mapFolder, {
		Name = name .. "_Crystal",
		Size = Vector3.new(2, 12, 2),
		Position = position + Vector3.new(0, 10.5, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = true,
	})

	-- Glow alrededor del cristal
	local crystal = mapFolder:FindFirstChild(name .. "_Crystal")
	if crystal then
		addPointLight(crystal, color, 4, 50)
	end

	-- Anillo de luz alrededor del pedestal
	makePart(mapFolder, {
		Name = name .. "_GlowRing",
		Size = Vector3.new(12, 0.3, 12),
		Position = position + Vector3.new(0, 1.65, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
	})
end

local function buildAllStructures(mapFolder: Folder)
	-- 4 torres de esquina (las más imponentes)
	local cx = MAP_SIZE_X / 2 - 8
	local cz = MAP_SIZE_Z / 2 - 8
	buildCornerTower(mapFolder, Vector3.new(-cx, GROUND_TOP_Y, -cz), "Tower_NW")
	buildCornerTower(mapFolder, Vector3.new(cx, GROUND_TOP_Y, -cz), "Tower_NE")
	buildCornerTower(mapFolder, Vector3.new(-cx, GROUND_TOP_Y, cz), "Tower_SW")
	buildCornerTower(mapFolder, Vector3.new(cx, GROUND_TOP_Y, cz), "Tower_SE")

	-- 4 pilares laterales a la altura de la zona neutral (marcan la "muralla" entre territorios)
	local sx = MAP_SIZE_X / 2 - 6
	buildSidePillar(mapFolder, Vector3.new(-sx, GROUND_TOP_Y, -NEUTRAL_HALF_WIDTH - 2), "Pillar_RedW")
	buildSidePillar(mapFolder, Vector3.new(sx, GROUND_TOP_Y, -NEUTRAL_HALF_WIDTH - 2), "Pillar_RedE")
	buildSidePillar(mapFolder, Vector3.new(-sx, GROUND_TOP_Y, NEUTRAL_HALF_WIDTH + 2), "Pillar_BlueW")
	buildSidePillar(mapFolder, Vector3.new(sx, GROUND_TOP_Y, NEUTRAL_HALF_WIDTH + 2), "Pillar_BlueE")

	-- Totems centrales por team (en el fondo de cada territorio, donde están los spawns)
	local backZ = MAP_SIZE_Z / 2 - 25
	buildTeamTotem(mapFolder, Vector3.new(0, GROUND_TOP_Y, -backZ), RED_COLOR, "RedTotem")
	buildTeamTotem(mapFolder, Vector3.new(0, GROUND_TOP_Y, backZ), BLUE_COLOR, "BlueTotem")
end

-- ── MURALLA CON ALMENAS ──────────────────────────────────────────────────────
local function buildBorderWalls(mapFolder: Folder)
	local height = 4
	local thickness = 2
	local y = GROUND_TOP_Y + height / 2

	-- 4 muros principales
	local walls = {
		{ name = "Wall_N", size = Vector3.new(MAP_SIZE_X, height, thickness), pos = Vector3.new(0, y, -MAP_SIZE_Z / 2) },
		{ name = "Wall_S", size = Vector3.new(MAP_SIZE_X, height, thickness), pos = Vector3.new(0, y, MAP_SIZE_Z / 2) },
		{ name = "Wall_E", size = Vector3.new(thickness, height, MAP_SIZE_Z), pos = Vector3.new(MAP_SIZE_X / 2, y, 0) },
		{ name = "Wall_W", size = Vector3.new(thickness, height, MAP_SIZE_Z), pos = Vector3.new(-MAP_SIZE_X / 2, y, 0) },
	}
	for _, w in ipairs(walls) do
		makePart(mapFolder, {
			Name = w.name,
			Size = w.size,
			Position = w.pos,
			Color = WALL_COLOR,
			Material = Enum.Material.Concrete,
		})
	end

	-- Almenas decorativas a lo largo de los muros N y S (cada 12 studs)
	local almenaSize = Vector3.new(3, 2, 3)
	local almenaY = GROUND_TOP_Y + height + 1
	local spacing = 12
	local numAlmenas = math.floor(MAP_SIZE_X / spacing)
	for i = 0, numAlmenas - 1 do
		local x = -MAP_SIZE_X / 2 + (i + 0.5) * spacing
		for _, zSide in ipairs({ -MAP_SIZE_Z / 2, MAP_SIZE_Z / 2 }) do
			makePart(mapFolder, {
				Name = "Almena",
				Size = almenaSize,
				Position = Vector3.new(x, almenaY, zSide),
				Color = WALL_COLOR,
				Material = Enum.Material.Concrete,
			})
		end
	end
	-- Almenas en los muros E y W
	local numAlmenasZ = math.floor(MAP_SIZE_Z / spacing)
	for i = 0, numAlmenasZ - 1 do
		local z = -MAP_SIZE_Z / 2 + (i + 0.5) * spacing
		for _, xSide in ipairs({ -MAP_SIZE_X / 2, MAP_SIZE_X / 2 }) do
			makePart(mapFolder, {
				Name = "Almena",
				Size = almenaSize,
				Position = Vector3.new(xSide, almenaY, z),
				Color = WALL_COLOR,
				Material = Enum.Material.Concrete,
			})
		end
	end
end

-- ── TEAMS + SPAWNS ───────────────────────────────────────────────────────────
local function ensureTeam(name: string, brickColorName: string): Team
	local team = Teams:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.AutoAssignable = true
		team.Parent = Teams
	end
	(team :: Team).TeamColor = BrickColor.new(brickColorName)
	return team :: Team
end

local function buildSpawnPad(mapFolder: Folder, position: Vector3, teamColor: BrickColor, name: string)
	-- Pequeña plataforma elevada bajo cada spawn
	makePart(mapFolder, {
		Name = name .. "_Plinth",
		Size = Vector3.new(8, 1, 8),
		Position = position - Vector3.new(0, 0.5, 0),
		Color = STONE_DARK,
		Material = Enum.Material.Cobblestone,
	})

	local pad = Instance.new("SpawnLocation")
	pad.Name = name
	pad.Size = Vector3.new(6, 1, 6)
	pad.Position = position
	pad.Anchored = true
	pad.CanCollide = true
	pad.BrickColor = teamColor
	pad.TeamColor = teamColor
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.3
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = mapFolder

	for _, child in ipairs(pad:GetChildren()) do
		child:Destroy()
	end

	addPointLight(pad, teamColor.Color, 2.5, 22)
end

local function buildSpawns(mapFolder: Folder)
	local redTeam = ensureTeam("Red", "Bright red")
	local blueTeam = ensureTeam("Blue", "Bright blue")

	-- 5 spawns por team (alineados a los lados del totem central)
	local backZ = MAP_SIZE_Z / 2 - 12
	local spawnY = GROUND_TOP_Y + 1.5
	local spreads = { -60, -30, 30, 60, 0 } -- el último (0) queda atrás del totem

	for i, x in ipairs(spreads) do
		local z = backZ
		if i == 5 then
			z = backZ + 4 -- pegado al totem
		end
		buildSpawnPad(mapFolder, Vector3.new(x, spawnY, -z), redTeam.TeamColor, "RedSpawn_" .. i)
		buildSpawnPad(mapFolder, Vector3.new(x, spawnY, z), blueTeam.TeamColor, "BlueSpawn_" .. i)
	end
end

-- ── VOID KILLPLANE ───────────────────────────────────────────────────────────
local function buildKillPlane(mapFolder: Folder)
	local void = makePart(mapFolder, {
		Name = "Void",
		Size = Vector3.new(3000, 1, 3000),
		Position = Vector3.new(0, -120, 0),
		Color = Color3.fromRGB(8, 8, 16),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
		CanCollide = false,
	})

	void.Touched:Connect(function(hit: BasePart)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

-- ── LIMPIEZA INICIAL ─────────────────────────────────────────────────────────
local function clearExistingMap()
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "Baseplate" or child.Name == "Map" then
			child:Destroy()
		end
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
end

-- ── ENTRY POINT ──────────────────────────────────────────────────────────────
function WorldMockup.Generate()
	clearExistingMap()
	setupLighting()

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	buildGround(map)
	buildTerritoryMarker(map, "RedTerritory", RED_COLOR, -(NEUTRAL_HALF_WIDTH + TERRITORY_DEPTH / 2), -NEUTRAL_HALF_WIDTH - 1)
	buildTerritoryMarker(map, "BlueTerritory", BLUE_COLOR, (NEUTRAL_HALF_WIDTH + TERRITORY_DEPTH / 2), NEUTRAL_HALF_WIDTH + 1)
	buildNeutralZone(map)
	buildAllStructures(map)
	buildBorderWalls(map)
	buildSpawns(map)
	buildKillPlane(map)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			player:LoadCharacter()
		end
	end
end

return WorldMockup
