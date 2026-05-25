-- BuildEffects.luau
-- Efectos visuales/audio para placement y rechazo.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BuildEffects = {}
BuildEffects.__index = BuildEffects

function BuildEffects.new()
	return setmetatable({}, BuildEffects)
end

function BuildEffects:PlayPlacement(position: Vector3)
	local effect = Instance.new("Part")
	effect.Size = Vector3.new(0.5, 0.5, 0.5)
	effect.Position = position
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = 0.5
	effect.Color = Color3.fromRGB(0, 255, 0)
	effect.Material = Enum.Material.Neon
	effect.Shape = Enum.PartType.Ball
	effect.Name = "PlacementEffect"
	effect.Parent = workspace

	TweenService:Create(
		effect,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(6, 6, 6), Transparency = 1 }
	):Play()

	Debris:AddItem(effect, 0.5)
end

function BuildEffects:PlayInvalid(previewPart: Part?)
	if not previewPart then
		return
	end
	local original = previewPart.Transparency
	task.spawn(function()
		for _ = 1, 3 do
			if not previewPart.Parent then
				return
			end
			previewPart.Transparency = 0.9
			task.wait(0.05)
			if not previewPart.Parent then
				return
			end
			previewPart.Transparency = original
			task.wait(0.05)
		end
	end)
end

function BuildEffects:Destroy() end

return BuildEffects
