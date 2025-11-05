-- NetworkManager.luau (Gestión centralizada de eventos de red)
-- Proporciona una abstracción sobre RemoteEvents con tipos seguros

local GameConfig = require(script.Parent.Parent.Config.GameConfig)
local Logger = require(script.Parent.Logger)

local logger = Logger.new("NetworkManager")

local NetworkManager = {}
NetworkManager.__index = NetworkManager

function NetworkManager.new()
	local self = setmetatable({}, NetworkManager)
	self.events = {}
	return self
end

-- Obtener o crear un RemoteEvent
function NetworkManager:GetOrCreateEvent(eventName: string): RemoteEvent
	if self.events[eventName] then
		return self.events[eventName]
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:FindFirstChild(eventName)

	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = ReplicatedStorage
		logger:Info("Created RemoteEvent: %s", eventName)
	end

	self.events[eventName] = event
	return event
end

-- Para el servidor: Enviar evento a todos los clientes
function NetworkManager:FireAllClients(eventName: string, ...)
	local event = self:GetOrCreateEvent(eventName)
	event:FireAllClients(...)
	logger:Debug("Fired %s to all clients", eventName)
end

-- Para el servidor: Enviar evento a un cliente específico
function NetworkManager:FireClient(eventName: string, player: Player, ...)
	local event = self:GetOrCreateEvent(eventName)
	event:FireClient(player, ...)
	logger:Debug("Fired %s to player %s", eventName, player.Name)
end

-- Para el cliente: Enviar evento al servidor
function NetworkManager:FireServer(eventName: string, ...)
	local event = self:GetOrCreateEvent(eventName)
	event:FireServer(...)
	logger:Debug("Fired %s to server", eventName)
end

-- Para el servidor: Conectar callback a evento del servidor
function NetworkManager:OnServerEvent(eventName: string, callback: (player: Player, ...any) -> ())
	local event = self:GetOrCreateEvent(eventName)
	event.OnServerEvent:Connect(callback)
	logger:Info("Connected server listener for %s", eventName)
end

-- Para el cliente: Conectar callback a evento del cliente
function NetworkManager:OnClientEvent(eventName: string, callback: (...any) -> ())
	local event = self:GetOrCreateEvent(eventName)
	event.OnClientEvent:Connect(callback)
	logger:Info("Connected client listener for %s", eventName)
end

-- Cleanup: Destruir todos los eventos
function NetworkManager:Destroy()
	for eventName, event in pairs(self.events) do
		if event and event:IsA("RemoteEvent") then
			event:Destroy()
			logger:Info("Destroyed RemoteEvent: %s", eventName)
		end
	end
	self.events = {}
end

return NetworkManager
