-- BuildService.luau
-- Lista autoritativa de bloques + representación física. Indexa por celda de
-- grid (Grid.CellKey) para que la validación de ocupación sea determinista y
-- coincida con la del cliente bit-a-bit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Block = require(ReplicatedStorage.Shared.Entities.Block)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Grid = require(ReplicatedStorage.Shared.Utils.Grid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("BuildService")

local BuildService = {}
BuildService.__index = BuildService

function BuildService.new(network)
	assert(network, "BuildService requires a ServerNetwork instance")
	local self = setmetatable({}, BuildService)
	self.network = network
	self.placedBlocks = {} -- [id] = Block
	self.blockParts = {} -- [id] = Part
	self.cellOwners = {} -- [cellKey] = id   (índice rápido por celda)
	return self
end

local function snapToGrid(position: Vector3): Vector3
	return Grid.Snap(position, GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.GRID_ORIGIN)
end

local function cellKey(position: Vector3): string
	return Grid.CellKey(position, GameConfig.BUILD.BLOCK_SIZE, GameConfig.BUILD.GRID_ORIGIN)
end

function BuildService:CanPlaceBlock(snappedPosition: Vector3, player: Player)
	if not player or not player:IsA("Player") then
		return Result.Err("Invalid player")
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return Result.Err("Player character not found")
	end

	local distance = (snappedPosition - character.HumanoidRootPart.Position).Magnitude
	local maxDistance = GameConfig.BUILD.MAX_PLACEMENT_DISTANCE
	if distance > maxDistance then
		return Result.Err(string.format("Too far away (max: %d studs)", maxDistance))
	end

	if self.cellOwners[cellKey(snappedPosition)] then
		return Result.Err("Cell already occupied")
	end

	return Result.Ok(true)
end

function BuildService:PlaceBlock(position: Vector3, blockType: Block.BlockType, player: Player)
	if not GameConfig.IsValidBlockType(blockType) then
		return Result.Err("Invalid block type")
	end

	-- Snap autoritativo: el cliente envía una posición ya snapeada, pero re-snapeamos
	-- por defensa contra clientes manipulados.
	local snapped = snapToGrid(position)

	local canPlaceResult = self:CanPlaceBlock(snapped, player)
	if Result.IsErr(canPlaceResult) then
		return canPlaceResult
	end

	local block = Block.new(snapped, blockType, player.UserId)
	local part = self:CreateBlockPart(block, blockType)
	if not part then
		return Result.Err("Failed to create block part")
	end

	self.placedBlocks[block.id] = block
	self.blockParts[block.id] = part
	self.cellOwners[cellKey(snapped)] = block.id

	self.network:FireAll(Events.BlockPlaced, block.id, snapped, blockType, player.UserId)

	logger:Info("Block placed: %s by userId=%d", block.id, player.UserId)
	return Result.Ok(block)
end

function BuildService:CreateBlockPart(block, blockType: Block.BlockType): Part?
	local blockProperties = GameConfig.GetBlockProperties(blockType)
	if not blockProperties then
		logger:Error("No properties found for block type: %s", blockType)
		return nil
	end

	local size = GameConfig.BUILD.BLOCK_SIZE
	local part = Instance.new("Part")
	part.Name = block.id
	part.Size = Vector3.new(size, size, size)
	part.Position = block.position
	part.Anchored = true
	part.CanCollide = true
	part.Color = blockProperties.Color
	part.Material = blockProperties.Material

	part:SetAttribute("IsBlock", true)
	part:SetAttribute("BlockOwnerId", block.ownerId)
	part:SetAttribute("BlockType", blockType)
	part:SetAttribute("BlockHealth", blockProperties.Health)

	part.Parent = workspace
	return part
end

function BuildService:ClearBlocks()
	local count = 0
	for _, part in pairs(self.blockParts) do
		if part.Parent then
			part:Destroy()
			count += 1
		end
	end
	self.placedBlocks = {}
	self.blockParts = {}
	self.cellOwners = {}

	self.network:FireAll(Events.BlocksCleared)
	logger:Info("Cleared %d blocks", count)
end

function BuildService:GetBlockCount(): number
	local count = 0
	for _ in pairs(self.placedBlocks) do
		count += 1
	end
	return count
end

function BuildService:GetPlayerBlocks(ownerId: number): { Block.Block }
	local playerBlocks = {}
	for _, block in pairs(self.placedBlocks) do
		if block.ownerId == ownerId then
			table.insert(playerBlocks, block)
		end
	end
	return playerBlocks
end

-- Reenvía todos los bloques actuales a un jugador recién llegado para que su
-- BuildPredictor (occupiedCells) arranque sincronizado. Los Parts ya replican
-- nativamente vía workspace; esto solo alimenta la predicción cliente, evitando
-- que el preview se pinte verde sobre celdas ya ocupadas. Reusa el evento
-- BlockPlaced (mismo handler cliente) en lugar de un evento de snapshot nuevo.
function BuildService:SendSnapshotToPlayer(player: Player)
	for id, block in pairs(self.placedBlocks) do
		self.network:FireClient(Events.BlockPlaced, player, id, block.position, block.blockType, block.ownerId)
	end
end

function BuildService:Destroy()
	self:ClearBlocks()
end

return BuildService
