local _, ns = ...
local L = ns.L
local unpack = unpack or table.unpack

-- ==========================================
-- RESUMEN DE LA MAZMORRA
-- ==========================================
-- Pagina izquierda (la cabecera ya dice nivel, misiones y jefes muertos):
--   "Donde": tipo de mazmorra y entrada, y los botones de la entrada, el mapa,
--   la ruta y AtlasLoot, de dos en dos;
--   "Jefes 2/8": lista a dos columnas con la cara y el nombre de cada jefe
--   (gris y con la X si ha muerto); clic, su botin.
-- Pagina derecha: la ilustracion y la historia de la mazmorra, del Diario del
-- juego (Core/Journal.lua), como la pagina de mazmorra del propio Diario.

local ICON = "|T%s:18:18|t  "
local PORTAL = "Interface\\Icons\\Spell_Arcane_PortalIronForge"
local BIG = 15        -- letra de los datos y de la historia
local BUTTON_H = 30
local BOSS_ROW = 34   -- fila de la lista de jefes (dos jefes por fila)

-- La fuente del juego, mas grande
local function Bigger(fs, size)
    local font, _, flags = fs:GetFont()
    if font then fs:SetFont(font, size, flags) end
end

local function ActionButton(parent, text, icon, onClick, tooltip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetHeight(BUTTON_H)
    b:SetText(text)
    b:SetNormalFontObject("GameFontNormalSmall") -- "Marcar entrada en el mapa" cabe en media pagina
    b:SetHighlightFontObject("GameFontHighlightSmall")
    b:SetDisabledFontObject("GameFontDisableSmall")
    ns.SetButtonIcon(b, icon)
    if b.SetMotionScriptsWhileDisabled then b:SetMotionScriptsWhileDisabled(true) end -- el tooltip dice por que
    b:SetScript("OnClick", onClick)
    ns.AddTooltip(b, tooltip)
    return b
end

-- Un jefe de la lista: cara redonda y nombre; muerto, en gris con la X roja
local function CreateBossEntry(parent)
    local e = CreateFrame("Button", nil, parent)
    e:SetHeight(BOSS_ROW - 4)
    local hl = e:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.12)
    e.portrait = e:CreateTexture(nil, "ARTWORK")
    e.portrait:SetSize(BOSS_ROW - 6, BOSS_ROW - 6)
    e.portrait:SetPoint("LEFT", 2, 0)
    e.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    local ring = e:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("TOPLEFT", e.portrait, -7, 6)
    ring:SetPoint("BOTTOMRIGHT", e.portrait, 7, -6)
    ns.SetEJTexture(ring, "BossModelButton")
    e.cross = ns.CreateSlainMark(e, BOSS_ROW - 8)
    e.cross:SetPoint("CENTER", e.portrait)
    e.name = ns.PaperText(e, "GameFontNormal")
    e.name:SetPoint("LEFT", e.portrait, "RIGHT", 8, 0)
    e.name:SetPoint("RIGHT", -2, 0)
    e.name:SetWordWrap(false)
    e:SetScript("OnClick", function(self) ns.ShowBoss(self.dungeon, self.index) end)
    ns.AddTooltip(e, function()
        return ns.BossName(e.boss, e.dungeon) .. "\n|cffffffff" .. L.MAP_PIN_TOOLTIP .. "|r"
    end)
    return e
end

local function UpdateBossEntry(e, d, index, boss)
    e.dungeon, e.index, e.boss = d, index, boss
    ns.SetBossPortrait(e.portrait, boss)
    local dead = ns.IsBossKilled(d, boss)
    e.portrait:SetDesaturated(dead)
    e.cross:SetShown(dead)
    e.name:SetText(ns.BossName(boss, d))
    e.name:SetTextColor(unpack(dead and ns.INK_LIGHT or ns.INK))
end

function ns.CreateOverviewPanel(left, right)
    local panel = { dungeon = nil }

    -- Donde: tipo y entrada, y los botones de dos en dos -----------------------
    local whereHeader = ns.CreatePaperHeader(left, L.WHERE)
    whereHeader:SetPoint("TOPLEFT", 0, -2)
    whereHeader:SetPoint("RIGHT", -4, 0)
    local facts = ns.PaperText(left, "QuestFont")
    Bigger(facts, BIG)
    facts:SetPoint("TOPLEFT", whereHeader, "BOTTOMLEFT", 2, -8)
    facts:SetPoint("RIGHT", -4, 0)
    facts:SetSpacing(6)

    local entrance = ActionButton(left, L.MARK_ENTRANCE, "Interface\\Icons\\Spell_Arcane_TeleportIronForge", function()
        local point = ns.Entrance(panel.dungeon)
        if ns.SetWaypoint(point, ns.DungeonName(panel.dungeon), "entrance") then ns.OpenMapAt(point.mapID) end
    end, function()
        local d = panel.dungeon
        local point = d and ns.Entrance(d)
        if not point then return L.NO_ENTRANCE:format(d and d.key or "") end
        return L.MARK_ENTRANCE_TOOLTIP .. "\n|cffffffff" .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) .. "|r"
    end)
    local map = ActionButton(left, L.VIEW_MAP, "Interface\\Icons\\INV_Misc_Map_01",
        function() ns.ShowDungeonMap(panel.dungeon) end,
        function() return ns.DungeonMaps(panel.dungeon) and L.VIEW_MAP_TOOLTIP or L.NO_MAP end)
    -- Ruta hasta la entrada, parada a parada (grabada con /dqa route)
    local route = ActionButton(left, L.ROUTE, "Interface\\Icons\\INV_Misc_Spyglass_03",
        function() ns.StartRoute(panel.dungeon) end,
        function()
            local d = panel.dungeon
            return d and ns.Route(d) and L.ROUTE_TOOLTIP or L.ROUTE_NONE:format(d and d.key or "")
        end)
    local loot = ActionButton(left, L.VIEW_LOOT, "Interface\\Icons\\INV_Box_01",
        function() ns.OpenAtlasLoot(panel.dungeon) end, L.VIEW_LOOT_TOOLTIP)
    local buttons = { entrance, map, route, loot }
    -- Dos columnas de media pagina (anchos calculados: mezclar TOPLEFT con un
    -- RIGHT al centro descuadra el alto del boton). Devuelve las filas.
    local function PlaceButtons()
        local half = (ns.Width(left, 360) - 10) / 2
        local n = 0
        for _, b in ipairs(buttons) do
            if b:IsShown() then
                local col, row = n % 2, math.floor(n / 2)
                b:ClearAllPoints()
                b:SetWidth(half)
                b:SetPoint("TOPLEFT", facts, "BOTTOMLEFT", -2 + col * (half + 6), -10 - row * (BUTTON_H + 6))
                n = n + 1
            end
        end
        return math.ceil(n / 2)
    end

    -- Jefes: lista a dos columnas ------------------------------------------------
    local bossHeader = ns.CreatePaperHeader(left, L.TAB_BOSSES)
    local bossArea = CreateFrame("Frame", nil, left)
    bossArea:SetPoint("TOPLEFT", bossHeader, "BOTTOMLEFT", 0, -4)
    bossArea:SetPoint("BOTTOMRIGHT")
    local bossList = ns.CreateScrollList(bossArea, BOSS_ROW, function(row)
        row.entries = { CreateBossEntry(row), CreateBossEntry(row) }
    end, function(row, item)
        local half = (ns.Width(row, 330) - 8) / 2
        for i, e in ipairs(row.entries) do
            e:ClearAllPoints()
            e:SetWidth(half)
            e:SetPoint("TOPLEFT", (i - 1) * (half + 8), -2)
            e:SetShown(item[i] ~= nil)
            if item[i] then UpdateBossEntry(e, panel.dungeon, item[i].index, item[i].boss) end
        end
    end)

    -- Ilustracion e historia (pagina derecha) ---------------------------------
    local art = right:CreateTexture(nil, "BACKGROUND")
    art:SetPoint("TOPLEFT", -6, 4)
    art:SetPoint("TOPRIGHT", 6, 4)
    art:SetHeight(250)
    local nameBg = right:CreateTexture(nil, "ARTWORK")
    nameBg:SetSize(256, 64)
    nameBg:SetPoint("TOP", art, "TOP", 0, -24)
    ns.SetEJTexture(nameBg, "DungeonNameBg")
    local title = right:CreateFontString(nil, "OVERLAY", "QuestFont_Super_Huge")
    title:SetPoint("CENTER", nameBg, "CENTER", 0, 4)
    title:SetWidth(320)
    title:SetWordWrap(false)

    local scroll = ns.CreateScrollFrame(right)
    scroll:SetPoint("TOPLEFT", art, "BOTTOMLEFT", 6, -10)
    scroll:SetPoint("BOTTOMRIGHT", -18, 0)
    -- El hijo del scroll tiene que ser un Frame: el texto va dentro
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    local lore = ns.PaperText(content, "QuestFont")
    Bigger(lore, BIG)
    lore:SetPoint("TOPLEFT")
    lore:SetSpacing(3)
    local function Fit()
        local width = math.max(100, scroll:GetWidth())
        content:SetWidth(width)
        lore:SetWidth(width)
        content:SetHeight(lore:GetStringHeight() + 8)
    end
    scroll:SetScript("OnSizeChanged", Fit)

    function panel:SetShown(shown)
        left:SetShown(shown)
        right:SetShown(shown)
    end

    function panel:SetDungeon(d)
        local changed = d ~= self.dungeon
        self.dungeon = d
        if not d then return end
        local journal = ns.Journal(d)
        local point = ns.Entrance(d)
        local lines = {
            ICON:format(d.isForever and ns.LOGO or "Interface\\Icons\\INV_Misc_Book_09")
                .. (d.isForever and L.KIND_FOREVER or L.KIND_CLASSIC),
        }
        if point then lines[#lines + 1] = ICON:format(PORTAL) .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) end
        facts:SetText(table.concat(lines, "\n"))
        entrance:SetEnabled(point ~= nil)
        map:SetEnabled(ns.DungeonMaps(d) ~= nil)
        route:SetEnabled(ns.Route(d) ~= nil)
        loot:SetShown(ns.AtlasLootAvailable())
        local buttonRows = PlaceButtons()

        -- "Jefes 2/8" y la lista (sin los bichos normales), dos por fila
        bossHeader:ClearAllPoints()
        bossHeader:SetPoint("TOPLEFT", facts, "BOTTOMLEFT", -2, -10 - buttonRows * (BUTTON_H + 6) - 8)
        bossHeader:SetWidth(ns.Width(left, 360) - 4)
        local killed, total = ns.BossKillProgress(d)
        bossHeader.text:SetText(L.TAB_BOSSES .. "  " .. killed .. "/" .. total)
        local rows, n = {}, 0
        for i, boss in ipairs(ns.Bosses[d.key] or {}) do
            if boss.kind ~= "trash" and boss.kind ~= "recipes" then
                n = n + 1
                local r = math.floor((n - 1) / 2) + 1
                rows[r] = rows[r] or {}
                rows[r][#rows[r] + 1] = { index = i, boss = boss }
            end
        end
        bossList:SetItems(rows)
        bossHeader:SetShown(n > 0)
        bossArea:SetShown(n > 0)

        ns.SetDungeonArt(art, d, "lore")
        title:SetText(ns.DungeonName(d))
        lore:SetText(journal.description or L.NO_LORE)
        Fit()
        -- Se refresca con cada QUEST_LOG_UPDATE: arriba solo al cambiar de mazmorra
        if changed then scroll:SetVerticalScroll(0) end
    end

    return panel
end
