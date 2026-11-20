local _, ns = ...
local L = ns.L

-- ==========================================
-- CONJUNTOS DE TIER (portada de Mazmorras)
-- ==========================================
-- Icono redondo junto al de Onyxia con el pecho de Tier 0 de tu clase: abre en la
-- portada, en lugar de las tarjetas, los conjuntos de Tier 0 y Tier 0.5 (Data/TierSets.lua).
-- Una fila por clase (la tuya primero; el desplegable elige cuales): sus ocho piezas
-- de cada tier, con marca verde las que tienes (bolsas, banco o puestas). Raton
-- encima: el tooltip del objeto (con su jefe, UI/ItemSource.lua) y, en Tier 0.5, la
-- mision de la cadena que la da. Clic: su jefe. Mayus+clic: enlace al chat.
-- El icono sale solo al nivel 50 (ns.db.tierIcon "auto"); clic derecho, se oculta.

local CHEST, SIZE, GAP = 3, 34, 6
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local CLASS_ICONS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"
local CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ROW_H = 24 + 2 * (SIZE + GAP) + 10

local function PlayerClass() return select(2, UnitClass("player")) end

local function ItemIcon(id)
    local get = (C_Item and C_Item.GetItemIconByID) or _G.GetItemIcon
    return get and get(id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- La tienes: puesta, en las bolsas o en el banco
function ns.HasTierPiece(id)
    local equipped = (C_Item and C_Item.IsEquippedItem) or _G.IsEquippedItem
    if equipped and equipped(id) then return true end
    local count = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
    return count and (count(id, true) or 0) > 0 or false
end

function ns.TierIconShown()
    local mode = ns.db.tierIcon
    if mode == "hide" then return false end
    if mode == "show" then return true end
    return (UnitLevel("player") or 0) >= ns.TIER_ICON_LEVEL
end

-- Nombre del conjunto: el del juego si lo da (setID del objeto), si no el ingles
local function SetName(set, class)
    local list = set[class]
    local get = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    local setID = list and select(16, get(list[1]))
    local info = setID and C_Item and C_Item.GetItemSetInfo and C_Item.GetItemSetInfo(setID)
    if type(info) == "string" and info ~= "" then return info end
    return list and list.name or ""
end

function ns.CreateTierButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(28, 28)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetMask(MASK)
    local own = ns.TierSets[1][PlayerClass()] or ns.TierSets[1].WARRIOR
    icon:SetTexture(ItemIcon(own[CHEST]))
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("CENTER")
    ring:SetSize(40, 40)
    ring:SetAtlas("Forge-ColorSwatchSelection", false) -- aro dorado: pagina abierta
    if not ring:GetAtlas() then
        ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        ring:SetSize(48, 48)
        ring:SetPoint("CENTER", 9, -9)
    end
    button.ring = ring
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture(MASK)
    hl:SetVertexColor(1, 1, 1, 0.25)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.padAlt = "PAD_HIDE" -- con mando (UI/GamepadNav.lua)
    button:SetScript("OnClick", function(_, mouse)
        GameTooltip:Hide()
        if mouse == "RightButton" then
            ns.db.tierIcon = "hide"
            ns.SetFilter("tiers", nil)
            return
        end
        local open = not ns.GetFilter("tiers")
        if open then ns.SetFilter("loot", nil) end
        ns.SetFilter("tiers", open or nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.TIER_TITLE, 1, 0.82, 0)
        GameTooltip:AddLine(L.TIER_ICON_TIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    function button:Update()
        self:SetShown(ns.TierIconShown())
        self.ring:SetShown(ns.GetFilter("tiers") and true or false)
    end
    return button
end

-- ------------------------------------------
-- Pagina
-- ------------------------------------------

local function PieceTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then GameTooltip:SetItemByID(self.itemID) end
    local set = self.set
    if set.quests then
        local q = set.quests[set.pieceQuest[self.slot]]
        local name = ns.QuestTitle(q)
        if name == L.QUEST_FALLBACK:format(q) then name = set.questNames[set.pieceQuest[self.slot]] end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.TIER05_FROM:format(name), 0.4, 0.8, 1, true)
    elseif not ns.ItemSources(self.itemID) then
        GameTooltip:AddLine(L.TIER_NO_SOURCE, 0.6, 0.6, 0.6, true)
    end
    if ns.HasTierPiece(self.itemID) then GameTooltip:AddLine(L.TIER_OWNED, 0.25, 0.75, 0.25) end
    GameTooltip:Show()
end

local function PieceClick(self)
    local link = select(2, ((C_Item and C_Item.GetItemInfo) or _G.GetItemInfo)(self.itemID))
    if IsModifiedClick() and link and HandleModifiedItemClick then
        HandleModifiedItemClick(link)
        return
    end
    if not ns.OpenItemSource(self.itemID) and self.set.quests then ns.Print(L.TIER05_HOWTO) end
end

local function CreatePiece(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(SIZE, SIZE)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    b.border:SetAllPoints()
    b.check = b:CreateTexture(nil, "OVERLAY", nil, 2)
    b.check:SetTexture(CHECK)
    b.check:SetSize(18, 18)
    b.check:SetPoint("BOTTOMRIGHT", 4, -4)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.2)
    b:SetScript("OnEnter", PieceTooltip)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", PieceClick)
    return b
end

local function SetPiece(b, set, slot, id)
    b.itemID, b.set, b.slot = id, set, slot
    b.icon:SetTexture(ItemIcon(id))
    local info = ns.ItemInfo(id)
    local color = info.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[info.quality]
    if color then b.border:SetVertexColor(color.r, color.g, color.b) else b.border:SetVertexColor(1, 1, 1) end
    local owned = ns.HasTierPiece(id)
    b.check:SetShown(owned)
    return owned
end

-- Clases a enseñar: "mine" (la tuya), "all" (la tuya primero) o una
local function Classes(choice)
    local mine = PlayerClass()
    if choice == "all" then
        local list = { mine }
        for _, c in ipairs(ns.LOOT_CLASSES) do if c ~= mine then list[#list + 1] = c end end
        return list
    end
    return { (choice and choice ~= "mine") and choice or mine }
end

local function ClassName(c) return (LOCALIZED_CLASS_NAMES_MALE or {})[c] or c end

function ns.CreateTierPage(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 6, -6)
    title:SetText(L.TIER_TITLE)

    local dd = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    dd:SetWidth(160)
    dd:SetPoint("TOPRIGHT", -26, -2)
    if dd.SetupMenu then
        dd:SetupMenu(function(_, root)
            local function Get(v) return (ns.char.tierClass or "mine") == v end
            local function Set(v) ns.char.tierClass = v; panel:Refresh() end
            root:CreateRadio(L.TIER_MY_CLASS, Get, Set, "mine")
            root:CreateRadio(L.LOOT_CLASS_ALL, Get, Set, "all")
            for _, c in ipairs(ns.LOOT_CLASSES) do root:CreateRadio(ClassName(c), Get, Set, c) end
        end)
    end

    local listArea = CreateFrame("Frame", nil, panel)
    listArea:SetPoint("TOPLEFT", 0, -34)
    listArea:SetPoint("BOTTOMRIGHT")
    local list = ns.CreateScrollList(listArea, ROW_H, function(row)
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(20, 20)
        row.classIcon:SetPoint("TOPLEFT", 4, -2)
        row.classIcon:SetTexture(CLASS_ICONS)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("LEFT", row.classIcon, "RIGHT", 6, 0)
        row.tiers = {}
        for t = 1, #ns.TierSets do
            local y = -24 - (t - 1) * (SIZE + GAP)
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("TOPLEFT", 8, y - 10)
            label:SetWidth(70)
            label:SetJustifyH("LEFT")
            local setName = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            setName:SetJustifyH("LEFT")
            setName:SetWordWrap(false)
            local pieces = {}
            for i = 1, 8 do
                pieces[i] = CreatePiece(row)
                pieces[i]:SetPoint("TOPLEFT", 82 + (i - 1) * (SIZE + GAP), y)
            end
            setName:SetPoint("LEFT", pieces[8], "RIGHT", 12, 0)
            setName:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.tiers[t] = { label = label, setName = setName, pieces = pieces }
        end
    end, function(row, class)
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
        if coords then row.classIcon:SetTexCoord(unpack(coords)) end
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        row.name:SetText(ClassName(class))
        if c then row.name:SetTextColor(c.r, c.g, c.b) end
        for t, set in ipairs(ns.TierSets) do
            local ui, ids, owned = row.tiers[t], set[class], 0
            ui.label:SetText(t == 1 and L.TIER_0 or L.TIER_05)
            for i, id in ipairs(ids) do
                if SetPiece(ui.pieces[i], set, i, id) then owned = owned + 1 end
            end
            ui.setName:SetText(SetName(set, class) .. "  " .. (owned == #ids and "|cff40c040" or "|cffaaaaaa")
                .. owned .. "/" .. #ids .. "|r")
        end
    end)

    function panel:Refresh()
        local choice = ns.char.tierClass or "mine"
        if dd.OverrideText then
            dd:OverrideText(choice == "mine" and L.TIER_MY_CLASS or choice == "all" and L.LOOT_CLASS_ALL
                or ClassName(choice))
        end
        list:SetItems(Classes(choice))
    end

    -- Coger, vender o ponerse una pieza: la marca al momento
    local events = CreateFrame("Frame", nil, panel)
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    events:SetScript("OnEvent", function() if panel:IsVisible() then panel:Refresh() end end)
    return panel
end
