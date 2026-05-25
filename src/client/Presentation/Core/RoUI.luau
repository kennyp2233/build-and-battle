--!strict
-- RoUI.luau
-- Librería ligera React-inspired para Roblox. Sin Virtual DOM ni reconciliación:
-- componentes son funciones que crean instancias reales. Reactividad vía Signals + observe.

local Signals = require(script.Parent.Signals)
local Animator = require(script.Parent.Animator)
local UIModifiers = require(script.Parent.UIModifiers)

local RoUI = {}

export type Signal<T> = Signals.Signal<T>
export type Animation = Animator.Animation
export type AnimationConfig = Animator.AnimationConfig
export type ComponentProps = { [string]: any }

type EventMap = { [string]: (...any) -> () }

-- ============================================================================
-- PROP APPLICATION
-- ============================================================================

local EVENT_PREFIX = "on"
local EVENT_PREFIX_LEN = #EVENT_PREFIX

local function isEventKey(key: string): boolean
	return key:sub(1, EVENT_PREFIX_LEN) == EVENT_PREFIX
end

-- Aplica una prop normal. Si falla, warn con valor incluido para debugging — no silenciado.
local function applySingleProp(instance: Instance, key: string, value: any)
	local ok, err = pcall(function()
		(instance :: any)[key] = value
	end)
	if not ok then
		warn(string.format(
			"[RoUI] No se pudo aplicar prop '%s' = %s en %s: %s",
			key, tostring(value), instance.ClassName, tostring(err)
		))
	end
end

-- Aplica props a una instancia.
-- Garantías de orden:
--   1. Props normales primero.
--   2. children parented antes de Parent (evita flicker de container vacío visible).
--   3. Parent al final.
--   4. Eventos conectados al final (después de que todo está estructurado).
function RoUI.applyProps(instance: Instance, props: ComponentProps)
	local deferredChildren: any = nil
	local deferredParent: Instance? = nil
	local deferredEvents: EventMap? = nil

	for key, value in pairs(props) do
		if key == "children" then
			deferredChildren = value
		elseif key == "Parent" then
			deferredParent = value
		elseif isEventKey(key) and typeof(value) == "function" then
			if not deferredEvents then
				deferredEvents = {}
			end
			(deferredEvents :: EventMap)[key] = value
		else
			applySingleProp(instance, key, value)
		end
	end

	if deferredChildren ~= nil then
		if typeof(deferredChildren) == "table" then
			for _, child in ipairs(deferredChildren) do
				if typeof(child) == "Instance" then
					(child :: Instance).Parent = instance
				end
			end
		elseif typeof(deferredChildren) == "Instance" then
			(deferredChildren :: Instance).Parent = instance
		end
	end

	if deferredEvents then
		for key, callback in pairs(deferredEvents) do
			local eventName = key:sub(EVENT_PREFIX_LEN + 1)
			local event = (instance :: any)[eventName]
			if event and typeof(event) == "RBXScriptSignal" then
				event:Connect(callback)
			else
				warn(string.format("[RoUI] Evento '%s' no existe en %s", eventName, instance.ClassName))
			end
		end
	end

	if deferredParent ~= nil then
		instance.Parent = deferredParent
	end
end

-- Crea una instancia con props.
function RoUI.create(className: string, props: ComponentProps?): Instance
	local instance = Instance.new(className)
	if props then
		RoUI.applyProps(instance, props)
	end
	return instance
end

-- Actualiza props en una instancia ya creada (skip children y eventos).
function RoUI.updateProps(instance: Instance, newProps: ComponentProps)
	for key, value in pairs(newProps) do
		if key ~= "children" and key ~= "Parent" and not isEventKey(key) then
			if (instance :: any)[key] ~= value then
				applySingleProp(instance, key, value)
			end
		end
	end
end

-- ============================================================================
-- PRIMITIVES
-- ============================================================================

function RoUI.Frame(props: ComponentProps): Frame
	return RoUI.create("Frame", props) :: Frame
end

function RoUI.ScrollingFrame(props: ComponentProps): ScrollingFrame
	return RoUI.create("ScrollingFrame", props) :: ScrollingFrame
end

function RoUI.TextLabel(props: ComponentProps): TextLabel
	return RoUI.create("TextLabel", props) :: TextLabel
end

function RoUI.TextButton(props: ComponentProps): TextButton
	return RoUI.create("TextButton", props) :: TextButton
end

function RoUI.ImageLabel(props: ComponentProps): ImageLabel
	return RoUI.create("ImageLabel", props) :: ImageLabel
end

function RoUI.ImageButton(props: ComponentProps): ImageButton
	return RoUI.create("ImageButton", props) :: ImageButton
end

-- ============================================================================
-- MODIFIERS (re-export desde UIModifiers)
-- ============================================================================

RoUI.padding = UIModifiers.padding
RoUI.paddingCustom = UIModifiers.paddingCustom
RoUI.corner = UIModifiers.corner
RoUI.stroke = UIModifiers.stroke
RoUI.gradient = UIModifiers.gradient
RoUI.gradientMulti = UIModifiers.gradientMulti
RoUI.shadow = UIModifiers.shadow
RoUI.glow = UIModifiers.glow
RoUI.listLayout = UIModifiers.listLayout
RoUI.gridLayout = UIModifiers.gridLayout
RoUI.tableLayout = UIModifiers.tableLayout
RoUI.pageLayout = UIModifiers.pageLayout
RoUI.aspectRatio = UIModifiers.aspectRatio
RoUI.sizeConstraint = UIModifiers.sizeConstraint
RoUI.textSizeConstraint = UIModifiers.textSizeConstraint
RoUI.scale = UIModifiers.scale

-- ============================================================================
-- REACTIVITY
-- ============================================================================

RoUI.createSignal = Signals.create
RoUI.computed = Signals.computed

-- Observa un signal y dispara `callback` con el valor inicial + cada cambio.
-- Retorna unsubscribe. Patrón típico: capturas una referencia a la instancia y la mutas.
--
--   local label = RoUI.TextLabel({ Text = "0" })
--   local unsub = RoUI.observe(scoreSignal, function(score)
--       label.Text = tostring(score)
--   end)
function RoUI.observe<T>(signal: Signal<T>, callback: (T) -> ()): () -> ()
	callback(signal:get())
	return signal:subscribe(callback)
end

-- ============================================================================
-- ANIMATIONS (re-export)
-- ============================================================================

RoUI.animate = Animator.animate
RoUI.fadeIn = Animator.fadeIn
RoUI.fadeOut = Animator.fadeOut
RoUI.scaleUp = Animator.scaleUp
RoUI.scaleDown = Animator.scaleDown
RoUI.slideIn = Animator.slideIn
RoUI.shake = Animator.shake
RoUI.pulse = Animator.pulse
RoUI.colorTo = Animator.colorTo
RoUI.numberTo = Animator.numberTo
RoUI.sequence = Animator.sequence
RoUI.parallel = Animator.parallel
RoUI.easings = Animator.easings

-- ============================================================================
-- MOUNT
-- ============================================================================

function RoUI.mount(instance: Instance, container: Instance): () -> ()
	instance.Parent = container
	return function()
		instance:Destroy()
	end
end

return RoUI
