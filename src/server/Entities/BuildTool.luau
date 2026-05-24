-- BuildTool.luau
-- Server-only builder: el servidor instancia esta Tool y la entrega al Backpack del jugador
-- durante la fase Building. Vive en server porque el cliente nunca debe instanciar Tools de gameplay.

local BuildTool = {}

function BuildTool.new(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "BuildTool"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(90), 0, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 1)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local mesh = Instance.new("BlockMesh")
	mesh.Scale = Vector3.new(1, 1, 2)
	mesh.Parent = handle

	return tool
end

return BuildTool
