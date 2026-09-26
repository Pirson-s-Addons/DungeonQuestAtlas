local _, ns = ...
local L = ns.L

-- ==========================================
-- MAZMORRA (en el libro)
-- ==========================================
-- Pagina izquierda: nivel, tipo, zona, progreso, jefes y los botones de la
-- entrada y AtlasLoot. Pagina derecha: la ilustracion y la historia de la
-- mazmorra, del Diario del juego (Core/Journal.lua), como la pagina de
-- mazmorra del propio Diario.

local PORTAL = "|TInterface\\Icons\\Spell_Arcane_PortalIronForge:16:16|t "

function ns.CreateOverviewPanel(left, right)
    local panel = { dungeon = nil }

    -- Datos (pagina izquierda) -------------------------------------------------
    local facts = ns.PaperText(left, "QuestFont")
    facts:SetPoint("TOPLEFT", 4, -6)
    facts:SetPoint("RIGHT", -4, 0)
    facts:SetSpacing(6)

    local entrance = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    entrance:SetSize(200, 26)
    entrance:SetPoint("TOPLEFT", facts, "BOTTOMLEFT", 0, -18)
    entrance:SetText(L.MARK_ENTRANCE)
    entrance:SetScript("OnClick", function()
        ns.SetWaypoint(ns.Entrance(panel.dungeon), ns.DungeonName(panel.dungeon), "entrance")
    end)
    ns.AddTooltip(entrance, function()
        local d = panel.dungeon
        local point = d and ns.Entrance(d)
        if not point then return L.NO_ENTRANCE:format(d and d.key or "") end
        return L.MARK_ENTRANCE_TOOLTIP .. "\n|cffffffff" .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) .. "|r"
    end)
    local loot = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    loot:SetSize(200, 26)
    loot:SetPoint("TOPLEFT", entrance, "BOTTOMLEFT", 0, -6)
    loot:SetText(L.VIEW_LOOT)
    loot:SetScript("OnClick", function() ns.OpenAtlasLoot(panel.dungeon) end)
    ns.AddTooltip(loot, L.VIEW_LOOT_TOOLTIP)

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
    lore:SetPoint("TOPLEFT")
    lore:SetSpacing(2)
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
        self.dungeon = d
        if not d then return end
        local journal = ns.Journal(d)
        local point = ns.Entrance(d)
        local lines = {
            d.isForever and L.KIND_FOREVER or L.KIND_CLASSIC,
            L.BOSS_COUNT:format(#(ns.Bosses[d.key] or {})),
        }
        if point then lines[#lines + 1] = PORTAL .. ns.ZoneName(point.mapID) .. " " .. ns.FormatCoords(point) end
        facts:SetText(table.concat(lines, "\n"))
        entrance:SetEnabled(point ~= nil)
        loot:SetShown(ns.AtlasLootAvailable())

        ns.SetDungeonArt(art, d, "lore")
        title:SetText(ns.DungeonName(d))
        lore:SetText(journal.description or L.NO_LORE)
        Fit()
        scroll:SetVerticalScroll(0)
    end

    return panel
end
