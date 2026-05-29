-- Grid.spec.luau
-- Tests de Grid: el módulo compartido cliente/server. La propiedad crítica es el
-- determinismo — dos puntos dentro de la misma celda deben producir la MISMA
-- CellKey en ambos lados, o la validación de ocupación se desincroniza.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Grid = require(ReplicatedStorage.Shared.Utils.Grid)
	local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

	local SIZE = GameConfig.BUILD.BLOCK_SIZE -- 4
	local ORIGIN = GameConfig.BUILD.GRID_ORIGIN -- (0, 2, 0)

	describe("Grid.Snap", function()
		it("snaps a point near the origin to the origin cell center", function()
			local snapped = Grid.Snap(Vector3.new(1, 2, 1), SIZE, ORIGIN)
			expect(snapped.X).to.equal(0)
			expect(snapped.Y).to.equal(2)
			expect(snapped.Z).to.equal(0)
		end)

		it("aligns Y to the origin offset (primer nivel centrado en origin.Y)", function()
			local snapped = Grid.Snap(Vector3.new(0, 2, 0), SIZE, ORIGIN)
			expect(snapped.Y).to.equal(ORIGIN.Y)
		end)

		it("is idempotent: snapping an already-snapped point returns it", function()
			local once = Grid.Snap(Vector3.new(7, 5, -3), SIZE, ORIGIN)
			local twice = Grid.Snap(once, SIZE, ORIGIN)
			expect(twice.X).to.equal(once.X)
			expect(twice.Y).to.equal(once.Y)
			expect(twice.Z).to.equal(once.Z)
		end)

		it("handles negative coordinates", function()
			-- cellIndex(-5, 4, 0) = floor(-1.25 + 0.5) = floor(-0.75) = -1 -> -4
			local snapped = Grid.Snap(Vector3.new(-5, 2, -5), SIZE, ORIGIN)
			expect(snapped.X).to.equal(-4)
			expect(snapped.Z).to.equal(-4)
		end)
	end)

	describe("Grid.CellKey", function()
		it("returns the same key for two distinct points in the same cell", function()
			-- Ambos caen en el rango [-2, 2) -> índice de celda 0 en X/Z.
			local a = Grid.CellKey(Vector3.new(0.5, 2, 0.5), SIZE, ORIGIN)
			local b = Grid.CellKey(Vector3.new(-0.9, 3, 1.4), SIZE, ORIGIN)
			expect(a).to.equal(b)
		end)

		it("returns different keys for adjacent cells", function()
			local a = Grid.CellKey(Vector3.new(0, 2, 0), SIZE, ORIGIN)
			local b = Grid.CellKey(Vector3.new(SIZE, 2, 0), SIZE, ORIGIN)
			expect(a).never.to.equal(b)
		end)

		it("agrees with Snap: same cell -> same snapped position", function()
			local p1 = Vector3.new(0.5, 2, 0.5)
			local p2 = Vector3.new(1.4, 2, -0.9)
			expect(Grid.CellKey(p1, SIZE, ORIGIN)).to.equal(Grid.CellKey(p2, SIZE, ORIGIN))
			local s1 = Grid.Snap(p1, SIZE, ORIGIN)
			local s2 = Grid.Snap(p2, SIZE, ORIGIN)
			expect(s1.X).to.equal(s2.X)
			expect(s1.Z).to.equal(s2.Z)
		end)

		it("formats as an integer triplet x,y,z", function()
			local key = Grid.CellKey(Vector3.new(0, 2, 0), SIZE, ORIGIN)
			expect(key).to.equal("0,0,0")
		end)
	end)
end
