local _, ns = ...
local L = ns.L

-- ==========================================
-- RECOLECTOR
-- ==========================================
-- Fuente principal de datos: lo que el propio juego ensena. El juego solo da el
-- texto de una mision cuando un PNJ te la ofrece o cuando la llevas, asi que se
-- guarda siempre, sin activar nada: al ofrecertela (QUEST_DETAIL) y desde tu
-- registro (al cogerla y al entrar al juego). Con /dqa collect on, ademas, el PNJ,
-- el mapa y tu posicion de todas las misiones, para /dqa export. /dqa entrance <clave> guarda la entrada de una mazmorra. Todo se usa
-- al momento y /dqa export lo saca como tabla Lua para pegarlo en Data/.
-- Se guardan todas las misiones, no solo las conocidas: asi salen tambien las
-- de las mazmorras nuevas de Forever, cuyos IDs aun no estan en Data/.

local function Round(v)
    return math.floor(v * 1000 + 0.5) / 10 -- 0-1 -> 0-100 con un decimal
end

-- Posicion actual: { mapID, x, y } en 0-100, o nil (dentro de instancias no hay)
function ns.PlayerPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end
    local x, y = pos:GetXY()
    if not x or (x == 0 and y == 0) then return nil end
    return { mapID = mapID, x = Round(x), y = Round(y) }
end

-- "Creature-0-1-2-3-<npcID>-<spawn>" -> npcID
function ns.NpcIDFromGUID(guid)
    if not guid or (issecretvalue and issecretvalue(guid)) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

local function Stamp(entry)
    local version, build = GetBuildInfo()
    entry.build = version .. "." .. build
    entry.date = date("%Y-%m-%d")
    return entry
end

-- El PNJ con el que hablas y tu posicion (pegada a la suya)
local function NpcHere()
    local npcID = ns.NpcIDFromGUID(UnitGUID("npc"))
    local pos = ns.PlayerPosition()
    if npcID and pos then
        return { npcID = npcID, name = UnitName("npc"), mapID = pos.mapID, x = pos.x, y = pos.y }
    end
end

local function RewardItems()
    local items = {}
    for _, kind in ipairs({ "choice", "reward" }) do
        local count = kind == "choice" and GetNumQuestChoices() or GetNumQuestRewards()
        for i = 1, count or 0 do
            local link = GetQuestItemLink(kind, i)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id then items[#items + 1] = id end
        end
    end
    return #items > 0 and items or nil
end

-- full: modo recolector (todas las misiones, con PNJ y posicion, y aviso en el
-- chat). Sin el, solo el texto de las misiones del addon y en silencio.
function ns.CollectQuestDetail(full)
    local id = GetQuestID()
    if not id or id == 0 then return end
    if not full and not ns.Quests[id] then return end
    local db = DungeonQuestAtlasCollectorDB.quests
    local entry = db[id] or {}
    entry.text = entry.text or {}
    entry.text[ns.LOCALE] = {
        title = GetTitleText(),
        desc = GetQuestText(),
        obj = GetObjectiveText(),
        giverName = UnitExists("npc") and UnitName("npc") or nil,
    }
    if full then
        entry.giver = NpcHere() or entry.giver
        entry.rewards = RewardItems() or entry.rewards
    end
    db[id] = Stamp(entry)
    ns.Debug("QUEST_DETAIL %d giver=%s", id, entry.giver and tostring(entry.giver.npcID) or "-")
    if full then ns.Print(L.COLLECTED:format(entry.text[ns.LOCALE].title or "?", id)) end
    ns.RequestRefresh()
end

-- Texto de una mision que llevas, desde el registro del juego (se elige un
-- momento y se vuelve a la que estaba elegida). Devuelve true si la guarda.
function ns.CollectFromLog(id)
    local log = C_QuestLog
    if not (log and log.GetLogIndexForQuestID and log.GetLogIndexForQuestID(id)
        and log.SetSelectedQuest and GetQuestLogQuestText) then return false end
    local previous = log.GetSelectedQuest and log.GetSelectedQuest()
    log.SetSelectedQuest(id)
    local desc, obj = GetQuestLogQuestText()
    if previous and previous ~= id then log.SetSelectedQuest(previous) end
    desc = ns.PlainText(desc)
    if type(desc) ~= "string" or desc == "" then return false end
    local db = DungeonQuestAtlasCollectorDB.quests
    local entry = db[id] or {}
    entry.text = entry.text or {}
    local text = entry.text[ns.LOCALE] or {}
    text.title = text.title or (log.GetTitleForQuestID and log.GetTitleForQuestID(id)) or nil
    text.desc, text.obj = desc, ns.PlainText(obj) or text.obj
    entry.text[ns.LOCALE] = text
    db[id] = Stamp(entry)
    ns.Debug("texto de %d desde el registro", id)
    return true
end

-- Todas las misiones del addon que llevas y aun no tienen texto
function ns.CollectLog()
    local log = C_QuestLog
    if not (log and log.GetNumQuestLogEntries and log.GetInfo) then return end
    local saved = false
    for i = 1, log.GetNumQuestLogEntries() do
        local info = log.GetInfo(i)
        local id = info and not info.isHeader and info.questID
        if id and ns.Quests[id] and not ns.QuestText(id).desc then
            saved = ns.CollectFromLog(id) or saved
        end
    end
    if saved then ns.RequestRefresh() end
end

-- QUEST_COMPLETE: el PNJ con el que se entrega
function ns.CollectQuestEnder()
    local id = GetQuestID()
    local ender = id and id ~= 0 and NpcHere()
    if not ender then return end
    local db = DungeonQuestAtlasCollectorDB.quests
    db[id] = db[id] or {}
    db[id].ender = ender
    Stamp(db[id])
    ns.Debug("QUEST_COMPLETE %d ender=%d", id, ender.npcID)
    ns.RequestRefresh()
end

function ns.SaveEntrance(key)
    local d = ns.DungeonByKey[(key or ""):upper()]
    if not d then
        local keys = {}
        for _, dungeon in ipairs(ns.Dungeons) do keys[#keys + 1] = dungeon.key end
        ns.Print(L.ENTRANCE_UNKNOWN_KEY:format(key or "", table.concat(keys, ", ")))
        return
    end
    local pos = ns.PlayerPosition()
    if not pos then
        ns.Print(L.ENTRANCE_NO_POS)
        return
    end
    DungeonQuestAtlasCollectorDB.entrances[d.key] = Stamp(pos)
    ns.Print(L.ENTRANCE_SAVED:format(ns.DungeonName(d), ns.ZoneName(pos.mapID) .. " " .. ns.FormatCoords(pos)))
    ns.RequestRefresh()
end

-- /dqa route <clave>: tu posicion es la siguiente parada de la ruta a esa
-- mazmorra (para tu faccion). /dqa route <clave> clear la borra. Las rutas se
-- graban andando: no se inventan caminos.
function ns.SaveRouteStop(arg)
    local key, clear = (arg or ""):match("^(%S*)%s*(%S*)")
    local d = ns.DungeonByKey[key:upper()]
    if not d then
        local keys = {}
        for _, dungeon in ipairs(ns.Dungeons) do keys[#keys + 1] = dungeon.key end
        ns.Print(L.ENTRANCE_UNKNOWN_KEY:format(key, table.concat(keys, ", ")))
        return
    end
    local faction = UnitFactionGroup("player")
    local routes = DungeonQuestAtlasCollectorDB.routes
    routes[d.key] = routes[d.key] or {}
    if clear:lower() == "clear" then
        routes[d.key][faction] = nil
        ns.Print(L.ROUTE_CLEARED:format(ns.DungeonName(d)))
        ns.RequestRefresh()
        return
    end
    local pos = ns.PlayerPosition()
    if not pos then
        ns.Print(L.ENTRANCE_NO_POS)
        return
    end
    local stops = routes[d.key][faction] or {}
    routes[d.key][faction] = stops
    stops[#stops + 1] = pos
    ns.Print(L.ROUTE_SAVED:format(#stops, ns.DungeonName(d), ns.ZoneName(pos.mapID) .. " " .. ns.FormatCoords(pos)))
    ns.RequestRefresh()
end

-- ==========================================
-- EXPORTAR
-- ==========================================

-- Valor -> literal Lua, con las claves ordenadas para que los diff sean limpios
function ns.Serialize(value, indent)
    indent = indent or ""
    local kind = type(value)
    if kind == "string" then return ("%q"):format(value) end
    if kind ~= "table" then return tostring(value) end
    local keys = {}
    for k in pairs(value) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    local inner, lines = indent .. "    ", {}
    for _, k in ipairs(keys) do
        local key = type(k) == "number" and ("[" .. k .. "]")
            or (k:match("^[%a_][%w_]*$") and k or ("[" .. ("%q"):format(k) .. "]"))
        lines[#lines + 1] = inner .. key .. " = " .. ns.Serialize(value[k], inner) .. ","
    end
    if #lines == 0 then return "{}" end
    return "{\n" .. table.concat(lines, "\n") .. "\n" .. indent .. "}"
end

-- quests[id].giver -> Data/Quests.lua, quests[id].text[locale] -> Data/QuestText.lua,
-- entrances[key] y routes[key][faccion] -> Data/Dungeons.lua
function ns.BuildExport()
    local db = DungeonQuestAtlasCollectorDB
    if not (next(db.quests) or next(db.entrances) or next(db.routes or {})) then return nil end
    return "-- Dungeon Quest Atlas: " .. date("%Y-%m-%d") .. " " .. GetLocale() .. "\n"
        .. "return " .. ns.Serialize({ quests = db.quests, entrances = db.entrances, routes = db.routes })
end

function ns.ShowExport()
    local text = ns.BuildExport()
    if not text then
        ns.Print(L.EXPORT_EMPTY)
        return
    end
    ns.ShowCopyDialog(L.EXPORT_TITLE, text)
end
