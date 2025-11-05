-- BuildService.luau (Servicio para manejar la construcción de bloques)
-- Gestiona la lista de bloques colocados con validación robusta

local Block = require(game.ReplicatedStorage.Shared.Entities.Block)
local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local Result = require(game.ReplicatedStorage.Shared.Utils.Result)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)
local NetworkManager = require(game.ReplicatedStorage.Shared.Utils.NetworkManager)

local logger = Logger.new("BuildService")

local BuildService = {}
BuildService.__index = BuildService

function BuildService.new(networkManager: any?)
	local self = setmetatable({}, BuildService)
	self.placedBlocks = {} -- Tabla de bloques por ID
	self.networkManager = networkManager or NetworkManager.new()
	self.blockParts = {} -- Cache de partes físicas por ID
	logger:Info("BuildService initialized")
	return self
end

-- Validar si un bloque puede ser colocado en la posición especificada
function BuildService:CanPlaceBlock(position: Vector3, player: Player): Result.Result<boolean, string>
	-- Validar jugador
	if not player or not player:IsA("Player") then
		return Result.Err("Invalid player")
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return Result.Err("Player character not found")
	end

	-- Validar distancia
	local distance = (position - character.HumanoidRootPart.Position).Magnitude
	local maxDistance = GameConfig.BUILD.MAX_PLACEMENT_DISTANCE

	if distance > maxDistance then
		logger:Warn("Player %s tried to place block too far away: %.1f studs", player.Name, distance)
		return Result.Err(string.format("Too far away (max: %d studs)", maxDistance))
	end

	-- Verificar colisión con otros bloques
	local minSeparation = GameConfig.BUILD.MIN_BLOCK_SEPARATION
	for _, block in pairs(self.placedBlocks) do
		if (block.position - position).Magnitude < minSeparation then
			return Result.Err("Block too close to another block")
		end
	end

	return Result.Ok(true)
end

-- Colocar un bloque en el mundo
function BuildService:PlaceBlock(position: Vector3, blockType: Block.BlockType, player: Player): Result.Result<Block.Block, string>
	-- Validar tipo de bloque
	if not GameConfig.IsValidBlockType(blockType) then
		logger:Error("Invalid block type: %s", tostring(blockType))
		return Result.Err("Invalid block type")
	end

	-- Validar si se puede colocar
	local canPlaceResult = self:CanPlaceBlock(position, player)
	if Result.IsErr(canPlaceResult) then
		return Result.Err(Result.UnwrapErr(canPlaceResult))
	end

	-- Crear la entidad del bloque
	local block = Block.new(position, blockType, player.Name)
	self.placedBlocks[block.id] = block

	-- Crear la representación física
	local part = self:CreateBlockPart(block, blockType)
	if not part then
		self.placedBlocks[block.id] = nil
		return Result.Err("Failed to create block part")
	end

	self.blockParts[block.id] = part

	-- Broadcast a clientes
	self.networkManager:FireAllClients(GameConfig.EVENTS.PLACE_BLOCK, block.id, position, blockType, player.Name)

	logger:Info("Block placed: %s by %s at %s", block.id, player.Name, tostring(position))
	return Result.Ok(block)
end

-- Crear la parte física del bloque
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

	-- Agregar atributos para identificación
	part:SetAttribute("IsBlock", true)
	part:SetAttribute("BlockOwner", block.owner)
	part:SetAttribute("BlockType", blockType)
	part:SetAttribute("BlockHealth", blockProperties.Health)

	part.Parent = workspace

	return part
end

-- Limpiar todos los bloques
function BuildService:ClearBlocks()
	logger:Info("Clearing all blocks...")
	local clearedCount = 0

	-- Destruir todas las partes físicas
	for id, part in pairs(self.blockParts) do
		if part and part.Parent then
			part:Destroy()
			clearedCount += 1
		end
	end

	-- También limpiar cualquier bloque huérfano
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

-- Obtener el número de bloques colocados
function BuildService:GetBlockCount(): number
	local count = 0
	for _ in pairs(self.placedBlocks) do
		count += 1
	end
	return count
end

-- Obtener bloques de un jugador específico
function BuildService:GetPlayerBlocks(playerName: string): { Block.Block }
	local playerBlocks = {}
	for _, block in pairs(self.placedBlocks) do
		if block.owner == playerName then
			table.insert(playerBlocks, block)
		end
	end
	return playerBlocks
end

-- Cleanup
function BuildService:Destroy()
	logger:Info("Destroying BuildService")
	self:ClearBlocks()
	if self.networkManager then
		self.networkManager:Destroy()
	end
end

return BuildService
