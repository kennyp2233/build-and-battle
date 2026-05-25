-- App.luau
-- Componente raíz del HUD. Suscribe al HudStore vía useEffect y mantiene
-- el state en useState — patrón React idiomático.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local GameStateHUD = require(script.Parent.Parent.Components.Game.GameState.GameStateHUD)

local e = React.createElement

export type AppProps = {
	store: any, -- HudStore
}

local function App(props: AppProps)
	local hudState, setHudState = React.useState(props.store:Get())

	React.useEffect(function()
		-- Re-sincroniza por si el store cambió entre render inicial y mount
		setHudState(props.store:Get())
		return props.store:Subscribe(function(newState)
			setHudState(newState)
		end)
	end, { props.store } :: { any })

	return e(GameStateHUD, hudState)
end

return App
