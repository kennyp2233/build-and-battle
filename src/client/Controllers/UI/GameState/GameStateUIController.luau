-- GameStateUIController.luau
-- Mantiene el countdown local sincronizado al servidor y empuja state al GameView,
-- que se encarga del re-render React.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logger = Logger.new("GameStateUIController")

local GameStateUIController = {}
GameStateUIController.__index = GameStateUIController

function GameStateUIController.new(gameView)
	local self = setmetatable({}, GameStateUIController)

	self.gameView = gameView
	self.countdownTask = nil
	self.currentState = {
		state = nil :: string?,
		timer = 0,
		round = nil :: number?,
		maxTimer = 0,
		endTimestamp = 0,
	}

	return self
end

function GameStateUIController:OnStateChanged(state: string, endTimestamp: number, round: number?)
	local maxTimer = GameConfig.PHASE_DURATIONS[state] or 0
	local serverTime = workspace:GetServerTimeNow()
	local remainingTime = math.max(0, endTimestamp - serverTime)

	self.currentState.state = state
	self.currentState.endTimestamp = endTimestamp
	self.currentState.round = round
	self.currentState.maxTimer = maxTimer

	logger:Debug("State: %s, remaining: %.1fs, maxTimer: %d", state, remainingTime, maxTimer)

	self.gameView:UpdateState(state, math.ceil(remainingTime), round, maxTimer)
	self:_startCountdown(endTimestamp, maxTimer)
end

function GameStateUIController:_startCountdown(endTimestamp: number, maxTimer: number)
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end

	self.countdownTask = task.spawn(function()
		while true do
			task.wait(0.1)
			local serverTime = workspace:GetServerTimeNow()
			local remaining = endTimestamp - serverTime

			if remaining <= 0 then
				self.gameView:UpdateTimer(0, maxTimer)
				break
			end

			local secondsRemaining = math.ceil(remaining)
			if secondsRemaining ~= self.currentState.timer then
				self.currentState.timer = secondsRemaining
				self.gameView:UpdateTimer(secondsRemaining, maxTimer)
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
