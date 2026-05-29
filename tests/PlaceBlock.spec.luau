-- PlaceBlock.spec.luau
-- Tests de la validación del use case PlaceBlock con mocks (sin tocar la red ni
-- bloques reales). Verifica: rechazo de player inválido, fase, payload, rate
-- limit, delegación a BuildService y reset de cooldown.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local PlaceBlock = require(ServerScriptService.Server.UseCases.PlaceBlock)
	local Result = require(ReplicatedStorage.Shared.Utils.Result)

	-- Mock mínimo de Player: PlaceBlock solo usa UserId, Name e IsA.
	local function fakePlayer(userId: number?)
		return {
			UserId = userId or 1,
			Name = "TestPlayer",
			IsA = function(_, className)
				return className == "Player"
			end,
		}
	end

	-- Mock de BuildService que registra las llamadas y devuelve un Result fijo.
	local function fakeBuildService(result)
		local calls = {}
		return {
			calls = calls,
			PlaceBlock = function(_, position, blockType, player)
				table.insert(calls, { position = position, blockType = blockType, player = player })
				return result or Result.Ok("block")
			end,
		}
	end

	local building = { currentState = "Building" }
	local validPos = Vector3.new(10, 2, 10)

	describe("PlaceBlock:Execute", function()
		it("rejects an invalid player", function()
			local uc = PlaceBlock(fakeBuildService())
			local r = uc:Execute(validPos, "Wood", nil, building)
			expect(Result.IsErr(r)).to.equal(true)
		end)

		it("rejects building outside the Building phase", function()
			local uc = PlaceBlock(fakeBuildService())
			local r = uc:Execute(validPos, "Wood", fakePlayer(), { currentState = "Battle" })
			expect(Result.IsErr(r)).to.equal(true)
			expect(Result.UnwrapErr(r)).to.equal("Building is only allowed during Building phase")
		end)

		it("rejects a non-finite (NaN) position", function()
			local uc = PlaceBlock(fakeBuildService())
			local nan = 0 / 0
			local r = uc:Execute(Vector3.new(nan, nan, nan), "Wood", fakePlayer(), building)
			expect(Result.IsErr(r)).to.equal(true)
		end)

		it("rejects a position out of world bounds", function()
			local uc = PlaceBlock(fakeBuildService())
			local r = uc:Execute(Vector3.new(99999, 2, 0), "Wood", fakePlayer(), building)
			expect(Result.IsErr(r)).to.equal(true)
		end)

		it("delegates to BuildService on a valid placement", function()
			local bs = fakeBuildService(Result.Ok("ok"))
			local uc = PlaceBlock(bs)
			local r = uc:Execute(validPos, "Wood", fakePlayer(), building)
			expect(Result.IsOk(r)).to.equal(true)
			expect(#bs.calls).to.equal(1)
			expect(bs.calls[1].blockType).to.equal("Wood")
		end)

		it("rate-limits a second immediate placement from the same player", function()
			local bs = fakeBuildService()
			local uc = PlaceBlock(bs)
			local player = fakePlayer(42)
			local first = uc:Execute(validPos, "Wood", player, building)
			local second = uc:Execute(validPos, "Wood", player, building)
			expect(Result.IsOk(first)).to.equal(true)
			expect(Result.IsErr(second)).to.equal(true)
			expect(Result.UnwrapErr(second)).to.equal("Rate limit exceeded")
			-- El delegate solo corrió una vez: la 2da se rechazó antes de llegar.
			expect(#bs.calls).to.equal(1)
		end)

		it("ClearPlayer resets the rate limit", function()
			local bs = fakeBuildService()
			local uc = PlaceBlock(bs)
			local player = fakePlayer(7)
			uc:Execute(validPos, "Wood", player, building)
			uc:ClearPlayer(7)
			local afterClear = uc:Execute(validPos, "Wood", player, building)
			expect(Result.IsOk(afterClear)).to.equal(true)
			expect(#bs.calls).to.equal(2)
		end)
	end)
end
