-- BuildController.luau (Controlador para manejar la construcción en el cliente)
-- Maneja inputs del jugador y actualiza bloques colocados con configuración centralizada

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local player = Players.LocalPlayer
local logger = Logger.new("BuildController")

local BuildController = {}
BuildController.__index = BuildController

-- Helpers
local function SnapToGrid(pos: Vector3, gridSize: number, origin: Vector3?)
	origin = origin or Vector3.new(0, 0, 0)
	return Vector3.new(
		math.floor((pos.X - origin.X) / gridSize + 0.5) * gridSize + origin.X,
		math.floor((pos.Y - origin.Y) / gridSize + 0.5) * gridSize + origin.Y,
		math.floor((pos.Z - origin.Z) / gridSize + 0.5) * gridSize + origin.Z
	)
end

function BuildController.new()
	local self = setmetatable({}, BuildController)

	-- Esperar el evento con timeout de 10 segundos
	self.placeBlockEvent = ReplicatedStorage:WaitForChild(GameConfig.EVENTS.PLACE_BLOCK, 10)
	if not self.placeBlockEvent then
		logger:Error("Failed to find PlaceBlock event after 10 seconds")
		return self
	end

	self.previewBlock = nil
	self.previewConnection = nil
	self.isEquipped = false
	self.currentTool = nil
	self.targetPosition = nil -- Para interpolación suave
	self.isValidPlacement = false -- Para validación visual
	self.lastPlacementTime = 0 -- Para cooldown
	self._firstPreviewPositioned = false

	-- Escuchar cuando se coloca un bloque
	self.placeBlockEvent.OnClientEvent:Connect(function(id, position, blockType, owner)
		self:OnBlockPlaced(id, position, blockType, owner)
	end)

	-- Configurar herramienta de construcción
	self:SetupTool()

	logger:Info("BuildController initialized")
	return self
end

function BuildController:SetupTool()
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	-- Conectar cuando se añade una nueva herramienta al backpack
	backpack.ChildAdded:Connect(function(child)
		if child.Name == "BuildTool" and child:IsA("Tool") then
			logger:Info("BuildTool detected in backpack (ChildAdded)")
			self:ConnectTool(child)
		end
	end)

	-- Conectar cuando se añade una herramienta al character (equipada)
	character.ChildAdded:Connect(function(child)
		if child.Name == "BuildTool" and child:IsA("Tool") then
			logger:Info("BuildTool detected in character (ChildAdded)")
			self:ConnectTool(child)
		end
	end)

	-- Verificar si ya tiene la herramienta en el backpack
	for _, child in ipairs(backpack:GetChildren()) do
		if child.Name == "BuildTool" and child:IsA("Tool") then
			logger:Info("BuildTool found in backpack (initial check)")
			self:ConnectTool(child)
		end
	end

	-- Verificar si ya tiene la herramienta equipada en el character
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "BuildTool" and child:IsA("Tool") then
			logger:Info("BuildTool found in character (initial check)")
			self:ConnectTool(child)
		end
	end

	logger:Debug("SetupTool completed")
end

function BuildController:ConnectTool(tool)
	-- Evitar conexiones duplicadas
	if tool:GetAttribute("Connected") then
		logger:Debug("Tool already connected, skipping")
		return
	end
	tool:SetAttribute("Connected", true)

	self.currentTool = tool
	logger:Info("Connecting BuildTool events...")

	-- Verificar que la herramienta tenga Handle
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		logger:Error("BuildTool has no Handle! Tool events may not work.")
	else
		logger:Debug("BuildTool has Handle: %s", handle.Name)
	end

	tool.Equipped:Connect(function()
		logger:Info("✅ BuildTool EQUIPPED - Preview should appear now")
		self.isEquipped = true
		self._firstPreviewPositioned = false
		self:ShowPreview()
	end)

	tool.Unequipped:Connect(function()
		logger:Info("❌ BuildTool UNEQUIPPED - Preview should hide now")
		self.isEquipped = false
		self:HidePreview()
	end)

	tool.Activated:Connect(function()
		logger:Info("🔨 BuildTool ACTIVATED - Attempting to place block")

		-- Verificar cooldown (evitar spam)
		local currentTime = tick()
		if currentTime - self.lastPlacementTime < 0.2 then
			logger:Debug("Cooldown active, ignoring click")
			return
		end

		if self.previewBlock and self.previewBlock.Transparency < 1 and self.isValidPlacement then
			local position = self.targetPosition or self.previewBlock.Position
			self:RequestPlaceBlock(position, "Wood")
			self.lastPlacementTime = currentTime

			-- Efecto visual de colocación
			self:PlayPlacementEffect(position)
		else
			if not self.isValidPlacement then
				logger:Warn("Cannot place block - invalid placement location")
				self:PlayInvalidPlacementEffect()
			else
				logger:Warn("Cannot place block - preview not visible")
			end
		end
	end)

	logger:Info("✅ BuildTool events connected successfully")
end

function BuildController:RequestPlaceBlock(position: Vector3, blockType: string)
	self.placeBlockEvent:FireServer(position, blockType)
	logger:Debug("Requested to place %s block at %s", blockType, tostring(position))
end

function BuildController:OnBlockPlaced(id, position, blockType, owner)
	-- El bloque ya se crea en el servidor, pero aquí podrías agregar efectos locales
	logger:Info("Block placed: %s by %s at %s", id, owner, tostring(position))
	-- Aquí se podrían agregar efectos de partículas, sonidos, etc.
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
	self.previewBlock.Material = Enum.Material.Neon -- Neon para efecto brillante
	self.previewBlock.CastShadow = false
	self.previewBlock.Name = "BuildPreview"
	self.previewBlock.Parent = workspace

	-- Agregar efecto de borde
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "PreviewOutline"
	selectionBox.Adornee = self.previewBlock
	selectionBox.LineThickness = 0.05
	selectionBox.Color3 = Color3.fromRGB(0, 255, 0) -- Verde por defecto
	selectionBox.Transparency = 0.5
	selectionBox.Parent = self.previewBlock

	-- Actualizar posición continuamente con interpolación suave
	self.previewConnection = RunService.RenderStepped:Connect(function(deltaTime)
		self:UpdatePreview(deltaTime)
	end)

	logger:Debug("Preview block shown with smooth interpolation")
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
	logger:Debug("Preview block hidden")
end

function BuildController:UpdatePreview(deltaTime)
	if not self.previewBlock or not self.isEquipped then
		return
	end

	-- Raycast desde la cámara hacia donde apunta el mouse
	local camera = workspace.CurrentCamera
	local mouseLocation = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character, self.previewBlock }

	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

	if raycastResult and raycastResult.Instance and raycastResult.Instance:IsA("BasePart") then
		local gridSize = GameConfig.BUILD.BLOCK_SIZE
		local origin = GameConfig.BUILD.GRID_ORIGIN or Vector3.new(0, 0, 0)

		-- ✅ FIX OFFSET: desde la superficie, avanza medio bloque y luego haz snap
		local rawTarget = raycastResult.Position + (raycastResult.Normal * (gridSize / 2))
		self.targetPosition = SnapToGrid(rawTarget, gridSize, origin)

		-- Interpolación suave (la primera vez coloca instantáneo)
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

		-- Validación
		self.isValidPlacement = self:CheckValidPlacement(self.targetPosition)

		-- Feedback visual
		local selectionBox = self.previewBlock:FindFirstChild("PreviewOutline")
		if selectionBox then
			if self.isValidPlacement then
				selectionBox.Color3 = Color3.fromRGB(0, 255, 0) -- OK
				self.previewBlock.Transparency = 0.5
			else
				selectionBox.Color3 = Color3.fromRGB(255, 0, 0) -- Inválido
				self.previewBlock.Transparency = 0.7
			end
		end
	else
		-- No hay superficie válida donde colocar
		self.previewBlock.Transparency = 1
		self.isValidPlacement = false
	end
end

-- Verificar si la posición es válida para colocar (validación del lado del cliente)
function BuildController:CheckValidPlacement(position: Vector3): boolean
	if not position or not player.Character then
		return false
	end

	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- 1) Distancia máxima
	local maxDist = GameConfig.BUILD.MAX_PLACEMENT_DISTANCE
	if (position - hrp.Position).Magnitude > maxDist then
		return false
	end

	-- 2) Ocupación de la celda con bounds (robusto y simple)
	local blockSize = GameConfig.BUILD.BLOCK_SIZE
	local origin = GameConfig.BUILD.GRID_ORIGIN or Vector3.new(0, 0, 0)
	local epsilon = 0.05 -- margen para evitar falsos positivos por imprecisión
	local checkSize = Vector3.new(blockSize - epsilon, blockSize - epsilon, blockSize - epsilon)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { player.Character, self.previewBlock }

	local touching = workspace:GetPartBoundsInBox(CFrame.new(position), checkSize, overlapParams)

	for _, part in ipairs(touching) do
		-- Si tus bloques tienen atributo "IsBlock", úsalo; si no, cae a CanCollide como heurística
		if part:GetAttribute("IsBlock") or part.CanCollide then
			-- Confirma misma celda (snap) para evitar colisiones por esquinas
			local snappedPart = SnapToGrid(part.Position, blockSize, origin)
			if snappedPart == position then
				return false -- Ya hay un bloque en esta posición del grid
			end
		end
	end

	return true
end

-- Efecto visual cuando se coloca un bloque exitosamente
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

-- Efecto visual cuando el placement es inválido
function BuildController:PlayInvalidPlacementEffect()
	if not self.previewBlock then
		return
	end

	local originalTransparency = self.previewBlock.Transparency
	self.previewBlock.Transparency = 0.9
	task.spawn(function()
		for _ = 1, 3 do
			self.previewBlock.Transparency = 0.9
			task.wait(0.05)
			self.previewBlock.Transparency = originalTransparency
			task.wait(0.05)
		end
	end)
end

-- Cleanup
function BuildController:Destroy()
	logger:Info("Destroying BuildController")
	self:HidePreview()
end

return BuildController
