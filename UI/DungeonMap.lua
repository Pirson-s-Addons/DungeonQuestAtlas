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

    -- Plano: 12 piezas; la ultima columna y la ultima fila se recortan
    local canvas = CreateFrame("Frame", nil, window)
    canvas:SetSize(WIDTH, MAP_H * SCALE)
    canvas:SetPoint("TOP", 0, -28)
    local tiles = {}
    for row = 0, 2 do
        for col = 0, 3 do
            local w, h = math.min(256, MAP_W - col * 256), math.min(256, MAP_H - row * 256)
            local tile = canvas:CreateTexture(nil, "BACKGROUND")
            tile:SetSize(w * SCALE, h * SCALE)
            tile:SetPoint("TOPLEFT", col * 256 * SCALE, -row * 256 * SCALE)
            tile:SetTexCoord(0, w / 256, 0, h / 256)
            tiles[row * 4 + col + 1] = tile
        end
    end

    local page = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    page:SetPoint("BOTTOM", 0, 18)
    local prev, nextPage = PageButton(window, "Prev"), PageButton(window, "Next")
    prev:SetPoint("RIGHT", page, "LEFT", -6, 0)
    nextPage:SetPoint("LEFT", page, "RIGHT", 6, 0)

    local pins = {}
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
        if fallback > 0 then ns.Debug("mapa %d: %d piezas del addon (el cliente no las tiene)", floor.id, fallback) end
        for _, pin in ipairs(pins) do pin:Hide() end
        for k, p in ipairs(floor.pins) do
            local pin = pins[k] or CreatePin(canvas)
            pins[k] = pin
            local boss = ns.Bosses[self.dungeon.key][p[1]]
            pin.dungeon, pin.index, pin.boss = self.dungeon, p[1], boss
            ns.SetBossPortrait(pin.portrait, boss)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", p[2] * WIDTH, -p[3] * MAP_H * SCALE)
            pin:Show()
        end
        page:SetText(#floors > 1 and L.MAP_FLOOR:format(index, #floors) or "")
        prev:SetShown(#floors > 1)
        nextPage:SetShown(#floors > 1)
        prev:SetEnabled(index > 1)
        nextPage:SetEnabled(index < #floors)
    end

    prev:SetScript("OnClick", function() window:ShowFloor(window.index - 1) end)
    nextPage:SetScript("OnClick", function() window:ShowFloor(window.index + 1) end)
    canvas:EnableMouseWheel(true)
    canvas:SetScript("OnMouseWheel", function(_, delta)
        local i = window.index - delta
        if i >= 1 and i <= #window.floors then window:ShowFloor(i) end
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
