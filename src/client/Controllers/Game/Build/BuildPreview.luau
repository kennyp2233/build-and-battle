-- BuildPreview.luau
-- Visualización del bloque-ghost: raycast desde el mouse, snap a grid,
-- pinta verde/rojo según el predictor. Expone GetTargetPosition() y
-- IsValidPlacement() para que el caller (BuildController) las consulte
-- al activar el Tool.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer

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

	local camera = workspace.CurrentCamera
	local mouseLocation = UserInputService:GetMouseLocation()
	-- ScreenPointToRay (no ViewportPointToRay) porque GetMouseLocation incluye
	-- el inset del topbar de Roblox.
	local unitRay = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character, part }

	local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

	if not (hit and hit.Instance and hit.Instance:IsA("BasePart")) then
		part.Transparency = 1
		self.isValid = false
		self.targetPosition = nil
		return
	end

	local size = GameConfig.BUILD.BLOCK_SIZE
	local rawTarget = hit.Position + (hit.Normal * (size / 2))
	local snapped = self.predictor:Snap(rawTarget)
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
