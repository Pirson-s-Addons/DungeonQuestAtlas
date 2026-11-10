local _, ns = ...
local L = ns.L

-- ==========================================
-- ESTADO DE LAS MISIONES Y FILTROS
-- ==========================================

ns.STATUS_COMPLETED = "COMPLETED"
ns.STATUS_READY = "READY" -- en el registro con los objetivos hechos: falta entregarla
ns.STATUS_IN_LOG = "IN_LOG"
ns.STATUS_AVAILABLE = "AVAILABLE"
ns.STATUS_BLOCKED = "BLOCKED"
-- Orden de la leyenda: el de una mision de principio a fin
ns.STATUS_ORDER = { "AVAILABLE", "IN_LOG", "READY", "COMPLETED", "BLOCKED" }

local function IsCompleted(id)
    return C_QuestLog.IsQuestFlaggedCompleted(id) and true or false
end

local function IsInLog(id)
    return C_QuestLog.GetLogIndexForQuestID(id) ~= nil
end

local function IsReady(id)
    return C_QuestLog.IsComplete and C_QuestLog.IsComplete(id) and true or false
end

-- Misiones de clase: q.classes = { "WARLOCK", ... } (fichas de UnitClass).
-- Nombres en el idioma del cliente y, si color, en el de la clase.
function ns.ClassNames(q, color)
    local names = {}
    for _, token in ipairs(q.classes or {}) do
        local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] or token
        local c = color and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
        names[#names + 1] = c and c.colorStr and ("|c%s%s|r"):format(c.colorStr, name) or name
    end
    return #names > 0 and table.concat(names, ", ") or nil
end

function ns.IsMyClass(q)
    if not q.classes then return true end
    local _, mine = UnitClass("player")
    for _, token in ipairs(q.classes) do
        if token == mine then return true end
    end
    return false
end

-- Ya no se puede hacer: q.lostIf es la mision que la cierra al entregarla sin hacer esta
function ns.IsQuestLost(id)
    local q = ns.Quests[id]
    return q ~= nil and q.lostIf ~= nil and IsCompleted(q.lostIf) and not IsCompleted(id) and not IsInLog(id)
end

-- Devuelve el estado y, si esta bloqueada, el motivo
function ns.QuestStatus(id)
    if IsCompleted(id) then return ns.STATUS_COMPLETED end
    if IsInLog(id) then return IsReady(id) and ns.STATUS_READY or ns.STATUS_IN_LOG end
    local q = ns.Quests[id] or {}
    if ns.IsQuestLost(id) then return ns.STATUS_BLOCKED, L.BLOCKED_LOST end
    if not ns.IsMyClass(q) then return ns.STATUS_BLOCKED, L.BLOCKED_CLASS:format(ns.ClassNames(q)) end
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
        if ns.MatchesFaction(q, faction) and not (hideCompleted and IsCompleted(id))
            and not (ns.db.hideOtherClasses and not ns.IsMyClass(q)) then
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

-- "3/7 completadas", contando solo las de la faccion y las de tu clase (una de
-- brujo no cuenta si no eres brujo: no la puedes hacer). Lo usan la lista, la
-- cabecera del libro y el "pendientes" del minimapa.
function ns.DungeonProgress(d, faction)
    local done, total = 0, 0
    for _, id in ipairs(d.quests) do
        local q = ns.Quests[id] or {}
        if ns.MatchesFaction(q, faction) and ns.IsMyClass(q) and not ns.IsQuestLost(id) then
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

-- Atajos del buscador y de /dqa <atajo> (las claves de Data/Dungeons.lua ya valen:
-- rfk, sfk, brd...). Un atajo puede dar varias alas.
local ALIASES = {
    stocks = { "STOCKS" }, stockade = { "STOCKS" }, gnomer = { "GNOMER" }, gnomeregan = { "GNOMER" },
    vc = { "DM" }, deadmines = { "DM" }, wailing = { "WC" }, ulda = { "ULDA" }, uldaman = { "ULDA" },
    zf = { "ZF" }, mara = { "MARA" }, sunken = { "ST" }, scholo = { "SCHOLO" }, scholomance = { "SCHOLO" },
    strat = { "STRAT_LIVE", "STRAT_UD" }, stratlive = { "STRAT_LIVE" }, stratud = { "STRAT_UD" },
    sm = { "SM_GY", "SM_LIB", "SM_ARM", "SM_CATH" }, smgy = { "SM_GY" }, gy = { "SM_GY" },
    smlib = { "SM_LIB" }, lib = { "SM_LIB" }, smarm = { "SM_ARM" }, arm = { "SM_ARM" },
    smcath = { "SM_CATH" }, cath = { "SM_CATH" },
    diremaul = { "DM_E", "DM_W", "DM_N" }, dme = { "DM_E" }, dmw = { "DM_W" }, dmn = { "DM_N" },
    dala = { "DALARAN" }, dalaran = { "DALARAN" }, exca = { "EXCAVATION" }, thanes = { "THANES" },
    ruins = { "LORDAERON" }, rol = { "LORDAERON" }, drowned = { "DROWNED" }, kroldok = { "KROLDOK" },
    alcaz = { "ALCAZ" }, blackmaw = { "BLACKMAW" }, shapers = { "SHAPERS" },
}

-- Atajo o clave -> lista de mazmorras (nil si no es ninguno)
function ns.DungeonsByAlias(text)
    text = (text or ""):lower()
    local keys = ALIASES[text] or (ns.DungeonByKey[text:upper()] and { text:upper() })
    if not keys then return end
    local list = {}
    for _, key in ipairs(keys) do list[#list + 1] = ns.DungeonByKey[key] end
    return list
end

-- Oculta en la portada: a mano (clic derecho en la tarjeta) o por las opciones
-- de nivel superado y misiones hechas (menu "Ocultas" de la portada)
function ns.IsDungeonHidden(d)
    if ns.char.hiddenDungeons[d.key] then return true end
    if ns.db.hideOutleveled and UnitLevel("player") > d.maxLevel then return true end
    if ns.db.hideDoneDungeons then
        local done, total = ns.DungeonProgress(d, UnitFactionGroup("player"))
        if total > 0 and done == total then return true end
    end
    return false
end

-- filters: { myRange, kind = "all"|"classic"|"forever", faction, search }
function ns.FilterDungeons(filters)
    local level = UnitLevel("player")
    local search = filters.search and filters.search:lower() or ""
    local aliased = ns.DungeonsByAlias(search) or {}
    local list = {}
    filters.hiddenCount = 0
    for _, d in ipairs(ns.Dungeons) do
        local hidden = ns.IsDungeonHidden(d)
        if hidden then filters.hiddenCount = filters.hiddenCount + 1 end
        local ok = (not hidden or filters.showHidden) and (not filters.myRange or ns.InRange(d, level))
            and (filters.kind ~= "classic" or not d.isForever)
            and (filters.kind ~= "forever" or d.isForever)
            and ns.MatchesFaction(d, filters.faction)
        if ok and search ~= "" then
            ok = ns.DungeonName(d):lower():find(search, 1, true) ~= nil
                or d.name:lower():find(search, 1, true) ~= nil
                or tContains(aliased, d)
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
