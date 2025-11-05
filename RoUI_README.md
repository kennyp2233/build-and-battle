# RoUI - React-inspired UI Library para Roblox

Una librería **simple y pragmática** para modularizar y organizar código de UI en Roblox, inspirada en React pero diseñada específicamente para el sistema de instancias de Roblox.

## 🎯 Filosofía

- **NO es un clon completo de React** - No necesitamos Virtual DOM ni reconciliación compleja
- **Trabaja CON Roblox, no contra él** - Usa instancias reales directamente
- **Modularización simple** - Componentes como funciones que crean instancias
- **Reactividad opcional** - Signals para actualizar UI cuando cambian valores
- **Composición declarativa** - Sintaxis clara para anidar componentes

## 📦 Características

### ✅ Lo que SÍ tiene:
- ✨ Creación declarativa de instancias
- 🧩 Componentes reutilizables
- 🔄 Sistema de Signals para reactividad básica
- 🎨 Helpers para UICorner, UIPadding, UIStroke, etc
- 🚀 Rendimiento excelente (sin overhead de Virtual DOM)

### ❌ Lo que NO tiene (y no necesita):
- ❌ Virtual DOM
- ❌ Reconciliación compleja
- ❌ Hooks (useState, useEffect, etc) - usa Signals en su lugar
- ❌ JSX/sintaxis especial - solo Luau normal

---

## 🚀 Guía Rápida

### 1. Crear componentes simples

```luau
local RoUI = require(path.to.RoUI)
local Theme = require(path.to.Theme)

-- Componente = función que retorna una instancia
local function MyButton(props: {text: string, onClick: () -> ()})
    return RoUI.TextButton({
        Text = props.text,
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = Theme.Success,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        onActivated = props.onClick,  -- Eventos con prefijo "on"
        children = {
            RoUI.corner(10),          -- UICorner con radio 10
            RoUI.stroke(2, Color3.new(0, 0, 0)),  -- UIStroke
        }
    })
end
```

### 2. Composición de componentes

```luau
local function Card(props: {title: string, content: string})
    return RoUI.Frame({
        Size = UDim2.new(0, 300, 0, 200),
        BackgroundColor3 = Theme.Card,
        children = {
            RoUI.corner(14),
            RoUI.padding(16),  -- Padding uniforme de 16px
            RoUI.listLayout(Enum.FillDirection.Vertical, 8),  -- Layout vertical con gap de 8

            -- Título
            RoUI.TextLabel({
                Text = props.title,
                Size = UDim2.new(1, 0, 0, 30),
                TextSize = 24,
                Font = Enum.Font.GothamBold,
            }),

            -- Contenido
            RoUI.TextLabel({
                Text = props.content,
                Size = UDim2.new(1, 0, 1, -38),
                TextSize = 16,
                TextWrapped = true,
            }),
        }
    })
end
```

### 3. Usar Signals para reactividad

```luau
local RoUI = require(path.to.RoUI)

-- Crear signal
local scoreSignal = RoUI.createSignal(0)

-- Leer valor
print(scoreSignal:get())  -- 0

-- Actualizar valor
scoreSignal:set(100)

-- Suscribirse a cambios
local unsubscribe = scoreSignal:subscribe(function(newScore)
    print("Score changed:", newScore)
end)

-- Cuando ya no necesites el listener
unsubscribe()
```

### 4. Actualizar UI existente

```luau
-- Crear instancia
local myLabel = RoUI.TextLabel({
    Text = "Puntuación: 0",
    TextSize = 20,
})

-- Actualizar props más tarde
RoUI.updateProps(myLabel, {
    Text = "Puntuación: 100",
    TextColor3 = Color3.new(0, 1, 0),
})
```

---

## 📚 API Reference

### Funciones principales

#### `RoUI.create(className: string, props: ComponentProps?): Instance`
Crea una instancia de Roblox con las props especificadas.

```luau
local frame = RoUI.create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(1, 0, 0),
})
```

#### `RoUI.applyProps(instance: Instance, props: ComponentProps)`
Aplica props a una instancia existente.

#### `RoUI.updateProps(instance: Instance, props: ComponentProps)`
Actualiza props de instancia existente (solo las especificadas).

---

### Helpers de instancias

Atajos para crear instancias comunes:

- `RoUI.Frame(props)` → Frame
- `RoUI.ScrollingFrame(props)` → ScrollingFrame
- `RoUI.TextLabel(props)` → TextLabel
- `RoUI.TextButton(props)` → TextButton
- `RoUI.ImageLabel(props)` → ImageLabel
- `RoUI.ImageButton(props)` → ImageButton

---

### Utilidades de UI

#### `RoUI.padding(amount: number): UIPadding`
Crea UIPadding uniforme.

```luau
RoUI.padding(16)  -- 16px en todos los lados
```

#### `RoUI.corner(radius: number): UICorner`
Crea UICorner redondeada.

```luau
RoUI.corner(10)  -- Radio de 10px
```

#### `RoUI.stroke(thickness: number, color: Color3?, transparency: number?): UIStroke`
Crea UIStroke (borde).

```luau
RoUI.stroke(2, Color3.new(1, 1, 1), 0.5)
```

#### `RoUI.gradient(colorA: Color3, colorB: Color3, rotation: number?): UIGradient`
Crea UIGradient de dos colores.

```luau
RoUI.gradient(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255), 45)
```

#### `RoUI.listLayout(direction: Enum.FillDirection?, padding: number?): UIListLayout`
Crea UIListLayout.

```luau
RoUI.listLayout(Enum.FillDirection.Horizontal, 8)  -- Horizontal con gap de 8
```

#### `RoUI.gridLayout(cellSize: UDim2, padding: UDim2?): UIGridLayout`
Crea UIGridLayout.

---

### Sistema de Signals

#### `RoUI.createSignal<T>(initialValue: T): Signal<T>`
Crea un valor observable/reactivo.

**Métodos del Signal:**
- `signal:get()` - Obtener valor actual
- `signal:set(newValue)` - Actualizar valor y notificar listeners
- `signal:subscribe(callback)` - Suscribirse a cambios, retorna función de cleanup

```luau
local count = RoUI.createSignal(0)

-- Leer
print(count:get())  -- 0

-- Escribir
count:set(10)

-- Observar cambios
local unsub = count:subscribe(function(newValue)
    print("Nuevo valor:", newValue)
end)

-- Cleanup
unsub()
```

---

## 🎨 Patrón recomendado: Clase con Signals

```luau
local MyUI = {}
MyUI.__index = MyUI

function MyUI.new()
    local self = setmetatable({}, MyUI)

    -- Crear signals para estado
    self.scoreSignal = RoUI.createSignal(0)
    self.healthSignal = RoUI.createSignal(100)

    -- Crear ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Parent = PlayerGui

    -- Renderizar UI inicial
    self:render()

    return self
end

function MyUI:render()
    self.gui:ClearAllChildren()

    local card = Card({
        score = self.scoreSignal:get(),
        health = self.healthSignal:get(),
    })

    card.Parent = self.gui
    self.currentCard = card
end

-- Actualización eficiente: solo lo que cambió
function MyUI:updateScore(newScore)
    self.scoreSignal:set(newScore)

    -- Opción 1: Re-render completo (simple pero menos eficiente)
    -- self:render()

    -- Opción 2: Actualizar solo el label necesario (más eficiente)
    local scoreLabel = self.currentCard:FindFirstChild("ScoreLabel")
    if scoreLabel then
        RoUI.updateProps(scoreLabel, {
            Text = "Score: " .. newScore
        })
    end
end

function MyUI:destroy()
    self.gui:Destroy()
end

return MyUI
```

---

## 💡 Props especiales

### `children`
Array de instancias hijo que se parentarán automáticamente.

```luau
RoUI.Frame({
    children = {
        RoUI.TextLabel({ Text = "Child 1" }),
        RoUI.TextLabel({ Text = "Child 2" }),
        RoUI.corner(10),
        RoUI.padding(8),
    }
})
```

### Eventos con prefijo `on`
Cualquier prop que empiece con "on" se tratará como evento.

```luau
RoUI.TextButton({
    Text = "Click me",
    onActivated = function()
        print("Button clicked!")
    end,
    onMouseEnter = function()
        print("Hover!")
    end,
})
```

El nombre del evento se obtiene quitando "on":
- `onActivated` → `Activated`
- `onMouseEnter` → `MouseEnter`
- `onInputBegan` → `InputBegan`

---

## 🆚 Comparación con ReactLuau anterior

| Aspecto | ReactLuau (anterior) | RoUI (nuevo) |
|---------|---------------------|--------------|
| Virtual DOM | ✅ Sí (complejo) | ❌ No (directo) |
| Reconciliación | ✅ Automática | ❌ Manual |
| Hooks | ✅ useState, useEffect, etc | ❌ Usa Signals |
| Performance | 🟡 Overhead de reconciliación | ✅ Excelente |
| Complejidad | 🔴 Alta (~400 líneas) | ✅ Baja (~250 líneas) |
| Bugs | 🔴 15+ problemas identificados | ✅ Arquitectura simple = menos bugs |
| Curva aprendizaje | 🟡 Media (conceptos React) | ✅ Baja (Luau + instancias) |

---

## 📖 Ejemplo completo: GameUI

Ver [GameUI_New.luau](src/client/Views/GameUI_New.luau) para un ejemplo completo de:
- Componentes modulares (Badge, Timer, ProgressBar, etc)
- Composición jerárquica (HUDCard compone otros componentes)
- Uso de Signals para estado
- Actualización eficiente (solo timer cambia, no toda la UI)
- API pública limpia

---

## 🤔 ¿Cuándo usar qué estrategia?

### Re-render completo
**Cuándo:** Cambios grandes (estado del juego cambia, nueva pantalla)

```luau
function MyUI:changeScreen(newScreen)
    self.gui:ClearAllChildren()
    self:render(newScreen)
end
```

**Pros:** Simple, fácil de razonar
**Contras:** Menos eficiente para cambios pequeños

### Actualización parcial
**Cuándo:** Cambios pequeños frecuentes (timer, score, health)

```luau
function MyUI:updateTimer(newTime)
    local timerLabel = self.gui:FindFirstChild("Timer")
    if timerLabel then
        RoUI.updateProps(timerLabel, { Text = newTime })
    end
end
```

**Pros:** Muy eficiente
**Contras:** Más código manual

### Hybrid approach (recomendado)
```luau
function MyUI:updateState(newState)
    if newState.screenChanged then
        -- Re-render completo
        self:render()
    else
        -- Actualización parcial
        self:updateTimerOnly()
    end
end
```

---

## 🎓 Conclusión

RoUI te da las **herramientas simples** que necesitas para:
1. ✅ Modularizar componentes
2. ✅ Componer UI declarativamente
3. ✅ Manejar estado reactivo (opcional)
4. ✅ Mantener código limpio y organizado

**Sin** la complejidad innecesaria de un clon completo de React.

---

## 📝 Licencia

MIT - Usa como quieras
