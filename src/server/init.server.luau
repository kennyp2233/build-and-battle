-- init.server.luau (Entry point del servidor)
-- Orden de boot: Logger.configure → Network → BuildService → Controller → Init.
-- ServerNetwork crea TODOS los RemoteEvents antes de que cualquier cliente intente conectarse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local ServerNetwork = require(script.Network.ServerNetwork)
local BuildService = require(script.Services.BuildService)
local GameController = require(script.Controllers.GameController)

Logger.configure({
	enabled = GameConfig.DEBUG.ENABLED,
	verbose = GameConfig.DEBUG.VERBOSE_LOGGING,
})

local logger = Logger.new("Server")

-- 1. Network: crea los RemoteEvents (necesario antes de que clientes hagan WaitForChild)
local network = ServerNetwork.new()

-- 2. BuildService: lógica con autoridad sobre bloques
local buildService = BuildService.new(network)

-- 3. Controller: orquesta servicios + use cases + jugadores
local gameController = GameController.new(buildService, network)
gameController:Init()

logger:Info("Server ready")

game:BindToClose(function()
	logger:Info("Server shutting down")
	gameController:Destroy()
	buildService:Destroy()
	network:Destroy()
end)
