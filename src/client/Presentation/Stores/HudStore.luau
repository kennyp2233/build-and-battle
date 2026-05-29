-- HudStore.luau
-- Store mínimo para el state del HUD. Los controllers de UI hacen Update();
-- el componente App suscribe en useEffect y dispara setState al recibir cambios.
-- Reemplaza el patrón "GameView re-renderea manualmente" — ahora React maneja
-- el ciclo de render, los controllers solo despachan.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

export type HudState = {
	state: string,
	timer: number,
	round: number?,
	maxTimer: number,
	lowTimeThreshold: number,
}

local HudStore = {}
HudStore.__index = HudStore

function HudStore.new(initial: HudState)
	return setmetatable({
		_state = initial,
		_signal = Signal.new(),
	}, HudStore)
end

function HudStore:Get(): HudState
	return self._state
end

function HudStore:Update(partial: { [string]: any })
	local merged = table.clone(self._state) :: any
	for k, v in pairs(partial) do
		merged[k] = v
	end
	self._state = merged
	self._signal:Fire(merged)
end

function HudStore:Subscribe(callback: (HudState) -> ()): () -> ()
	-- sleitnick/signal:Connect devuelve una Connection (no una función disconnect).
	-- Devolvemos un closure para mantener el contrato de Subscribe (cleanup de useEffect).
	local connection = self._signal:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

function HudStore:Destroy()
	self._signal:Destroy()
end

return HudStore
