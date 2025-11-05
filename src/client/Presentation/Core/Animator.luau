-- Animator.luau
-- Sistema declarativo de animaciones para RoUI

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
	tween: Tween,
	play: (self: Animation) -> (),
	pause: (self: Animation) -> (),
	cancel: (self: Animation) -> (),
	onComplete: (self: Animation, callback: () -> ()) -> Animation,
}

-- ============================================================================
-- CONFIGURACIÓN POR DEFECTO
-- ============================================================================

local DEFAULT_CONFIG: AnimationConfig = {
	duration = 0.3,
	style = Enum.EasingStyle.Quad,
	direction = Enum.EasingDirection.Out,
	repeatCount = 0,
	reverses = false,
	delayTime = 0,
}

-- ============================================================================
-- ANIMACIÓN BÁSICA
-- ============================================================================

-- Animar un componente con propiedades objetivo
function Animator.animate(
	instance: Instance, 
	targetProps: {[string]: any},
	config: AnimationConfig?
): Animation
	local finalConfig = config or {}
	
	-- Aplicar defaults
	for key, value in pairs(DEFAULT_CONFIG) do
		if finalConfig[key] == nil then
			finalConfig[key] = value
		end
	end
	
	-- Crear TweenInfo
	local tweenInfo = TweenInfo.new(
		finalConfig.duration,
		finalConfig.style,
		finalConfig.direction,
		finalConfig.repeatCount,
		finalConfig.reverses,
		finalConfig.delayTime
	)
	
	-- Crear tween
	local tween = TweenService:Create(instance, tweenInfo, targetProps)
	
	-- Crear objeto de animación
	local animation = {
		tween = tween
	}
	
	function animation:play()
		self.tween:Play()
		return self
	end
	
	function animation:pause()
		self.tween:Pause()
		return self
	end
	
	function animation:cancel()
		self.tween:Cancel()
		return self
	end
	
	function animation:onComplete(callback: () -> ())
		self.tween.Completed:Connect(callback)
		return self
	end
	
	return animation
end

-- ============================================================================
-- ANIMACIONES PREDEFINIDAS (PRESETS)
-- ============================================================================

-- Fade in
function Animator.fadeIn(instance: Instance, duration: number?): Animation
	return Animator.animate(instance, {
		Transparency = 0
	}, {
		duration = duration or 0.3,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	})
end

-- Fade out
function Animator.fadeOut(instance: Instance, duration: number?): Animation
	return Animator.animate(instance, {
		Transparency = 1
	}, {
		duration = duration or 0.3,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.In,
	})
end

-- Scale up (bounce)
function Animator.scaleUp(instance: Instance, targetScale: number?, duration: number?): Animation
	local scale = targetScale or 1.1
	local originalSize = instance.Size
	
	return Animator.animate(instance, {
		Size = UDim2.new(
			originalSize.X.Scale * scale,
			originalSize.X.Offset * scale,
			originalSize.Y.Scale * scale,
			originalSize.Y.Offset * scale
		)
	}, {
		duration = duration or 0.2,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	})
end

-- Scale down
function Animator.scaleDown(instance: Instance, targetScale: number?, duration: number?): Animation
	local scale = targetScale or 0.9
	local originalSize = instance.Size
	
	return Animator.animate(instance, {
		Size = UDim2.new(
			originalSize.X.Scale * scale,
			originalSize.X.Offset * scale,
			originalSize.Y.Scale * scale,
			originalSize.Y.Offset * scale
		)
	}, {
		duration = duration or 0.2,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	})
end

-- Slide in (desde arriba, abajo, izquierda, derecha)
function Animator.slideIn(
	instance: Instance, 
	direction: "top" | "bottom" | "left" | "right",
	distance: number?,
	duration: number?
): Animation
	local dist = distance or 100
	local currentPos = instance.Position
	
	local targetPos = currentPos
	if direction == "top" then
		instance.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset - dist)
	elseif direction == "bottom" then
		instance.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset + dist)
	elseif direction == "left" then
		instance.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset - dist, currentPos.Y.Scale, currentPos.Y.Offset)
	elseif direction == "right" then
		instance.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + dist, currentPos.Y.Scale, currentPos.Y.Offset)
	end
	
	return Animator.animate(instance, {
		Position = targetPos
	}, {
		duration = duration or 0.4,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	})
end

-- Shake (efecto de vibración)
function Animator.shake(instance: Instance, intensity: number?, duration: number?): Animation
	local int = intensity or 5
	local dur = duration or 0.5
	local originalPos = instance.Position
	
	-- Crear secuencia de shakes
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < dur do
			local offsetX = math.random(-int, int)
			local offsetY = math.random(-int, int)
			
			instance.Position = UDim2.new(
				originalPos.X.Scale,
				originalPos.X.Offset + offsetX,
				originalPos.Y.Scale,
				originalPos.Y.Offset + offsetY
			)
			
			task.wait(0.05)
		end
		
		-- Volver a posición original
		instance.Position = originalPos
	end)
	
	-- Retornar animación dummy (para API consistente)
	return {
		tween = nil,
		play = function() end,
		pause = function() end,
		cancel = function() end,
		onComplete = function(_, callback) 
			task.delay(dur, callback)
			return _
		end,
	}
end

-- Pulse (efecto de pulso)
function Animator.pulse(instance: Instance, scale: number?, duration: number?): Animation
	local targetScale = scale or 1.1
	local dur = duration or 0.3
	
	return Animator.animate(instance, {
		Size = UDim2.new(
			instance.Size.X.Scale * targetScale,
			instance.Size.X.Offset,
			instance.Size.Y.Scale * targetScale,
			instance.Size.Y.Offset
		)
	}, {
		duration = dur,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.InOut,
		repeatCount = 1,
		reverses = true,
	})
end

-- ============================================================================
-- ANIMACIONES ENCADENADAS (SEQUENCE)
-- ============================================================================

-- Ejecutar animaciones en secuencia
function Animator.sequence(animations: {Animation}): Animation
	local currentIndex = 1
	
	local function playNext()
		if currentIndex <= #animations then
			local anim = animations[currentIndex]
			currentIndex = currentIndex + 1
			
			anim:onComplete(function()
				playNext()
			end)
			
			anim:play()
		end
	end
	
	return {
		tween = nil,
		play = function()
			playNext()
		end,
		pause = function() end,
		cancel = function()
			for _, anim in ipairs(animations) do
				anim:cancel()
			end
		end,
		onComplete = function(_, callback)
			if #animations > 0 then
				animations[#animations]:onComplete(callback)
			end
			return _
		end,
	}
end

-- Ejecutar animaciones en paralelo
function Animator.parallel(animations: {Animation}): Animation
	return {
		tween = nil,
		play = function()
			for _, anim in ipairs(animations) do
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
		onComplete = function(_, callback)
			-- Esperar a que todas terminen
			local completed = 0
			for _, anim in ipairs(animations) do
				anim:onComplete(function()
					completed = completed + 1
					if completed == #animations then
						callback()
					end
				end)
			end
			return _
		end,
	}
end

return Animator
