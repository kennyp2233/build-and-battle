-- GameView.luau
-- Owns el ReactRoblox root y el state del HUD. Los controllers llaman a
-- UpdateState/UpdateTimer y GameView re-renderea el componente React con las
-- nuevas props — React se encarga del diff.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GameStateHUD = require(script.Parent.Parent.Components.Game.GameState.GameStateHUD)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameView = {}
GameView.__index = GameView

function GameView.new()
	local self = setmetatable({}, GameView)

	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "GameHUD"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.IgnoreGuiInset = true
	self.screenGui.Parent = playerGui

	self.root = ReactRoblox.createRoot(self.screenGui)

	self.state = {
		state = "Intermission",
		timer = 30,
		round = nil :: number?,
		maxTimer = 30,
		lowTimeThreshold = 10,
	}

	self:_render()
	return self
end

function GameView:_render()
	self.root:render(React.createElement(GameStateHUD, self.state))
end

function GameView:UpdateState(newState: string, timer: number, round: number?, maxTimer: number?)
	self.state = {
		state = newState,
		timer = timer,
		round = round,
		maxTimer = maxTimer or timer,
		lowTimeThreshold = self.state.lowTimeThreshold,
	}
	self:_render()
end

function GameView:UpdateTimer(timer: number, maxTimer: number?)
	self.state = {
		state = self.state.state,
		timer = timer,
		round = self.state.round,
		maxTimer = maxTimer or self.state.maxTimer,
		lowTimeThreshold = self.state.lowTimeThreshold,
	}
	self:_render()
end

function GameView:Destroy()
	if self.root then
		self.root:unmount()
		self.root = nil
	end
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return GameView
