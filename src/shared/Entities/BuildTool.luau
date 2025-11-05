-- BuildTool.luau (Herramienta para construcción)
-- Se da a los jugadores en fase Building

local BuildTool = {}
BuildTool.__index = BuildTool

function BuildTool.new()
	local tool = Instance.new("Tool")
	tool.Name = "BuildTool"
	tool.RequiresHandle = true -- IMPORTANTE: true para que funcionen los eventos
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(90), 0, 0)

	-- Crear un handle invisible (necesario para que la Tool funcione)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 1)
	handle.Transparency = 1 -- Invisible
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	-- Agregar un mesh para darle forma visual (opcional)
	local mesh = Instance.new("BlockMesh")
	mesh.Scale = Vector3.new(1, 1, 2)
	mesh.Parent = handle

	return tool
end

return BuildTool