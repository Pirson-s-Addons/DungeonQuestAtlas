local _, ns = ...
local L = ns.L

-- ==========================================
-- JEFES Y BOTIN (en el libro)
-- ==========================================
-- Pagina izquierda: botones de jefe del Diario, con la cara del jefe en el
-- hueco redondo del boton. Pagina derecha: el modelo 3D del jefe sobre el
-- fondo de la mazmorra (como la vista de modelo del Diario) y debajo su
-- botin. Nombre e historia salen del Diario del juego si lo conoce
-- (Core/Journal.lua); si no, el nombre de Data/Bosses.lua.

local unpack = unpack or table.unpack
local RARE = "|cff4a4a8c"
local ICON = {
    trash = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    object = "Interface\\Icons\\INV_Box_01",
    unknown = "Interface\\Icons\\INV_Misc_QuestionMark",
}
local SEP = "  ·  "

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
    local journal = d and ns.JournalBoss(d, boss)
    if journal then return journal.name end
    return boss.npcID and ns.PlaceName(boss) or boss.name
end

-- "Nivel 19 · Raro · 3 objetos"
function ns.BossInfo(boss)
    local info = {}
    local level = type(boss.level) == "table" and table.concat(boss.level, "-") or boss.level
    if level then info[#info + 1] = L.LEVEL .. " " .. level end
    if boss.kind == "rare" then info[#info + 1] = L.RARE end
    info[#info + 1] = L.ITEMS:format(#boss.loot)
    return table.concat(info, SEP)
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
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.info:SetTextColor(0.75, 0.7, 0.6)
        row:SetScript("OnClick", function(self) panel:SelectBoss(self.index) end)
    end, function(row, item)
        local boss, d = item.boss, panel.dungeon
        row.index = item.index
        SetBossImage(row.creature, row.portrait, boss, d)
        row.label:SetText((boss.kind == "rare" and "|cffc0c0ff" or "") .. ns.BossName(boss, d) .. "|r")
        row.info:SetText(ns.BossInfo(boss))
        ns.SetJournalButtonSelected(row, item.index == panel.index)
    end)

    -- Jefe elegido (pagina derecha) -------------------------------------------
    local header = CreateFrame("Frame", nil, right)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(196)
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
        self:SetCamDistanceScale(1.35)
    end)
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
    local loot = ns.CreateScrollList(lootArea, ns.ITEM_ROW_HEIGHT + 2, ns.SetupItemButton,
        function(row, item) ns.SetItemButton(row, item[1], nil, item[2] and (item[2] .. "%")) end)

    function panel:SetShown(shown)
        left:SetShown(shown)
        right:SetShown(shown)
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
        if boss.display then
            model:ClearModel()
            model:SetDisplayInfo(boss.display)
            model:SetPortraitZoom(0)
            model:SetCamDistanceScale(1.35)
            model.facing = 0.35
            model:SetFacing(model.facing)
        else
            ns.SetBossPortrait(icon, boss)
        end
        title:SetText(ns.BossName(boss, d))
        info:SetText((boss.kind == "rare" and RARE or "") .. ns.BossInfo(boss) .. "|r")
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
