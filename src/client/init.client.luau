-- init.client.luau (Entry point del cliente)
-- Orden de boot: ClientNetwork (espera a server) → View → UI controllers → Game controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local ClientNetwork = require(script.Network.ClientNetwork)
local GameView = require(script.Presentation.Views.GameView)
local GameUIController = require(script.Controllers.UI.GameUIController)
local BuildController = require(script.Controllers.Game.BuildController)

local logger = Logger.new("Client")

-- 1. Network: espera por los RemoteEvents creados por el servidor
local network = ClientNetwork.new()

-- 2. Presentación (views renderean, no escuchan red)
local gameView = GameView.new()

-- 3. UI controllers (puente red → view)
local gameUIController = GameUIController.new(gameView, network)

-- 4. Game controllers (input + mecánicas)
local buildController = BuildController.new(network)

logger:Info("Client ready")
