local _, ns = ...
local L = ns.L

-- ==========================================
-- ESTADO DE LAS MISIONES Y FILTROS
-- ==========================================

ns.STATUS_COMPLETED = "COMPLETED"
ns.STATUS_IN_LOG = "IN_LOG"
ns.STATUS_AVAILABLE = "AVAILABLE"
ns.STATUS_BLOCKED = "BLOCKED"

local function IsCompleted(id)
    return C_QuestLog.IsQuestFlaggedCompleted(id) and true or false
end

local function IsInLog(id)
    return C_QuestLog.GetLogIndexForQuestID(id) ~= nil
end

-- Devuelve el estado y, si esta bloqueada, el motivo
function ns.QuestStatus(id)
    if IsCompleted(id) then return ns.STATUS_COMPLETED end
    if IsInLog(id) then return ns.STATUS_IN_LOG end
    local q = ns.Quests[id] or {}
    for _, pre in ipairs(q.prereqs or {}) do
        if not IsCompleted(pre) then return ns.STATUS_BLOCKED, L.BLOCKED_PREREQ end
    end
    if q.minLevel and UnitLevel("player") < q.minLevel then
        return ns.STATUS_BLOCKED, L.BLOCKED_LEVEL:format(q.minLevel)
    end
    return ns.STATUS_AVAILABLE
end

-- faction: "Alliance", "Horde" o nil (todas)
function ns.MatchesFaction(entry, faction)
    return not faction or not entry.faction or entry.faction == "Both" or entry.faction == faction
end

-- Misiones de una mazmorra que se ven con los filtros actuales
function ns.DungeonQuests(d, faction, hideCompleted)
    local list = {}
    for _, id in ipairs(d.quests) do
        local q = ns.Quests[id] or {}
        if ns.MatchesFaction(q, faction) and not (hideCompleted and IsCompleted(id)) then
            list[#list + 1] = id
        end
    end
    table.sort(list, function(a, b)
        local la, lb = (ns.Quests[a] or {}).level or 0, (ns.Quests[b] or {}).level or 0
        if la ~= lb then return la < lb end
        return a < b
    end)
    return list
end

-- "3/7 completadas", contando solo las de la faccion
function ns.DungeonProgress(d, faction)
    local done, total = 0, 0
    for _, id in ipairs(d.quests) do
        if ns.MatchesFaction(ns.Quests[id] or {}, faction) then
            total = total + 1
            if IsCompleted(id) then done = done + 1 end
        end
    end
    return done, total
end

-- Color como la dificultad de mision, con el nivel medio de la mazmorra:
-- rojo / naranja / amarillo / verde / gris
local COLORS = { red = "ffff1a1a", orange = "ffff8040", yellow = "ffffff00", green = "ff40c040", gray = "ff808080" }
function ns.LevelColor(minLevel, maxLevel, playerLevel)
    local diff = math.floor((minLevel + maxLevel) / 2) - playerLevel
    local greenRange = GetQuestGreenRange and GetQuestGreenRange() or 8
    if diff >= 5 then return COLORS.red end
    if diff >= 3 then return COLORS.orange end
    if diff >= -2 then return COLORS.yellow end
    if -diff <= greenRange then return COLORS.green end
    return COLORS.gray
end

-- En tu rango: puedes entrar ya (2 niveles de margen) y aun da experiencia
function ns.InRange(d, playerLevel)
    return playerLevel + 2 >= d.minLevel and playerLevel <= d.maxLevel
end

-- filters: { myRange, kind = "all"|"classic"|"forever", faction, search }
function ns.FilterDungeons(filters)
    local level = UnitLevel("player")
    local search = filters.search and filters.search:lower() or ""
    local list = {}
    for _, d in ipairs(ns.Dungeons) do
        local ok = (not filters.myRange or ns.InRange(d, level))
            and (filters.kind ~= "classic" or not d.isForever)
            and (filters.kind ~= "forever" or d.isForever)
            and ns.MatchesFaction(d, filters.faction)
        if ok and search ~= "" then
            ok = ns.DungeonName(d):lower():find(search, 1, true) ~= nil
                or d.name:lower():find(search, 1, true) ~= nil
                or d.key:lower() == search
            for _, boss in ipairs(not ok and ns.Bosses and ns.Bosses[d.key] or {}) do
                if boss.name and boss.name:lower():find(search, 1, true) then ok = true break end
            end
        end
        if ok then list[#list + 1] = d end
    end
    return list
end

-- Para el tooltip del minimapa: misiones sin hacer de las mazmorras de tu rango
function ns.PendingInRange()
    local level, faction, count = UnitLevel("player"), UnitFactionGroup("player"), 0
    for _, d in ipairs(ns.Dungeons) do
        if ns.InRange(d, level) then
            local done, total = ns.DungeonProgress(d, faction)
            count = count + total - done
        end
    end
    return count
end
