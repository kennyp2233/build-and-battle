-- Signals.luau
-- Sistema de reactividad basado en signals para RoUI

local Signals = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type Signal<T> = {
	value: T,
	listeners: {(T) -> ()},
	set: (self: Signal<T>, newValue: T) -> (),
	get: (self: Signal<T>) -> T,
	subscribe: (self: Signal<T>, callback: (T) -> ()) -> () -> (),
}

-- ============================================================================
-- SIGNAL CREATION
-- ============================================================================

function Signals.create<T>(initialValue: T): Signal<T>
	local signal = {
		value = initialValue,
		listeners = {},
	}

	function signal:set(newValue: T)
		if self.value ~= newValue then
			self.value = newValue
			-- Notificar a todos los listeners
			for _, listener in ipairs(self.listeners) do
				task.spawn(listener, newValue)
			end
		end
	end

	function signal:get(): T
		return self.value
	end

	function signal:subscribe(callback: (T) -> ()): () -> ()
		table.insert(self.listeners, callback)
		-- Retornar función de cleanup
		return function()
			local index = table.find(self.listeners, callback)
			if index then
				table.remove(self.listeners, index)
			end
		end
	end

	return signal
end

-- ============================================================================
-- DERIVED SIGNALS (Computed)
-- ============================================================================

-- Crear un signal derivado que se actualiza automáticamente
function Signals.computed<T>(dependencies: {Signal<any>}, compute: () -> T): Signal<T>
	local derivedSignal = Signals.create(compute())
	
	for _, dependency in ipairs(dependencies) do
		dependency:subscribe(function()
			derivedSignal:set(compute())
		end)
	end
	
	return derivedSignal
end

-- ============================================================================
-- REACTIVE COMPONENT
-- ============================================================================

type ReactiveComponent = {
	instance: Instance,
	cleanup: () -> (),
	update: (self: ReactiveComponent, props: any) -> (),
	destroy: (self: ReactiveComponent) -> (),
}

-- Crear componente reactivo que se actualiza cuando cambian signals
function Signals.reactive(
	builder: (props: any) -> Instance,
	signals: {Signal<any>}
): (props: any) -> ReactiveComponent
	return function(props: any): ReactiveComponent
		local instance = builder(props)
		local unsubscribers = {}

		-- Suscribirse a todos los signals
		for _, signal in ipairs(signals) do
			local unsubscribe = signal:subscribe(function()
				-- Re-aplicar props cuando el signal cambie
				-- Nota: Necesita acceso a updateProps de RoUI
				-- Se manejará en la integración
			end)
			table.insert(unsubscribers, unsubscribe)
		end

		local component = {
			instance = instance,
		}

		function component:update(newProps: any)
			-- Se implementará con RoUI.updateProps
		end

		function component:cleanup()
			for _, unsub in ipairs(unsubscribers) do
				unsub()
			end
		end

		function component:destroy()
			self:cleanup()
			if self.instance then
				self.instance:Destroy()
			end
		end

		return component
	end
end

return Signals
