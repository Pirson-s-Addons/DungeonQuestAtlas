local addonName, ns = ...
local L = ns.L

-- ==========================================
-- MAPAS DE MAZMORRA
-- ==========================================
-- Los planos de Data/Maps.lua (mapas de Blizzard de WoW Classic; WoW Forever
-- no trae mapas de mazmorra), en su propia ventana (boton "Ver mapa" de la
-- pestana Mazmorra) y, dentro de la mazmorra, en el mapa del mundo (M). Cada
-- jefe es una chincheta con su cara: al pulsarla se abre su pestana de Jefes.

local ART = "Interface\\AddOns\\" .. addonName .. "\\Art\\Maps\\"
local MAP_W, MAP_H = 1002, 668 -- lo que se ve de las 4x3 piezas de 256
local WIDTH = 780              -- ancho del plano en la ventana
local SCALE = WIDTH / MAP_W
local FOOTER = 44              -- franja de abajo: la placa de las plantas
local PAD, TOP = 10, 62        -- margen del plano y alto del titulo (con el retrato)
local PIN = 24                 -- la cara; con el aro, la chincheta mide ~1,5 veces
local MAX_ZOOM, ZOOM_STEP = 4, 1.25 -- rueda del raton: zoom hacia el cursor

-- Planos de una mazmorra (o nil)
function ns.DungeonMaps(d)
    return d and ns.Maps[d.key]
end

local function PageButton(parent, kind)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(32, 32)
    b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Down")
    b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return b
end

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
    pin:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    pin:SetScript("OnClick", function(self)
        ns.ShowBoss(self.dungeon, self.index)
        if onClick then onClick() end
    end)
    ns.AddTooltip(pin, function()
        return ns.BossName(pin.boss, pin.dungeon) .. "\n|cffffffff" .. L.MAP_PIN_TOOLTIP .. "|r"
    end)
    return pin
end

-- Plano: viewport que recorta y, dentro, el plano a escala con sus 12 piezas
-- (la ultima columna y la ultima fila se recortan) y las chinchetas. El plano
-- cabe entero en el viewport (centrado si sobra sitio) y la rueda hace zoom.
-- Arrastrar con zoom mueve el plano; sin zoom llama a onIdleDrag(true/false).
-- La placa de plantas (plan.plaque) la coloca quien crea el plano.
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
    local pins = {}
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
        for _, pin in ipairs(pins) do
            if pin.x then
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", canvas, "TOPLEFT", pin.x * mw, -pin.y * mh)
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

    -- Plantas: placa de cuero con las flechas en sus puntas y "Planta 2/3"
    local plaque = ns.CreateDarkBox(parent)
    plaque:SetSize(250, 38)
    local page = plaque:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ns.SetTitleFont(page, 17)
    page:SetPoint("CENTER", 0, 1)
    local prev, nextPage = PageButton(plaque, "Prev"), PageButton(plaque, "Next")
    prev:SetPoint("LEFT", 12, 0)
    nextPage:SetPoint("RIGHT", -12, 0)
    plaque.page, plaque.prev, plaque.next = page, prev, nextPage
    plan.plaque = plaque

    function plan:ShowFloor(index)
        local floors = self.floors
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
        for _, pin in ipairs(pins) do pin:Hide() end
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
            pin:Show()
        end
        for k = #floor.pins + 1, #pins do pins[k].x = nil end
        zoom, ox, oy = 1, 0, 0
        Layout()
        page:SetText(#floors > 1 and L.MAP_FLOOR:format(index, #floors) or "")
        plaque:SetShown(#floors > 1)
        prev:SetEnabled(index > 1)
        nextPage:SetEnabled(index < #floors)
    end

    function plan:SetDungeon(d, floors)
        self.dungeon, self.floors = d, floors
        self:ShowFloor(1)
    end

    prev:SetScript("OnClick", function() plan:ShowFloor(plan.index - 1) end)
    nextPage:SetScript("OnClick", function() plan:ShowFloor(plan.index + 1) end)
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
    return plan
end

-- ==========================================
-- VENTANA DEL MAPA (boton "Ver mapa")
-- ==========================================

local window
local function CreateWindow()
    -- El marco con retrato del juego (como la Guia): el nombre en el titulo, el
    -- plano en un hueco hundido y la placa de plantas debajo
    window = CreateFrame("Frame", "DungeonQuestAtlasMapFrame", UIParent, "PortraitFrameTemplate")
    window:Hide()
    window:SetSize(WIDTH + 2 * PAD, TOP + MAP_H * SCALE + FOOTER + PAD)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG") -- encima de la ventana principal (HIGH)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    if window.SetPortraitToAsset then window:SetPortraitToAsset(ns.LOGO) end
    tinsert(UISpecialFrames, "DungeonQuestAtlasMapFrame")

    -- Arrastrar el plano sin zoom mueve la ventana
    local plan = CreatePlan(window, function(start)
        if start then window:StartMoving() else window:StopMovingOrSizing() end
    end)
    window.plan = plan
    local viewport = plan.viewport
    viewport:SetSize(WIDTH, MAP_H * SCALE)
    viewport:SetPoint("TOPLEFT", PAD, -TOP)
    local inset = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", viewport, -3, 3)
    inset:SetPoint("BOTTOMRIGHT", viewport, 3, -3)
    inset:SetFrameLevel(math.max(viewport:GetFrameLevel() - 1, 0))
    plan.plaque:SetPoint("CENTER", window, "BOTTOM", 0, (FOOTER + PAD) / 2)

    -- Clic derecho mantenido y arrastrar (en el plano o en el marco): tamano
    window:SetScale(ns.db.mapScale or 1)
    ns.EnableRightDragScale(window, { window, viewport }, function(scale) ns.db.mapScale = scale end)
end

function ns.ShowDungeonMap(d)
    local floors = ns.DungeonMaps(d)
    if not floors then return end
    if not window then CreateWindow() end
    if window.SetTitle then window:SetTitle(ns.DungeonName(d)) end
    window.plan:SetDungeon(d, floors)
    window:Show()
end

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
    -- Plantas: placa pequena bajo el boton de volver al mapa del mundo, fuera del
    -- plano (abajo tapaba las salas)
    local plaque = plan.plaque
    plaque:SetSize(170, 28)
    plaque.page:SetFontObject("GameFontNormal")
    ns.SetTitleFont(plaque.page, 14)
    for _, arrow in ipairs({ plaque.prev, plaque.next }) do arrow:SetSize(24, 24) end
    plaque.prev:SetPoint("LEFT", 4, 0)
    plaque.next:SetPoint("RIGHT", -4, 0)
    plaque:SetFrameLevel(plan.viewport:GetFrameLevel() + 10)
    -- Clic derecho: planta siguiente; izquierdo: la anterior (no al soltar un arrastre)
    local downX, downY
    plan.viewport:HookScript("OnMouseDown", function() downX, downY = GetCursorPosition() end)
    plan.viewport:HookScript("OnMouseUp", function(_, button)
        local x, y = GetCursorPosition()
        if not downX or math.abs(x - downX) + math.abs(y - downY) > 8 then return end
        local step = (button == "RightButton" and 1) or (button == "LeftButton" and -1) or 0
        if step ~= 0 and plan.floors[plan.index + step] then plan:ShowFloor(plan.index + step) end
    end)

    toggle = CreateFrame("Button", nil, WorldMapFrame, "UIPanelButtonTemplate")
    toggle:SetSize(170, 26)
    toggle:SetPoint("TOPRIGHT", host, "TOPRIGHT", -8, -8)
    toggle:SetFrameLevel(overlay:GetFrameLevel() + 30)
    toggle:SetText(L.VIEW_MAP)
    ns.SetButtonIcon(toggle, "Interface\\Icons\\INV_Misc_Map_01")
    plaque:SetPoint("TOPRIGHT", toggle, "BOTTOMRIGHT", 0, -4)
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
