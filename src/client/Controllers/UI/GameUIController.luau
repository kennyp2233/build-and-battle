-- GameUIController.luau
-- Orquestador de UI: enruta eventos de red a los sub-controllers, que a su vez
-- escriben al store del HUD.

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

	self.gameStateUIController = GameStateUIController.new(gameView:GetStore())

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
