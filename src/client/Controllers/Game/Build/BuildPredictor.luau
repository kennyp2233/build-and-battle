-- BuildPredictor.luau
-- Validación cliente-side de placement. Mantiene un set local de celdas
-- ocupadas sincronizado vía BlockPlaced / BlocksCleared para que el preview
-- prediga el resultado del server sin round-trip.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Grid = require(ReplicatedStorage.Shared.Utils.Grid)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)

local player = Players.LocalPlayer

local BuildPredictor = {}
BuildPredictor.__index = BuildPredictor

function BuildPredictor.new(network)
	local self = setmetatable({}, BuildPredictor)

	self.occupiedCells = {} -- [cellKey] = true
	self.maid = Maid.new()

	self.maid:Give(network:On(Events.BlockPlaced, function(_, position)
		self.occupiedCells[self:_cellKey(position)] = true
	end))
	self.maid:Give(network:On(Events.BlocksCleared, function()
		self.occupiedCells = {}
	end))

	return self
end

function BuildPredictor:_cellKey(position: Vector3): string
	return Grid.CellKey(position, GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.GRID_ORIGIN)
end

function BuildPredictor:Snap(position: Vector3): Vector3
	return Grid.Snap(position, GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.GRID_ORIGIN)
end

-- Returns true if the snapped position is a legal placement for the local player.
function BuildPredictor:IsValid(snappedPosition: Vector3): boolean
	local character = player.Character
	if not character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	if (snappedPosition - hrp.Position).Magnitude > GameConfig.BUILD.MAX_PLACEMENT_DISTANCE then
		return false
	end

	if self.occupiedCells[self:_cellKey(snappedPosition)] then
		return false
	end

	return true
end

function BuildPredictor:Destroy()
	self.maid:Clean()
	self.occupiedCells = {}
end

return BuildPredictor
