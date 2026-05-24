-- ClientNetwork.luau
-- Client-side network wrapper. Waits for the container + events that the server
-- creates in ServerNetwork.new(). Never creates RemoteEvents (avoids the
-- non-replicated-local-event footgun on FilteringEnabled).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Network.Events)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CONTAINER_NAME = "NetworkEvents"
local WAIT_TIMEOUT = 10

local logger = Logger.new("ClientNetwork")

local ClientNetwork = {}
ClientNetwork.__index = ClientNetwork

function ClientNetwork.new()
	local self = setmetatable({}, ClientNetwork)

	local container = ReplicatedStorage:WaitForChild(CONTAINER_NAME, WAIT_TIMEOUT)
	if not container then
		error("[ClientNetwork] NetworkEvents container missing — server not initialized?")
	end
	self.container = container

	self.events = {}
	for _, eventName in ipairs(Events.All) do
		local event = container:WaitForChild(eventName, WAIT_TIMEOUT)
		if not event then
			error("[ClientNetwork] Missing event: " .. eventName)
		end
		self.events[eventName] = event
	end

	logger:Info("Connected to %d events", #Events.All)
	return self
end

function ClientNetwork:_get(eventName: string): RemoteEvent
	local event = self.events[eventName]
	if not event then
		error("[ClientNetwork] Unknown event: " .. tostring(eventName))
	end
	return event
end

function ClientNetwork:Fire(eventName: string, ...)
	self:_get(eventName):FireServer(...)
end

function ClientNetwork:On(eventName: string, callback: (...any) -> ()): RBXScriptConnection
	return self:_get(eventName).OnClientEvent:Connect(callback)
end

return ClientNetwork
