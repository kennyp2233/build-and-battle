-- GameConfig.luau (Configuración compartida server+cliente)
-- Solo constantes de gameplay. Los nombres de RemoteEvents viven en shared/Network/Events
-- y la configuración visual del HUD vive en client/Presentation.

local GameConfig = {
	-- Tiempos de las fases del juego (en segundos)
	PHASE_DURATIONS = {
		Intermission = 15,
		Building = 100,
		Battle = 120,
	},

	-- Configuración de construcción
	BUILD = {
		MAX_PLACEMENT_DISTANCE = 20,
		BLOCK_SIZE = 4,
		GRID_ORIGIN = Vector3.new(0, 0, 0),
		-- Cooldown único leído por cliente (rate guard) y server (validación autoritativa).
		PLACEMENT_COOLDOWN = 0.2,
	},

	-- Tipos de bloques y sus propiedades
	BLOCK_TYPES = {
		Wood = {
			Color = Color3.fromRGB(139, 69, 19),
			Material = Enum.Material.Wood,
			Health = 100,
		},
		Stone = {
			Color = Color3.fromRGB(128, 128, 128),
			Material = Enum.Material.Slate,
			Health = 200,
		},
		Metal = {
			Color = Color3.fromRGB(192, 192, 192),
			Material = Enum.Material.Metal,
			Health = 300,
		},
	},

	-- Debug
	DEBUG = {
		ENABLED = true,
		VERBOSE_LOGGING = false,
	},
}

function GameConfig.IsValidBlockType(blockType: string): boolean
	return GameConfig.BLOCK_TYPES[blockType] ~= nil
end

function GameConfig.GetBlockProperties(blockType: string)
	return GameConfig.BLOCK_TYPES[blockType]
end

return GameConfig
