-- BuildController.luau
-- Orquestador del flujo de construcción cliente. Compone Predictor + Preview +
-- Effects. El constructor no hace yields — el setup de tool corre en task.spawn
-- para no bloquear el resto del boot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local BuildPredictor = require(script.Parent.Build.BuildPredictor)
local BuildPreview = require(script.Parent.Build.BuildPreview)
local BuildEffects = require(script.Parent.Build.BuildEffects)

local player = Players.LocalPlayer
local logger = Logger.new("BuildController")

local BuildController = {}
BuildController.__index = BuildController

function BuildController.new(network)
	assert(network, "BuildController requires a ClientNetwork instance")
	local self = setmetatable({}, BuildController)

	self.network = network
	self.maid = Maid.new()

	self.predictor = BuildPredictor.new(network)
	self.preview = BuildPreview.new(self.predictor)
	self.effects = BuildEffects.new()

	self.isEquipped = false
	self.lastPlacementTime = 0

	self.maid:Give(self.network:On(Events.BlockPlaced, function(id, _, _, ownerId)
		logger:Debug("Block placed broadcast: %s by userId=%s", id, tostring(ownerId))
	end))

	self.maid:Give(self.network:On(Events.PlaceBlockRejected, function(reason)
		logger:Warn("Placement rejected by server: %s", reason)
		self.effects:PlayInvalid(self.preview:GetPart())
	end))

	-- Setup de tool: contiene WaitForChild — corre en spawn para no bloquear init.
	task.spawn(function()
		self:_setupTool()
	end)

	logger:Info("BuildController initialized")
	return self
end

function BuildController:_setupTool()
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	local function tryConnect(child: Instance)
		if child.Name == "BuildTool" and child:IsA("Tool") then
			self:_connectTool(child)
		end
	end

	self.maid:Give(backpack.ChildAdded:Connect(tryConnect))
	self.maid:Give(character.ChildAdded:Connect(tryConnect))

	for _, child in ipairs(backpack:GetChildren()) do
		tryConnect(child)
	end
	for _, child in ipairs(character:GetChildren()) do
		tryConnect(child)
	end
end

function BuildController:_connectTool(tool: Tool)
	if tool:GetAttribute("Connected") then
		return
	end
	tool:SetAttribute("Connected", true)

	self.maid:Give(tool.Equipped:Connect(function()
		self.isEquipped = true
		self.preview:Show()
	end))

	self.maid:Give(tool.Unequipped:Connect(function()
		self.isEquipped = false
		self.preview:Hide()
	end))

	self.maid:Give(tool.Activated:Connect(function()
		self:_tryPlace()
	end))
end

function BuildController:_tryPlace()
	local cooldown = GameConfig.BUILD.PLACEMENT_COOLDOWN
	local now = os.clock()
	if now - self.lastPlacementTime < cooldown then
		return
	end

	local position = self.preview:GetTargetPosition()
	local valid = self.preview:IsValidPlacement()

	if position and valid then
		self.network:Fire(Events.PlaceBlockRequest, position, "Wood")
		self.lastPlacementTime = now
		self.effects:PlayPlacement(position)
	else
		self.effects:PlayInvalid(self.preview:GetPart())
	end
end

function BuildController:Destroy()
	self.preview:Destroy()
	self.predictor:Destroy()
	self.effects:Destroy()
	self.maid:Clean()
end

return BuildController
