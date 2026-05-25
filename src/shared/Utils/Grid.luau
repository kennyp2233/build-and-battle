-- Grid.luau
-- Snap a grid + identidad de celda. Compartido server/cliente para que la
-- validación de ocupación use exactamente el mismo cálculo en ambos lados.

local Grid = {}

local function cellIndex(coord: number, gridSize: number, originCoord: number): number
	return math.floor((coord - originCoord) / gridSize + 0.5)
end

function Grid.Snap(position: Vector3, gridSize: number, origin: Vector3): Vector3
	return Vector3.new(
		cellIndex(position.X, gridSize, origin.X) * gridSize + origin.X,
		cellIndex(position.Y, gridSize, origin.Y) * gridSize + origin.Y,
		cellIndex(position.Z, gridSize, origin.Z) * gridSize + origin.Z
	)
end

-- Clave única determinista de la celda. Server y cliente comparan con esto,
-- no con `==` de Vector3 (que es frágil a floating point).
function Grid.CellKey(position: Vector3, gridSize: number, origin: Vector3): string
	return string.format(
		"%d,%d,%d",
		cellIndex(position.X, gridSize, origin.X),
		cellIndex(position.Y, gridSize, origin.Y),
		cellIndex(position.Z, gridSize, origin.Z)
	)
end

return Grid
