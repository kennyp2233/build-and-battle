-- Block.luau (Entidad pura para representar un bloque construido)

local HttpService = game:GetService("HttpService")

export type BlockType = "Wood" | "Stone" | "Metal"

export type Block = {
	position: Vector3,
	blockType: BlockType,
	owner: string,
	id: string,
}

local Block = {}
Block.__index = Block

function Block.new(position: Vector3, blockType: BlockType, owner: string): Block
	local instance = {
		position = position,
		blockType = blockType,
		owner = owner,
		id = HttpService:GenerateGUID(false),
	}
	setmetatable(instance, Block)
	return instance
end

return Block
