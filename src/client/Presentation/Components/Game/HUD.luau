-- HUD.luau
-- Componente principal del HUD que agrupa el HUDCard y el botón de toggle

local RoUI = require(script.Parent.Parent.Parent.Core.RoUI)
local Theme = require(script.Parent.Parent.Parent.Core.Theme)
local HUDCard = require(script.Parent.HUDCard)

local function HUD(props: {
	state: string,
	timer: number,
	maxTimer: number,
	round: number?,
	lowTimeThreshold: number,
	visible: boolean?,
	onToggle: (() -> ())?
})
	-- Determinar si está visible (por defecto true)
	local isVisible = if props.visible ~= nil then props.visible else true
	
	-- Posiciones para la animación
	local visiblePosition = UDim2.new(0.5, 0, 0.06, 0)
	local hiddenPosition = UDim2.new(0.5, 0, -0.25, 0)

	-- Crear el card del HUD
	local card = RoUI.Frame({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 124),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		children = HUDCard({
			state = props.state,
			timer = props.timer,
			maxTimer = props.maxTimer,
			round = props.round,
			lowTimeThreshold = props.lowTimeThreshold,
		})
	})

	-- Botón de toggle debajo del card (centrado)
	local toggleButton = RoUI.TextButton({
		Name = "ToggleButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132), -- Centrado, 132px desde arriba (124 card + 8 margen)
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Text = isVisible and "▼" or "▲",
		TextColor3 = Theme.Text,
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		children = {
			RoUI.stroke(1, Theme.CardStroke, 0.2),
			RoUI.corner(10),
		}
	})

	-- Animación hover del botón usando RoUI.animate
	toggleButton.MouseEnter:Connect(function()
		RoUI.animate(toggleButton, {
			BackgroundColor3 = Theme.Primary,
			Size = UDim2.new(0, 44, 0, 44)
		}, {
			duration = 0.2,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out,
		}):play()
	end)

	toggleButton.MouseLeave:Connect(function()
		RoUI.animate(toggleButton, {
			BackgroundColor3 = Theme.Card,
			Size = UDim2.new(0, 40, 0, 40)
		}, {
			duration = 0.2,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out,
		}):play()
	end)

	-- Conectar el callback de toggle
	if props.onToggle then
		toggleButton.Activated:Connect(props.onToggle)
	end

	-- Contenedor que agrupa el card y el botón para animarlos juntos
	local container = RoUI.Frame({
		Name = "HUD",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 172), -- 124 (card) + 8 (margen) + 40 (botón)
		Position = isVisible and visiblePosition or hiddenPosition,
		BackgroundTransparency = 1,
		children = {
			card,
			toggleButton,
		}
	})

	-- Animar la transición cuando cambia la visibilidad usando RoUI
	task.spawn(function()
		local targetPosition = isVisible and visiblePosition or hiddenPosition
		
		RoUI.animate(container, {
			Position = targetPosition
		}, {
			duration = 0.4,
			style = Enum.EasingStyle.Back,
			direction = Enum.EasingDirection.Out,
		}):play()
	end)

	return container
end

return HUD
