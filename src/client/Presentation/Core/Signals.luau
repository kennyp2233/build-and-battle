--!strict
-- Signals.luau
-- Observable values con suscripciones. `_value` y `_listeners` son privados —
-- no los toques desde afuera o se rompe la reactividad.
--
-- Pasa un `name` al crear el signal para que los errores de listeners incluyan
-- contexto en el warning.

local Signals = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type Signal<T> = {
	get: (self: Signal<T>) -> T,
	set: (self: Signal<T>, newValue: T) -> (),
	subscribe: (self: Signal<T>, callback: (T) -> ()) -> () -> (),
	_value: T,
	_listeners: { (T) -> () },
	_name: string?,
}

export type ComputedSignal<T> = Signal<T> & {
	destroy: (self: ComputedSignal<T>) -> (),
}

-- ============================================================================
-- CREATION
-- ============================================================================

function Signals.create<T>(initialValue: T, name: string?): Signal<T>
	local signal: any = {
		_value = initialValue,
		_listeners = {},
		_name = name,
	}

	function signal:get(): T
		return self._value
	end

	function signal:set(newValue: T)
		if self._value == newValue then
			return
		end
		self._value = newValue

		-- Copia defensiva: un listener puede agregar/quitar otros durante la notificación
		local snapshot = table.clone(self._listeners)
		local signalName: string = self._name or "anonymous"

		for _, listener in ipairs(snapshot) do
			task.spawn(function()
				local ok, err = xpcall(function()
					listener(newValue)
				end, debug.traceback)
				if not ok then
					warn(string.format(
						"[Signal '%s'] listener error:\n%s",
						signalName,
						tostring(err)
					))
				end
			end)
		end
	end

	function signal:subscribe(callback: (T) -> ()): () -> ()
		table.insert(self._listeners, callback)
		return function()
			local index = table.find(self._listeners, callback)
			if index then
				table.remove(self._listeners, index)
			end
		end
	end

	return (signal :: any) :: Signal<T>
end

-- ============================================================================
-- COMPUTED (derived signals)
-- ============================================================================

-- Crea un signal derivado que recomputa cuando cualquier dependencia cambia.
-- Devuelve un signal extendido con :destroy() — llamarlo cuando dejes de usarlo
-- para no filtrar suscripciones a las dependencias.
function Signals.computed<T>(
	dependencies: { Signal<any> },
	compute: () -> T,
	name: string?
): ComputedSignal<T>
	local derived: any = Signals.create(compute(), name)
	local unsubscribers: { () -> () } = {}

	for _, dependency in ipairs(dependencies) do
		table.insert(unsubscribers, dependency:subscribe(function()
			derived:set(compute())
		end))
	end

	function derived:destroy()
		for _, unsub in ipairs(unsubscribers) do
			unsub()
		end
		unsubscribers = {}
		self._listeners = {}
	end

	return (derived :: any) :: ComputedSignal<T>
end

return Signals
