-- GameConfig.luau (Configuración centralizada del juego)
-- Contiene todas las constantes y configuraciones del juego

local GameConfig = {
	-- Tiempos de las fases del juego (en segundos)
	PHASE_DURATIONS = {
		Intermission = 1,
		Building = 100,
		Battle = 120,
	},

	-- Configuración de construcción
	BUILD = {
		MAX_PLACEMENT_DISTANCE = 20, -- Distancia máxima para colocar bloques
		BLOCK_SIZE = 4, -- Tamaño de cada bloque
		MIN_BLOCK_SEPARATION = 4, -- Separación mínima entre bloques
		GRID_SNAP_SIZE = 4, -- Tamaño del grid para snap
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

	-- Configuración de UI
	UI = {
		HUD_SIZE = UDim2.new(0, 400, 0, 100),
		HUD_POSITION = UDim2.new(0.5, -200, 0.1, 0),
		UPDATE_INTERVAL = 0.1, -- Intervalo de actualización de UI en segundos
	},

	-- Nombres de eventos de red
	EVENTS = {
		GAME_STATE_CHANGED = "GameStateChanged",
		PLACE_BLOCK = "PlaceBlock",
	},

	-- Configuración de debug
	DEBUG = {
		ENABLED = true,
		VERBOSE_LOGGING = false,
	},
}

-- Función helper para validar tipos de bloques
function GameConfig.IsValidBlockType(blockType: string): boolean
	return GameConfig.BLOCK_TYPES[blockType] ~= nil
end

-- Función helper para obtener propiedades de bloque
function GameConfig.GetBlockProperties(blockType: string)
	return GameConfig.BLOCK_TYPES[blockType]
end

return GameConfig
