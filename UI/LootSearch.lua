local _, ns = ...
local L = ns.L

-- ==========================================
-- BUSCADOR DE BOTIN (todas las mazmorras y bandas)
-- ==========================================
-- Vista de la portada de Mazmorras (boton "Buscar botin"): todos los objetos del
-- atlas (UI/ItemSource.lua: botin de jefes y recompensas de mision), filtrados por
-- el texto del buscador (nombre), una estadistica, el tipo de armadura y los
-- favoritos (clic derecho en cualquier objeto del addon). Clic: su jefe o su mision.
-- Las estadisticas salen de C_Item.GetItemStats (claves ITEM_MOD_*); el nombre de
-- cada una, de las cadenas del juego en su idioma.

local MAX_RESULTS = 200
local COLS, GAP = 2, 12

-- { cadena del juego para el nombre, trozos de la clave de GetItemStats, clave de L si
-- el juego no tiene nombre bueno }
local STATS = {
    { "ITEM_MOD_STAMINA_SHORT", { "STAMINA" } },
    { "ITEM_MOD_STRENGTH_SHORT", { "STRENGTH" } },
    { "ITEM_MOD_AGILITY_SHORT", { "AGILITY" } },
    { "ITEM_MOD_INTELLECT_SHORT", { "INTELLECT" } },
    { "ITEM_MOD_SPIRIT_SHORT", { "SPIRIT" } },
    { nil, { "POWER_REGEN0", "MANA_REGENERATION" }, "STAT_MP5" },
    { "ITEM_MOD_ATTACK_POWER_SHORT", { "ATTACK_POWER" } },
    { "ITEM_MOD_SPELL_POWER_SHORT", { "SPELL_POWER", "SPELL_DAMAGE", "SPELL_HEALING" } },
    { "ITEM_MOD_CRIT_RATING_SHORT", { "CRIT" } },
    { "ITEM_MOD_HIT_RATING_SHORT", { "HIT_RATING", "HIT_MELEE", "HIT_RANGED" } },
    { nil, { "HIT_SPELL", "SPELL_HIT" }, "STAT_SPELL_HIT" },
    { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", { "DEFENSE" } },
    { "ITEM_MOD_DODGE_RATING_SHORT", { "DODGE" } },
    { "ITEM_MOD_PARRY_RATING_SHORT", { "PARRY" } },
    { "ITEM_MOD_BLOCK_RATING_SHORT", { "BLOCK" } },
    { "RESISTANCE2_NAME", { "RESISTANCE2" } }, -- fuego
    { "RESISTANCE3_NAME", { "RESISTANCE3" } }, -- naturaleza
    { "RESISTANCE4_NAME", { "RESISTANCE4" } }, -- escarcha
    { "RESISTANCE5_NAME", { "RESISTANCE5" } }, -- sombras
    { "RESISTANCE6_NAME", { "RESISTANCE6" } }, -- arcano
}

local function StatName(stat)
    if stat[3] then return L[stat[3]] end
    local text = _G[stat[1]]
    return type(text) == "string" and text ~= "" and text or stat[1]
end

-- Armaduras: subclase de la clase 4 (tela 1, cuero 2, malla 3, placas 4)
local function ArmorName(sub)
    local get = (C_Item and C_Item.GetItemSubClassInfo) or _G.GetItemSubClassInfo
    return get and get(4, sub) or tostring(sub)
end

-- Claves de estadistica de un objeto, en mayusculas y juntas (una vez cargado)
local statCache = {}
local function StatKeys(itemID)
    if statCache[itemID] then return statCache[itemID] end
    local link = select(2, ((C_Item and C_Item.GetItemInfo) or _G.GetItemInfo)(itemID))
    local get = (C_Item and C_Item.GetItemStats) or _G.GetItemStats
    if not (link and get) then return "" end
    local keys = {}
    for key in pairs(get(link) or {}) do keys[#keys + 1] = key end
    statCache[itemID] = table.concat(keys, " "):upper()
    return statCache[itemID]
end

local function HasStat(itemID, stat)
    local keys = StatKeys(itemID)
    for _, piece in ipairs(stat[2]) do
        if keys:find(piece, 1, true) then return true end
    end
    return false
end

-- filters: search (nombre), stat (indice de STATS), armor (subclase), favorites
function ns.SearchLoot(filters)
    local search = (filters.search or ""):lower()
    local instant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    local found = {}
    for itemID in pairs(ns.AllSourceItems()) do
        local ok = not filters.favorites or ns.IsFavorite(itemID)
        if ok and filters.armor then
            local _, _, _, _, _, classID, subID = instant(itemID)
            ok = classID == 4 and subID == filters.armor
        end
        if ok and filters.stat then ok = HasStat(itemID, STATS[filters.stat]) end
        local info = ok and ns.ItemInfo(itemID)
        if ok and search ~= "" then ok = info.name ~= nil and info.name:lower():find(search, 1, true) ~= nil end
        if ok then found[#found + 1] = { id = itemID, name = info.name or "", quality = info.quality or 0 } end
    end
    table.sort(found, function(a, b)
        if a.quality ~= b.quality then return a.quality > b.quality end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    local total = #found
    for i = MAX_RESULTS + 1, total do found[i] = nil end
    return found, total
end

local function Dropdown(parent, width, options, get, set)
    local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(width)
    if dd.SetupMenu then
        dd:SetupMenu(function(_, root)
            for _, o in ipairs(options()) do
                root:CreateRadio(o[2], function() return get() == o[1] end, function() set(o[1]) end)
            end
        end)
    end
    return dd
end

function ns.CreateLootSearch(parent, filters)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    filters.lootFilters = filters.lootFilters or {}
    local lf = filters.lootFilters
    local function Changed() ns.RefreshUI() end

    local stat = Dropdown(panel, 190, function()
        local list = { { false, L.LOOT_STAT_ANY } }
        for i, s in ipairs(STATS) do list[#list + 1] = { i, StatName(s) } end
        return list
    end, function() return lf.stat or false end, function(v) lf.stat = v or nil; Changed() end)
    stat:SetPoint("TOPLEFT", 4, -2)
    local armor = Dropdown(panel, 150, function()
        local list = { { false, L.LOOT_ARMOR_ANY } }
        for sub = 1, 4 do list[#list + 1] = { sub, ArmorName(sub) } end
        return list
    end, function() return lf.armor or false end, function(v) lf.armor = v or nil; Changed() end)
    armor:SetPoint("LEFT", stat, "RIGHT", 10, 0)
    local fav = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    fav:SetSize(26, 26)
    fav:SetPoint("LEFT", armor, "RIGHT", 10, 0)
    fav:SetScript("OnClick", function(self) lf.favorites = self:GetChecked() or nil; Changed() end)
    ns.AddTooltip(fav, L.LOOT_FAVORITES_TOOLTIP)
    local favLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    favLabel:SetPoint("LEFT", fav, "RIGHT", 0, 0)
    favLabel:SetText(L.LOOT_FAVORITES)
    local count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("TOPRIGHT", -26, -10)

    local listArea = CreateFrame("Frame", nil, panel)
    listArea:SetPoint("TOPLEFT", 0, -36)
    listArea:SetPoint("BOTTOMRIGHT")
    local colW = (ns.GRID_WIDTH - (COLS - 1) * GAP) / COLS
    local list = ns.CreateScrollList(listArea, ns.ITEM_ROW_HEIGHT + 6, function(row)
        row.items = {}
        for i = 1, COLS do
            local b = ns.CreateItemButton(row)
            b:SetWidth(colW)
            b:SetPoint("TOPLEFT", (i - 1) * (colW + GAP), 0)
            b.extra:SetTextColor(1, 0.82, 0) -- sobre el fondo oscuro de la portada, no sobre papel
            b.onPlainClick = function(self) ns.OpenItemSource(self.itemID) end
            row.items[i] = b
        end
    end, function(row, item)
        for i, b in ipairs(row.items) do
            local it = item[i]
            b:SetShown(it ~= nil)
            if it then
                local source = (ns.ItemSources(it.id) or {})[1]
                ns.SetItemButton(b, it.id, nil, source and ns.DungeonName(source.d) or "")
            end
        end
    end)
    local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    empty:SetPoint("CENTER", 0, -20)
    empty:SetText(L.LOOT_NO_RESULTS)

    function panel:Refresh()
        fav:SetChecked(lf.favorites and true or false)
        local found, total = ns.SearchLoot({ search = filters.search, stat = lf.stat, armor = lf.armor,
            favorites = lf.favorites })
        count:SetText(L.LOOT_RESULTS:format(total))
        local rows = {}
        for i, it in ipairs(found) do
            local r = math.floor((i - 1) / COLS) + 1
            rows[r] = rows[r] or {}
            rows[r][#rows[r] + 1] = it
        end
        list:SetItems(rows)
        empty:SetShown(total == 0)
    end
    return panel
end
