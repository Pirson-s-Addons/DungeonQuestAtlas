local _, ns = ...
local L = ns.L

-- ==========================================
-- BUSCADOR DE BOTIN (todas las mazmorras y bandas)
-- ==========================================
-- Vista de la portada de Mazmorras (boton "Buscar botin"): todos los objetos del
-- atlas (UI/ItemSource.lua: botin de jefes y recompensas de mision), filtrados por
-- el texto del buscador (nombre), una estadistica, el tipo de armadura, la ranura,
-- la clase y los favoritos (clic derecho en cualquier objeto del addon), en paginas
-- de 40 por mazmorra y jefe. Clic: su jefe o su mision.
-- Las estadisticas salen de C_Item.GetItemStats (claves ITEM_MOD_*); el nombre de
-- cada una, de las cadenas del juego en su idioma.

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

-- Ranuras (el nombre, el del juego). Pecho incluye las togas
local SLOTS = { "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_CLOAK", "INVTYPE_CHEST", "INVTYPE_WRIST",
    "INVTYPE_HAND", "INVTYPE_WAIST", "INVTYPE_LEGS", "INVTYPE_FEET", "INVTYPE_FINGER", "INVTYPE_TRINKET",
    "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND", "INVTYPE_SHIELD",
    "INVTYPE_HOLDABLE", "INVTYPE_RANGED" }
local SAME_SLOT = { INVTYPE_ROBE = "INVTYPE_CHEST", INVTYPE_RANGEDRIGHT = "INVTYPE_RANGED", INVTYPE_THROWN = "INVTYPE_RANGED" }

-- ------------------------------------------
-- Datos de los objetos sin atascar el juego
-- ------------------------------------------
-- Pedir al servidor miles de objetos de golpe congela el juego (cada respuesta
-- refresca la ventana). Aqui nada se pide sin necesidad: la pagina abierta pide
-- solo sus 40 objetos, y buscar por nombre o estadistica los va pidiendo en
-- tandas pequenas (Loader) mientras se ve el buscador.

local function Cached(itemID)
    local cached = C_Item and C_Item.IsItemDataCachedByID
    if cached then return cached(itemID) and true or false end
    return true -- sin la API, GetItemInfo dira
end

local queue, queued, head = {}, {}, 1
local BATCH, EVERY = 20, 0.25 -- 80 objetos por segundo
local loader = CreateFrame("Frame")
loader:Hide()
local wait = 0
loader:SetScript("OnUpdate", function(self, delta)
    wait = wait + delta
    if wait < EVERY then return end
    wait = 0
    local request = C_Item and C_Item.RequestLoadItemDataByID
    for _ = 1, BATCH do
        local id = queue[head]
        if not id then
            wipe(queue); head = 1
            return self:Hide()
        end
        head = head + 1
        if request and not Cached(id) then request(id) end
    end
end)
local function Want(itemID)
    if queued[itemID] then return end
    queued[itemID] = true
    queue[#queue + 1] = itemID
    loader:Show()
end
-- El buscador se cierra: lo que falte se deja de pedir
function ns.StopLootLoader()
    for i = head, #queue do queued[queue[i]] = nil end
    wipe(queue); head = 1
    loader:Hide()
end

-- Nombre en minusculas de un objeto cargado (nil si aun no)
local nameCache = {}
local function LowerName(itemID)
    if nameCache[itemID] then return nameCache[itemID] end
    if not Cached(itemID) then return nil end
    local name = ((C_Item and C_Item.GetItemInfo) or _G.GetItemInfo)(itemID)
    if not name then return nil end
    nameCache[itemID] = name:lower()
    return nameCache[itemID]
end

-- Claves de estadistica de un objeto, en mayusculas y juntas (una vez cargado). nil: sin cargar
local statCache = {}
local function StatKeys(itemID)
    if statCache[itemID] then return statCache[itemID] end
    local get = (C_Item and C_Item.GetItemStats) or _G.GetItemStats
    if not get then return "" end
    if not Cached(itemID) then return nil end
    local link = select(2, ((C_Item and C_Item.GetItemInfo) or _G.GetItemInfo)(itemID))
    if not link then return nil end
    local keys = {}
    for key in pairs(get(link) or {}) do keys[#keys + 1] = key end
    statCache[itemID] = table.concat(keys, " "):upper()
    return statCache[itemID]
end

-- nil: aun sin cargar
local function HasStat(itemID, stat)
    local keys = StatKeys(itemID)
    if not keys then return nil end
    for _, piece in ipairs(stat[2]) do
        if keys:find(piece, 1, true) then return true end
    end
    return false
end

-- Orden fijo que no pide nada al servidor: por mazmorra (la de su primera fuente,
-- en el orden de la portada; las bandas al final), jefe y objeto
local ordered
local function Ordered()
    if ordered then return ordered end
    local rank = {}
    for i, d in ipairs(ns.Dungeons) do rank[d] = i end
    for i, r in ipairs(ns.Raids or {}) do rank[r] = 1000 + i end
    local key = {}
    ordered = {}
    for itemID, sources in pairs(ns.AllSourceItems()) do
        local e = sources[1]
        key[itemID] = { rank[e.d] or 9999, e.boss or 999 }
        ordered[#ordered + 1] = itemID
    end
    table.sort(ordered, function(a, b)
        local ka, kb = key[a], key[b]
        if ka[1] ~= kb[1] then return ka[1] < kb[1] end
        if ka[2] ~= kb[2] then return ka[2] < kb[2] end
        return a < b
    end)
    return ordered
end

ns.LOOT_PAGE_SIZE = 40
ns.LOOT_MIN_SEARCH = 2 -- letras para buscar por nombre (una sola pediria todo el botin)

-- filters: search (nombre), stat (indice de STATS), armor (subclase de armadura), slot (ranura de SLOTS),
-- class (solo lo que esa clase lleva, ns.ClassCanUse), favorites, page.
-- Devuelve los objetos de la pagina, el total, cuantos faltan por cargar (para saber si tienen
-- el nombre o la estadistica; se van pidiendo) y el numero de paginas
function ns.SearchLoot(filters)
    local search = (filters.search or ""):lower()
    if #search < ns.LOOT_MIN_SEARCH then search = "" end
    local instant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    local found, loading = {}, 0
    for _, itemID in ipairs(Ordered()) do
        local ok = not filters.favorites or ns.IsFavorite(itemID)
        if ok and (filters.armor or filters.slot) then
            local _, _, _, equipLoc, _, classID, subID = instant(itemID)
            if filters.armor then ok = classID == 4 and subID == filters.armor end
            if ok and filters.slot then ok = (SAME_SLOT[equipLoc] or equipLoc) == filters.slot end
        end
        if ok and filters.class then ok = ns.ClassCanUse(itemID, filters.class) end
        if ok and filters.stat then
            ok = HasStat(itemID, STATS[filters.stat])
            if ok == nil then loading = loading + 1; Want(itemID) end
        end
        if ok and search ~= "" then
            local name = LowerName(itemID)
            if not name then loading = loading + 1; Want(itemID) end
            ok = name ~= nil and name:find(search, 1, true) ~= nil
        end
        if ok then found[#found + 1] = itemID end
    end
    local total = #found
    local pages = math.max(1, math.ceil(total / ns.LOOT_PAGE_SIZE))
    local page = math.min(math.max(filters.page or 1, 1), pages)
    local first = (page - 1) * ns.LOOT_PAGE_SIZE
    local shown = {}
    for i = first + 1, math.min(first + ns.LOOT_PAGE_SIZE, total) do shown[#shown + 1] = { id = found[i] } end
    return shown, total, loading, pages, page
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
    local function Changed() lf.page = 1; ns.RefreshUI() end
    panel:SetScript("OnHide", ns.StopLootLoader)

    local stat = Dropdown(panel, 150, function()
        local list = { { false, L.LOOT_STAT_ANY } }
        for i, s in ipairs(STATS) do list[#list + 1] = { i, StatName(s) } end
        return list
    end, function() return lf.stat or false end, function(v) lf.stat = v or nil; Changed() end)
    stat:SetPoint("TOPLEFT", 4, -2)
    local armor = Dropdown(panel, 112, function()
        local list = { { false, L.LOOT_ARMOR_ANY } }
        for sub = 1, 4 do list[#list + 1] = { sub, ArmorName(sub) } end
        return list
    end, function() return lf.armor or false end, function(v) lf.armor = v or nil; Changed() end)
    armor:SetPoint("LEFT", stat, "RIGHT", 8, 0)
    if type(lf.armor) == "string" then lf.slot, lf.armor = lf.armor, nil end -- antes, las ranuras iban aqui
    local slot = Dropdown(panel, 112, function()
        local list = { { false, L.LOOT_SLOT_ANY } }
        for _, s in ipairs(SLOTS) do list[#list + 1] = { s, _G[s] or s } end
        return list
    end, function() return lf.slot or false end, function(v) lf.slot = v or nil; Changed() end)
    slot:SetPoint("LEFT", armor, "RIGHT", 8, 0)
    local class = Dropdown(panel, 112, function()
        local list = { { false, L.LOOT_CLASS_ALL } }
        for _, c in ipairs(ns.LOOT_CLASSES) do list[#list + 1] = { c, (LOCALIZED_CLASS_NAMES_MALE or {})[c] or c } end
        return list
    end, function() return lf.class or false end, function(v) lf.class = v or nil; Changed() end)
    class:SetPoint("LEFT", slot, "RIGHT", 8, 0)
    class:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L.LOOT_CLASS_TOOLTIP, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    class:HookScript("OnLeave", GameTooltip_Hide)
    local fav = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    fav:SetSize(26, 26)
    fav:SetPoint("LEFT", class, "RIGHT", 6, 0)
    fav:SetScript("OnClick", function(self) lf.favorites = self:GetChecked() or nil; Changed() end)
    ns.AddTooltip(fav, L.LOOT_FAVORITES_TOOLTIP)
    local favLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    favLabel:SetPoint("LEFT", fav, "RIGHT", 0, 0)
    favLabel:SetText(L.LOOT_FAVORITES)
    local count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("TOPRIGHT", -26, -10)

    local listArea = CreateFrame("Frame", nil, panel)
    listArea:SetPoint("TOPLEFT", 0, -36)
    listArea:SetPoint("BOTTOMRIGHT", 0, 30)

    -- Paginas: < Pagina 2 / 9 >
    local pageText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pageText:SetPoint("BOTTOM", 0, 8)
    local function PageButton(dir)
        local b = CreateFrame("Button", nil, panel)
        b:SetSize(26, 26)
        local name = dir < 0 and "PrevPage" or "NextPage"
        b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "-Up")
        b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "-Down")
        b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "-Disabled")
        b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        b:SetPoint(dir < 0 and "RIGHT" or "LEFT", pageText, dir < 0 and "LEFT" or "RIGHT", dir < 0 and -8 or 8, 0)
        b:SetScript("OnClick", function()
            lf.page = (lf.page or 1) + dir
            panel:Refresh()
        end)
        return b
    end
    local prev, nextPage = PageButton(-1), PageButton(1)
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

    local lastSearch
    function panel:Refresh()
        fav:SetChecked(lf.favorites and true or false)
        if filters.search ~= lastSearch then lastSearch, lf.page = filters.search, 1 end
        local found, total, loading, pages, page = ns.SearchLoot({ search = filters.search, stat = lf.stat,
            armor = lf.armor, slot = lf.slot, class = lf.class, favorites = lf.favorites, page = lf.page })
        lf.page = page
        pageText:SetText(L.LOOT_PAGE:format(page, pages))
        prev:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pages)
        count:SetText(L.LOOT_RESULTS:format(total)
            .. (loading > 0 and ("\n|cffaaaaaa" .. L.LOOT_LOADING:format(loading) .. "|r") or ""))
        local rows = {}
        for i, it in ipairs(found) do
            local r = math.floor((i - 1) / COLS) + 1
            rows[r] = rows[r] or {}
            rows[r][#rows[r] + 1] = it
        end
        list:SetItems(rows)
        empty:SetShown(total == 0 and loading == 0)
    end
    return panel
end
