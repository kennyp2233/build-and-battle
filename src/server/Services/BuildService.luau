-- BuildService.luau
-- Servidor-only. Mantiene la lista autoritativa de bloques colocados y su representación
-- física en workspace. Notifica a los clientes vía ServerNetwork con BlockPlaced.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Block = require(ReplicatedStorage.Shared.Entities.Block)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("BuildService")

local BuildService = {}
BuildService.__index = BuildService

function BuildService.new(network)
	assert(network, "BuildService requires a ServerNetwork instance")
	local self = setmetatable({}, BuildService)
	self.network = network
	self.placedBlocks = {}
	self.blockParts = {}
	return self
end

function BuildService:CanPlaceBlock(position: Vector3, player: Player)
	if not player or not player:IsA("Player") then
		return Result.Err("Invalid player")
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return Result.Err("Player character not found")
	end

	local distance = (position - character.HumanoidRootPart.Position).Magnitude
	local maxDistance = GameConfig.BUILD.MAX_PLACEMENT_DISTANCE
	if distance > maxDistance then
		return Result.Err(string.format("Too far away (max: %d studs)", maxDistance))
	end

	local minSeparation = GameConfig.BUILD.MIN_BLOCK_SEPARATION
	for _, block in pairs(self.placedBlocks) do
		if (block.position - position).Magnitude < minSeparation then
			return Result.Err("Block too close to another block")
		end
	end

	return Result.Ok(true)
end

function BuildService:PlaceBlock(position: Vector3, blockType: Block.BlockType, player: Player)
	if not GameConfig.IsValidBlockType(blockType) then
		return Result.Err("Invalid block type")
	end

	local canPlaceResult = self:CanPlaceBlock(position, player)
	if Result.IsErr(canPlaceResult) then
		return Result.Err(Result.UnwrapErr(canPlaceResult))
	end

	local block = Block.new(position, blockType, player.Name)
	self.placedBlocks[block.id] = block

	local part = self:CreateBlockPart(block, blockType)
	if not part then
		self.placedBlocks[block.id] = nil
		return Result.Err("Failed to create block part")
	end
	self.blockParts[block.id] = part

	self.network:FireAll(Events.BlockPlaced, block.id, position, blockType, player.Name)

	logger:Info("Block placed: %s by %s", block.id, player.Name)
	return Result.Ok(block)
end

function BuildService:CreateBlockPart(block, blockType: Block.BlockType): Part?
	local blockProperties = GameConfig.GetBlockProperties(blockType)
	if not blockProperties then
		logger:Error("No properties found for block type: %s", blockType)
		return nil
	end

	local part = Instance.new("Part")
	part.Name = block.id
	part.Size = Vector3.new(GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.BLOCK_SIZE)
	part.Position = block.position
	part.Anchored = true
	part.CanCollide = true
	part.Color = blockProperties.Color
	part.Material = blockProperties.Material

	part:SetAttribute("IsBlock", true)
	part:SetAttribute("BlockOwner", block.owner)
	part:SetAttribute("BlockType", blockType)
	part:SetAttribute("BlockHealth", blockProperties.Health)

	part.Parent = workspace
	return part
end

function BuildService:ClearBlocks()
	local clearedCount = 0

	for _, part in pairs(self.blockParts) do
		if part and part.Parent then
			part:Destroy()
			clearedCount += 1
		end
	end

	-- Limpia huérfanos que pudieran quedar (p.ej. tras un crash recargado)
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("IsBlock") then
			part:Destroy()
			clearedCount += 1
		end
	end

	self.placedBlocks = {}
	self.blockParts = {}
	logger:Info("Cleared %d blocks", clearedCount)
end

function BuildService:GetBlockCount(): number
	local count = 0
	for _ in pairs(self.placedBlocks) do
		count += 1
	end
	return count
end

function BuildService:GetPlayerBlocks(playerName: string): { Block.Block }
	local playerBlocks = {}
	for _, block in pairs(self.placedBlocks) do
		if block.owner == playerName then
			table.insert(playerBlocks, block)
		end
	end
	return playerBlocks
end

function BuildService:Destroy()
	self:ClearBlocks()
end

return BuildService
