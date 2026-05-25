-- Signal.luau
-- Mini event emitter sincrónico. Connect retorna una función disconnect.
-- Usado por stores de UI y emitters de red en cliente.

export type Disconnect = () -> ()

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(callback: (...any) -> ()): Disconnect
	local listeners = self._listeners
	table.insert(listeners, callback)
	return function()
		for i, l in ipairs(listeners) do
			if l == callback then
				table.remove(listeners, i)
				return
			end
		end
	end
end

function Signal:Fire(...)
	-- Copia defensiva: un listener puede disconnectar durante el fire.
	local snapshot = table.clone(self._listeners)
	for _, l in ipairs(snapshot) do
		xpcall(l, function(err)
			warn("[Signal] listener error: " .. tostring(err))
		end, ...)
	end
end

function Signal:Destroy()
	self._listeners = {}
end

return Signal
