-- PlaceBlock.luau
-- Factory function que retorna un use case con rate-limit state encapsulado.
-- Validaciones: fase activa, payload sano, cooldown por jugador. La validación
-- de celda/ocupación la hace BuildService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Block = require(ReplicatedStorage.Shared.Entities.Block)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("PlaceBlock")

local MAX_WORLD_DISTANCE = 10000 -- sanity bound contra posiciones absurdas

local function isFiniteVector3(v: Vector3): boolean
	-- NaN nunca es igual a sí mismo
	return v.X == v.X
		and v.Y == v.Y
		and v.Z == v.Z
		and math.abs(v.X) ~= math.huge
		and math.abs(v.Y) ~= math.huge
		and math.abs(v.Z) ~= math.huge
end

export type PlaceBlockUseCase = {
	Execute: (
		self: PlaceBlockUseCase,
		position: Vector3,
		blockType: Block.BlockType,
		player: Player,
		currentGameState: any
	) -> any,
	ClearPlayer: (self: PlaceBlockUseCase, userId: number) -> (),
}

local function PlaceBlock(buildService): PlaceBlockUseCase
	local lastPlacement: { [number]: number } = {}

	local self = {} :: PlaceBlockUseCase

	function self:Execute(position, blockType, player, currentGameState)
		if not player or not player:IsA("Player") then
			return Result.Err("Invalid player")
		end

		local cooldown = GameConfig.BUILD.PLACEMENT_COOLDOWN
		local now = os.clock()
		local last = lastPlacement[player.UserId] or 0
		if now - last < cooldown then
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

		local result = buildService:PlaceBlock(position, blockType, player)
		if Result.IsOk(result) then
			lastPlacement[player.UserId] = now
		end
		return result
	end

	function self:ClearPlayer(userId: number)
		lastPlacement[userId] = nil
	end

	return self
end

return PlaceBlock
