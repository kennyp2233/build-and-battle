-- GameView.luau
-- Vista principal del juego - Orquestador puro de componentes de HUD
-- RESPONSABILIDAD: Ensamblar y coordinar componentes visuales, NO contiene lógica de negocio

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameStateHUD = require(script.Parent.Parent.Components.Game.GameState.GameStateHUD)

local GameView = {}
GameView.__index = GameView

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function GameView.new()
	local self = setmetatable({}, GameView)

	-- Crear ScreenGui contenedor
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "GameHUD"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.IgnoreGuiInset = true
	self.screenGui.Parent = playerGui

	-- Instanciar componentes de HUD
	self.gameStateHUD = GameStateHUD.new(self.screenGui)

	return self
end

-- ============================================================================
-- API PÚBLICA - Solo delegación a componentes
-- ============================================================================

-- Actualizar estado completo del juego
function GameView:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.gameStateHUD:UpdateState(newState, timer, round, maxTimer)
end

-- Actualizar solo el timer
function GameView:UpdateTimer(timer: number, maxTimer: number?)
	self.gameStateHUD:UpdateTimer(timer, maxTimer)
end

-- Destruir vista y todos sus componentes
function GameView:Destroy()
	if self.gameStateHUD then
		self.gameStateHUD:Destroy()
	end

	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return GameView
