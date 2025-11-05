-- GameController.luau (Controlador para manejar la lógica del juego en el servidor)
-- Coordina casos de uso y responde a eventos con configuración centralizada

local ChangeGameState = require(script.Parent.Parent.UseCases.ChangeGameState)
local PlaceBlock = require(script.Parent.Parent.UseCases.PlaceBlock)
local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(game.ReplicatedStorage.Shared.Utils.Logger)
local Result = require(game.ReplicatedStorage.Shared.Utils.Result)

local logger = Logger.new("GameController")

local GameController = {}
GameController.__index = GameController

function GameController.new(gameStateService, buildService)
	local self = setmetatable({}, GameController)
	self.gameStateService = gameStateService
	self.buildService = buildService
	self.changeGameState = ChangeGameState.new(gameStateService)
	self.placeBlock = PlaceBlock.new(buildService)
	self.currentGameState = nil -- Se inicializa en Init
	self.connections = {} -- Para cleanup de conexiones
	logger:Info("GameController initialized")
	return self
end

function GameController:Init()
	-- Inicializar estado inicial
	local GameState = require(game.ReplicatedStorage.Shared.Entities.GameState)
	self.currentGameState = GameState.new("Intermission", GameConfig.PHASE_DURATIONS.Intermission, 0)
	self.gameStateService:UpdateState(self.currentGameState)
	logger:Info("Initial game state set to Intermission")

	-- Configurar eventos de red
	self:SetupNetworkEvents()

	-- Configurar manejo de jugadores
	self:SetupPlayerHandling()

	-- Iniciar el bucle de estados
	self:StartStateLoop()
end

-- Configurar eventos de red
function GameController:SetupNetworkEvents()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local placeBlockEvent = ReplicatedStorage:WaitForChild(GameConfig.EVENTS.PLACE_BLOCK, 10)

	if not placeBlockEvent then
		logger:Error("Failed to find PlaceBlock event after 10 seconds")
		return
	end

	local connection = placeBlockEvent.OnServerEvent:Connect(function(player, position, blockType)
		local result = self.placeBlock:Execute(position, blockType, player, self.currentGameState)

		if Result.IsErr(result) then
			local error = Result.UnwrapErr(result)
			logger:Warn("Block placement failed for %s: %s", player.Name, error)
		end
	end)

	table.insert(self.connections, connection)
	logger:Info("Network events configured")
end

-- Configurar manejo de jugadores
function GameController:SetupPlayerHandling()
	local Players = game:GetService("Players")

	-- Manejar nuevos jugadores
	local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		logger:Info("Player joined: %s", player.Name)

		-- Enviar estado actual al jugador
		if self.currentGameState then
			self.gameStateService:BroadcastStateToPlayer(self.currentGameState, player)
		end

		-- Configurar CharacterAdded
		local characterAddedConnection = player.CharacterAdded:Connect(function()
			if self.currentGameState and self.currentGameState.currentState == "Building" then
				task.wait(0.5) -- Esperar carga del personaje
				self:GiveBuildToolToPlayer(player)
			end
		end)

		table.insert(self.connections, characterAddedConnection)
	end)

	table.insert(self.connections, playerAddedConnection)

	-- Configurar para jugadores que ya están en el servidor
	for _, player in ipairs(Players:GetPlayers()) do
		if self.currentGameState then
			self.gameStateService:BroadcastStateToPlayer(self.currentGameState, player)
		end

		local characterAddedConnection = player.CharacterAdded:Connect(function()
			if self.currentGameState and self.currentGameState.currentState == "Building" then
				task.wait(0.5)
				self:GiveBuildToolToPlayer(player)
			end
		end)

		table.insert(self.connections, characterAddedConnection)
	end

	logger:Info("Player handling configured")
end

-- Bucle de estados del juego
function GameController:StartStateLoop()
	logger:Info("Starting game state loop")

	task.spawn(function()
		while true do
			-- Intermission
			logger:Info("Entering Intermission phase")
			self.changeGameState:Execute(
				self.currentGameState,
				"Intermission",
				GameConfig.PHASE_DURATIONS.Intermission
			)
			self:RemoveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Intermission)

			-- Building
			logger:Info("Entering Building phase")
			self.changeGameState:Execute(
				self.currentGameState,
				"Building",
				GameConfig.PHASE_DURATIONS.Building
			)
			self:GiveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Building)

			-- Battle
			logger:Info("Entering Battle phase")
			self.changeGameState:Execute(
				self.currentGameState,
				"Battle",
				GameConfig.PHASE_DURATIONS.Battle
			)
			self:RemoveBuildTools()
			task.wait(GameConfig.PHASE_DURATIONS.Battle)

			-- Limpiar bloques antes de la siguiente ronda
			logger:Info("Clearing blocks for next round")
			self.buildService:ClearBlocks()
		end
	end)
end

-- Dar herramientas de construcción a todos los jugadores
function GameController:GiveBuildTools()
	local Players = game:GetService("Players")
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:GiveBuildToolToPlayer(player)
			count += 1
		end
	end

	logger:Info("Gave build tools to %d players", count)
end

-- Quitar herramientas de construcción de todos los jugadores
function GameController:RemoveBuildTools()
	local Players = game:GetService("Players")
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if self:RemoveBuildToolFromPlayer(player) then
			count += 1
		end
	end

	logger:Info("Removed build tools from %d players", count)
end

-- Dar herramienta de construcción a un jugador específico
function GameController:GiveBuildToolToPlayer(player: Player): boolean
	-- Verificar que el jugador es válido
	if not player or not player:IsA("Player") then
		logger:Error("Attempted to give tool to invalid player")
		return false
	end

	-- Verificar que el jugador no tenga ya la herramienta
	if player.Backpack:FindFirstChild("BuildTool") or (player.Character and player.Character:FindFirstChild("BuildTool")) then
		logger:Debug("Player %s already has BuildTool", player.Name)
		return false
	end

	-- Crear y dar la herramienta
	local BuildTool = require(game.ReplicatedStorage.Shared.Entities.BuildTool)
	local tool = BuildTool.new()
	tool.Parent = player.Backpack

	logger:Info("Gave BuildTool to %s", player.Name)
	return true
end

-- Quitar herramienta de construcción de un jugador específico
function GameController:RemoveBuildToolFromPlayer(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	local tool = player.Backpack:FindFirstChild("BuildTool")
		or (player.Character and player.Character:FindFirstChild("BuildTool"))

	if tool then
		tool:Destroy()
		logger:Debug("Removed BuildTool from %s", player.Name)
		return true
	end

	return false
end

-- Cleanup
function GameController:Destroy()
	logger:Info("Destroying GameController")

	-- Desconectar todas las conexiones
	for _, connection in ipairs(self.connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	self.connections = {}
	logger:Info("GameController destroyed")
end

return GameController
