-- GameUIController.luau
-- Puente red → store del HUD. Escucha GameStateChanged, mantiene el countdown
-- local sincronizado al servidor (endTimestamp absoluto) y empuja state al store.
-- React re-renderea via Subscribe — este controller no toca la view imperativamente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Events = require(ReplicatedStorage.Shared.Network.Events)
local Maid = require(ReplicatedStorage.Shared.Utils.Maid)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameUIController")

local COUNTDOWN_INTERVAL = 0.1

local GameUIController = {}
GameUIController.__index = GameUIController

function GameUIController.new(gameView, network)
	assert(network, "GameUIController requires a ClientNetwork instance")
	local self = setmetatable({}, GameUIController)

	self.gameView = gameView
	self.network = network
	self.store = gameView:GetStore()
	self.maid = Maid.new()

	self.countdownTask = nil
	self.lastTimerEmitted = -1
	self.currentEndTimestamp = 0

	self.maid:Give(self.network:On(Events.GameStateChanged, function(state, endTimestamp, round)
		self:_onStateChanged(state, endTimestamp, round)
	end))

	logger:Info("GameUIController initialized")
	return self
end

function GameUIController:_onStateChanged(state: string, endTimestamp: number, round: number?)
	local maxTimer = GameConfig.PHASE_DURATIONS[state] or 0
	local remainingSeconds = math.ceil(math.max(0, endTimestamp - workspace:GetServerTimeNow()))

	self.currentEndTimestamp = endTimestamp
	self.lastTimerEmitted = remainingSeconds

	logger:Debug("State: %s, remaining: %ds, maxTimer: %d", state, remainingSeconds, maxTimer)

	self.store:Update({
		state = state,
		timer = remainingSeconds,
		round = round,
		maxTimer = maxTimer,
	})

	self:_startCountdown()
end

function GameUIController:_startCountdown()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end

	self.countdownTask = task.spawn(function()
		while true do
			task.wait(COUNTDOWN_INTERVAL)
			local remaining = self.currentEndTimestamp - workspace:GetServerTimeNow()

			if remaining <= 0 then
				if self.lastTimerEmitted ~= 0 then
					self.lastTimerEmitted = 0
					self.store:Update({ timer = 0 })
				end
				break
			end

			local secondsRemaining = math.ceil(remaining)
			if secondsRemaining ~= self.lastTimerEmitted then
				self.lastTimerEmitted = secondsRemaining
				self.store:Update({ timer = secondsRemaining })
			end
		end
	end)
end

function GameUIController:Destroy()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end
	self.maid:Clean()
	if self.gameView then
		self.gameView:Destroy()
	end
end

return GameUIController
