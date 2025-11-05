-- init.server.luau (Punto de entrada principal del servidor)
-- Inicializa la arquitectura modular del juego con Clean Architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar utilidades
local NetworkManager = require(ReplicatedStorage.Shared.Utils.NetworkManager)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

-- Importar servicios compartidos
local GameStateService = require(ReplicatedStorage.Shared.Services.GameStateService)
local BuildService = require(ReplicatedStorage.Shared.Services.BuildService)

-- Importar controlador del servidor
local GameController = require(script.Controllers.GameController)

local logger = Logger.new("Server")

-- Crear instancia compartida de NetworkManager
local networkManager = NetworkManager.new()

-- IMPORTANTE: Crear todos los eventos ANTES de inicializar servicios y controladores
-- Esto evita "Infinite yield" en WaitForChild
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
networkManager:GetOrCreateEvent(GameConfig.EVENTS.GAME_STATE_CHANGED)
networkManager:GetOrCreateEvent(GameConfig.EVENTS.PLACE_BLOCK)

logger:Info("Network events pre-created")

-- Inicializar servicios con dependencias inyectadas
local gameStateService = GameStateService.new(networkManager)
local buildService = BuildService.new(networkManager)

logger:Info("Services initialized")

-- Inicializar controlador con inyección de dependencias
local gameController = GameController.new(gameStateService, buildService)

-- Iniciar el juego (el GameController maneja PlayerAdded internamente)
gameController:Init()

logger:Info("Server initialized with Clean Architecture")
print("==============================================")
print("  Build & Battle Server - Ready")
print("  Architecture: Clean Architecture Modular")
print("==============================================")

-- Cleanup cuando el servidor se cierra (opcional, para testing)
game:BindToClose(function()
	logger:Info("Server shutting down...")
	gameController:Destroy()
end)
