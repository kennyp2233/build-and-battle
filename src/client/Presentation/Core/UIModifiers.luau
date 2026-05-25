--!strict
-- UIModifiers.luau
-- Utilidades para modificar/decorar componentes UI

local UIModifiers = {}

-- ============================================================================
-- LAYOUT MODIFIERS
-- ============================================================================

-- Aplicar padding uniforme
function UIModifiers.padding(amount: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	return padding
end

-- Aplicar padding personalizado
function UIModifiers.paddingCustom(left: number, right: number, top: number, bottom: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	return padding
end

-- Corner redondeada
function UIModifiers.corner(radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

-- ============================================================================
-- VISUAL MODIFIERS
-- ============================================================================

-- Stroke/borde
function UIModifiers.stroke(thickness: number, color: Color3?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color or Color3.new(1, 1, 1)
	stroke.Transparency = transparency or 0
	return stroke
end

-- Gradiente
function UIModifiers.gradient(colorA: Color3, colorB: Color3, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	gradient.Rotation = rotation or 0
	return gradient
end

-- Gradiente con múltiples colores
function UIModifiers.gradientMulti(keypoints: {{offset: number, color: Color3}}, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	local sequence = {}
	
	for _, kp in ipairs(keypoints) do
		table.insert(sequence, ColorSequenceKeypoint.new(kp.offset, kp.color))
	end
	
	gradient.Color = ColorSequence.new(sequence)
	gradient.Rotation = rotation or 0
	return gradient
end

-- Sombra (usando UIStroke)
function UIModifiers.shadow(blur: number?, transparency: number?): UIStroke
	local shadow = Instance.new("UIStroke")
	shadow.Color = Color3.new(0, 0, 0)
	shadow.Transparency = transparency or 0.5
	shadow.Thickness = blur or 4
	shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return shadow
end

-- Glow: borde semi-transparente coloreado para dar sensación de luz/accent.
-- Roblox no tiene shadow real 2D — un UIStroke grueso con transparencia simula el glow.
function UIModifiers.glow(color: Color3, intensity: number?, transparency: number?): UIStroke
	local glow = Instance.new("UIStroke")
	glow.Color = color
	glow.Thickness = intensity or 3
	glow.Transparency = transparency or 0.35
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return glow
end

-- ============================================================================
-- LAYOUT CONSTRAINTS
-- ============================================================================

-- List layout (vertical/horizontal)
function UIModifiers.listLayout(direction: Enum.FillDirection?, padding: number?, alignment: Enum.HorizontalAlignment?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 0)
	
	if alignment then
		layout.HorizontalAlignment = alignment
	end
	
	return layout
end

-- Grid layout
function UIModifiers.gridLayout(cellSize: UDim2, padding: UDim2?): UIGridLayout
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = cellSize
	layout.CellPadding = padding or UDim2.new(0, 0, 0, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	return layout
end

-- Table layout (para layouts de tabla)
function UIModifiers.tableLayout(padding: UDim2?): UITableLayout
	local layout = Instance.new("UITableLayout")
	layout.Padding = padding or UDim2.new(0, 0, 0, 0)
	return layout
end

-- Page layout (para páginas deslizables)
function UIModifiers.pageLayout(animated: boolean?): UIPageLayout
	local layout = Instance.new("UIPageLayout")
	layout.Animated = if animated ~= nil then animated else true
	layout.EasingStyle = Enum.EasingStyle.Quad
	layout.EasingDirection = Enum.EasingDirection.Out
	layout.TweenTime = 0.3
	return layout
end

-- ============================================================================
-- SIZE CONSTRAINTS
-- ============================================================================

-- Constraint de aspecto (mantener proporciones)
function UIModifiers.aspectRatio(ratio: number): UIAspectRatioConstraint
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio
	return constraint
end

-- Constraint de tamaño
function UIModifiers.sizeConstraint(minSize: Vector2?, maxSize: Vector2?): UISizeConstraint
	local constraint = Instance.new("UISizeConstraint")
	
	if minSize then
		constraint.MinSize = minSize
	end
	
	if maxSize then
		constraint.MaxSize = maxSize
	end
	
	return constraint
end

-- Text size constraint (para texto escalable)
function UIModifiers.textSizeConstraint(minSize: number?, maxSize: number?): UITextSizeConstraint
	local constraint = Instance.new("UITextSizeConstraint")
	
	if minSize then
		constraint.MinTextSize = minSize
	end
	
	if maxSize then
		constraint.MaxTextSize = maxSize
	end
	
	return constraint
end

-- ============================================================================
-- SCALE MODIFIERS
-- ============================================================================

-- UI Scale (para escalar todo un componente)
function UIModifiers.scale(scale: number): UIScale
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	return uiScale
end

return UIModifiers
