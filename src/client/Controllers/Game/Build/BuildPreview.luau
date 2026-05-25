-- BuildPreview.luau
-- Preview tipo Minecraft. Usa Mouse API de Roblox (mouse.Target /
-- mouse.TargetSurface / mouse.Hit) que es la implementación canónica para
-- placement systems y tiene mejor desambiguación en bordes de bloques apilados
-- que un raycast manual desde el cursor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local LERP_SPEED = 15

local BuildPreview = {}
BuildPreview.__index = BuildPreview

function BuildPreview.new(predictor)
	local self = setmetatable({}, BuildPreview)
	self.predictor = predictor
	self.previewBlock = nil :: Part?
	self.connection = nil :: RBXScriptConnection?
	self.targetPosition = nil :: Vector3?
	self.isValid = false
	self._firstPositioned = false
	return self
end

function BuildPreview:Show()
	if self.previewBlock then
		return
	end

	local blockProps = GameConfig.GetBlockProperties("Wood")
	local size = GameConfig.BUILD.BLOCK_SIZE

	local part = Instance.new("Part")
	part.Size = Vector3.new(size, size, size)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.6
	part.Color = blockProps.Color
	part.Material = Enum.Material.Neon
	part.CastShadow = false
	part.Name = "BuildPreview"

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "PreviewOutline"
	selectionBox.Adornee = part
	selectionBox.LineThickness = 0.05
	selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
	selectionBox.Transparency = 0.5
	selectionBox.Parent = part

	part.Parent = workspace
	self.previewBlock = part
	self._firstPositioned = false

	-- Mouse.TargetFilter solo admite UNA instancia. El preview es lo más crítico
	-- para excluir (autocollision); el character no estorba porque en TPS la
	-- cámara está detrás del char, no entre la cámara y el cursor.
	mouse.TargetFilter = part

	self.connection = RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end)
end

function BuildPreview:Hide()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.previewBlock then
		mouse.TargetFilter = nil
		self.previewBlock:Destroy()
		self.previewBlock = nil
	end
	self.targetPosition = nil
	self.isValid = false
end

function BuildPreview:_update(deltaTime: number)
	local part = self.previewBlock
	if not part then
		return
	end

	local target = mouse.Target
	if not target or not target:IsA("BasePart") then
		part.Transparency = 1
		self.isValid = false
		self.targetPosition = nil
		return
	end

	-- Convertir NormalId (Top/Bottom/Front/...) a world-space Vector3.
	-- target.CFrame:VectorToWorldSpace transforma el normal local de la cara
	-- al mundo, respetando cualquier rotación del part.
	local localNormal = Vector3.FromNormalId(mouse.TargetSurface)
	local worldNormal = target.CFrame:VectorToWorldSpace(localNormal)
	local hitPosition = mouse.Hit.Position

	-- Algoritmo Minecraft auténtico:
	--   Si el hit es un bloque placeado → ignorar hit.Position, snapped =
	--   centro(target) + normal*size. La celda adyacente es siempre exacta.
	--   Si el hit es mundo (baseplate, etc.) → snap del rawTarget porque no hay
	--   "celda" definida en el target.
	local size = GameConfig.BUILD.BLOCK_SIZE
	local snapped: Vector3
	if target:GetAttribute("IsBlock") then
		snapped = target.Position + worldNormal * size
	else
		snapped = self.predictor:Snap(hitPosition + worldNormal * (size / 2))
	end
	self.targetPosition = snapped

	if not self._firstPositioned then
		part.Position = snapped
		self._firstPositioned = true
	else
		part.Position = part.Position:Lerp(snapped, math.clamp(deltaTime * LERP_SPEED, 0, 1))
	end

	self.isValid = self.predictor:IsValid(snapped)
	local selectionBox = part:FindFirstChild("PreviewOutline") :: SelectionBox?
	if selectionBox then
		if self.isValid then
			selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
			part.Transparency = 0.5
		else
			selectionBox.Color3 = Color3.fromRGB(255, 0, 0)
			part.Transparency = 0.7
		end
	end
end

function BuildPreview:GetTargetPosition(): Vector3?
	return self.targetPosition
end

function BuildPreview:IsValidPlacement(): boolean
	return self.isValid
end

-- Llamado por BuildEffects para hacer parpadear el preview al rechazar.
function BuildPreview:GetPart(): Part?
	return self.previewBlock
end

function BuildPreview:Destroy()
	self:Hide()
end

return BuildPreview
