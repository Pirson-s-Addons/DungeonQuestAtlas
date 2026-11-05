local _, ns = ...
local L = ns.L

-- ==========================================
-- DE DONDE SALE UN OBJETO (tooltip de cualquier objeto)
-- ==========================================
-- Si el objeto esta en el atlas (botin de un jefe de mazmorra o de banda, o
-- recompensa de una mision de mazmorra), su tooltip lleva una linea mas al
-- final con el logo: "Jefe - Mazmorra" (o "Mision - Mazmorra"). Sale en las
-- bolsas, al inspeccionar, en las tiradas y en la ventana de un enlace del chat.
-- La tecla "Abrir en Dungeon Quest Atlas el objeto bajo el raton" (Bindings.xml)
-- abre el atlas en ese jefe o mision. Opcion itemSourceTip.

local index -- itemID -> { { d = mazmorra o banda, boss = indice } o { d, quest = id }, ... }

local function Add(itemID, entry)
    index[itemID] = index[itemID] or {}
    table.insert(index[itemID], entry)
end

local function Build()
    index = {}
    for _, d in ipairs(ns.Dungeons) do
        for i, boss in ipairs(ns.Bosses[d.key] or {}) do
            if boss.kind ~= "recipes" then -- las recetas ya van en el botin de cada jefe
                for _, it in ipairs(boss.loot or {}) do Add(it[1], { d = d, boss = i, chance = it[2] }) end
            end
        end
        for _, id in ipairs(d.quests) do
            local q = ns.Quests[id] or {}
            for _, list in ipairs({ q.choice or {}, q.rewards or {} }) do
                for _, itemID in ipairs(list) do Add(itemID, { d = d, quest = id }) end
            end
        end
    end
    for _, raid in ipairs(ns.Raids or {}) do
        for i, boss in ipairs(raid.bosses or {}) do
            for _, it in ipairs(boss.loot or {}) do Add(it[1], { d = raid, boss = i, chance = it[2] }) end
        end
    end
    -- La fuente mas probable primero
    for _, list in pairs(index) do
        table.sort(list, function(a, b) return (a.chance or 0) > (b.chance or 0) end)
    end
end

-- Todos: [itemID] = fuentes (buscador de botin)
function ns.AllSourceItems()
    if not index then Build() end
    return index
end

function ns.ItemSources(itemID)
    if not index then Build() end
    return itemID and index[itemID]
end

local function SourceName(e)
    local where = ns.DungeonName(e.d)
    if e.quest then return "|cffffd100!|r " .. ns.QuestTitle(e.quest) .. " - " .. where end
    local boss = e.d.size and e.d.bosses[e.boss] or ns.Bosses[e.d.key][e.boss]
    local name = e.d.size and (boss.name or "?") or ns.BossName(boss, e.d)
    return name .. " - " .. where
end

-- "[logo] Jefe - Mazmorra (+2)" o nil
function ns.ItemSourceLine(itemID)
    local list = ns.ItemSources(itemID)
    if not list then return end
    local line = "|T" .. ns.LOGO .. ":14:14|t " .. SourceName(list[1])
    if #list > 1 then line = line .. " |cff999999(+" .. (#list - 1) .. ")|r" end
    return line
end

-- Abre el atlas en la fuente de un objeto: el botin de su jefe o la hoja de su mision
function ns.OpenItemSource(itemID)
    local e = (ns.ItemSources(itemID) or {})[1]
    if not e then return false end
    if e.quest then
        ns.ShowQuest(e.quest)
    elseif e.d.size then
        ns.OpenRaid(e.d, e.boss, "loot")
    else
        ns.ShowBoss(e.d, e.boss, "loot")
    end
    return true
end

-- El ultimo objeto con tooltip (raton encima o ventana de enlace), para la tecla
local lastItem
function ns.OpenHoveredItem()
    if not (lastItem and ns.OpenItemSource(lastItem)) then ns.Print(L.ITEM_SOURCE_NONE) end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not (ns.db and ns.db.itemSourceTip) then return end
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
        local itemID = data and ns.PlainText(data.id)
        if type(itemID) ~= "number" then return end
        lastItem = itemID
        local line = ns.ItemSourceLine(itemID)
        if line then tooltip:AddLine(line, 1, 1, 1) end
    end)
end
