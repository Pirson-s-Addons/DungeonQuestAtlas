local _, ns = ...
local L = ns.L

-- ==========================================
-- JEFES Y BOTIN
-- ==========================================
-- Pagina izquierda del libro: botones de jefe del Diario, con la cara del jefe
-- en el hueco redondo del boton (ns.CreateBossList). Pestanas laterales de la
-- pagina derecha: Botin (ns.CreateLootPanel) y Modelo (ns.CreateModelPanel).
-- Nombre e historia salen del Diario del juego si lo conoce (Core/Journal.lua);
-- si no, el nombre de Data/Bosses.lua.

local unpack = unpack or table.unpack
-- Delante de "Raro" sobre el papel: el dragon plateado de los raros del juego (el
-- texto, en tinta: ningun color claro se lee sobre el pergamino)
ns.RARE_PREFIX = "|A:nameplates-icon-elite-silver:14:14|a "
local ICON = {
    trash = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    object = "Interface\\Icons\\INV_Box_01",
    recipes = "Interface\\Icons\\INV_Scroll_05",
    unknown = "Interface\\Icons\\INV_Misc_QuestionMark",
}
local SEP = "  ·  "
-- Distancia de la camara del modelo 3D: el cuerpo entero en la pagina
local MODEL_DISTANCE = 2

-- Retrato del jefe con su modelo (displayID); si el cliente no puede, un icono
function ns.SetBossPortrait(texture, boss)
    texture:SetTexture(nil)
    if boss.display and SetPortraitTextureFromCreatureDisplayID then
        pcall(SetPortraitTextureFromCreatureDisplayID, texture, boss.display)
        if texture:GetTexture() then return end
    end
    texture:SetTexture(ICON[boss.kind] or ICON.unknown)
end

-- Nombre en el idioma del cliente: el del Diario si conoce al jefe; si no, el
-- del tooltip del juego por su npcID (como los PNJ de las misiones)
function ns.BossName(boss, d)
    if boss.kind == "trash" then return L.TRASH end
    if boss.kind == "recipes" then return L.RECIPES end
    local journal = d and ns.JournalBoss(d, boss)
    if journal then return journal.name end
    return boss.npcID and ns.PlaceName(boss) or boss.name
end

-- "Nivel 19 · Raro · 3 objetos"; rarePrefix: lo que va delante de "Raro"
function ns.BossInfo(boss, rarePrefix)
    local info = {}
    local level = type(boss.level) == "table" and table.concat(boss.level, "-") or boss.level
    if level then info[#info + 1] = L.LEVEL .. " " .. level end
    if boss.kind == "rare" then info[#info + 1] = (rarePrefix or "") .. L.RARE end
    info[#info + 1] = L.ITEMS:format(#boss.loot)
    return table.concat(info, SEP)
end

-- Probabilidad (%) de un objeto en el botin de un jefe, si se conoce
function ns.LootChance(boss, itemID)
    for _, it in ipairs(boss and boss.loot or {}) do
        if it[1] == itemID then return it[2] end
    end
end

-- Imagen del Diario (128x64) o, si no, la cara del jefe (retrato redondo)
local function SetBossImage(creature, portrait, boss, d)
    local journal = ns.JournalBoss(d, boss)
    creature:SetShown(journal and journal.icon ~= nil)
    portrait:SetShown(not (journal and journal.icon))
    if journal and journal.icon then
        creature:SetTexture(journal.icon)
    else
        ns.SetBossPortrait(portrait, boss)
    end
end

-- Marca de jefe muerto: la X roja del juego (size px; quien la crea la coloca)
-- y una placa oscura "Derrotado" (ancho segun el texto). Las dos ocultas.
function ns.CreateSlainMark(parent, size)
    local cross = parent:CreateTexture(nil, "OVERLAY", nil, 3)
    cross:SetSize(size, size)
    cross:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    cross:Hide()
    local slain = ns.CreateDarkBox(parent, 10)
    slain:SetFrameLevel(parent:GetFrameLevel() + 5)
    slain:SetHeight(16)
    local text = slain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", 0, 0)
    text:SetTextColor(1, 0.3, 0.25)
    text:SetText(L.BOSS_KILLED)
    slain:SetWidth(math.max(56, text:GetStringWidth() + 16))
    slain:Hide()
    return cross, slain
end

-- Marco del retrato como el del objetivo del juego: el dragon plateado en los
-- raros (reflejado: rodea la cara por la izquierda y no tapa el nombre) y el
-- nivel en la moneda negra con aro dorado, abajo a la derecha ("??" si no se sabe).
-- Borde interior del arco en el atlas del dragon reflejado (80x79): circulo ajustado
-- a su borde, centro (42,9, 41) y radio 27,3. El hueco del boton del Diario es un
-- circulo de radio 30,5 con centro 8 px por debajo de la cara, cortado por abajo: el
-- dragon siguiendolo entero quedaba bajo. Va centrado en lo que se ve (la cara y la
-- cupula), en (36, 28,5) desde la esquina de la fila, con radio 27,5 (maqueta).
local DRAGON, LEVEL_RING = "ui-hud-unitframe-target-portraiton-boss-rare-silver",
    "ui-hud-unitframe-target-portraiton-boss-iconring"

local function AtlasInfo(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

local function DecoratePortrait(row)
    -- Sobresale de la fila (como en el marco de objetivo): va en su propio marco, por
    -- encima de las filas vecinas.
    local k = 27.5 / 27.3
    local holder = CreateFrame("Frame", nil, row)
    holder:SetAllPoints()
    holder:SetFrameLevel(row:GetFrameLevel() + 8)
    local dragon = holder:CreateTexture(nil, "OVERLAY")
    local info = AtlasInfo(DRAGON)
    if info and info.file then
        dragon:SetTexture(info.file)
        dragon:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    end
    dragon:SetSize(80 * k, 79 * k)
    dragon:SetPoint("TOPLEFT", row, "TOPLEFT", 36 - 42.9 * k, -(28.5 - 41 * k))
    dragon:Hide()
    row.dragon, row.hasDragon = dragon, info and info.file and true

    local badge = CreateFrame("Frame", nil, row)
    badge:SetSize(22, 22)
    badge:SetPoint("CENTER", row, "LEFT", ns.JOURNAL_HOLE_X + 16, -15)
    badge:SetFrameLevel(row:GetFrameLevel() + 9) -- encima del dragon de los raros (+8)
    local ring = badge:CreateTexture(nil, "ARTWORK")
    ring:SetAllPoints()
    if AtlasInfo(LEVEL_RING) then
        ring:SetAtlas(LEVEL_RING)
    else
        ring:SetColorTexture(0, 0, 0, 0.9)
        ring:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge.text:SetPoint("CENTER", 0, 0)
    row.levelBadge = badge
end

local function UpdatePortraitFrame(row, boss)
    row.dragon:SetShown(boss.kind == "rare" and row.hasDragon or false)
    local level = type(boss.level) == "table" and boss.level[1] or boss.level
    row.levelBadge:SetShown(boss.kind == nil or boss.kind == "rare") -- cofres, objetos, recetas: sin nivel
    row.levelBadge.text:SetText(level and tostring(level) or "??")
end

-- ------------------------------------------
-- Lista de jefes (pagina izquierda del libro)
-- ------------------------------------------
-- Los botones de jefe del Diario, con la cara del jefe en el hueco redondo.
-- Clic: onSelect(indice); clic derecho: derrotado o no. :SetDungeon(d, elegido)
function ns.CreateBossList(parent, onSelect)
    local list = { dungeon = nil, index = nil }

    local empty = ns.PaperText(parent, "QuestFont")
    empty:SetPoint("TOP", 0, -30)
    empty:SetText(L.NO_BOSSES)

    local rows = ns.CreateScrollList(parent, 54, function(row)
        ns.SetupJournalButton(row)
        -- Imagen del Diario: donde la pone Blizzard (sale un poco por arriba)
        row.creature = row:CreateTexture(nil, "OVERLAY")
        row.creature:SetSize(128, 64)
        row.creature:SetPoint("TOPLEFT", -4, 13)
        -- Sin ella, la cara del jefe, redonda, en el centro del hueco
        row.portrait = row:CreateTexture(nil, "ARTWORK")
        ns.PlaceInHole(row.portrait, row)
        row.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
        row.label:SetPoint("TOPLEFT", 72, -11) -- fuera del borde curvo del hueco
        row.label:SetPoint("RIGHT", -12, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        ns.RowText(row.label)
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.info:SetTextColor(unpack(ns.PARCHMENT_SUB))
        ns.RowText(row.info)
        -- Jefe muerto: cruz roja sobre la cara y la placa "Derrotado" debajo
        row.cross, row.slain = ns.CreateSlainMark(row, ns.JOURNAL_HOLE_SIZE + 4)
        ns.PlaceInHole(row.cross, row, ns.JOURNAL_HOLE_SIZE + 4)
        row.slain:SetPoint("BOTTOM", row, "BOTTOMLEFT", ns.JOURNAL_HOLE_X, 1)
        DecoratePortrait(row)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                if self.kind == "recipes" then return end
                ns.ToggleBossKill(list.dungeon, ns.Bosses[list.dungeon.key][self.index])
            else
                if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
                onSelect(self.index)
            end
        end)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.label:GetText())
            if self.kind ~= "recipes" then GameTooltip:AddLine(L.BOSS_KILL_HINT, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end, function(row, item)
        local boss, d = item.boss, list.dungeon
        row.index, row.kind = item.index, boss.kind
        SetBossImage(row.creature, row.portrait, boss, d)
        UpdatePortraitFrame(row, boss)
        row.label:SetText((boss.kind == "rare" and "|cffc0c0ff" or "") .. ns.BossName(boss, d) .. "|r")
        local killed = ns.IsBossKilled(d, boss)
        row.info:SetText(ns.BossInfo(boss))
        row.creature:SetDesaturated(killed)
        row.portrait:SetDesaturated(killed)
        row.label:SetAlpha(killed and 0.6 or 1)
        row.cross:SetShown(killed)
        row.slain:SetShown(killed)
        ns.SetJournalButtonSelected(row, item.index == list.index)
    end)

    function list:SetShown(shown)
        parent:SetShown(shown)
    end

    function list:SetDungeon(d, index)
        self.dungeon, self.index = d, index
        local bosses = d and ns.Bosses[d.key] or {}
        empty:SetShown(#bosses == 0)
        local items = {}
        for i, boss in ipairs(bosses) do items[i] = { index = i, boss = boss } end
        rows:SetItems(items)
    end

    return list
end

-- ------------------------------------------
-- Botin (pestana lateral)
-- ------------------------------------------
-- Sin jefe elegido: todo el botin de la mazmorra, cada objeto con "Jefe: X"
-- debajo (clic, ese jefe); con jefe, solo el suyo y su probabilidad. Arriba un
-- desplegable por tipo de objeto (ns.LOOT_FILTERS).

-- Tipo de un objeto para el filtro: classID e INVTYPE de GetItemInfoInstant
-- (sin el objeto en cache, solo "Todo" lo muestra)
local ACCESSORY = { INVTYPE_NECK = true, INVTYPE_FINGER = true, INVTYPE_TRINKET = true }
function ns.LootCategory(itemID)
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not instant then return nil end
    local _, _, _, equipLoc, _, classID = instant(itemID)
    if classID == 2 then return "weapons" end
    if classID == 9 then return "recipes" end
    if classID == 4 then return ACCESSORY[equipLoc] and "accessories" or "armor" end
    if classID then return "other" end
end
ns.LOOT_FILTERS = { { "all", "LOOT_ALL" }, { "weapons", "LOOT_WEAPONS" }, { "armor", "LOOT_ARMOR" },
    { "accessories", "LOOT_ACCESSORIES" }, { "recipes", "RECIPES" }, { "other", "LOOT_OTHER" } }

-- Todo el botin de la mazmorra: { itemID, %, from = { jefes } }, sin repetir objetos
-- (las recetas caen de varios jefes: el primero que la suelta y "+N")
function ns.DungeonLoot(d)
    local items, seen = {}, {}
    for i, boss in ipairs(d and ns.Bosses[d.key] or {}) do
        if boss.kind ~= "recipes" then
            for _, it in ipairs(boss.loot or {}) do
                local item = seen[it[1]]
                if item then
                    item.from[#item.from + 1] = i
                else
                    item = { it[1], it[2], from = { i } }
                    seen[it[1]] = item
                    items[#items + 1] = item
                end
            end
        end
    end
    return items
end

local function FilterLoot(items, filter)
    if filter == "all" then return items end
    local out = {}
    for _, it in ipairs(items) do
        if ns.LootCategory(it[1]) == filter then out[#out + 1] = it end
    end
    return out
end

-- page: la pagina derecha entera; bar: la franja de arriba (desplegables)
function ns.CreateLootPanel(page, bar)
    local panel = { dungeon = nil, index = nil, filter = "all" }
    local frame = CreateFrame("Frame", nil, page)
    frame:SetPoint("TOPLEFT", 0, -34)
    frame:SetPoint("BOTTOMRIGHT")

    local filter = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    filter:SetWidth(150)
    filter:SetPoint("RIGHT", bar, "RIGHT", -150, 0)
    if filter.SetupMenu then
        filter:SetupMenu(function(_, root)
            for _, o in ipairs(ns.LOOT_FILTERS) do
                root:CreateRadio(L[o[2]], function() return panel.filter == o[1] end,
                    function() panel.filter = o[1]; panel:Refresh() end)
            end
        end)
    end
    panel.filterButton = filter

    local empty = ns.PaperText(frame, "QuestFont")
    empty:SetPoint("TOP", 0, -30)
    empty:SetWidth(300)
    empty:SetJustifyH("CENTER")

    -- Con jefe: recetas a la derecha con el jefe que mas la suelta ("+N" si hay
    -- mas); clic en el, su botin, y el tooltip con todos los que la sueltan
    local function SourceButton(row, anchor)
        local source = CreateFrame("Button", nil, row)
        source:SetPoint("TOPLEFT", anchor, "TOPLEFT", -3, 3)
        source:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 3, -3)
        source:SetFrameLevel(row:GetFrameLevel() + 2)
        source:SetScript("OnClick", function(self) ns.SelectBoss(self.from[1]) end)
        source:SetScript("OnEnter", function(self)
            anchor:SetTextColor(unpack(ns.INK_HEADER)) -- sobre el papel: granate, no dorado
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.TAB_BOSSES)
            local list, d = ns.Bosses[panel.dungeon.key], panel.dungeon
            for _, i in ipairs(self.from) do
                local pct = ns.LootChance(list[i], self.itemID)
                GameTooltip:AddDoubleLine(ns.BossName(list[i], d), pct and (pct .. "%") or "", 1, 1, 1, 1, 1, 1)
            end
            GameTooltip:AddLine(L.MAP_PIN_TOOLTIP, 0.6, 0.8, 1)
            GameTooltip:Show()
        end)
        source:SetScript("OnLeave", function()
            anchor:SetTextColor(unpack(anchor.color))
            GameTooltip_Hide()
        end)
        return source
    end

    local function BossLabel(from)
        local d = panel.dungeon
        local boss = from and d and ns.Bosses[d.key][from[1]]
        return boss and (ns.BossName(boss, d) .. (#from > 1 and (" +" .. (#from - 1)) or ""))
    end

    local bossArea = CreateFrame("Frame", nil, frame)
    bossArea:SetAllPoints()
    local bossLoot = ns.CreateScrollList(bossArea, ns.ITEM_ROW_HEIGHT + 2, function(row)
        ns.SetupItemButton(row)
        row.extra.color = ns.INK
        row.source = SourceButton(row, row.extra)
    end, function(row, item)
        local extra = item[2] and (item[2] .. "%")
        local from = BossLabel(item.from)
        if from then extra = from .. (extra and ("  " .. extra) or "") end
        ns.SetItemButton(row, item[1], nil, extra)
        row.source.from, row.source.itemID = item.from, item[1]
        row.source:SetShown(from ~= nil)
    end)

    -- Sin jefe: la fila de botin y "Jefe: X" debajo, sobre el papel (tinta)
    local allArea = CreateFrame("Frame", nil, frame)
    allArea:SetAllPoints()
    local allLoot = ns.CreateScrollList(allArea, ns.ITEM_ROW_HEIGHT + 16, function(row)
        local item = CreateFrame("Button", nil, row)
        item:SetPoint("TOPLEFT")
        item:SetPoint("TOPRIGHT")
        item:SetHeight(ns.ITEM_ROW_HEIGHT)
        ns.SetupItemButton(item)
        row.item = item
        -- En tinta oscura y a la altura del nombre: la franja oscura de la fila ya
        -- se ha desvanecido ahi y el gris claro no se leia sobre el papel
        row.boss = ns.PaperText(row, "GameFontBlack", ns.INK)
        row.boss:SetPoint("TOPLEFT", item, "BOTTOMLEFT", 52, -1)
        row.boss.color = ns.INK
        row.source = SourceButton(row, row.boss)
    end, function(row, item)
        ns.SetItemButton(row.item, item[1], nil, item[2] and (item[2] .. "%"))
        row.boss:SetText(L.LOOT_BOSS:format(BossLabel(item.from) or "?"))
        row.source.from, row.source.itemID = item.from, item[1]
    end)

    function panel:SetShown(shown)
        frame:SetShown(shown)
        filter:SetShown(shown)
    end

    function panel:Refresh()
        local d = self.dungeon
        local boss = d and self.index and ns.Bosses[d.key][self.index]
        local items = boss and boss.loot or ns.DungeonLoot(d)
        items = FilterLoot(items, self.filter)
        allArea:SetShown(boss == nil)
        bossArea:SetShown(boss ~= nil)
        if boss then bossLoot:SetItems(items) else allLoot:SetItems(items) end
        empty:SetShown(#items == 0)
        empty:SetText(self.filter == "all" and L.NO_BOSSES or L.LOOT_NONE)
        self.items = items
    end

    function panel:SetDungeon(d, index)
        self.dungeon, self.index = d, index
        self:Refresh()
    end

    return panel
end

-- ------------------------------------------
-- Modelo (pestana lateral)
-- ------------------------------------------
-- El modelo 3D del jefe en grande sobre el fondo de la mazmorra, con su nombre
-- abajo (la vista de modelo del Diario). Se gira arrastrando; rueda y + / -
-- acercan. Sin modelo (bichos normales, cofres), su icono.
function ns.CreateModelPanel(page)
    local panel = { dungeon = nil, index = nil }
    local frame = CreateFrame("Frame", nil, page)
    frame:SetAllPoints()
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -8, 8)
    bg:SetPoint("BOTTOMRIGHT", 8, -6)
    local model = CreateFrame("PlayerModel", nil, frame)
    model:SetPoint("TOPLEFT", 0, -4)
    model:SetPoint("BOTTOMRIGHT", 0, 36)
    -- Cuerpo entero: la camara automatica encuadra muy cerca; se aleja cuando
    -- el modelo ha cargado
    model:SetScript("OnModelLoaded", function(self)
        self:SetPortraitZoom(0)
        self:SetCamDistanceScale(self.distance or MODEL_DISTANCE)
    end)
    local function Zoom(delta)
        model.distance = math.max(0.5, math.min(4, (model.distance or MODEL_DISTANCE) - delta * 0.2))
        model:SetCamDistanceScale(model.distance)
    end
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(_, delta) Zoom(delta) end)
    for i, step in ipairs({ 1, -1 }) do
        local b = CreateFrame("Button", nil, frame)
        b:SetSize(22, 22)
        b:SetPoint("TOPRIGHT", -6 - (2 - i) * 24, -6)
        b:SetFrameLevel(model:GetFrameLevel() + 2)
        local name = step > 0 and "Plus" or "Minus"
        b:SetNormalTexture("Interface\\Buttons\\UI-" .. name .. "Button-Up")
        b:SetPushedTexture("Interface\\Buttons\\UI-" .. name .. "Button-Down")
        b:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
        b:SetScript("OnClick", function() Zoom(step) end)
    end
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        self.facing = (self.facing or 0) + (x - self.dragX) / 80
        self.dragX = x
        self:SetFacing(self.facing)
    end)
    -- Ver al jefe en el mapa de la mazmorra (si tiene chincheta)
    local onMap = CreateFrame("Button", nil, frame)
    onMap:SetSize(30, 30)
    onMap:SetPoint("TOPLEFT", 6, -6)
    onMap:SetFrameLevel(model:GetFrameLevel() + 2)
    local mapIcon = onMap:CreateTexture(nil, "ARTWORK")
    mapIcon:SetAllPoints()
    mapIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    mapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    onMap:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    onMap:SetScript("OnClick", function() ns.ShowDungeonMap(panel.dungeon, panel.index) end)
    ns.AddTooltip(onMap, L.VIEW_ON_MAP)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(72, 72)
    icon:SetPoint("CENTER", 0, 20)
    local shadow = frame:CreateTexture(nil, "OVERLAY")
    shadow:SetPoint("BOTTOMLEFT", -8, -6)
    shadow:SetPoint("BOTTOMRIGHT", 8, -6)
    shadow:SetHeight(76)
    ns.SetEJTexture(shadow, "BossNameShadow")
    local title = frame:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    ns.SetTitleFont(title, 22)
    title:SetTextColor(1, 0.82, 0)
    title:SetPoint("BOTTOM", 0, 26) -- separado del borde de abajo
    title:SetPoint("LEFT", 8, 0)
    title:SetPoint("RIGHT", -8, 0)
    panel.title = title

    function panel:SetShown(shown)
        frame:SetShown(shown)
        if not shown then model.boss = nil end -- al volver, el modelo otra vez desde cero
    end

    function panel:SetDungeon(d, index)
        self.dungeon, self.index = d, index
        local boss = d and index and ns.Bosses[d.key][index]
        ns.SetDungeonArt(bg, d, "bg")
        if not boss then
            model:Hide(); icon:Hide(); onMap:Hide()
            title:SetText("")
            return
        end
        model:SetShown(boss.display ~= nil)
        icon:SetShown(boss.display == nil)
        -- Solo al cambiar de jefe: cada refresco (datos de objetos, misiones)
        -- reiniciaba el modelo y su animacion en bucle
        if boss.display and model.boss ~= boss then
            model.boss = boss
            model:ClearModel()
            model:SetDisplayInfo(boss.display)
            model:SetPortraitZoom(0)
            model.distance = MODEL_DISTANCE
            model:SetCamDistanceScale(MODEL_DISTANCE)
            model.facing = 0.35
            model:SetFacing(model.facing)
        elseif not boss.display then
            model.boss = nil
            ns.SetBossPortrait(icon, boss)
        end
        onMap:SetShown(ns.BossFloor(d, index) ~= nil)
        title:SetText(ns.BossName(boss, d))
    end

    return panel
end
