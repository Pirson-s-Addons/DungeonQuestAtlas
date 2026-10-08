local addonName, ns = ...
local L = ns.L

-- ==========================================
-- MAPAS DE MAZMORRA
-- ==========================================
-- Los planos de Data/Maps.lua (mapas de Blizzard de WoW Classic; WoW Forever
-- no trae mapas de mazmorra), en la ventana principal (boton "Ver mapa": vista
-- "Principal > Mazmorra > Mapa", UI/MainFrame.lua) y, dentro de la mazmorra, en
-- el mapa del mundo (M). Cada jefe es una chincheta con su cara: al pulsarla se
-- abre su pestana de Jefes. La entrada y las escaleras llevan los iconos del
-- mapa del juego; pulsar una escalera lleva a su planta.

local ART = "Interface\\AddOns\\" .. addonName .. "\\Art\\Maps\\"
local MAP_W, MAP_H = 1002, 668 -- lo que se ve de las 4x3 piezas de 256
local PIN = 24                 -- la cara; con el aro, la chincheta mide ~1,5 veces
local MAX_ZOOM, ZOOM_STEP = 4, 1.25 -- rueda del raton: zoom hacia el cursor

-- Planos de una mazmorra (o nil)
function ns.DungeonMaps(d)
    return d and ns.Maps[d.key]
end

-- Planta en la que esta la chincheta de un jefe (por su posicion en ns.Bosses), o nil
function ns.BossFloor(d, bossIndex)
    for f, floor in ipairs(ns.DungeonMaps(d) or {}) do
        for _, p in ipairs(floor.pins) do
            if p[1] == bossIndex then return f end
        end
    end
end

local FLOOR_BUTTON_W, FLOOR_BUTTON_H = 96, 22 -- botones de planta
local FLOOR_PAD, FLOOR_GAP = 7, 3              -- margen de su placa y hueco entre botones

-- Chincheta de jefe: su cara recortada en circulo dentro de un aro, como los
-- botones del minimapa (medidas de LibDBIcon: aro de 53 con el hueco de 20 en
-- 7,-5; aqui escaladas a PIN)
local function CreatePin(canvas, onClick)
    local k = PIN / 20
    local pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(PIN, PIN)
    pin.portrait = pin:CreateTexture(nil, "ARTWORK")
    pin.portrait:SetAllPoints()
    local mask = pin:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(pin.portrait)
    pin.portrait:AddMaskTexture(mask) -- los iconos cuadrados (cofres, objetos) tambien, redondos
    local ring = pin:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(53 * k, 53 * k)
    ring:SetPoint("TOPLEFT", -7 * k, 5 * k)
    pin.cross = ns.CreateSlainMark(pin, PIN + 6) -- jefe muerto (sin placa: no cabe)
    pin.cross:SetPoint("CENTER")
    -- Brillo al pasar el raton: del tamano del boton del minimapa (31 con el aro de
    -- 53 en su esquina), no solo de la cara, para que coincida con el aro
    pin:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    local glow = pin:GetHighlightTexture()
    if glow then
        glow:ClearAllPoints()
        glow:SetSize(31 * k, 31 * k)
        glow:SetPoint("TOPLEFT", -7 * k, 5 * k)
    end
    -- Jefe buscado desde "Ver en el mapa": estrella dorada detras de la cara, grande y
    -- latiendo (brillo y tamano), y el aro encendido. pin.focus es un marco del plano
    -- (no de la chincheta, para quedar detras de ella): con Show/Hide arranca y para todo.
    pin.focus = CreateFrame("Frame", nil, canvas)
    pin.focus:SetAllPoints(pin)
    pin.focus:Hide()
    local star = pin.focus:CreateTexture(nil, "OVERLAY", nil, 7)
    star:SetTexture("Interface\\Cooldown\\star4")
    star:SetBlendMode("ADD")
    star:SetVertexColor(1, 0.8, 0.2)
    star:SetSize(PIN * 3.4, PIN * 3.4)
    star:SetPoint("CENTER")
    local pulse = star:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.35)
    fade:SetDuration(0.45)
    local grow = pulse:CreateAnimation("Scale")
    grow:SetScaleFrom(0.8, 0.8)
    grow:SetScaleTo(1.25, 1.25)
    grow:SetDuration(0.45)
    pin.focus:SetScript("OnShow", function()
        pin:SetFrameLevel(pin:GetParent():GetFrameLevel() + 5) -- encima de caras y marcas, bajo los botones de planta
        pin.focus:SetFrameLevel(pin:GetFrameLevel() - 1)
        pin:LockHighlight()
        pulse:Play()
    end)
    pin.focus:SetScript("OnHide", function()
        pulse:Stop()
        pin:UnlockHighlight()
        pin:SetFrameLevel(pin:GetParent():GetFrameLevel() + 1)
    end)
    pin:SetScript("OnClick", function(self)
        ns.ShowBoss(self.dungeon, self.index)
        if onClick then onClick() end
    end)
    ns.AddTooltip(pin, function()
        return ns.BossName(pin.boss, pin.dungeon) .. "\n|cffffffff" .. L.MAP_PIN_TOOLTIP .. "|r"
    end)
    return pin
end

-- Marcas de la planta: la entrada (el portal de las entradas de mazmorra del mapa
-- del mundo) y las escaleras (las puertas con flecha de los mapas de Blizzard).
-- Si el cliente no tiene el atlas, unas flechas y un icono clasicos.
local MARK_ICON = {
    entrance = { atlas = "dungeon", file = "Interface\\Icons\\Spell_Nature_AstralRecal", size = 30 },
    up = { atlas = "poi-door-up", file = "Interface\\Buttons\\Arrow-Up-Up", size = 28 },
    down = { atlas = "poi-door-down", file = "Interface\\Buttons\\Arrow-Down-Up", size = 28 },
    floor = { atlas = "poi-door", file = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", size = 28 },
}

local function SetMarkIcon(texture, kind)
    local icon = MARK_ICON[kind]
    if texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon.atlas) then
        texture:SetAtlas(icon.atlas)
    else
        texture:SetTexture(icon.file)
    end
end

-- Marca: icono con su rotulo debajo, dorado con contorno como los del mapa del
-- juego (se lee sobre cualquier plano); tooltip y, en las escaleras, clic
local function CreateMark(canvas, plan)
    local mark = CreateFrame("Button", nil, canvas)
    mark.icon = mark:CreateTexture(nil, "ARTWORK")
    mark.icon:SetAllPoints()
    mark.glow = mark:CreateTexture(nil, "HIGHLIGHT")
    mark.glow:SetAllPoints()
    mark.glow:SetBlendMode("ADD")
    mark.label = mark:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font = mark.label:GetFont()
    if font then mark.label:SetFont(font, 13, "OUTLINE") end
    mark.label:SetPoint("TOP", mark, "BOTTOM", 0, -1)
    mark:SetScript("OnClick", function(self)
        if self.kind == "entrance" then return ns.ShowEntranceOnWorldMap(plan.dungeon) end
        if self.to and plan.floors[self.to] then plan:ShowFloor(self.to) end
    end)
    ns.AddTooltip(mark, function()
        if mark.kind == "entrance" then
            local point = plan.dungeon and ns.Entrance(plan.dungeon)
            return L.MAP_ENTRANCE .. (point and ("\n|cffffffff" .. ns.ZoneName(point.mapID) .. " "
                .. ns.FormatCoords(point) .. "|r\n" .. L.MARK_ENTRANCE_TOOLTIP) or "")
        end
        local title = (mark.kind == "up" and L.MAP_UP) or (mark.kind == "down" and L.MAP_DOWN)
            or L.MAP_FLOOR_SHORT:format(mark.to)
        return title .. "\n|cffffffff" .. L.MAP_GO_FLOOR:format(mark.to) .. "|r"
    end)
    return mark
end

-- Plano: viewport que recorta y, dentro, el plano a escala con sus 12 piezas
-- (la ultima columna y la ultima fila se recortan) y las chinchetas. El plano
-- cabe entero en el viewport (centrado si sobra sitio) y la rueda hace zoom.
-- Arrastrar mueve el plano si es mas grande que el viewport; si no, llama a
-- onIdleDrag(true/false). Los botones de planta (plan.floorBar) los coloca quien crea el plano.
local function CreatePlan(parent, onIdleDrag, onPinClick)
    local plan = {}
    local viewport = CreateFrame("Frame", nil, parent)
    viewport:SetClipsChildren(true)
    plan.viewport = viewport
    local canvas = CreateFrame("Frame", nil, viewport)
    local tiles = {}
    for n = 1, 12 do
        tiles[n] = canvas:CreateTexture(nil, "BACKGROUND")
        local w, h = math.min(256, MAP_W - (n - 1) % 4 * 256), math.min(256, MAP_H - math.floor((n - 1) / 4) * 256)
        tiles[n]:SetTexCoord(0, w / 256, 0, h / 256)
    end
    local pins, marks = {}, {}
    local zoom, ox, oy = 1, 0, 0

    -- Coloca piezas y chinchetas para el zoom y el desplazamiento actuales
    -- (las chinchetas no crecen: siguen siendo botones del mismo tamano)
    local function Layout()
        local w, h = viewport:GetSize()
        if type(w) ~= "number" or w <= 0 or h <= 0 then return end
        local s = math.min(w / MAP_W, h / MAP_H) * zoom
        local mw, mh = MAP_W * s, MAP_H * s
        ox = mw <= w and (mw - w) / 2 or math.max(0, math.min(ox, mw - w))
        oy = mh <= h and (mh - h) / 2 or math.max(0, math.min(oy, mh - h))
        canvas:SetSize(mw, mh)
        canvas:ClearAllPoints()
        canvas:SetPoint("TOPLEFT", -ox, oy)
        for n, tile in ipairs(tiles) do
            local col, row = (n - 1) % 4, math.floor((n - 1) / 4)
            tile:SetSize(math.min(256, MAP_W - col * 256) * s, math.min(256, MAP_H - row * 256) * s)
            tile:SetPoint("TOPLEFT", col * 256 * s, -row * 256 * s)
        end
        for _, list in ipairs({ pins, marks }) do
            for _, pin in ipairs(list) do
                if pin.x then
                    pin:ClearAllPoints()
                    pin:SetPoint("CENTER", canvas, "TOPLEFT", pin.x * mw, -pin.y * mh)
                end
            end
        end
    end
    viewport:SetScript("OnSizeChanged", Layout)

    -- Zoom con la rueda; (cx, cy): el cursor dentro del viewport, que no se mueve
    function plan:GetZoom() return zoom end
    local function Zoom(delta, cx, cy)
        local old = zoom
        zoom = math.max(1, math.min(MAX_ZOOM, zoom * ZOOM_STEP ^ delta))
        ox = (cx + ox) * zoom / old - cx
        oy = (cy + oy) * zoom / old - cy
        Layout()
    end
    plan.Zoom = function(_, ...) Zoom(...) end

    -- Plantas: un boton del juego por planta, en columna sobre una placa oscura
    -- (idea de ForeverDungeonJournal); la de ahora, iluminada y en blanco. Solo si
    -- hay mas de una. Caben todas: si no hay alto para 22 px por boton, menguan
    -- (minimo 16). Lo coloca quien crea el plano (plan.floorBar, anclado por arriba).
    local floorBar = ns.CreateDarkBox(parent, 10)
    floorBar:SetFrameLevel(viewport:GetFrameLevel() + 10)
    local floorButtons = {}
    plan.floorBar, plan.floorButtons = floorBar, floorButtons

    local function UpdateFloorButtons()
        local floors = plan.floors
        if not floors then return end
        local n = #floors
        local room = viewport:GetHeight()
        room = (type(room) == "number" and room > 0) and room or 400
        local h = math.max(16, math.min(FLOOR_BUTTON_H, math.floor((room - 20 - 2 * FLOOR_PAD) / n) - FLOOR_GAP))
        for i = 1, math.max(n, #floorButtons) do
            local b = floorButtons[i]
            if i <= n and n > 1 then
                if not b then
                    b = CreateFrame("Button", nil, floorBar, "UIPanelButtonTemplate")
                    b:SetScript("OnClick", function(self) plan:ShowFloor(self.floor) end)
                    floorButtons[i] = b
                end
                b:SetSize(FLOOR_BUTTON_W, h)
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", FLOOR_PAD, -FLOOR_PAD - (i - 1) * (h + FLOOR_GAP))
                b.floor = i
                b:SetText(L.MAP_FLOOR_SHORT:format(i))
                local current = i == plan.index
                if current then b:LockHighlight() else b:UnlockHighlight() end
                local text = b:GetFontString()
                if text then
                    if current then text:SetTextColor(1, 1, 1) else text:SetTextColor(1, 0.82, 0) end
                end
                b:Show()
            elseif b then
                b:Hide()
            end
        end
        floorBar:SetSize(FLOOR_BUTTON_W + 2 * FLOOR_PAD, n * (h + FLOOR_GAP) - FLOOR_GAP + 2 * FLOOR_PAD)
        floorBar:SetShown(n > 1)
    end
    viewport:HookScript("OnSizeChanged", UpdateFloorButtons)

    -- Otra planta: zoom fuera. La misma (refresco de jefes muertos): se queda como esta
    function plan:ShowFloor(index)
        local floors = self.floors
        if index ~= self.index then zoom, ox, oy = 1, 0, 0 end
        self.index = index
        local floor = floors[index]
        -- Primero la pieza del cliente (floor.tex); si no la tiene, la del addon
        local fallback = 0
        for n, tile in ipairs(tiles) do
            if not (floor.tex and tile:SetTexture(floor.tex:format(n)) ~= false) then
                tile:SetTexture(ART .. floor.id .. "_" .. n)
                fallback = fallback + 1
            end
        end
        if fallback > 0 then ns.Debug("mapa %s: %d piezas del addon (el cliente no las tiene)", floor.id, fallback) end
        for _, pin in ipairs(pins) do pin:Hide(); pin.focus:Hide() end
        for k, p in ipairs(floor.pins) do
            local pin = pins[k] or CreatePin(canvas, onPinClick)
            pins[k] = pin
            local boss = ns.Bosses[self.dungeon.key][p[1]]
            pin.dungeon, pin.index, pin.boss = self.dungeon, p[1], boss
            ns.SetBossPortrait(pin.portrait, boss)
            local killed = ns.IsBossKilled(self.dungeon, boss)
            pin.portrait:SetDesaturated(killed)
            pin.cross:SetShown(killed)
            pin.x, pin.y = p[2], p[3]
            pin.focus:SetShown(p[1] == self.focus)
            pin:Show()
        end
        for k = #floor.pins + 1, #pins do pins[k].x = nil end
        for _, mark in ipairs(marks) do mark:Hide(); mark.x = nil end
        local floorMarks = ns.MapMarks[self.dungeon.key] and ns.MapMarks[self.dungeon.key][index] or {}
        for k, m in ipairs(floorMarks) do
            local mark = marks[k] or CreateMark(canvas, self)
            marks[k] = mark
            mark.kind, mark.x, mark.y, mark.to = m[1], m[2], m[3], m[4]
            SetMarkIcon(mark.icon, m[1])
            SetMarkIcon(mark.glow, m[1])
            mark:SetSize(MARK_ICON[m[1]].size, MARK_ICON[m[1]].size)
            mark.label:SetText(m[1] == "entrance" and L.MAP_ENTRANCE or L.MAP_FLOOR_SHORT:format(m[4]))
            mark:SetFrameLevel(canvas:GetFrameLevel() + 2) -- encima de las caras si coinciden
            mark:Show()
        end
        Layout()
        UpdateFloorButtons()
    end

    -- "Ver en el mapa": va a la planta del jefe y lo resalta 3 s, para ver cual es
    -- (nil: quita el resalte)
    function plan:FocusBoss(bossIndex)
        self.focus = bossIndex
        self:ShowFloor(bossIndex and ns.BossFloor(self.dungeon, bossIndex) or self.index)
        if not bossIndex then return end
        local token = {}
        self.focusToken = token
        C_Timer.After(3, function()
            if self.focusToken ~= token then return end
            self.focus = nil
            for _, pin in ipairs(pins) do pin.focus:Hide() end
        end)
    end

    function plan:SetDungeon(d, floors)
        self.dungeon, self.floors, self.index, self.focus = d, floors, nil, nil
        self:ShowFloor(1)
    end

    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", function(self, delta)
        local x, y = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        Zoom(delta, x / scale - self:GetLeft(), self:GetTop() - y / scale)
    end)
    viewport:EnableMouse(true)
    viewport:RegisterForDrag("LeftButton")
    viewport:SetScript("OnDragStart", function(self)
        if zoom == 1 then
            if onIdleDrag then onIdleDrag(true) end
            return
        end
        local x, y = GetCursorPosition()
        local startX, startY, startOx, startOy, scale = x, y, ox, oy, self:GetEffectiveScale()
        self:SetScript("OnUpdate", function()
            local cx, cy = GetCursorPosition()
            ox, oy = startOx - (cx - startX) / scale, startOy + (cy - startY) / scale
            Layout()
        end)
    end)
    viewport:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        if onIdleDrag then onIdleDrag(false) end
    end)
    -- Clic derecho: planta siguiente; izquierdo: la anterior (no al soltar un arrastre)
    local downX, downY
    viewport:HookScript("OnMouseDown", function() downX, downY = GetCursorPosition() end)
    viewport:HookScript("OnMouseUp", function(_, button)
        local x, y = GetCursorPosition()
        if not downX or math.abs(x - downX) + math.abs(y - downY) > 8 then return end
        local step = (button == "RightButton" and 1) or (button == "LeftButton" and -1) or 0
        if step ~= 0 and plan.floors[plan.index + step] then plan:ShowFloor(plan.index + step) end
    end)
    return plan
end
ns.CreateDungeonPlan = CreatePlan

-- ==========================================
-- EN EL MAPA DEL MUNDO (M), DENTRO DE LA MAZMORRA
-- ==========================================
-- Idea de ForeverDungeonJournal (sin su codigo): al abrir el mapa del mundo
-- dentro de una mazmorra con plano, el plano tapa el mapa. Un boton vuelve al
-- mapa del mundo; al entrar en otra mazmorra se empieza otra vez por el plano.

local overlay, toggle
local wantWorld = false

local function CreateOverlay()
    local host = WorldMapFrame.ScrollContainer or WorldMapFrame
    overlay = CreateFrame("Frame", nil, WorldMapFrame)
    overlay:SetAllPoints(host)
    overlay:SetFrameLevel(host:GetFrameLevel() + 20) -- encima de los pines del mapa
    overlay:EnableMouse(true) -- que los clics no lleguen al mapa de debajo
    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.025, 0.02, 1)
    local plan = CreatePlan(overlay, nil, function()
        if not InCombatLockdown() then HideUIPanel(WorldMapFrame) end -- que se vea el libro
    end)
    overlay.plan = plan
    plan.viewport:SetAllPoints()
    plan.viewport:SetFrameLevel(overlay:GetFrameLevel() + 1)

    toggle = CreateFrame("Button", nil, WorldMapFrame, "UIPanelButtonTemplate")
    toggle:SetSize(170, 26)
    toggle:SetPoint("TOPRIGHT", host, "TOPRIGHT", -8, -8)
    toggle:SetFrameLevel(overlay:GetFrameLevel() + 30)
    toggle:SetText(L.VIEW_MAP)
    ns.SetButtonIcon(toggle, "Interface\\Icons\\INV_Misc_Map_01")
    -- Plantas: arriba a la izquierda del plano, como en la ventana
    plan.floorBar:SetPoint("TOPLEFT", host, "TOPLEFT", 10, -10)
    plan.floorBar:SetFrameLevel(plan.viewport:GetFrameLevel() + 10)
    toggle:SetScript("OnClick", function()
        wantWorld = not wantWorld
        ns.UpdateWorldMapOverlay()
    end)
end

function ns.UpdateWorldMapOverlay()
    local d = WorldMapFrame and WorldMapFrame:IsShown() and ns.CurrentDungeon()
    local floors = ns.DungeonMaps(d)
    if not floors then
        if overlay then overlay:Hide(); toggle:Hide() end
        return
    end
    if not overlay then CreateOverlay() end
    toggle:SetText(wantWorld and L.VIEW_MAP or (WORLD_MAP or L.VIEW_MAP))
    toggle:Show()
    if wantWorld then overlay:Hide() return end
    local plan = overlay.plan
    if plan.dungeon ~= d then
        plan:SetDungeon(d, floors)
    else
        plan:ShowFloor(plan.index) -- jefes muertos al dia
    end
    overlay:Show()
end

-- Entrada del plano: la marca en el mapa del mundo y lo abre en su zona (fuera
-- de la mazmorra: desde la Sima Ignea, Orgrimmar). En M, quita el plano.
function ns.ShowEntranceOnWorldMap(d)
    local point = d and ns.Entrance(d)
    if not point then return end
    ns.SetWaypoint(point, ns.DungeonName(d), "entrance")
    if DungeonQuestAtlasFrame then DungeonQuestAtlasFrame:Hide() end -- que no tape el mapa
    wantWorld = true
    ns.UpdateWorldMapOverlay()
    ns.OpenMapAt(point.mapID)
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not WorldMapFrame then return end
        WorldMapFrame:HookScript("OnShow", ns.UpdateWorldMapOverlay)
        return
    end
    wantWorld = false
    ns.UpdateWorldMapOverlay()
end)
