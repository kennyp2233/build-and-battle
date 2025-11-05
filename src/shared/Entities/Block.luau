-- Block.luau (Entidad para representar un bloque construido)
-- Esta es una entidad pura, independiente de Roblox

export type BlockType = "Wood" | "Stone" | "Metal"

export type Block = {
    position: Vector3,
    blockType: BlockType,
    owner: string,  -- Nombre del jugador
    id: string,     -- ID único
}

local Block = {}

Block.__index = Block

function Block.new(position: Vector3, blockType: BlockType, owner: string): Block
    local id = owner .. "_" .. tostring(position) .. "_" .. blockType .. "_" .. tick()
    local instance = {
        position = position,
        blockType = blockType,
        owner = owner,
        id = id,
    }
    setmetatable(instance, Block)
    return instance
end

return Block