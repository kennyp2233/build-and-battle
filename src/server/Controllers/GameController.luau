-- GameController.luau
-- Orquestador del servidor: bucle de fases, hooks de jugador, ruteo de requests.
-- Único owner de currentGameState. GameStateService son funciones de broadcast,
-- no guarda copia paralela.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local GameState = require(ReplicatedStorage.Shared.Entities.GameState)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Result = require(ReplicatedStorage.Shared.Utils.Result)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local GameStateService = require(script.Parent.Parent.Services.GameStateService)
local PlaceBlock = require(script.Parent.Parent.UseCases.PlaceBlock)
local BuildTool = require(script.Parent.Parent.Factories.BuildTool)

local logger = Logger.new("GameController")

local CHARACTER_WAIT_TIMEOUT = 5
local PHASE_POLL_INTERVAL = 0.1

local GameController = {}
GameController.__index = GameController

function GameController.new(buildService, network)
	assert(network, "GameController requires a ServerNetwork instance")
	local self = setmetatable({}, GameController)

	self.buildService = buildService
	self.network = network

	self.placeBlock = PlaceBlock(buildService)

	self.currentGameState = nil :: any
	self.maid = Maid.new()
	self.playerMaids = {} -- [userId] = Maid
	self.stateLoopRunning = false

	return self
end

function GameController:Init()
	-- Inicial: GameState con timer expirado para que cualquier early-joiner
	-- vea un valor coherente hasta que el state loop arranque y emita Intermission.
	self.currentGameState = GameState.new("Intermission", 0, 0)

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

	GameStateService.BroadcastToPlayer(self.network, self.currentGameState, player)

	-- Bug #1: si el jugador entra durante Building, dale la tool inmediatamente
	-- en lugar de esperar al siguiente CharacterAdded.
	if player.Character and self.currentGameState.currentState == "Building" then
		self:GiveBuildToolToPlayer(player)
	end

	pmaid:Give(player.CharacterAdded:Connect(function(character)
		if self.currentGameState.currentState ~= "Building" then
			return
		end
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

-- Espera hasta currentGameState.endTimestamp (no a un task.wait fijo) para
-- que el final del countdown del cliente coincida con el cambio de fase real.
function GameController:_waitUntilPhaseEnd()
	while self.stateLoopRunning do
		local remaining = self.currentGameState.endTimestamp - workspace:GetServerTimeNow()
		if remaining <= 0 then
			break
		end
		task.wait(math.min(remaining, PHASE_POLL_INTERVAL))
	end
end

-- Aplica la transición de fase: muta el GameState (single source of truth) y
-- broadcastea via GameStateService. Solo se llama desde el state loop con phases
-- literales, así que no necesita validar el nombre de fase (no es input de red).
function GameController:_transition(phase: GameState.GameStateType, duration: number)
	local previousState = self.currentGameState.currentState

	self.currentGameState:setState(phase)
	self.currentGameState:setDuration(duration)
	if phase == "Intermission" then
		self.currentGameState:incrementRound()
	end

	GameStateService.Broadcast(self.network, self.currentGameState)

	logger:Info("Game state: %s -> %s (duration: %ds)", previousState, phase, duration)
end

function GameController:StartStateLoop()
	self.stateLoopRunning = true
	self.maid:Give(function()
		self.stateLoopRunning = false
	end)

	task.spawn(function()
		while self.stateLoopRunning do
			self:_transition("Intermission", GameConfig.PHASE_DURATIONS.Intermission)
			self:RemoveBuildTools()
			self:_waitUntilPhaseEnd()
			if not self.stateLoopRunning then
				break
			end

			self:_transition("Building", GameConfig.PHASE_DURATIONS.Building)
			self:GiveBuildTools()
			self:_waitUntilPhaseEnd()
			if not self.stateLoopRunning then
				break
			end

			self:_transition("Battle", GameConfig.PHASE_DURATIONS.Battle)
			self:RemoveBuildTools()
			self:_waitUntilPhaseEnd()
			if not self.stateLoopRunning then
				break
			end

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
	if
		player.Backpack:FindFirstChild("BuildTool")
		or (player.Character and player.Character:FindFirstChild("BuildTool"))
	then
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
