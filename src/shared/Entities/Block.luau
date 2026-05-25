-- Block.luau (Entidad pura para representar un bloque construido)
-- ownerId es la única fuente para "es mi bloque" — no usar nombre del player.
-- id puede inyectarse (tests, replay); si es nil se autogenera.

local HttpService = game:GetService("HttpService")

export type BlockType = "Wood" | "Stone" | "Metal"

export type Block = {
	position: Vector3,
	blockType: BlockType,
	ownerId: number,
	id: string,
}

local Block = {}
Block.__index = Block

function Block.new(position: Vector3, blockType: BlockType, ownerId: number, id: string?): Block
	local instance = {
		position = position,
		blockType = blockType,
		ownerId = ownerId,
		id = id or HttpService:GenerateGUID(false),
	}
	setmetatable(instance, Block)
	return instance
end

return Block
