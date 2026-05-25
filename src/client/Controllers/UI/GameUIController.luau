-- GameUIController.luau
-- Orquestador de UI del cliente. Escucha eventos del servidor vía ClientNetwork
-- y los delega a los sub-controladores especializados.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Network.Events)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local GameStateUIController = require(script.Parent.GameState.GameStateUIController)

local logger = Logger.new("GameUIController")

local GameUIController = {}
GameUIController.__index = GameUIController

function GameUIController.new(gameView, network)
	assert(network, "GameUIController requires a ClientNetwork instance")
	local self = setmetatable({}, GameUIController)

	self.gameView = gameView
	self.network = network
	self.maid = Maid.new()

	self.gameStateUIController = GameStateUIController.new(gameView)

	self.maid:Give(self.network:On(Events.GameStateChanged, function(state, endTimestamp, round)
		self.gameStateUIController:OnStateChanged(state, endTimestamp, round)
	end))

	logger:Info("GameUIController initialized")
	return self
end

function GameUIController:Destroy()
	self.maid:Clean()
	if self.gameStateUIController then
		self.gameStateUIController:Destroy()
	end
	if self.gameView then
		self.gameView:Destroy()
	end
end

return GameUIController
