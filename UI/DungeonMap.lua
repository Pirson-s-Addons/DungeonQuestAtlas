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
    item = { size = 16 }, -- el icono del propio objeto
    -- Como llegar a un jefe: escalera de mano propia (_project/tools/dqa_art/ladder.py)
    note = { file = "Interface\\AddOns\\DungeonQuestAtlas\\Art\\UI\\ladder", size = 30 },
    pull = { file = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", size = 16 }, -- Data/Pulls.lua
}

local function SetMarkIcon(texture, kind, itemID)
    if kind == "item" then return texture:SetTexture(ns.ItemInfo(itemID).icon) end
    local icon = MARK_ICON[kind]
    if icon.atlas and texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon.atlas) then
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
        if self.kind == "item" or self.kind == "note" or self.kind == "pull" then return end
        if self.to and plan.floors[self.to] then plan:ShowFloor(self.to) end
    end)
    ns.AddTooltip(mark, function()
        if mark.kind == "entrance" then
            local point = plan.dungeon and ns.Entrance(plan.dungeon)
            return L.MAP_ENTRANCE .. (point and ("\n|cffffffff" .. ns.ZoneName(point.mapID) .. " "
                .. ns.FormatCoords(point) .. "|r\n"
                .. (ns.db.mapEntrances and L.MAP_ENTRANCE_SHOW or L.MARK_ENTRANCE_TOOLTIP)) or "")
        end
        if mark.kind == "item" then
            local item = ns.ItemInfo(mark.itemID)
            return ns.QualityColor(item.quality) .. (item.name or ("#" .. mark.itemID)) .. "|r\n|cffffffff"
                .. L[mark.hint] .. "\n" .. L.MAP_ITEM_SPOT .. "|r"
        end
        if mark.kind == "note" then
            local boss = ns.Bosses[plan.dungeon.key] and ns.Bosses[plan.dungeon.key][mark.boss]
            return "|cff59ff59" .. L[mark.hint]:format(boss and ns.BossName(boss, plan.dungeon) or "?") .. "|r"
        end
        if mark.kind == "pull" then
            return L.MAP_PULL:format(mark.count) .. (mark.step and ("\n|cffffffff" .. L.MAP_ROUTE_STEP:format(mark.step) .. "|r") or "")
        end
        local title = (mark.kind == "up" and L.MAP_UP) or (mark.kind == "down" and L.MAP_DOWN)
            or L.MAP_FLOOR_SHORT:format(mark.to)
        return title .. "\n|cffffffff" .. L.MAP_GO_FLOOR:format(mark.to) .. "|r"
    end)
    return mark
end

-- Tamano de las caras de jefe (ns.db.mapBossScale), de 0 (escondidas) a 150 %
local BOSS_SCALE_MAX, BOSS_SCALE_STEP = 1.5, 0.1
local plans = {}
local function SetBossScale(value) -- tambien ns.SetMapBossScale (Valores por defecto)
    ns.db.mapBossScale = math.floor(math.max(0, math.min(BOSS_SCALE_MAX, value)) * 10 + 0.5) / 10
    for _, plan in ipairs(plans) do plan:UpdateBossScale() end
end
ns.SetMapBossScale = SetBossScale

-- Repinta la planta de cada plano abierto (opciones de pulls y ruta, Valores por defecto)
function ns.RefreshMapPlans()
    for _, plan in ipairs(plans) do
        if plan.dungeon then plan:ShowFloor(plan.index) end
    end
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
    local pins, marks, lines = {}, {}, {}
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
        -- Caras de jefe al tamano elegido (SetScale: su punto va en su propia escala)
        local bossScale = ns.db and ns.db.mapBossScale or 1
        for _, list in ipairs({ pins, marks }) do
            for _, pin in ipairs(list) do
                if pin.x then
                    local k = 1
                    if list == pins then
                        pin:SetShown(bossScale > 0)
                        k = math.max(bossScale, 0.1)
                        pin:SetScale(k)
                    end
                    pin:ClearAllPoints()
                    pin:SetPoint("CENTER", canvas, "TOPLEFT", pin.x * mw / k, -pin.y * mh / k)
                end
            end
        end
        -- Ruta: lineas del plano (debajo de caras y marcas, que son marcos)
        for _, line in ipairs(lines) do
            if line.from then
                line:SetStartPoint("TOPLEFT", canvas, line.from[1] * mw, -line.from[2] * mh)
                line:SetEndPoint("TOPLEFT", canvas, line.to[1] * mw, -line.to[2] * mh)
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

    -- Plantas: un boton del juego por planta, en columna sobre una placa oscura;
    -- la de ahora, iluminada y en blanco. Solo si
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

    -- Tamano de las caras de jefe: placa abajo a la izquierda con - y +; el mismo
    -- en todos los planos
    local sizeBar = ns.CreateDarkBox(parent, 10)
    sizeBar:SetFrameLevel(viewport:GetFrameLevel() + 10)
    sizeBar:SetSize(190, 30)
    sizeBar:SetPoint("BOTTOMLEFT", viewport, "BOTTOMLEFT", 10, 10)
    local sizeText = sizeBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sizeText:SetPoint("CENTER")
    local function SizeButton(text, delta, point, x)
        local b = CreateFrame("Button", nil, sizeBar, "UIPanelButtonTemplate")
        b:SetSize(24, 20)
        b:SetText(text)
        b:SetPoint(point, x, 0)
        b:SetScript("OnClick", function() SetBossScale(ns.db.mapBossScale + delta) end)
        ns.AddTooltip(b, L.MAP_BOSS_ICONS_TOOLTIP)
        return b
    end
    local minus = SizeButton("-", -BOSS_SCALE_STEP, "LEFT", 5)
    local plus = SizeButton("+", BOSS_SCALE_STEP, "RIGHT", -5)
    -- Pulls y ruta (Data/Pulls.lua): placa a la derecha de la de las caras, con un
    -- boton para cada uno (encendido: iluminado y en blanco, como el de la planta).
    -- Solo en las mazmorras con pulls; el mismo valor en todos los planos.
    local pullBar = ns.CreateDarkBox(parent, 10)
    pullBar:SetFrameLevel(viewport:GetFrameLevel() + 10)
    pullBar:SetSize(160, 30)
    pullBar:SetPoint("LEFT", sizeBar, "RIGHT", 6, 0)
    local pullButtons = {}
    local function PullButton(key, text, tooltip, point, x)
        local b = CreateFrame("Button", nil, pullBar, "UIPanelButtonTemplate")
        b:SetSize(72, 20)
        b:SetText(text)
        b:SetPoint(point, x, 0)
        b:SetScript("OnClick", function()
            ns.db[key] = not ns.db[key]
            ns.RefreshMapPlans()
        end)
        ns.AddTooltip(b, tooltip)
        b.key = key
        pullButtons[#pullButtons + 1] = b
    end
    PullButton("mapPulls", L.MAP_PULLS, L.MAP_PULLS_TOOLTIP, "LEFT", 6)
    PullButton("mapRoute", L.MAP_ROUTE, L.MAP_ROUTE_TOOLTIP, "RIGHT", -6)

    function plan:UpdateBossScale()
        local v = ns.db.mapBossScale
        sizeText:SetText(L.MAP_BOSS_ICONS:format(math.floor(v * 100 + 0.5)))
        minus:SetEnabled(v > 0)
        plus:SetEnabled(v < BOSS_SCALE_MAX)
        pullBar:SetShown(self.dungeon and ns.Pulls[self.dungeon.key] ~= nil)
        for _, b in ipairs(pullButtons) do
            local on = ns.db[b.key]
            if on then b:LockHighlight() else b:UnlockHighlight() end
            local text = b:GetFontString()
            if text then
                if on then text:SetTextColor(1, 1, 1) else text:SetTextColor(1, 0.82, 0) end
            end
        end
        Layout()
    end
    plans[#plans + 1] = plan

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
            local boss = (ns.Bosses[self.dungeon.key] or self.dungeon.bosses)[p[1]] -- bandas: los suyos
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
        -- Pulls de la planta (Data/Pulls.lua) delante: las demas marcas quedan encima
        local pulls = ns.Pulls[self.dungeon.key]
        local floorPulls = ns.db.mapPulls and pulls and pulls[index] or {}
        local all = {}
        for _, p in ipairs(floorPulls) do all[#all + 1] = { "pull", p[1], p[2], p[3], p[4] } end
        for _, m in ipairs(floorMarks) do all[#all + 1] = m end
        for k, m in ipairs(all) do
            local mark = marks[k] or CreateMark(canvas, self)
            marks[k] = mark
            local item, note, pull = m[1] == "item", m[1] == "note", m[1] == "pull"
            mark.kind, mark.x, mark.y = m[1], m[2], m[3]
            mark.to = not (item or note or pull) and m[4] or nil
            mark.boss = note and m[4] or nil
            mark.count, mark.step = pull and m[4] or nil, pull and m[5] or nil
            mark.itemID, mark.hint = item and m[4] or nil, m[5]
            SetMarkIcon(mark.icon, m[1], mark.itemID)
            SetMarkIcon(mark.glow, m[1], mark.itemID)
            -- Entrada de una banda (tiene size): verde, como su portal en el mapa del mundo
            local raid = m[1] == "entrance" and self.dungeon.size ~= nil
            ns.TintPortal(mark.icon, raid)
            ns.TintPortal(mark.glow, raid)
            mark:SetSize(MARK_ICON[m[1]].size, MARK_ICON[m[1]].size)
            mark.label:SetText(m[1] == "entrance" and L.MAP_ENTRANCE
                or pull and (ns.db.mapRoute and mark.step and tostring(mark.step) or "")
                or (item or note) and "" or L.MAP_FLOOR_SHORT:format(m[4]))
            mark:SetFrameLevel(canvas:GetFrameLevel() + (pull and 1 or 2)) -- encima de las caras si coinciden; los pulls no
            mark:Show()
        end
        -- Ruta: una linea entre dos pasos seguidos de esta planta (pulls y jefes). El
        -- paso siguiente en otra planta no se une: alli se llega por la escalera.
        for _, line in ipairs(lines) do line:Hide(); line.from = nil end
        if ns.db.mapRoute and pulls and canvas.CreateLine then
            local steps = {}
            for _, p in ipairs(pulls[index] or {}) do
                if p[4] then steps[p[4]] = { p[1], p[2] } end
            end
            for _, p in ipairs(floor.pins) do
                local step = pulls.bosses and pulls.bosses[p[1]]
                if step then steps[step] = { p[2], p[3] } end
            end
            local n = 0
            for step, from in pairs(steps) do
                local to = steps[step + 1]
                if to then
                    n = n + 1
                    local line = lines[n]
                    if not line then
                        line = canvas:CreateLine(nil, "ARTWORK")
                        line:SetThickness(3)
                        line:SetColorTexture(1, 0.82, 0, 0.8)
                        lines[n] = line
                    end
                    line.from, line.to = from, to
                    line:Show()
                end
            end
        end
        self:UpdateBossScale()
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
    -- Clic derecho: atras, al mapa del mundo en la zona de la entrada (como el mapa de
    -- Retail); izquierdo: planta siguiente, y de la ultima a la 1 (no al soltar un arrastre)
    local downX, downY
    viewport:HookScript("OnMouseDown", function() downX, downY = GetCursorPosition() end)
    viewport:HookScript("OnMouseUp", function(_, button)
        local x, y = GetCursorPosition()
        if not downX or math.abs(x - downX) + math.abs(y - downY) > 8 then return end
        if button == "RightButton" then return ns.ShowEntranceOnWorldMap(plan.dungeon) end
        if button == "LeftButton" and #plan.floors > 1 then plan:ShowFloor(plan.index % #plan.floors + 1) end
    end)
    return plan
end
ns.CreateDungeonPlan = CreatePlan

-- ==========================================
-- EN EL MAPA DEL MUNDO (M), DENTRO DE LA MAZMORRA
-- ==========================================
-- Al abrir el mapa del mundo
-- dentro de una mazmorra con plano, el plano tapa el mapa. Un boton vuelve al
-- mapa del mundo; al entrar en otra mazmorra se empieza otra vez por el plano.
-- Fuera de ella, el plano de la mazmorra cuya entrada pulses en el mapa
-- (UI/MapPins.lua) hasta volver, cambiar de mapa o cerrarlo.

local overlay, toggle
local wantWorld = false -- el mapa del mundo en vez del plano (opcion worldMapPlan apagada, o el boton)
local shown -- mazmorra abierta desde su entrada en el mapa del mundo

local function CreateOverlay()
    local host = WorldMapFrame.ScrollContainer or WorldMapFrame
    overlay = CreateFrame("Frame", nil, WorldMapFrame)
    overlay:SetAllPoints(host)
    -- Encima de los pines del mapa; con otro addon que pone su propio plano encima del
    -- mapa (hasta el nivel 9950), el nuestro por delante
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
    local rivals = loaded and (loaded("OpenMap") or loaded("ForeverDungeonJournal"))
    overlay:SetFrameLevel(rivals and math.min(host:GetFrameLevel() + 9900, 9960) or host:GetFrameLevel() + 20)
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
        if shown then shown = nil else wantWorld = not wantWorld end
        ns.UpdateWorldMapOverlay()
    end)
end

-- Banda en la que estas (Data/Raids.lua, por instanceID), o nil
local function CurrentRaid()
    local id = GetInstanceInfo and select(8, GetInstanceInfo())
    for _, raid in ipairs(ns.Raids or {}) do
        if id and raid.instanceID == id then return raid end
    end
end

function ns.UpdateWorldMapOverlay()
    local d = WorldMapFrame and WorldMapFrame:IsShown() and (shown or ns.CurrentDungeon() or CurrentRaid())
    local floors = ns.DungeonMaps(d)
    if not floors then
        if overlay then overlay:Hide(); toggle:Hide() end
        return
    end
    if not overlay then CreateOverlay() end
    toggle:SetText((wantWorld and not shown) and L.VIEW_MAP or (WORLD_MAP or L.VIEW_MAP))
    toggle:Show()
    if wantWorld and not shown then overlay:Hide() return end
    local plan = overlay.plan
    if plan.dungeon ~= d then
        plan:SetDungeon(d, floors)
    else
        plan:ShowFloor(plan.index) -- jefes muertos al dia
    end
    overlay:Show()
end

-- Entrada del plano: abre el mapa del mundo en su zona (fuera de la mazmorra:
-- desde la Sima Ignea, Orgrimmar) con su portal (UI/MapPins.lua) latiendo unos
-- segundos. Con los portales apagados en opciones, un marcador. En M, quita el plano.
function ns.ShowEntranceOnWorldMap(d)
    local point = d and ns.Entrance(d)
    if not point then return end
    if ns.db.mapEntrances then
        ns.entranceHighlight = { key = d.key, untilTime = GetTime() + ns.HIGHLIGHT_TIME }
    else
        ns.SetWaypoint(point, ns.DungeonName(d), "entrance")
    end
    if DungeonQuestAtlasFrame then DungeonQuestAtlasFrame:Hide() end -- que no tape el mapa
    wantWorld, shown = true, nil
    ns.UpdateWorldMapOverlay()
    ns.OpenMapAt(point.mapID)
    ns.RefreshMapPins() -- si el mapa ya estaba en esa zona, no se repinta solo
end

-- Clic en la entrada de una mazmorra en el mapa del mundo: su plano encima
function ns.ShowDungeonOnWorldMap(d)
    if not ns.DungeonMaps(d) then return end
    shown = d
    ns.UpdateWorldMapOverlay()
end

local function ForgetShown()
    if not shown then return end
    shown = nil
    ns.UpdateWorldMapOverlay()
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not WorldMapFrame then return end
        WorldMapFrame:HookScript("OnShow", ns.UpdateWorldMapOverlay)
        WorldMapFrame:HookScript("OnHide", ForgetShown)
        -- Ir a otro mapa (migas, rueda) quita el plano abierto desde una entrada
        if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", ForgetShown) end
        return
    end
    wantWorld = not ns.db.worldMapPlan
    ns.UpdateWorldMapOverlay()
end)

-- Opcion "Plano de la mazmorra en el mapa del mundo": vale ya, sin salir de la mazmorra
function ns.ApplyWorldMapPlan()
    wantWorld = not ns.db.worldMapPlan
    ns.UpdateWorldMapOverlay()
end
