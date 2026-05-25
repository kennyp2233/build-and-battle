-- GameController.luau
-- Orquestador del servidor: bucle de fases, hooks de jugador, ruteo de requests del cliente.
-- Network y servicios se inyectan; las conexiones se gestionan vía Maid.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local GameState = require(ReplicatedStorage.Shared.Entities.GameState)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local ChangeGameState = require(script.Parent.Parent.UseCases.ChangeGameState)
local PlaceBlock = require(script.Parent.Parent.UseCases.PlaceBlock)
local BuildTool = require(script.Parent.Parent.Entities.BuildTool)

local logger = Logger.new("GameController")

local CHARACTER_WAIT_TIMEOUT = 5

local GameController = {}
GameController.__index = GameController

function GameController.new(gameStateService, buildService, network)
	assert(network, "GameController requires a ServerNetwork instance")
	local self = setmetatable({}, GameController)

	self.gameStateService = gameStateService
	self.buildService = buildService
	self.network = network

	self.changeGameState = ChangeGameState.new(gameStateService)
	self.placeBlock = PlaceBlock.new(buildService)

	self.currentGameState = nil
	self.maid = Maid.new()
	self.playerMaids = {} -- [userId] = Maid
	self.stateLoopRunning = false

	return self
end

function GameController:Init()
	self.currentGameState = GameState.new("Intermission", GameConfig.PHASE_DURATIONS.Intermission, 0)
	self.gameStateService:UpdateState(self.currentGameState)

	self:SetupNetworkEvents()
	self:SetupPlayerHandling()
	self:StartStateLoop()
end

function GameController:SetupNetworkEvents()
	self.maid:Give(self.network:OnRequest(Events.PlaceBlockRequest, function(player, position, blockType)
		local result = self.placeBlock:Execute(position, blockType, player, self.currentGameState)
		if Result.IsErr(result) then
			local reason = Result.UnwrapErr(result)
			logger:Warn("Place rejected for %s: %s", player.Name, reason)
			-- Avisarle al cliente para que pueda dar feedback visual/sonoro
			self.network:FireClient(Events.PlaceBlockRejected, player, reason)
		end
	end))
end

function GameController:_attachPlayer(player: Player)
	if self.playerMaids[player.UserId] then
		return
	end

	local pmaid = Maid.new()
	self.playerMaids[player.UserId] = pmaid

	if self.currentGameState then
		self.gameStateService:BroadcastStateToPlayer(self.currentGameState, player)
	end

	pmaid:Give(player.CharacterAdded:Connect(function(character)
		if not (self.currentGameState and self.currentGameState.currentState == "Building") then
			return
		end
		-- Esperar al HRP en lugar de un task.wait mágico
		local hrp = character:WaitForChild("HumanoidRootPart", CHARACTER_WAIT_TIMEOUT)
		if not hrp then
			logger:Warn("Character of %s never produced HumanoidRootPart", player.Name)
			return
		end
		self:GiveBuildToolToPlayer(player)
	end))
end

function GameController:_detachPlayer(player: Player)
	local pmaid = self.playerMaids[player.UserId]
	if pmaid then
		pmaid:Clean()
		self.playerMaids[player.UserId] = nil
	end
	self.placeBlock:ClearPlayer(player.UserId)
end

function GameController:SetupPlayerHandling()
	self.maid:Give(Players.PlayerAdded:Connect(function(player)
		self:_attachPlayer(player)
	end))
	self.maid:Give(Players.PlayerRemoving:Connect(function(player)
		self:_detachPlayer(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		self:_attachPlayer(player)
	end
end

function GameController:StartStateLoop()
	self.stateLoopRunning = true
	self.maid:Give(function()
		self.stateLoopRunning = false
	end)

	task.spawn(function()
		while self.stateLoopRunning do
			self.changeGameState:Execute(self.currentGameState, "Intermission", GameConfig.PHASE_DURATIONS.Intermission)
			self:RemoveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Intermission)
			if not self.stateLoopRunning then break end

			self.changeGameState:Execute(self.currentGameState, "Building", GameConfig.PHASE_DURATIONS.Building)
			self:GiveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Building)
			if not self.stateLoopRunning then break end

			self.changeGameState:Execute(self.currentGameState, "Battle", GameConfig.PHASE_DURATIONS.Battle)
			self:RemoveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Battle)
			if not self.stateLoopRunning then break end

			self.buildService:ClearBlocks()
		end
	end)
end

function GameController:GiveBuildTools()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:GiveBuildToolToPlayer(player)
		end
	end
end

function GameController:RemoveBuildTools()
	for _, player in ipairs(Players:GetPlayers()) do
		self:RemoveBuildToolFromPlayer(player)
	end
end

function GameController:GiveBuildToolToPlayer(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end
	if player.Backpack:FindFirstChild("BuildTool")
		or (player.Character and player.Character:FindFirstChild("BuildTool")) then
		return false
	end

	local tool = BuildTool.new()
	tool.Parent = player.Backpack
	return true
end

function GameController:RemoveBuildToolFromPlayer(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end
	local tool = player.Backpack:FindFirstChild("BuildTool")
		or (player.Character and player.Character:FindFirstChild("BuildTool"))
	if tool then
		tool:Destroy()
		return true
	end
	return false
end

function GameController:Destroy()
	for _, pmaid in pairs(self.playerMaids) do
		pmaid:Clean()
	end
	self.playerMaids = {}
	self.maid:Clean()
end

return GameController
