-- init.client.luau (Punto de entrada del cliente)
-- Inicializa la arquitectura modular del cliente con Clean Architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar utilidades
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

-- Importar módulos
local GameView = require(script.Presentation.Views.GameView)
local GameUIController = require(script.Controllers.GameUIController)
local BuildController = require(script.Controllers.BuildController)

local logger = Logger.new("Client")

-- Inicializar vista
local gameView = GameView.new()
logger:Info("GameView initialized")

-- Inicializar controladores con inyección de dependencias
local gameUIController = GameUIController.new(gameView)
local buildController = BuildController.new()

logger:Info("Client initialized with Clean Architecture")
print("==============================================")
print("  Build & Battle Client - Ready")
print("  Architecture: Clean Architecture Modular")
print("===============================================")
