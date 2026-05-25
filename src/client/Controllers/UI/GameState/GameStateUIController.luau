-- GameStateUIController.luau
-- Mantiene el countdown local sincronizado al servidor y empuja state al store
-- del HUD. React se encarga del re-render via Subscribe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameStateUIController")

local GameStateUIController = {}
GameStateUIController.__index = GameStateUIController

function GameStateUIController.new(store)
	local self = setmetatable({}, GameStateUIController)

	self.store = store
	self.countdownTask = nil
	self.lastTimerEmitted = -1
	self.currentEndTimestamp = 0
	self.currentMaxTimer = 0

	return self
end

function GameStateUIController:OnStateChanged(state: string, endTimestamp: number, round: number?)
	local maxTimer = GameConfig.PHASE_DURATIONS[state] or 0
	local serverTime = workspace:GetServerTimeNow()
	local remainingSeconds = math.ceil(math.max(0, endTimestamp - serverTime))

	self.currentEndTimestamp = endTimestamp
	self.currentMaxTimer = maxTimer
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

function GameStateUIController:_startCountdown()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end

	self.countdownTask = task.spawn(function()
		while true do
			task.wait(0.1)
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

function GameStateUIController:Destroy()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end
end

return GameStateUIController
