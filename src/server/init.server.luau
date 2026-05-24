-- init.server.luau (Entry point del servidor)
-- Orden de boot: Network → Services → Controller → Init.
-- ServerNetwork crea TODOS los RemoteEvents antes de que cualquier cliente intente conectarse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local ServerNetwork = require(script.Network.ServerNetwork)
local GameStateService = require(script.Services.GameStateService)
local BuildService = require(script.Services.BuildService)
local GameController = require(script.Controllers.GameController)

local logger = Logger.new("Server")

-- 1. Network: crea los RemoteEvents (necesario antes de que clientes hagan WaitForChild)
local network = ServerNetwork.new()

-- 2. Services: lógica con autoridad
local gameStateService = GameStateService.new(network)
local buildService = BuildService.new(network)

-- 3. Controller: orquesta servicios + use cases + jugadores
local gameController = GameController.new(gameStateService, buildService, network)
gameController:Init()

logger:Info("Server ready")

game:BindToClose(function()
	logger:Info("Server shutting down")
	gameController:Destroy()
	network:Destroy()
end)
