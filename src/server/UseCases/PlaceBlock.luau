-- PlaceBlock.luau (Caso de uso para colocar un bloque)
-- Validaciones server-side: fase, payload sano, rate-limit por jugador.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Block = require(ReplicatedStorage.Shared.Entities.Block)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("PlaceBlock")

local COOLDOWN_SECONDS = 0.1
local MAX_WORLD_DISTANCE = 10000 -- sanity bound contra posiciones absurdas

local PlaceBlock = {}
PlaceBlock.__index = PlaceBlock

function PlaceBlock.new(buildService)
	local self = setmetatable({}, PlaceBlock)
	self.buildService = buildService
	self.lastPlacement = {} -- [userId] = os.clock()
	return self
end

local function isFiniteVector3(v: Vector3): boolean
	-- NaN nunca es igual a sí mismo
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) ~= math.huge
		and math.abs(v.Y) ~= math.huge
		and math.abs(v.Z) ~= math.huge
end

function PlaceBlock:Execute(
	position: Vector3,
	blockType: Block.BlockType,
	player: Player,
	currentGameState
)
	if not player or not player:IsA("Player") then
		return Result.Err("Invalid player")
	end

	-- Rate limit por jugador
	local now = os.clock()
	local last = self.lastPlacement[player.UserId] or 0
	if now - last < COOLDOWN_SECONDS then
		return Result.Err("Rate limit exceeded")
	end

	if not currentGameState or currentGameState.currentState ~= "Building" then
		logger:Warn("Player %s tried to build outside Building phase", player.Name)
		return Result.Err("Building is only allowed during Building phase")
	end

	if typeof(position) ~= "Vector3" or not isFiniteVector3(position) then
		return Result.Err("Invalid position")
	end
	if position.Magnitude > MAX_WORLD_DISTANCE then
		return Result.Err("Position out of bounds")
	end

	local result = self.buildService:PlaceBlock(position, blockType, player)
	if Result.IsOk(result) then
		self.lastPlacement[player.UserId] = now
	end
	return result
end

function PlaceBlock:ClearPlayer(userId: number)
	self.lastPlacement[userId] = nil
end

return PlaceBlock
