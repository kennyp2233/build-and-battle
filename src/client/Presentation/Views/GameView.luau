-- GameView.luau
-- Wrapper delgado: monta el árbol React y expone el store al exterior. No
-- mantiene state propio — React tiene el state, el store es el bus de updates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local HudStore = require(script.Parent.Parent.Stores.HudStore)
local App = require(script.Parent.App)

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

	self.store = HudStore.new({
		state = "Intermission",
		timer = 30,
		round = nil,
		maxTimer = 30,
		lowTimeThreshold = 10,
	})

	self.root = ReactRoblox.createRoot(self.screenGui)
	self.root:render(React.createElement(App, { store = self.store }))

	return self
end

function GameView:GetStore()
	return self.store
end

function GameView:Destroy()
	if self.root then
		self.root:unmount()
		self.root = nil
	end
	if self.store then
		self.store:Destroy()
		self.store = nil
	end
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return GameView
