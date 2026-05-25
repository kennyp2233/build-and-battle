-- BuildController.luau (Cliente)
-- Input + preview de construcción. Pide al servidor con PlaceBlockRequest
-- y reacciona al broadcast BlockPlaced para efectos locales.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local player = Players.LocalPlayer
local logger = Logger.new("BuildController")

local PLACEMENT_COOLDOWN = 0.2

local BuildController = {}
BuildController.__index = BuildController

local function SnapToGrid(pos: Vector3, gridSize: number, origin: Vector3?)
	origin = origin or Vector3.new(0, 0, 0)
	return Vector3.new(
		math.floor((pos.X - origin.X) / gridSize + 0.5) * gridSize + origin.X,
		math.floor((pos.Y - origin.Y) / gridSize + 0.5) * gridSize + origin.Y,
		math.floor((pos.Z - origin.Z) / gridSize + 0.5) * gridSize + origin.Z
	)
end

function BuildController.new(network)
	assert(network, "BuildController requires a ClientNetwork instance")
	local self = setmetatable({}, BuildController)

	self.network = network
	self.maid = Maid.new()

	self.previewBlock = nil
	self.previewConnection = nil
	self.isEquipped = false
	self.currentTool = nil
	self.targetPosition = nil
	self.isValidPlacement = false
	self.lastPlacementTime = 0
	self._firstPreviewPositioned = false

	self.maid:Give(self.network:On(Events.BlockPlaced, function(id, position, blockType, owner)
		self:OnBlockPlaced(id, position, blockType, owner)
	end))

	-- Server rechaza una colocación → feedback visual/audio para que el jugador sepa
	self.maid:Give(self.network:On(Events.PlaceBlockRejected, function(reason)
		self:OnPlacementRejected(reason)
	end))

	self:SetupTool()

	logger:Info("BuildController initialized")
	return self
end

function BuildController:SetupTool()
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	self.maid:Give(backpack.ChildAdded:Connect(function(child)
		if child.Name == "BuildTool" and child:IsA("Tool") then
			self:ConnectTool(child)
		end
	end))

	self.maid:Give(character.ChildAdded:Connect(function(child)
		if child.Name == "BuildTool" and child:IsA("Tool") then
			self:ConnectTool(child)
		end
	end))

	for _, child in ipairs(backpack:GetChildren()) do
		if child.Name == "BuildTool" and child:IsA("Tool") then
			self:ConnectTool(child)
		end
	end
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "BuildTool" and child:IsA("Tool") then
			self:ConnectTool(child)
		end
	end
end

function BuildController:ConnectTool(tool)
	if tool:GetAttribute("Connected") then
		return
	end
	tool:SetAttribute("Connected", true)
	self.currentTool = tool

	self.maid:Give(tool.Equipped:Connect(function()
		self.isEquipped = true
		self._firstPreviewPositioned = false
		self:ShowPreview()
	end))

	self.maid:Give(tool.Unequipped:Connect(function()
		self.isEquipped = false
		self:HidePreview()
	end))

	self.maid:Give(tool.Activated:Connect(function()
		local currentTime = tick()
		if currentTime - self.lastPlacementTime < PLACEMENT_COOLDOWN then
			return
		end

		if self.previewBlock and self.previewBlock.Transparency < 1 and self.isValidPlacement then
			local position = self.targetPosition or self.previewBlock.Position
			self:RequestPlaceBlock(position, "Wood")
			self.lastPlacementTime = currentTime
			self:PlayPlacementEffect(position)
		elseif not self.isValidPlacement then
			self:PlayInvalidPlacementEffect()
		end
	end))
end

function BuildController:RequestPlaceBlock(position: Vector3, blockType: string)
	self.network:Fire(Events.PlaceBlockRequest, position, blockType)
end

function BuildController:OnBlockPlaced(id, position, blockType, owner)
	logger:Debug("Block placed broadcast: %s by %s", id, owner)
	-- Hook futuro: efectos locales (particulas, sonido)
end

function BuildController:OnPlacementRejected(reason: string)
	logger:Warn("Placement rejected by server: %s", reason)
	-- Feedback visual al jugador: el preview parpadea rojo
	self:PlayInvalidPlacementEffect()
end

function BuildController:ShowPreview()
	if self.previewBlock then
		return
	end

	local blockProps = GameConfig.GetBlockProperties("Wood")
	self.previewBlock = Instance.new("Part")
	self.previewBlock.Size = Vector3.new(
		GameConfig.BUILD.BLOCK_SIZE,
		GameConfig.BUILD.BLOCK_SIZE,
		GameConfig.BUILD.BLOCK_SIZE
	)
	self.previewBlock.Anchored = true
	self.previewBlock.CanCollide = false
	self.previewBlock.Transparency = 0.6
	self.previewBlock.Color = blockProps.Color
	self.previewBlock.Material = Enum.Material.Neon
	self.previewBlock.CastShadow = false
	self.previewBlock.Name = "BuildPreview"
	self.previewBlock.Parent = workspace

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "PreviewOutline"
	selectionBox.Adornee = self.previewBlock
	selectionBox.LineThickness = 0.05
	selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
	selectionBox.Transparency = 0.5
	selectionBox.Parent = self.previewBlock

	self.previewConnection = RunService.RenderStepped:Connect(function(deltaTime)
		self:UpdatePreview(deltaTime)
	end)
end

function BuildController:HidePreview()
	if self.previewBlock then
		self.previewBlock:Destroy()
		self.previewBlock = nil
	end
	if self.previewConnection then
		self.previewConnection:Disconnect()
		self.previewConnection = nil
	end
end

function BuildController:UpdatePreview(deltaTime)
	if not self.previewBlock or not self.isEquipped then
		return
	end

	local camera = workspace.CurrentCamera
	local mouseLocation = UserInputService:GetMouseLocation()
	-- ScreenPointToRay (no ViewportPointToRay) porque GetMouseLocation incluye
	-- el inset del topbar de Roblox; ScreenPoint usa el mismo sistema de coordenadas.
	local unitRay = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character, self.previewBlock }

	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

	if raycastResult and raycastResult.Instance and raycastResult.Instance:IsA("BasePart") then
		local gridSize = GameConfig.BUILD.BLOCK_SIZE
		local origin = GameConfig.BUILD.GRID_ORIGIN or Vector3.new(0, 0, 0)

		local rawTarget = raycastResult.Position + (raycastResult.Normal * (gridSize / 2))
		self.targetPosition = SnapToGrid(rawTarget, gridSize, origin)

		local lerpSpeed = 15
		if not self._firstPreviewPositioned then
			self.previewBlock.Position = self.targetPosition
			self._firstPreviewPositioned = true
		else
			self.previewBlock.Position = self.previewBlock.Position:Lerp(
				self.targetPosition,
				math.clamp(deltaTime * lerpSpeed, 0, 1)
			)
		end

		self.isValidPlacement = self:CheckValidPlacement(self.targetPosition)

		local selectionBox = self.previewBlock:FindFirstChild("PreviewOutline")
		if selectionBox then
			if self.isValidPlacement then
				selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
				self.previewBlock.Transparency = 0.5
			else
				selectionBox.Color3 = Color3.fromRGB(255, 0, 0)
				self.previewBlock.Transparency = 0.7
			end
		end
	else
		self.previewBlock.Transparency = 1
		self.isValidPlacement = false
	end
end

function BuildController:CheckValidPlacement(position: Vector3): boolean
	if not position or not player.Character then
		return false
	end

	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	if (position - hrp.Position).Magnitude > GameConfig.BUILD.MAX_PLACEMENT_DISTANCE then
		return false
	end

	local blockSize = GameConfig.BUILD.BLOCK_SIZE
	local origin = GameConfig.BUILD.GRID_ORIGIN or Vector3.new(0, 0, 0)
	local epsilon = 0.05
	local checkSize = Vector3.new(blockSize - epsilon, blockSize - epsilon, blockSize - epsilon)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { player.Character, self.previewBlock }

	local touching = workspace:GetPartBoundsInBox(CFrame.new(position), checkSize, overlapParams)

	for _, part in ipairs(touching) do
		if part:GetAttribute("IsBlock") or part.CanCollide then
			local snappedPart = SnapToGrid(part.Position, blockSize, origin)
			if snappedPart == position then
				return false
			end
		end
	end

	return true
end

function BuildController:PlayPlacementEffect(position: Vector3)
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

	local tween = TweenService:Create(
		effect,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(6, 6, 6), Transparency = 1 }
	)
	tween:Play()

	Debris:AddItem(effect, 0.5)
end

function BuildController:PlayInvalidPlacementEffect()
	if not self.previewBlock then
		return
	end
	local originalTransparency = self.previewBlock.Transparency
	task.spawn(function()
		for _ = 1, 3 do
			if not self.previewBlock then return end
			self.previewBlock.Transparency = 0.9
			task.wait(0.05)
			if not self.previewBlock then return end
			self.previewBlock.Transparency = originalTransparency
			task.wait(0.05)
		end
	end)
end

function BuildController:Destroy()
	self:HidePreview()
	self.maid:Clean()
end

return BuildController
