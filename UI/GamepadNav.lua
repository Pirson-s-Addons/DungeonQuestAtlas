local ADDON_NAME, ns = ...

-- ==========================================
-- NAVEGACION CON MANDO
-- ==========================================
-- Fichero comun a los addons de Pirson con ventanas: el mismo en todos (se copia tal cual).
-- Cada ventana se apunta con ns.GamepadNavFor(frame).
-- Necesita en ns.L las claves PAD_MOVE, PAD_SELECT, PAD_TOGGLE, PAD_CLOSE, PAD_BACK,
-- PAD_CLOSE_MENU y PAD_SCROLL. En clientes sin mando, ns.GamepadNavFor no hace nada.
-- Mientras haya una ventana del addon abierta, los botones del mando son de la ventana y no del
-- juego: atajos prioritarios propios (SetOverrideBindingClick, como hace el modo mando del
-- juego sobre UIParent, pero con nuestro marco de dueno). La navegacion del juego
-- (SmartNavigation) no vale: solo recorre ventanas que registra su codigo seguro, y
-- registrarlas desde un addon acaba en SetPreferredGamepadInteractTarget bloqueado.
--   Cruceta / stick izquierdo: al boton mas cercano en esa direccion
--   A / X de PlayStation: clic   X / cuadrado: clic derecho
--   Deslizador elegido: izquierda / derecha cambian su valor
--   Boton seguro elegido (lanzar un hechizo...): A va directo a el, como un atajo
--   B / circulo: atras (padGoBack de la ventana: sus migas) y, en su primera pagina, cerrar
--   Stick derecho y LB/RB: desplazar la lista que hay bajo la seleccion
-- Debajo de la ventana (y de sus pestanas), una barra dice que hay elegido y que hace cada
-- boton ahi: solo los que sirven. Los elementos con clic derecho lo dicen con
-- `padAlt` (clave de L); `padMain` cambia el texto del clic.
-- En combate el juego no deja cambiar atajos: se sueltan al entrar y vuelven al salir.

if not ns then return end -- clientes < 3.0: no pasan la tabla del addon (ni tienen mando)
ns.GamepadNavFor = function() end -- (devuelve nil: sin mando no vigila nada)
if not (C_GamePad and C_Timer and C_Timer.After and SetOverrideBindingClick) then return end

local L = ns.L

-- Nombres genericos del juego, iguales en Xbox, PlayStation y los demas: PAD1 es A o la X de
-- PlayStation, PAD2 es B o el circulo, PAD3 es X o el cuadrado (GamepadConstants.lua).
local CONFIRM = GAMEPAD_FACE_BOTTOM or "PAD1"
local CANCEL = GAMEPAD_FACE_RIGHT or "PAD2"
local ALT = GAMEPAD_FACE_LEFT or "PAD3"
local KEYS = {
    PADDUP = "UP", PADDDOWN = "DOWN", PADDLEFT = "LEFT", PADDRIGHT = "RIGHT",
    [CONFIRM] = "CLICK", [ALT] = "RCLICK", [CANCEL] = "BACK",
    PADLSHOULDER = "SCROLLUP", PADRSHOULDER = "SCROLLDOWN",
}
-- Los sticks no van como botones (PADRSTICKUP solo salta una vez al pasar el umbral): se leen
-- enteros con OnGamePadStick, como el cursor del juego (SoftCursor.lua). "Movement" es el
-- izquierdo y "Camera" el derecho.
local STICK_DEAD = 0.35
local DIRS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

local windows = {}   -- ventanas de DQA abiertas, la ultima arriba
local current        -- elemento elegido
local bound = false

local owner = CreateFrame("Frame")
local nav = CreateFrame("Button", (ADDON_NAME:gsub("%W", "")) .. "PadNav", UIParent)
nav:Hide()

-- Marco dorado sobre lo elegido: cuatro lineas de 2 px por fuera
local mark = CreateFrame("Frame", nil, UIParent)
mark:SetFrameStrata("TOOLTIP")
mark:Hide()
local function Edge(p1, r1, x1, y1, p2, r2, x2, y2)
    local t = mark:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 0.82, 0, 0.95)
    t:SetPoint(p1, mark, r1, x1, y1)
    t:SetPoint(p2, mark, r2, x2, y2)
end
Edge("TOPLEFT", "TOPLEFT", -3, 3, "BOTTOMRIGHT", "TOPRIGHT", 3, 1)            -- arriba
Edge("TOPLEFT", "BOTTOMLEFT", -3, -1, "BOTTOMRIGHT", "BOTTOMRIGHT", 3, -3)    -- abajo
Edge("TOPLEFT", "TOPLEFT", -3, 3, "BOTTOMRIGHT", "BOTTOMLEFT", -1, -3)        -- izquierda
Edge("TOPLEFT", "TOPRIGHT", 1, 3, "BOTTOMRIGHT", "BOTTOMRIGHT", 3, -3)        -- derecha

-- ------------------------------------------
-- Ventana, menu y que se puede elegir
-- ------------------------------------------

local function Window()
    for i = #windows, 1, -1 do
        if windows[i]:IsVisible() then return windows[i] end
        table.remove(windows, i)
    end
end

-- El menu desplegable del juego abierto (filtros, desplegables), si lo hay: el nuevo (Menu) o
-- el clasico (UIDropDownMenu, su nivel mas alto abierto)
local function OpenMenu()
    local manager = Menu and Menu.GetManager and Menu.GetManager()
    local menu = manager and manager.GetOpenMenu and manager:GetOpenMenu()
    if menu and menu:IsVisible() then return menu end
    for level = (UIDROPDOWNMENU_MAXLEVELS or 3), 1, -1 do
        local list = _G["DropDownList" .. level]
        if list and list:IsVisible() then return list end
    end
end

local function Scope() return OpenMenu() or Window() end

local function Clickable(o)
    if not (o.IsVisible and o:IsVisible()) or o == mark then return false end
    if o:IsObjectType("EditBox") then return false end
    if o:IsObjectType("Button") then return o:IsEnabled() end
    if o:IsObjectType("Slider") then return not o.IsEnabled or o:IsEnabled() end
    return o:IsMouseEnabled() and (o:GetScript("OnMouseDown") or o:GetScript("OnMouseUp")) and true or false
end

-- En pantalla y sin cortar por una lista (ScrollBox, scroll frames). Lo que cuelga fuera de la
-- ventana, como las pestanas de abajo, tambien vale.
local function OnScreen(o, scope)
    local l, b, w, h = o:GetRect()
    if not l or w < 4 or h < 4 then return false end
    local cx, cy = l + w / 2, b + h / 2
    local p = o:GetParent()
    while p and p ~= UIParent and p ~= scope do
        if p.DoesClipChildren and p:DoesClipChildren() then
            local pl, pb, pw, ph = p:GetRect()
            if pl and (cx < pl or cx > pl + pw or cy < pb or cy > pb + ph) then return false end
        end
        p = p:GetParent()
    end
    return true
end

local function Collect(frame, scope, list)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsVisible() then
            if Clickable(child) and OnScreen(child, scope) then list[#list + 1] = child end
            Collect(child, scope, list)
        end
    end
    return list
end

local function Center(o)
    local l, b, w, h = o:GetRect()
    return l + w / 2, b + h / 2
end

local function Valid(o)
    local scope = Scope()
    return o and scope and Clickable(o) and OnScreen(o, scope)
end

-- La lista con rueda que hay debajo de algo (o de la ventana)
local function WheelOwner(from)
    local p = from
    while p and p ~= UIParent do
        if p.GetScript and p:GetScript("OnMouseWheel") then return p end
        p = p:GetParent()
    end
end

-- La lista mas grande con rueda dentro de la ventana (sin nada elegido, o fuera de una lista)
local function BiggestWheel(frame, best, area)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsVisible() then
            if child:GetScript("OnMouseWheel") then
                local w, h = child:GetSize()
                if w * h > (area or 0) then best, area = child, w * h end
            end
            best, area = BiggestWheel(child, best, area)
        end
    end
    return best, area
end

-- ------------------------------------------
-- Barra de ayuda: que hay elegido y que hace cada boton ahi
-- ------------------------------------------

local bar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
bar:SetFrameStrata("TOOLTIP")
bar:SetHeight(32)
bar:SetClampedToScreen(true)
bar:Hide()
bar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
bar:SetBackdropColor(0.05, 0.04, 0.03, 0.92)
bar:SetBackdropBorderColor(0.85, 0.68, 0.25, 1)
local focus = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal") -- lo elegido, en dorado
focus:SetPoint("LEFT", 12, 0)
focus:SetJustifyH("LEFT")
focus:SetWordWrap(false)
local divider = bar:CreateTexture(nil, "OVERLAY")
divider:SetColorTexture(0.85, 0.68, 0.25, 0.6)
divider:SetSize(1, 18)
local hints = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

local function Glyph(key) return GetBindingText and GetBindingText(key, "KEY_", true) or key end

-- Texto de lo elegido: el del boton o el de su etiqueta
local function Label(o)
    local text = o.GetText and o:GetText()
    for _, field in ipairs({ "Text", "Name", "label", "title", "name" }) do
        if text and text ~= "" then break end
        local fs = type(o[field]) == "table" and o[field].GetText and o[field]
        text = fs and fs:GetText()
    end
    if not text or text == "" then return nil end
    return (text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("\n.*", ""))
end

-- Lo mas bajo de la ventana con lo que cuelga de ella (las pestanas de abajo)
local function Bottom(win)
    local bottom = win:GetBottom() or 0
    for _, child in ipairs({ win:GetChildren() }) do
        local b = child:IsShown() and child:GetBottom()
        if b and b < bottom then bottom = b end
    end
    return bottom
end

local function UpdateBar()
    local win = Window()
    if not (bound and win) then bar:Hide() return end
    local parts = { Glyph("PADLSTICKUP") .. " " .. L.PAD_MOVE }
    local o = Valid(current) and current
    if o then
        if o:IsObjectType("Slider") then
            parts[#parts + 1] = Glyph("PADDLEFT") .. Glyph("PADDRIGHT") .. " " .. (o:GetValue() or "")
        else
            local main = o.padMain and L[o.padMain] or (o:IsObjectType("CheckButton") and L.PAD_TOGGLE) or L.PAD_SELECT
            parts[#parts + 1] = Glyph(CONFIRM) .. " " .. main
        end
        if o.padAlt and L[o.padAlt] then parts[#parts + 1] = Glyph(ALT) .. " " .. L[o.padAlt] end
    end
    if (o and WheelOwner(o)) or BiggestWheel(win) then parts[#parts + 1] = Glyph("PADRSTICKUP") .. " " .. L.PAD_SCROLL end
    local back = win.padCanGoBack and win.padCanGoBack()
    parts[#parts + 1] = Glyph(CANCEL) .. " " .. (OpenMenu() and L.PAD_CLOSE_MENU or back and L.PAD_BACK or L.PAD_CLOSE)
    hints:SetText(table.concat(parts, "     "))
    local label = o and Label(o)
    focus:SetText(label or "")
    focus:SetWidth(label and math.min((focus.GetUnboundedStringWidth or focus.GetStringWidth)(focus), 240) or 0)
    divider:ClearAllPoints()
    hints:ClearAllPoints()
    if label then
        divider:SetPoint("LEFT", focus, "RIGHT", 12, 0)
        divider:Show()
        hints:SetPoint("LEFT", divider, "RIGHT", 12, 0)
    else
        divider:Hide()
        hints:SetPoint("LEFT", 12, 0)
    end
    bar:SetWidth((label and focus:GetWidth() + 25 or 0) + hints:GetStringWidth() + 24)
    bar:ClearAllPoints()
    bar:SetPoint("TOP", win, "BOTTOM", 0, -((win:GetBottom() or 0) - Bottom(win)) - 6)
    bar:Show()
end

-- ------------------------------------------
-- Moverse y pulsar
-- ------------------------------------------

local function Leave(o)
    local f = o and o.GetScript and o:GetScript("OnLeave")
    if f then pcall(f, o) end
    -- Algunos elementos no esconden su tooltip al salir (con raton lo hace el juego al moverse)
    if o and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(o) then GameTooltip:Hide() end
end

-- A / X de PlayStation: a nuestro boton o, sobre un boton seguro (lanzar un hechizo, usar un
-- objeto), directo a el. Pulsarlo desde nuestro codigo lo bloquearia el juego.
local function BindConfirm(o)
    if not bound or InCombatLockdown() then return end
    local secure = o and o.IsProtected and o:IsProtected() and o:GetName()
    if secure then SetOverrideBindingClick(owner, true, CONFIRM, secure, "LeftButton")
    else SetOverrideBindingClick(owner, true, CONFIRM, nav:GetName(), "CLICK") end
end

local function Select(o)
    if current and current ~= o then Leave(current) end
    current = o
    BindConfirm(o)
    if o then
        mark:ClearAllPoints()
        mark:SetPoint("TOPLEFT", o, "TOPLEFT")
        mark:SetPoint("BOTTOMRIGHT", o, "BOTTOMRIGHT")
        mark:Show()
        local f = o:GetScript("OnEnter")
        if f then pcall(f, o) end
    else
        mark:Hide()
    end
    UpdateBar()
end

-- El mas cercano en esa direccion: distancia en la direccion + el doble de la de lado
function ns.PadBest(fromX, fromY, dir, list, except)
    local dx, dy = dir[1], dir[2]
    local best, bestScore
    for _, o in ipairs(list) do
        if o ~= except then
            local x, y = Center(o)
            local along = (x - fromX) * dx + (y - fromY) * dy
            local side = math.abs((x - fromX) * dy - (y - fromY) * dx)
            if along > 2 then
                local score = along + 2 * side
                if not bestScore or score < bestScore then best, bestScore = o, score end
            end
        end
    end
    return best
end

-- Para empezar (al abrir o al cambiar de pagina): arriba a la izquierda, pero sin la barra del
-- titulo y las migas (rueda de opciones, X, idioma...) si hay algo mas abajo
local TITLE_STRIP = 90
local function First(list, scope)
    local top = scope and scope.GetTop and scope:GetTop()
    local best, bx, by
    for pass = 1, 2 do
        for _, o in ipairs(list) do
            local x, y = Center(o)
            if pass == 2 or not top or y < top - TITLE_STRIP then
                if not best or y > by + 4 or (math.abs(y - by) <= 4 and x < bx) then best, bx, by = o, x, y end
            end
        end
        if best then return best end
    end
end

local function Wheel(delta)
    local scope = Scope()
    local p = (current and WheelOwner(current)) or (scope and BiggestWheel(scope))
    if not p then return false end
    pcall(p:GetScript("OnMouseWheel"), p, delta)
    -- Lo elegido puede quedar fuera de la vista: pasar a lo primero que se vea de esa lista
    C_Timer.After(0.05, function()
        if current and not Valid(current) then
            local inList = First(Collect(p, scope, {}))
            if inList then Select(inList) else Select(nil) end
        else
            UpdateBar()
        end
    end)
    return true
end

local function Move(dirName)
    local scope = Scope()
    if not scope then return end
    local list = Collect(scope, scope, {})
    if not Valid(current) then return Select(First(list, scope)) end
    if current:IsObjectType("Slider") and (dirName == "LEFT" or dirName == "RIGHT") then
        local lo, hi = current:GetMinMaxValues()
        local step = current.GetValueStep and current:GetValueStep() or 0
        if step <= 0 then step = (hi - lo) / 20 end
        local v = current:GetValue() + (dirName == "RIGHT" and step or -step)
        current:SetValue(math.max(lo, math.min(hi, v)))
        return UpdateBar()
    end
    local x, y = Center(current)
    local nextOne = ns.PadBest(x, y, DIRS[dirName], list, current)
    if nextOne then return Select(nextOne) end
    -- Al borde de una lista: bajarla o subirla y probar otra vez
    if (dirName == "DOWN" or dirName == "UP") and Wheel(dirName == "DOWN" and -1 or 1) then
        C_Timer.After(0.05, function()
            local found = ns.PadBest(x, y, DIRS[dirName], Collect(scope, scope, {}), current)
            if found then Select(found) end
        end)
    end
end

local function Press(button)
    if not Valid(current) then return Move("DOWN") end
    local o = current
    if o:IsObjectType("Button") then
        o:Click(button)
    else
        local down, up = o:GetScript("OnMouseDown"), o:GetScript("OnMouseUp")
        if down then down(o, button) end
        if up then up(o, button) end
    end
    -- Lo pulsado puede cambiar la ventana (o abrir un menu): seguir en algo que se vea
    C_Timer.After(0.05, function()
        if Valid(current) then UpdateBar() else Select(nil); Move("DOWN") end
    end)
end

nav:SetScript("OnClick", function(_, action)
    if action == "CLICK" then Press("LeftButton")
    elseif action == "RCLICK" then Press("RightButton")
    elseif action == "BACK" then
        local menu = OpenMenu()
        if menu then
            if menu.Close then menu:Close() elseif CloseDropDownMenus then CloseDropDownMenus() else menu:Hide() end
            C_Timer.After(0.05, UpdateBar)
            return
        end
        -- Atras por las paginas de la ventana (sus migas) y, ya en la primera, cerrar
        local win = Window()
        if win and win.padGoBack and win.padGoBack() then
            Select(nil)
            C_Timer.After(0.05, function() Move("DOWN") end)
        elseif win then
            win:Hide()
        end
    elseif action == "SCROLLUP" then Wheel(1)
    elseif action == "SCROLLDOWN" then Wheel(-1)
    else Move(action) end
end)

-- ------------------------------------------
-- Tomar y soltar el mando
-- ------------------------------------------

-- Stick izquierdo: un paso al inclinarlo y, mantenido, repite (0,35 s y luego cada 0,12 s).
-- Stick derecho: desplaza sin parar, mas rapido cuanto mas inclinado.
local sticks = { Movement = { 0, 0 }, Camera = { 0, 0 } }
local moveDir, moveWait, scrollWait = nil, 0, 0
local stickFrame = CreateFrame("Frame")
stickFrame:Hide()
if stickFrame.EnableGamePadStick then stickFrame:SetScript("OnGamePadStick", function(_, stick, x, y)
    if stick ~= "Movement" and stick ~= "Camera" then return true end
    sticks[stick][1], sticks[stick][2] = x or 0, y or 0
    if stick == "Movement" then
        local dir
        if math.max(math.abs(x), math.abs(y)) >= STICK_DEAD then
            if math.abs(x) > math.abs(y) then dir = x > 0 and "RIGHT" or "LEFT" else dir = y > 0 and "UP" or "DOWN" end
        end
        if dir ~= moveDir then
            moveDir, moveWait = dir, 0.35
            if dir then Move(dir) end
        end
    end
    return false -- es nuestro: ni el personaje ni la camara se mueven
end) end
stickFrame:SetScript("OnUpdate", function(_, elapsed)
    if moveDir then
        moveWait = moveWait - elapsed
        if moveWait <= 0 then moveWait = 0.12; Move(moveDir) end
    end
    local y = sticks.Camera[2]
    if math.abs(y) >= STICK_DEAD then
        scrollWait = scrollWait - elapsed
        if scrollWait <= 0 then
            scrollWait = 0.25 - 0.17 * math.min((math.abs(y) - STICK_DEAD) / (1 - STICK_DEAD), 1)
            Wheel(y > 0 and 1 or -1)
        end
    else
        scrollWait = 0
    end
end)

local function Bind()
    if bound or InCombatLockdown() then return end
    for key, action in pairs(KEYS) do SetOverrideBindingClick(owner, true, key, nav:GetName(), action) end
    bound = true
    BindConfirm(current)
    if stickFrame.EnableGamePadStick then stickFrame:EnableGamePadStick(true) end
    stickFrame:Show()
end

local function Release()
    Select(nil)
    bar:Hide()
    if not bound or InCombatLockdown() then return end
    ClearOverrideBindings(owner)
    bound = false
    if stickFrame.EnableGamePadStick then stickFrame:EnableGamePadStick(false) end
    stickFrame:Hide()
    moveDir = nil
    sticks.Movement[1], sticks.Movement[2], sticks.Camera[1], sticks.Camera[2] = 0, 0, 0, 0
end

owner:RegisterEvent("PLAYER_REGEN_DISABLED") -- aun se puede: se sueltan antes del bloqueo
owner:RegisterEvent("PLAYER_REGEN_ENABLED")
owner:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then Release()
    elseif Window() then Bind() UpdateBar() end
end)

-- Vigila la ventana con un hijo invisible: recibe OnShow/OnHide con ella y ningun SetScript
-- posterior de la ventana lo pisa (un HookScript si). Devuelve ese hijo.
function ns.GamepadNavFor(frame)
    local watch = CreateFrame("Frame", nil, frame)
    watch:SetScript("OnShow", function()
        for i = #windows, 1, -1 do if windows[i] == frame then table.remove(windows, i) end end
        windows[#windows + 1] = frame
        Bind()
        Select(nil)
    end)
    watch:SetScript("OnHide", function()
        if not Window() then Release() elseif not Valid(current) then Select(nil) else UpdateBar() end
    end)
    -- Ventana creada ya visible (se crea al abrirla la primera vez): su OnShow no llega nunca.
    -- Se toma el mando ya y la barra se recoloca cuando esten sus pestanas.
    if frame:IsVisible() == true then
        watch:GetScript("OnShow")()
        C_Timer.After(0, UpdateBar)
    end
    return watch
end
