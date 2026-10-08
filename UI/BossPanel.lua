local _, ns = ...
local L = ns.L

-- ==========================================
-- JEFES Y BOTIN
-- ==========================================
-- Pagina izquierda: botones de jefe del Diario, con la cara del jefe en el
-- hueco redondo del boton. Pagina derecha: el modelo 3D del jefe sobre el
-- fondo de la mazmorra (como la vista de modelo del Diario) y debajo su
-- botin. Nombre e historia salen del Diario del juego si lo conoce
-- (Core/Journal.lua); si no, el nombre de Data/Bosses.lua.

local unpack = unpack or table.unpack
-- Delante de "Raro" sobre el papel: el dragon plateado de los raros del juego (el
-- texto, en tinta: ningun color claro se lee sobre el pergamino)
local RARE = "|A:nameplates-icon-elite-silver:14:14|a "
local ICON = {
    trash = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    object = "Interface\\Icons\\INV_Box_01",
    recipes = "Interface\\Icons\\INV_Scroll_05",
    unknown = "Interface\\Icons\\INV_Misc_QuestionMark",
}
local SEP = "  ·  "
-- Distancia de la camara del modelo 3D: el cuerpo entero en el recuadro de 136 de alto
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

function ns.CreateBossPanel(left, right)
    local panel = { dungeon = nil, index = 1 }

    local empty = ns.PaperText(left, "QuestFont")
    empty:SetPoint("TOP", 0, -30)
    empty:SetText(L.NO_BOSSES)

    -- Jefes (pagina izquierda) ------------------------------------------------
    local bosses = ns.CreateScrollList(left, 54, function(row)
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
        row.label:SetTextColor(unpack(ns.PARCHMENT_GOLD))
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
                ns.ToggleBossKill(panel.dungeon, ns.Bosses[panel.dungeon.key][self.index])
            else
                panel:SelectBoss(self.index)
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
        local boss, d = item.boss, panel.dungeon
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
        ns.SetJournalButtonSelected(row, item.index == panel.index)
    end)

    -- Jefe elegido (pagina derecha) -------------------------------------------
    local header = CreateFrame("Frame", nil, right)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(136) -- bajo, para que se vea mas botin
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    -- Modelo 3D del jefe; se gira arrastrando con el raton
    local model = CreateFrame("PlayerModel", nil, header)
    model:SetPoint("TOPLEFT", 0, -2)
    model:SetPoint("BOTTOMRIGHT", 0, 26)
    -- Cuerpo entero: la camara automatica encuadra muy cerca en una franja
    -- ancha; se aleja cuando el modelo ha cargado
    model:SetScript("OnModelLoaded", function(self)
        self:SetPortraitZoom(0)
        self:SetCamDistanceScale(self.distance or MODEL_DISTANCE)
    end)
    -- Zoom: rueda del raton y botones + / - (mas cerca = menos distancia)
    local function Zoom(delta)
        model.distance = math.max(0.5, math.min(4, (model.distance or MODEL_DISTANCE) - delta * 0.2))
        model:SetCamDistanceScale(model.distance)
    end
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(_, delta) Zoom(delta) end)
    for i, step in ipairs({ 1, -1 }) do
        local b = CreateFrame("Button", nil, model)
        b:SetSize(20, 20)
        b:SetPoint("TOPRIGHT", -6 - (2 - i) * 22, -6)
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
    local onMap = CreateFrame("Button", nil, header)
    onMap:SetSize(26, 26)
    onMap:SetPoint("BOTTOMRIGHT", -6, 6)
    onMap:SetFrameLevel(model:GetFrameLevel() + 2)
    local mapIcon = onMap:CreateTexture(nil, "ARTWORK")
    mapIcon:SetAllPoints()
    mapIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    mapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    onMap:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    onMap:SetScript("OnClick", function() ns.ShowDungeonMap(panel.dungeon, panel.index) end)
    ns.AddTooltip(onMap, L.VIEW_ON_MAP)
    -- Sin modelo (bichos normales, cofres): su icono
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(56, 56)
    icon:SetPoint("CENTER", 0, 12)
    local shadow = header:CreateTexture(nil, "OVERLAY")
    shadow:SetPoint("BOTTOMLEFT", 0, -2)
    shadow:SetPoint("BOTTOMRIGHT", 0, -2)
    shadow:SetHeight(40)
    ns.SetEJTexture(shadow, "BossNameShadow")
    local title = header:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    title:SetPoint("BOTTOM", 0, 8)
    title:SetPoint("LEFT", 8, 0)
    title:SetPoint("RIGHT", -8, 0)

    local info = ns.PaperText(right, "GameFontBlack")
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
    local lore = ns.PaperText(right, "GameFontBlack", ns.INK_LIGHT)
    lore:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -4)
    lore:SetPoint("RIGHT", right, "RIGHT", 0, 0)
    lore:SetMaxLines(3)

    local section = ns.CreatePaperHeader(right, L.LOOT)
    section:SetPoint("TOPLEFT", lore, "BOTTOMLEFT", 0, -6)
    section:SetPoint("RIGHT")

    local lootArea = CreateFrame("Frame", nil, right)
    lootArea:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, -6)
    lootArea:SetPoint("BOTTOMRIGHT")
    -- Recetas: a la derecha, el jefe que mas la suelta y su probabilidad ("+N" si hay
    -- mas); clic en el, su botin, y el tooltip con todos los que la sueltan
    local function SetupLootRow(row)
        ns.SetupItemButton(row)
        local source = CreateFrame("Button", nil, row)
        source:SetPoint("TOPLEFT", row.extra, "TOPLEFT", -3, 3)
        source:SetPoint("BOTTOMRIGHT", row.extra, "BOTTOMRIGHT", 3, -3)
        source:SetFrameLevel(row:GetFrameLevel() + 2)
        source:SetScript("OnClick", function(self) panel:SelectBoss(self.from[1]) end)
        source:SetScript("OnEnter", function(self)
            row.extra:SetTextColor(1, 0.82, 0)
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
            row.extra:SetTextColor(unpack(ns.TEXT_ON_DARK))
            GameTooltip_Hide()
        end)
        row.source = source
    end
    local loot = ns.CreateScrollList(lootArea, ns.ITEM_ROW_HEIGHT + 2, SetupLootRow,
        function(row, item)
            local extra = item[2] and (item[2] .. "%")
            local from = item.from and panel.dungeon and ns.Bosses[panel.dungeon.key][item.from[1]]
            if from then
                extra = ns.BossName(from, panel.dungeon) .. (#item.from > 1 and (" +" .. (#item.from - 1)) or "")
                    .. (extra and ("  " .. extra) or "")
            end
            ns.SetItemButton(row, item[1], nil, extra)
            row.source.from, row.source.itemID = item.from, item[1]
            row.source:SetShown(from ~= nil)
        end)

    function panel:SetShown(shown)
        left:SetShown(shown)
        right:SetShown(shown)
        if not shown then model.boss = nil end -- al volver, el modelo otra vez desde cero
    end

    function panel:Refresh()
        local d = self.dungeon
        local list = d and ns.Bosses[d.key] or {}
        empty:SetShown(#list == 0)
        right:SetAlpha(#list > 0 and 1 or 0)
        local items = {}
        for i, boss in ipairs(list) do items[i] = { index = i, boss = boss } end
        bosses:SetItems(items)
        local boss = list[self.index]
        if not boss then return end
        ns.SetDungeonArt(bg, d, "bg")
        model:SetShown(boss.display ~= nil)
        icon:SetShown(boss.display == nil)
        -- Solo al cambiar de jefe: cada refresco (datos de objetos al pasar el raton,
        -- misiones) reiniciaba el modelo y su animacion en bucle
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
        onMap:SetShown(ns.BossFloor(d, self.index) ~= nil)
        title:SetText(ns.BossName(boss, d))
        info:SetText((ns.IsBossKilled(d, boss) and ("|cffa01010" .. L.BOSS_KILLED .. "|r" .. SEP) or "")
            .. ns.BossInfo(boss, RARE))
        local journal = ns.JournalBoss(d, boss)
        lore:SetText(journal and journal.description or "")
        loot:SetItems(boss.loot)
    end

    function panel:SetDungeon(d)
        if d ~= self.dungeon then self.index = 1 end
        self.dungeon = d
        self:Refresh()
    end

    function panel:SelectBoss(index)
        self.index = index
        self:Refresh()
    end

    return panel
end
