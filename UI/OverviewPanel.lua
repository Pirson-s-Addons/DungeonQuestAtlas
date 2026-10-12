local _, ns = ...
local L = ns.L
local unpack = unpack or table.unpack

-- ==========================================
-- RESUMEN (pestana lateral del libro)
-- ==========================================
-- Pagina derecha, como el resumen del Diario de mazmorras:
--   sin jefe elegido: la ilustracion de la mazmorra con su nombre encima y, abajo
--   sobre ella, los botones Ver mapa, Entrada, Ruta y AtlasLoot (icono y texto
--   claro sobre la franja oscura del arte); debajo, tipo y entrada, y la
--   historia del Diario del juego (Core/Journal.lua) con scroll;
--   con un jefe: su cara, nombre, nivel, raro, derrotado, "Ver en el mapa" y su
--   historia del Diario.

local PORTAL = "Interface\\Icons\\Spell_Arcane_PortalIronForge"
local BIG = 15 -- letra de la historia
local ART_H = 200

-- La fuente del juego, mas grande
local function Bigger(fs, size)
    local font, _, flags = fs:GetFont()
    if font then fs:SetFont(font, size, flags) end
end

-- Boton sobre la ilustracion, como "Mostrar mapa" del Diario: icono con marco y
-- el texto claro a su derecha (dos lineas como mucho); gris si esta apagado
local function ArtButton(parent, text, icon, onClick, tooltip)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(84, 34)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(30, 30)
    b.icon:SetPoint("LEFT")
    b.icon:SetTexture(icon)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Common\\WhiteIconFrame")
    border:SetAllPoints(b.icon)
    border:SetVertexColor(0.75, 0.6, 0.35)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 4, 0)
    b.text:SetPoint("RIGHT")
    b.text:SetJustifyH("LEFT")
    b.text:SetMaxLines(2)
    b.text:SetText(text)
    b.text:SetShadowOffset(1, -1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b.icon)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    b:HookScript("OnEnable", function() b.icon:SetDesaturated(false); b.text:SetTextColor(1, 1, 1) end)
    b:HookScript("OnDisable", function() b.icon:SetDesaturated(true); b.text:SetTextColor(0.6, 0.6, 0.6) end)
    if b.SetMotionScriptsWhileDisabled then b:SetMotionScriptsWhileDisabled(true) end -- el tooltip dice por que
    b:SetScript("OnClick", onClick)
    ns.AddTooltip(b, tooltip)
    return b
end

-- Historia con scroll bajo anchor (el hijo del scroll tiene que ser un Frame)
local function LoreScroll(parent, anchor, gap)
    local scroll = ns.CreateScrollFrame(parent)
    scroll:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    scroll:SetPoint("BOTTOMRIGHT", -18, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    local text = ns.PaperText(content, "QuestFont")
    Bigger(text, BIG)
    text:SetPoint("TOPLEFT")
    text:SetSpacing(3)
    function scroll:Fit()
        local width = math.max(100, self:GetWidth())
        content:SetWidth(width)
        text:SetWidth(width)
        content:SetHeight(text:GetStringHeight() + 8)
    end
    scroll:SetScript("OnSizeChanged", scroll.Fit)
    scroll.text = text
    return scroll
end

-- page: la pagina derecha (bajo la franja de los desplegables)
function ns.CreateOverviewPanel(page)
    local panel = { dungeon = nil, index = nil }

    -- Mazmorra -----------------------------------------------------------------
    local dungeonView = CreateFrame("Frame", nil, page)
    dungeonView:SetAllPoints()
    local art = dungeonView:CreateTexture(nil, "BACKGROUND")
    art:SetPoint("TOPLEFT", -6, 0)
    art:SetPoint("TOPRIGHT", 6, 0)
    art:SetHeight(ART_H)
    -- Oscura abajo: los botones se leen sobre cualquier ilustracion
    local shade = dungeonView:CreateTexture(nil, "BORDER")
    shade:SetPoint("BOTTOMLEFT", art)
    shade:SetPoint("BOTTOMRIGHT", art)
    shade:SetHeight(64)
    if CreateColor and shade.SetGradient then
        shade:SetColorTexture(1, 1, 1, 1)
        shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0))
    else
        shade:SetColorTexture(0, 0, 0, 0.5)
    end
    local nameBg = dungeonView:CreateTexture(nil, "ARTWORK")
    nameBg:SetSize(256, 64)
    nameBg:SetPoint("TOP", art, "TOP", 0, -14)
    ns.SetEJTexture(nameBg, "DungeonNameBg")
    local title = dungeonView:CreateFontString(nil, "OVERLAY", "QuestFont_Super_Huge")
    ns.SetTitleFont(title, 24)
    title:SetTextColor(1, 0.82, 0)
    title:SetPoint("CENTER", nameBg, "CENTER", 0, 4)
    title:SetWidth(330)
    title:SetMaxLines(2)

    local map = ArtButton(dungeonView, L.VIEW_MAP, "Interface\\Icons\\INV_Misc_Map_01",
        function() ns.ShowDungeonMap(panel.dungeon) end,
        function() return ns.DungeonMaps(panel.dungeon) and L.VIEW_MAP_TOOLTIP or L.NO_MAP end)
    local entrance = ArtButton(dungeonView, L.MAP_ENTRANCE, "Interface\\Icons\\Spell_Arcane_TeleportIronForge", function()
        local point = ns.Entrance(panel.dungeon)
        if ns.SetWaypoint(point, ns.DungeonName(panel.dungeon), "entrance") then ns.OpenMapAt(point.mapID) end
    end, function()
        local d = panel.dungeon
        local point = d and ns.Entrance(d)
        if not point then return L.NO_ENTRANCE:format(d and d.key or "") end
        return L.MARK_ENTRANCE_TOOLTIP .. "\n|cffffffff" .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) .. "|r"
    end)
    -- Ruta hasta la entrada, parada a parada (grabada con /dqa route)
    local route = ArtButton(dungeonView, L.ROUTE, "Interface\\Icons\\INV_Misc_Spyglass_03",
        function() ns.StartRoute(panel.dungeon) end,
        function()
            local d = panel.dungeon
            return d and ns.Route(d) and L.ROUTE_TOOLTIP or L.ROUTE_NONE:format(d and d.key or "")
        end)
    local loot = ArtButton(dungeonView, "AtlasLoot", "Interface\\Icons\\INV_Box_01",
        function() ns.OpenAtlasLoot(panel.dungeon) end, L.VIEW_LOOT_TOOLTIP)
    local buttons = { map, entrance, route, loot }
    panel.buttons = { map = map, entrance = entrance, route = route, loot = loot }

    local facts = ns.PaperText(dungeonView, "GameFontBlack")
    facts:SetPoint("TOPLEFT", art, "BOTTOMLEFT", 8, -8)
    facts:SetPoint("RIGHT", -4, 0)
    facts:SetWordWrap(false)
    local lore = LoreScroll(dungeonView, facts, 6)
    lore:SetPoint("TOPLEFT", facts, "BOTTOMLEFT", -2, -6)

    -- Jefe ---------------------------------------------------------------------
    local bossView = CreateFrame("Frame", nil, page)
    bossView:SetAllPoints()
    local ringButton = CreateFrame("Frame", nil, bossView)
    ringButton:SetSize(64, 61)
    ringButton:SetPoint("TOPLEFT", -4, 2)
    local portrait = ringButton:CreateTexture(nil, "BACKGROUND")
    portrait:SetSize(40, 40)
    portrait:SetPoint("CENTER")
    portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    local ring = ringButton:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ns.SetEJTexture(ring, "BossModelButton")
    local cross = ns.CreateSlainMark(ringButton, 44)
    cross:SetPoint("CENTER")
    local bossName = ns.PaperText(bossView, "GameFontNormal")
    ns.SetPaperTitleFont(bossName, 18)
    bossName:SetPoint("TOPLEFT", ringButton, "TOPRIGHT", 2, -12)
    bossName:SetPoint("RIGHT", -4, 0)
    bossName:SetWordWrap(false)
    local bossInfo = ns.PaperText(bossView, "GameFontBlack")
    bossInfo:SetPoint("TOPLEFT", bossName, "BOTTOMLEFT", 0, -4)
    bossInfo:SetPoint("RIGHT", -4, 0)
    local onMap = CreateFrame("Button", nil, bossView, "UIPanelButtonTemplate")
    onMap:SetSize(150, 24)
    onMap:SetText(L.VIEW_ON_MAP)
    onMap:SetNormalFontObject("GameFontNormalSmall")
    onMap:SetHighlightFontObject("GameFontHighlightSmall")
    ns.SetButtonIcon(onMap, "Interface\\Icons\\INV_Misc_Map_01")
    onMap:SetPoint("TOPLEFT", ringButton, "BOTTOMLEFT", 6, -6)
    onMap:SetScript("OnClick", function() ns.ShowDungeonMap(panel.dungeon, panel.index) end)
    local lootButton = CreateFrame("Button", nil, bossView, "UIPanelButtonTemplate")
    lootButton:SetSize(150, 24)
    lootButton:SetText(L.LOOT)
    lootButton:SetNormalFontObject("GameFontNormalSmall")
    lootButton:SetHighlightFontObject("GameFontHighlightSmall")
    ns.SetButtonIcon(lootButton, "Interface\\Icons\\INV_Box_02")
    lootButton:SetPoint("LEFT", onMap, "RIGHT", 8, 0)
    lootButton:SetScript("OnClick", function() ns.ShowBoss(panel.dungeon, panel.index, "loot") end)
    local header = ns.CreatePaperHeader(bossView, L.LORE)
    header:SetPoint("TOPLEFT", onMap, "BOTTOMLEFT", -6, -8)
    header:SetPoint("RIGHT", -4, 0)
    local bossLore = LoreScroll(bossView, header, 6)
    panel.bossName, panel.onMap = bossName, onMap

    function panel:SetShown(shown)
        dungeonView:SetShown(shown and not self.index)
        bossView:SetShown(shown and self.index ~= nil)
        self.shown = shown
    end

    local function ShowDungeon(d, changed)
        local journal = ns.Journal(d)
        local point = ns.Entrance(d)
        local parts = { "|T" .. (d.isForever and ns.LOGO or "Interface\\Icons\\INV_Misc_Book_09") .. ":14:14|t "
            .. (d.isForever and L.KIND_FOREVER or L.KIND_CLASSIC) }
        if point then parts[2] = "|T" .. PORTAL .. ":14:14|t " .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) end
        facts:SetText(table.concat(parts, "    "))
        map:SetEnabled(ns.DungeonMaps(d) ~= nil)
        entrance:SetEnabled(point ~= nil)
        route:SetEnabled(ns.Route(d) ~= nil)
        loot:SetShown(ns.AtlasLootAvailable())
        local x = 6
        for _, b in ipairs(buttons) do
            if b:IsShown() then
                b:ClearAllPoints()
                b:SetPoint("BOTTOMLEFT", art, "BOTTOMLEFT", x + 6, 8)
                x = x + 88
            end
        end
        ns.SetDungeonArt(art, d, "lore")
        title:SetText(ns.DungeonName(d))
        lore.text:SetText(journal.description or L.NO_LORE)
        lore:Fit()
        -- Se refresca con cada QUEST_LOG_UPDATE: arriba solo al cambiar de mazmorra
        if changed then lore:SetVerticalScroll(0) end
    end

    local function ShowBossInfo(d, boss, changed)
        ns.SetBossPortrait(portrait, boss)
        local dead = ns.IsBossKilled(d, boss)
        portrait:SetDesaturated(dead)
        cross:SetShown(dead)
        bossName:SetText(ns.BossName(boss, d))
        bossInfo:SetText((dead and ("|cffa01010" .. L.BOSS_KILLED .. "|r  ·  ") or "") .. ns.BossInfo(boss, ns.RARE_PREFIX))
        onMap:SetEnabled(ns.BossFloor(d, panel.index) ~= nil)
        local journal = ns.JournalBoss(d, boss)
        bossLore.text:SetText(journal and journal.description or L.NO_BOSS_LORE)
        bossLore:Fit()
        if changed then bossLore:SetVerticalScroll(0) end
    end

    function panel:SetDungeon(d, index)
        local changed = d ~= self.dungeon or index ~= self.index
        self.dungeon, self.index = d, index
        if not d then return end
        local boss = index and ns.Bosses[d.key][index]
        if not boss then self.index = nil end
        self:SetShown(self.shown ~= false)
        if boss then ShowBossInfo(d, boss, changed) else ShowDungeon(d, changed) end
    end

    return panel
end
