local addonName, ns = ...
local L = ns.L

-- ==========================================
-- MAPAS DE MAZMORRA
-- ==========================================
-- Los planos de Data/Maps.lua (mapas de Blizzard de WoW Classic; WoW Forever
-- no trae mapas de mazmorra), en su propia ventana: boton "Ver mapa" de la
-- pestana Mazmorra. Cada jefe es una chincheta con su cara: al pulsarla se
-- abre su pestana de Jefes con el botin.

local ART = "Interface\\AddOns\\" .. addonName .. "\\Art\\Maps\\"
local MAP_W, MAP_H = 1002, 668 -- lo que se ve de las 4x3 piezas de 256
local WIDTH = 780              -- ancho del plano en la ventana
local SCALE = WIDTH / MAP_W
local FOOTER = 36              -- barra de abajo: plantas
local PIN = 24                 -- la cara; con el aro, la chincheta mide ~1,5 veces
local MAX_ZOOM, ZOOM_STEP = 4, 1.25 -- rueda del raton: zoom hacia el cursor

-- Planos de una mazmorra (o nil)
function ns.DungeonMaps(d)
    return d and ns.Maps[d.key]
end

local function PageButton(parent, kind)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(28, 28)
    b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Down")
    b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. kind .. "Page-Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return b
end

-- Chincheta de jefe: su cara recortada en circulo dentro de un aro, como los
-- botones del minimapa (medidas de LibDBIcon: aro de 53 con el hueco de 20 en
-- 7,-5; aqui escaladas a PIN)
local function CreatePin(canvas)
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
    pin:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    pin:SetScript("OnClick", function(self) ns.ShowBoss(self.dungeon, self.index) end)
    ns.AddTooltip(pin, function()
        return ns.BossName(pin.boss, pin.dungeon) .. "\n|cffffffff" .. L.MAP_PIN_TOOLTIP .. "|r"
    end)
    return pin
end

local window
local function CreateWindow()
    window = CreateFrame("Frame", "DungeonQuestAtlasMapFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(WIDTH + 20, MAP_H * SCALE + FOOTER + 38)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG") -- encima de la ventana principal (HIGH)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    tinsert(UISpecialFrames, "DungeonQuestAtlasMapFrame")
    window.title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.title:SetPoint("TOP", 0, -5)

    -- Plano: 12 piezas; la ultima columna y la ultima fila se recortan.
    -- viewport recorta; canvas es el plano a zoom * SCALE, desplazado (ox, oy).
    local viewport = CreateFrame("Frame", nil, window)
    viewport:SetSize(WIDTH, MAP_H * SCALE)
    viewport:SetPoint("TOP", 0, -28)
    viewport:SetClipsChildren(true)
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
        local s = SCALE * zoom
        ox = math.max(0, math.min(ox, MAP_W * s - WIDTH))
        oy = math.max(0, math.min(oy, MAP_H * s - MAP_H * SCALE))
        canvas:SetSize(MAP_W * s, MAP_H * s)
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
                pin:SetPoint("CENTER", canvas, "TOPLEFT", pin.x * MAP_W * s, -pin.y * MAP_H * s)
            end
        end
    end

    -- Zoom con la rueda; (cx, cy): el cursor dentro del plano, que no se mueve
    function window:Zoom(delta, cx, cy)
        local old = zoom
        zoom = math.max(1, math.min(MAX_ZOOM, zoom * ZOOM_STEP ^ delta))
        ox = (cx + ox) * zoom / old - cx
        oy = (cy + oy) * zoom / old - cy
        Layout()
    end
    function window:GetZoom() return zoom end

    local page = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    page:SetPoint("BOTTOM", 0, 18)
    local prev, nextPage = PageButton(window, "Prev"), PageButton(window, "Next")
    prev:SetPoint("RIGHT", page, "LEFT", -6, 0)
    nextPage:SetPoint("LEFT", page, "RIGHT", 6, 0)

    function window:ShowFloor(index)
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
            local pin = pins[k] or CreatePin(canvas)
            pins[k] = pin
            local boss = ns.Bosses[self.dungeon.key][p[1]]
            pin.dungeon, pin.index, pin.boss = self.dungeon, p[1], boss
            ns.SetBossPortrait(pin.portrait, boss)
            pin.x, pin.y = p[2], p[3]
            pin:Show()
        end
        for k = #floor.pins + 1, #pins do pins[k].x = nil end
        zoom, ox, oy = 1, 0, 0
        Layout()
        page:SetText(#floors > 1 and L.MAP_FLOOR:format(index, #floors) or "")
        prev:SetShown(#floors > 1)
        nextPage:SetShown(#floors > 1)
        prev:SetEnabled(index > 1)
        nextPage:SetEnabled(index < #floors)
    end

    prev:SetScript("OnClick", function() window:ShowFloor(window.index - 1) end)
    nextPage:SetScript("OnClick", function() window:ShowFloor(window.index + 1) end)
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", function(self, delta)
        local x, y = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        window:Zoom(delta, x / scale - self:GetLeft(), self:GetTop() - y / scale)
    end)
    -- Arrastrar: con zoom mueve el plano; sin zoom, la ventana
    viewport:EnableMouse(true)
    viewport:RegisterForDrag("LeftButton")
    viewport:SetScript("OnDragStart", function(self)
        if zoom == 1 then window:StartMoving() return end
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
        window:StopMovingOrSizing()
    end)
end

-- Boton "Ver mapa"
function ns.ShowDungeonMap(d)
    local floors = ns.DungeonMaps(d)
    if not floors then return end
    if not window then CreateWindow() end
    window.dungeon, window.floors = d, floors
    window.title:SetText(ns.DungeonName(d))
    window:ShowFloor(1)
    window:Show()
end
