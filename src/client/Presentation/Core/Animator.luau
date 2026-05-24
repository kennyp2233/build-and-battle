-- Animator.luau
-- Sistema declarativo de animaciones para RoUI.
-- Todos los presets retornan un objeto Animation con play/pause/cancel/onComplete consistente,
-- independientemente de si por debajo usan TweenService o un task.spawn (shake, sequence, parallel).

local TweenService = game:GetService("TweenService")

local Animator = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type AnimationConfig = {
	duration: number?,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverses: boolean?,
	delayTime: number?,
}

export type Animation = {
	tween: Tween?,
	play: (self: Animation) -> Animation,
	pause: (self: Animation) -> Animation,
	cancel: (self: Animation) -> Animation,
	onComplete: (self: Animation, callback: () -> ()) -> Animation,
}

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local DEFAULT_CONFIG: AnimationConfig = {
	duration = 0.3,
	style = Enum.EasingStyle.Quad,
	direction = Enum.EasingDirection.Out,
	repeatCount = 0,
	reverses = false,
	delayTime = 0,
}

local function mergedConfig(config: AnimationConfig?): AnimationConfig
	local merged = table.clone(DEFAULT_CONFIG)
	if config then
		for key, value in pairs(config) do
			merged[key] = value
		end
	end
	return merged
end

-- ============================================================================
-- TRANSPARENCY PROPERTY DETECTION
-- ============================================================================

-- TweenService falla si pides animar una propiedad inexistente: Frame no tiene Transparency.
-- Esta función elige la prop de transparencia correcta para el ClassName del instance.
local function transparencyPropertyFor(instance: Instance): string
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		return "ImageTransparency"
	elseif instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		return "TextTransparency"
	else
		return "BackgroundTransparency"
	end
end

-- ============================================================================
-- BASIC ANIMATION
-- ============================================================================

function Animator.animate(
	instance: Instance,
	targetProps: { [string]: any },
	config: AnimationConfig?
): Animation
	local finalConfig = mergedConfig(config)

	local tweenInfo = TweenInfo.new(
		finalConfig.duration,
		finalConfig.style,
		finalConfig.direction,
		finalConfig.repeatCount,
		finalConfig.reverses,
		finalConfig.delayTime
	)

	local tween = TweenService:Create(instance, tweenInfo, targetProps)

	local animation: Animation
	animation = {
		tween = tween,
		play = function(self)
			tween:Play()
			return self
		end,
		pause = function(self)
			tween:Pause()
			return self
		end,
		cancel = function(self)
			tween:Cancel()
			return self
		end,
		onComplete = function(self, callback)
			tween.Completed:Connect(callback)
			return self
		end,
	}
	return animation
end

-- Crea un Animation "dummy" usado por shake/sequence/parallel — mismo shape que el real
local function makeCustomAnimation(handlers: {
	play: () -> (),
	pause: (() -> ())?,
	cancel: (() -> ())?,
	onComplete: (callback: () -> ()) -> (),
}): Animation
	local animation: Animation
	animation = {
		tween = nil,
		play = function(self)
			handlers.play()
			return self
		end,
		pause = function(self)
			if handlers.pause then handlers.pause() end
			return self
		end,
		cancel = function(self)
			if handlers.cancel then handlers.cancel() end
			return self
		end,
		onComplete = function(self, callback)
			handlers.onComplete(callback)
			return self
		end,
	}
	return animation
end

-- ============================================================================
-- PRESETS
-- ============================================================================

-- Fade in: anima la transparencia correcta del instance hasta 0.
-- `property` opcional para forzar otra (e.g. "TextTransparency" en TextButton además de Background).
function Animator.fadeIn(instance: Instance, duration: number?, property: string?): Animation
	local prop = property or transparencyPropertyFor(instance)
	return Animator.animate(instance, { [prop] = 0 }, {
		duration = duration or 0.3,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	})
end

function Animator.fadeOut(instance: Instance, duration: number?, property: string?): Animation
	local prop = property or transparencyPropertyFor(instance)
	return Animator.animate(instance, { [prop] = 1 }, {
		duration = duration or 0.3,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.In,
	})
end

-- Escala uniforme aplicada tanto a Scale como a Offset
local function scaleUDim2(udim: UDim2, factor: number): UDim2
	return UDim2.new(
		udim.X.Scale * factor,
		udim.X.Offset * factor,
		udim.Y.Scale * factor,
		udim.Y.Offset * factor
	)
end

function Animator.scaleUp(instance: GuiObject, targetScale: number?, duration: number?): Animation
	local scale = targetScale or 1.1
	return Animator.animate(instance, {
		Size = scaleUDim2(instance.Size, scale),
	}, {
		duration = duration or 0.2,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	})
end

function Animator.scaleDown(instance: GuiObject, targetScale: number?, duration: number?): Animation
	local scale = targetScale or 0.9
	return Animator.animate(instance, {
		Size = scaleUDim2(instance.Size, scale),
	}, {
		duration = duration or 0.2,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	})
end

-- Slide in: mueve `instance` a una posición offset (off-screen) y la anima hasta su pos actual.
function Animator.slideIn(
	instance: GuiObject,
	direction: "top" | "bottom" | "left" | "right",
	distance: number?,
	duration: number?
): Animation
	local dist = distance or 100
	local finalPos = instance.Position
	local offsetX, offsetY = 0, 0

	if direction == "top" then
		offsetY = -dist
	elseif direction == "bottom" then
		offsetY = dist
	elseif direction == "left" then
		offsetX = -dist
	elseif direction == "right" then
		offsetX = dist
	end

	instance.Position = UDim2.new(
		finalPos.X.Scale,
		finalPos.X.Offset + offsetX,
		finalPos.Y.Scale,
		finalPos.Y.Offset + offsetY
	)

	return Animator.animate(instance, { Position = finalPos }, {
		duration = duration or 0.4,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	})
end

-- Shake: usa UIScale aplicado al GuiObject. Sobrevive a layouts que sobrescriben Position.
-- Requiere que el instance pueda contener un UIScale (cualquier GuiObject).
function Animator.shake(instance: GuiObject, intensity: number?, duration: number?): Animation
	local int = intensity or 5
	local dur = duration or 0.5
	local completeCallbacks: { () -> () } = {}
	local cancelled = false

	local function play()
		-- Aplicamos translaciones via un UIScale hijo no es válido (UIScale no traslada);
		-- usamos AnchorPoint-based: añadimos un offset temporal restaurando al final.
		local originalPos = instance.Position
		task.spawn(function()
			local startTime = os.clock()
			while not cancelled and (os.clock() - startTime) < dur do
				local offsetX = math.random(-int, int)
				local offsetY = math.random(-int, int)
				instance.Position = UDim2.new(
					originalPos.X.Scale,
					originalPos.X.Offset + offsetX,
					originalPos.Y.Scale,
					originalPos.Y.Offset + offsetY
				)
				task.wait(0.04)
			end
			instance.Position = originalPos
			for _, cb in ipairs(completeCallbacks) do
				task.spawn(cb)
			end
		end)
	end

	return makeCustomAnimation({
		play = play,
		cancel = function()
			cancelled = true
		end,
		onComplete = function(callback)
			table.insert(completeCallbacks, callback)
		end,
	})
end

function Animator.pulse(instance: GuiObject, scale: number?, duration: number?): Animation
	local targetScale = scale or 1.1
	return Animator.animate(instance, {
		Size = scaleUDim2(instance.Size, targetScale),
	}, {
		duration = duration or 0.3,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.InOut,
		repeatCount = 1,
		reverses = true,
	})
end

-- ============================================================================
-- COMPOSITION
-- ============================================================================

function Animator.sequence(animations: { Animation }): Animation
	local cancelled = false

	local function playFrom(index: number, onAllDone: () -> ())
		if cancelled or index > #animations then
			onAllDone()
			return
		end
		local anim = animations[index]
		anim:onComplete(function()
			playFrom(index + 1, onAllDone)
		end)
		anim:play()
	end

	local completeCallbacks: { () -> () } = {}

	return makeCustomAnimation({
		play = function()
			playFrom(1, function()
				for _, cb in ipairs(completeCallbacks) do
					task.spawn(cb)
				end
			end)
		end,
		cancel = function()
			cancelled = true
			for _, anim in ipairs(animations) do
				anim:cancel()
			end
		end,
		onComplete = function(callback)
			table.insert(completeCallbacks, callback)
		end,
	})
end

function Animator.parallel(animations: { Animation }): Animation
	local completeCallbacks: { () -> () } = {}

	return makeCustomAnimation({
		play = function()
			local completed = 0
			local total = #animations
			for _, anim in ipairs(animations) do
				anim:onComplete(function()
					completed += 1
					if completed == total then
						for _, cb in ipairs(completeCallbacks) do
							task.spawn(cb)
						end
					end
				end)
				anim:play()
			end
		end,
		pause = function()
			for _, anim in ipairs(animations) do
				anim:pause()
			end
		end,
		cancel = function()
			for _, anim in ipairs(animations) do
				anim:cancel()
			end
		end,
		onComplete = function(callback)
			table.insert(completeCallbacks, callback)
		end,
	})
end

return Animator
