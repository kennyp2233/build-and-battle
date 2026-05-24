-- ServerNetwork.luau
-- Server-side network wrapper. Creates every RemoteEvent declared in shared/Network/Events
-- at construction time inside a single folder, so clients can WaitForChild deterministically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Network.Events)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CONTAINER_NAME = "NetworkEvents"

local logger = Logger.new("ServerNetwork")

local ServerNetwork = {}
ServerNetwork.__index = ServerNetwork

function ServerNetwork.new()
	local self = setmetatable({}, ServerNetwork)

	local container = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
	if not container then
		container = Instance.new("Folder")
		container.Name = CONTAINER_NAME
		container.Parent = ReplicatedStorage
	end
	self.container = container

	self.events = {}
	for _, eventName in ipairs(Events.All) do
		local event = container:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = container
		end
		self.events[eventName] = event
	end

	logger:Info("Registered %d events", #Events.All)
	return self
end

function ServerNetwork:_get(eventName: string): RemoteEvent
	local event = self.events[eventName]
	if not event then
		error("[ServerNetwork] Unknown event: " .. tostring(eventName))
	end
	return event
end

function ServerNetwork:FireAll(eventName: string, ...)
	self:_get(eventName):FireAllClients(...)
end

function ServerNetwork:FireClient(eventName: string, player: Player, ...)
	self:_get(eventName):FireClient(player, ...)
end

function ServerNetwork:OnRequest(eventName: string, callback: (player: Player, ...any) -> ()): RBXScriptConnection
	return self:_get(eventName).OnServerEvent:Connect(callback)
end

function ServerNetwork:Destroy()
	if self.container then
		self.container:Destroy()
		self.container = nil
	end
	self.events = {}
end

return ServerNetwork
