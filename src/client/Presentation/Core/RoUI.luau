-- RoUI.luau
-- Librería modular React-inspired para Roblox UI
-- Sistema completo de componentes con reactividad y animaciones

-- Importar módulos
local Signals = require(script.Parent.Signals)
local Animator = require(script.Parent.Animator)
local UIModifiers = require(script.Parent.UIModifiers)

local RoUI = {}

-- Re-exportar tipos
export type Signal<T> = Signals.Signal<T>
export type Animation = Animator.Animation
export type AnimationConfig = Animator.AnimationConfig

-- ============================================================================
-- COMPONENTES
-- ============================================================================

export type ComponentProps = {[string]: any}

-- Crear una instancia de Roblox con props
function RoUI.create(className: string, props: ComponentProps?): Instance
	local instance = Instance.new(className)

	if props then
		RoUI.applyProps(instance, props)
	end

	return instance
end

-- Aplicar props a una instancia existente
function RoUI.applyProps(instance: Instance, props: ComponentProps)
	for key, value in pairs(props) do
		if key == "children" then
			-- Los children se manejan aparte
			if typeof(value) == "table" then
				for _, child in ipairs(value) do
					if typeof(child) == "Instance" then
						child.Parent = instance
					end
				end
			elseif typeof(value) == "Instance" then
				value.Parent = instance
			end
		elseif key:sub(1, 2) == "on" and typeof(value) == "function" then
			-- Eventos (onClick, onHover, etc)
			local eventName = key:sub(3) -- Remove "on"
			local event = instance[eventName]
			if event and typeof(event) == "RBXScriptSignal" then
				event:Connect(value)
			end
		else
			-- Props normales
			local success = pcall(function()
				instance[key] = value
			end)
			if not success then
				warn("[RoUI] No se pudo aplicar prop:", key, "a", className)
			end
		end
	end
end

-- Actualizar props de instancia existente (sin recrear)
function RoUI.updateProps(instance: Instance, newProps: ComponentProps)
	for key, value in pairs(newProps) do
		if key ~= "children" and key:sub(1, 2) ~= "on" then
			local success = pcall(function()
				if instance[key] ~= value then
					instance[key] = value
				end
			end)
			if not success then
				warn("[RoUI] No se pudo actualizar prop:", key)
			end
		end
	end
end

-- ============================================================================
-- COMPONENTES HELPER
-- ============================================================================

-- Frame con children
function RoUI.Frame(props: ComponentProps): Frame
	return RoUI.create("Frame", props)
end

-- ScrollingFrame con children
function RoUI.ScrollingFrame(props: ComponentProps): ScrollingFrame
	return RoUI.create("ScrollingFrame", props)
end

-- TextLabel
function RoUI.TextLabel(props: ComponentProps): TextLabel
	return RoUI.create("TextLabel", props)
end

-- TextButton
function RoUI.TextButton(props: ComponentProps): TextButton
	return RoUI.create("TextButton", props)
end

-- ImageLabel
function RoUI.ImageLabel(props: ComponentProps): ImageLabel
	return RoUI.create("ImageLabel", props)
end

-- ImageButton
function RoUI.ImageButton(props: ComponentProps): ImageButton
	return RoUI.create("ImageButton", props)
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================

-- Crear múltiples hijos fácilmente
function RoUI.children(...): {Instance}
	return {...}
end

-- Re-exportar modificadores de UI desde UIModifiers
RoUI.padding = UIModifiers.padding
RoUI.paddingCustom = UIModifiers.paddingCustom
RoUI.corner = UIModifiers.corner
RoUI.stroke = UIModifiers.stroke
RoUI.gradient = UIModifiers.gradient
RoUI.gradientMulti = UIModifiers.gradientMulti
RoUI.shadow = UIModifiers.shadow
RoUI.listLayout = UIModifiers.listLayout
RoUI.gridLayout = UIModifiers.gridLayout
RoUI.tableLayout = UIModifiers.tableLayout
RoUI.pageLayout = UIModifiers.pageLayout
RoUI.aspectRatio = UIModifiers.aspectRatio
RoUI.sizeConstraint = UIModifiers.sizeConstraint
RoUI.textSizeConstraint = UIModifiers.textSizeConstraint
RoUI.scale = UIModifiers.scale

-- ============================================================================
-- SIGNALS (Reactividad)
-- ============================================================================

-- Re-exportar funciones de Signals
RoUI.createSignal = Signals.create
RoUI.computed = Signals.computed

-- Crear componente reactivo que se actualiza cuando cambian signals
function RoUI.reactive(
	builder: (props: ComponentProps) -> Instance,
	signals: {Signal<any>}
): (props: ComponentProps) -> any
	return function(props: ComponentProps)
		local instance = builder(props)
		local unsubscribers = {}

		-- Suscribirse a todos los signals
		for _, signal in ipairs(signals) do
			local unsubscribe = signal:subscribe(function()
				-- Re-aplicar props cuando el signal cambie
				RoUI.updateProps(instance, props)
			end)
			table.insert(unsubscribers, unsubscribe)
		end

		local component = {
			instance = instance,
		}

		function component:update(newProps: ComponentProps)
			RoUI.updateProps(self.instance, newProps)
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

-- ============================================================================
-- ANIMACIONES
-- ============================================================================

-- Re-exportar funciones de Animator
RoUI.animate = Animator.animate
RoUI.fadeIn = Animator.fadeIn
RoUI.fadeOut = Animator.fadeOut
RoUI.scaleUp = Animator.scaleUp
RoUI.scaleDown = Animator.scaleDown
RoUI.slideIn = Animator.slideIn
RoUI.shake = Animator.shake
RoUI.pulse = Animator.pulse
RoUI.sequence = Animator.sequence
RoUI.parallel = Animator.parallel

-- ============================================================================
-- MOUNT/UNMOUNT
-- ============================================================================

-- Montar componente en un container
function RoUI.mount(component: Instance | ReactiveComponent, container: Instance)
	if typeof(component) == "Instance" then
		component.Parent = container
		return function()
			component:Destroy()
		end
	elseif typeof(component) == "table" and component.instance then
		component.instance.Parent = container
		return function()
			component:destroy()
		end
	else
		error("[RoUI] Tipo de componente inválido para mount")
	end
end

return RoUI
