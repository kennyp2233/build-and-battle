-- PlaceBlock.luau (Caso de uso para colocar un bloque)
-- Lógica de negocio para construcción con validación de estado del juego

local Block = require(game.ReplicatedStorage.Shared.Entities.Block)
local Result = require(game.ReplicatedStorage.Shared.Utils.Result)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("PlaceBlock")

local PlaceBlock = {}
PlaceBlock.__index = PlaceBlock

function PlaceBlock.new(buildService)
	local self = setmetatable({}, PlaceBlock)
	self.buildService = buildService
	logger:Info("PlaceBlock use case initialized")
	return self
end

function PlaceBlock:Execute(
	position: Vector3,
	blockType: Block.BlockType,
	player: Player,
	currentGameState
): Result.Result<Block.Block, string>
	-- Validar que el jugador existe
	if not player or not player:IsA("Player") then
		logger:Error("Invalid player attempted to place block")
		return Result.Err("Invalid player")
	end

	-- Solo permitir en fase Building
	if not currentGameState or currentGameState.currentState ~= "Building" then
		logger:Warn("Player %s tried to build outside Building phase (current: %s)", player.Name, tostring(currentGameState and currentGameState.currentState or "nil"))
		return Result.Err("Building is only allowed during Building phase")
	end

	-- Validar posición
	if not position or typeof(position) ~= "Vector3" then
		logger:Error("Invalid position provided: %s", tostring(position))
		return Result.Err("Invalid position")
	end

	-- Intentar colocar el bloque a través del servicio
	local result = self.buildService:PlaceBlock(position, blockType, player)

	if Result.IsOk(result) then
		local block = Result.Unwrap(result)
		logger:Info("Block placed successfully: %s by %s", block.id, player.Name)
	else
		local error = Result.UnwrapErr(result)
		logger:Warn("Failed to place block for %s: %s", player.Name, error)
	end

	return result
end

return PlaceBlock