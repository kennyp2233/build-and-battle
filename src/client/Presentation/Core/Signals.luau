-- Signals.luau
-- Observable values con suscripciones. Mantén `_value` y `_listeners` como privados
-- (con underscore) — no los toques desde afuera o se rompe la reactividad.

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
}

-- ============================================================================
-- CREATION
-- ============================================================================

function Signals.create<T>(initialValue: T): Signal<T>
	local signal = {
		_value = initialValue,
		_listeners = {},
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
		-- sin corromper el iterador.
		local snapshot = table.clone(self._listeners)
		for _, listener in ipairs(snapshot) do
			task.spawn(listener, newValue)
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

	return signal
end

-- ============================================================================
-- COMPUTED (derived signals)
-- ============================================================================

export type ComputedSignal<T> = Signal<T> & {
	destroy: (self: ComputedSignal<T>) -> (),
}

-- Crea un signal derivado que recomputa cuando cualquier dependencia cambia.
-- Devuelve un signal extendido con :destroy() — llamarlo cuando dejes de usarlo
-- para no filtrar suscripciones a las dependencias.
function Signals.computed<T>(dependencies: { Signal<any> }, compute: () -> T): ComputedSignal<T>
	local derived = Signals.create(compute())
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

	return derived
end

return Signals
