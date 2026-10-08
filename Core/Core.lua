-- Dungeon Quest Atlas Forever: todas las misiones de mazmorra de WoW Forever
-- en una ventana estilo AtlasLoot, con su texto, el PNJ que las da, pines en el
-- mapa y la entrada de cada instancia.
--
-- Este fichero: base de datos guardada, acceso a los datos, eventos y /dqa.
-- Forever usa la API moderna (como Retail 12.x) y WOW_PROJECT_ID == 1, asi que
-- nada se decide por WOW_PROJECT_ID: cada API se comprueba antes de usarla.

local ADDON_NAME, ns = ...
local L = ns.L

DungeonQuestAtlas = ns -- objeto global del addon (para otros addons y /dump)

local DB_VERSION = 4
local DEFAULTS = {
    minimap = { hide = false },
    scale = 1,
    hideCompleted = false,
    hideOtherClasses = false, -- ocultar las misiones de clase que no son de la tuya
    chainGuide = true,    -- al entregar un paso de una cadena, marcar el inicio del siguiente
    autoFaction = true,
    waypointMode = "own", -- "own" (flecha y marcadores del addon), "native" (pin del juego), "tomtom"
    arrow = {},           -- posicion de la flecha
    pinSize = 20,         -- tamano del marcador en el mapa y el minimapa (px)
    wowheadLang = "auto", -- "auto" (idioma del cliente) o "en"
    language = "auto",    -- idioma de la ventana: "auto" (el del juego) o "deDE", "enUS"...
    collect = false,
    debug = false,
    window = {},
}
local CHAR_DEFAULTS = { dungeon = nil, view = "home", tab = "quests", markers = {}, target = nil,
    kills = {}, runs = {}, left = {}, done = {} } -- jefes muertos (Core/BossKills.lua): por mazmorra,
    -- copia de la instancia, cuando saliste de ella y cuando murio el ultimo jefe
ns.DEFAULTS = DEFAULTS

ns.PREFIX = "|cffd597ffDungeon Quest Atlas|r: "
ns.LOCALE = GetLocale() == "esMX" and "esES" or GetLocale()

-- ==========================================
-- IDIOMA DE LA VENTANA
-- ==========================================
-- Por defecto el del juego; se puede elegir otro desde la ventana. Solo cambian
-- los textos del addon: nombres de misiones, PNJ, zonas y objetos los da el
-- juego en su idioma. Cada idioma con su nombre en ese idioma.
ns.LANGUAGES = {
    { "enUS", "English" }, { "esES", "Español" }, { "deDE", "Deutsch" }, { "frFR", "Français" },
    { "itIT", "Italiano" }, { "ptBR", "Português" }, { "ruRU", "Русский" }, { "plPL", "Polski" },
    { "csCZ", "Čeština" }, { "svSE", "Svenska" }, { "noNO", "Norsk" }, { "trTR", "Türkçe" },
    { "koKR", "한국어" }, { "zhCN", "简体中文" }, { "zhTW", "繁體中文" }, { "jaJP", "日本語" },
    { "arSA", "العربية" }, { "hiIN", "हिन्दी" }, { "thTH", "ไทย" }, { "viVN", "Tiếng Việt" },
}

-- code: "enUS", "deDE"...; nil o "auto" = el del juego. Rellena L (la misma
-- tabla que ya tienen todos los ficheros) con el ingles y encima ese idioma.
function ns.ApplyLanguage(code)
    if not (code and ns.LOCALES[code]) then code = GetLocale() end
    -- Idioma de la ventana, como los guarda el addon (esMX -> esES, enGB -> enUS)
    ns.UILANG = code == "esMX" and "esES" or code == "enGB" and "enUS" or code
    for key in pairs(L) do L[key] = nil end
    for key, text in pairs(ns.LOCALES.enUS) do L[key] = text end
    for key, text in pairs(ns.LOCALES[code] or {}) do L[key] = text end
end
ns.ApplyLanguage() -- el del juego mientras no se lean las opciones guardadas

function ns.Print(msg)
    print(ns.PREFIX .. msg)
end

function ns.Debug(fmt, ...)
    if ns.db and ns.db.debug then print("|cff888888[DQA]|r " .. fmt:format(...)) end
end

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

-- Migraciones: cada salto de dbVersion anade aqui su paso
function ns.MigrateDB(db, defaults)
    db = db or {}
    local v = db.dbVersion or DB_VERSION
    if v < 2 and db.preferTomTom ~= nil then
        -- v2: "Preferir TomTom" pasa a ser el modo de guia; por defecto, la propia
        db.waypointMode = db.preferTomTom and "tomtom" or "own"
        db.preferTomTom = nil
    end
    db = CopyDefaults(defaults, db)
    -- v3/v4: el marcador de 16 px casi no se veia y el de 26 era grande; 20 por defecto
    if v < 4 and (db.pinSize == 16 or db.pinSize == 26) then db.pinSize = 20 end
    db.dbVersion = DB_VERSION
    return db
end

-- En su sitio: LibDBIcon guarda la referencia a db.minimap
function ns.ResetOptions()
    for k, v in pairs(DEFAULTS) do
        if type(v) ~= "table" then ns.db[k] = v end
    end
    ns.db.minimap.hide = false
end

-- ==========================================
-- DATOS
-- ==========================================
-- Mazmorras ordenadas por nivel minimo; cada mision sabe en que mazmorras esta.

local function IndexData()
    table.sort(ns.Dungeons, function(a, b)
        if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
        return a.maxLevel < b.maxLevel
    end)
    ns.DungeonByKey = {}
    for _, d in ipairs(ns.Dungeons) do ns.DungeonByKey[d.key] = d end
    -- chain = { paso1, paso2, ... } (Wowhead): los pasos de antes son requisitos
    for id, q in pairs(ns.Quests) do
        if type(q.chain) == "table" then
            q.prereqs = {}
            for _, step in ipairs(q.chain) do
                if step == id then break end
                q.prereqs[#q.prereqs + 1] = step
            end
        end
    end
end
IndexData()

local function Collected()
    return DungeonQuestAtlasCollectorDB or {}
end

-- Nombre en el idioma del cliente: lo da el juego si se conoce la instancia.
-- Con la ventana en ingles, el de los datos (ya esta en ingles).
function ns.DungeonName(d)
    if ns.UILANG == "enUS" then return d.name end
    local name = d.instanceID and GetRealZoneText and GetRealZoneText(d.instanceID)
    if not name or name == "" then return d.name end -- el ingles ya lleva "Lower"/"Upper"
    if d.part then name = name .. " (" .. L[d.part] .. ")" end
    return name
end

-- Texto de mision: lo recogido en este cliente, luego Data/QuestText.lua
function ns.QuestText(id)
    local mine = Collected().quests and Collected().quests[id]
    local texts = mine and mine.text or {}
    -- Primero en el idioma de la ventana (si se ha recogido), luego en el del juego
    local chosen = ns.QuestTextData.byLocale[ns.UILANG or ns.LOCALE]
    return texts[ns.UILANG] or (chosen and chosen[id]) or texts[ns.LOCALE] or ns.QuestTextData.active[id]
        or ns.QuestTextData.fallback[id] or {}
end

local requested = {}
function ns.QuestTitle(id)
    local text = ns.QuestText(id)
    if text.title then return text.title end
    local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(id)
    if title and title ~= "" then return title end
    -- El servidor aun no lo ha mandado: se pide y QUEST_DATA_LOAD_RESULT refresca
    if not requested[id] and C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        requested[id] = true
        C_QuestLog.RequestLoadQuestByID(id)
    end
    return L.QUEST_FALLBACK:format(id)
end

-- Objetivos: lo recogido; si no, el tooltip de la mision que da el juego (en
-- su idioma, sin la linea del titulo); si el juego aun no la tiene, nil.
function ns.QuestObjective(id)
    local text = ns.QuestText(id)
    if text.obj then return text.obj end
    local info = C_TooltipInfo and C_TooltipInfo.GetHyperlink and C_TooltipInfo.GetHyperlink("quest:" .. id)
    local lines = {}
    for i, line in ipairs(info and info.lines or {}) do
        local left = ns.PlainText(line.leftText)
        -- " - 8 x": el juego aun no tiene el nombre del objetivo; mejor nada
        if i > 1 and left and left ~= "" and not left:find("^%s*%-%s*%d*%s*x?%s*$") then
            lines[#lines + 1] = left
        end
    end
    -- Sin objetivos debajo, "Requisitos:" sobra
    while #lines > 0 and lines[#lines]:find(":%s*$") do lines[#lines] = nil end
    if #lines > 0 then return table.concat(lines, "\n") end
end

-- Recompensas: lo que diga el juego (ya ajustado a tu nivel) o lo observado en Forever
function ns.QuestXP(q, id)
    local xp = GetQuestLogRewardXP and GetQuestLogRewardXP(id)
    if xp and xp > 0 then return xp end
    return q.xp
end

function ns.QuestMoney(q, id)
    local money = GetQuestLogRewardMoney and GetQuestLogRewardMoney(id)
    if money and money > 0 then return money end
    return q.money
end

function ns.QuestLevel(q, id)
    if q.level then return q.level end
    local level = C_QuestLog and C_QuestLog.GetQuestDifficultyLevel and C_QuestLog.GetQuestDifficultyLevel(id)
    if level and level > 0 then return level end
end

-- PNJ u objeto con el que empieza ("starts") o termina ("ends") una mision.
-- Lista de { name, mapID, x, y } (sin mapID: empieza con un objeto del inventario).
-- Orden: lo recogido en el juego, Data/Places.lua (Wowhead Forever), Questie.
function ns.QuestPlaces(id, which)
    local mine = Collected().quests and Collected().quests[id]
    mine = mine and mine[which == "starts" and "giver" or "ender"]
    if mine then return { mine }, true end
    local list = {}
    for _, key in ipairs((ns.Quests[id] or {})[which] or {}) do
        if ns.Places[key] then list[#list + 1] = ns.Places[key] end
    end
    if #list > 0 then return list, false end
    local questie = ns.QuestiePlace and ns.QuestiePlace(id, which)
    return { questie }, false
end

-- Nombre del PNJ en el idioma del cliente (tooltip del juego, si lo tiene en
-- cache); si no, el ingles de Data/Places.lua.
-- Texto del juego que se puede usar. Forever (como Retail 12) marca algunos
-- como "secretos": ni se pueden comparar; se tratan como si no hubiera texto.
function ns.PlainText(value)
    if issecretvalue and issecretvalue(value) then return nil end -- antes de compararlo con nada
    return value
end

local npcNames = {}
function ns.PlaceName(p)
    -- Misiones que empiezan con un objeto: su nombre lo da el juego
    if p.itemID then
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(p.itemID)
        return name or p.name or L.UNKNOWN
    end
    if p.npcID and npcNames[p.npcID] == nil and C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local info = C_TooltipInfo.GetHyperlink(("unit:Creature-0-0-0-0-%d-0000000000"):format(p.npcID))
        local line = info and info.lines and info.lines[1]
        local raw = line and line.leftText
        -- Secreto: false, no se vuelve a pedir. Sin cargar aun: se pide otra vez luego.
        if issecretvalue and issecretvalue(raw) then
            npcNames[p.npcID] = false
        elseif raw and raw ~= "" then
            npcNames[p.npcID] = raw
        end
    end
    return (p.npcID and npcNames[p.npcID]) or p.name or L.UNKNOWN
end

-- Donde esta la entrada: la del mapa del juego, lo recogido o Data/Dungeons.lua
function ns.Entrance(d)
    -- La grabada con /dqa entrance, la exacta de Data/Dungeons.lua y, si no hay,
    -- el icono del mapa del juego (en las de bajo tierra no esta en la puerta)
    local mine = Collected().entrances and Collected().entrances[d.key]
    if mine then return mine, true end
    if d.entrance then return d.entrance, true end
    local game = ns.GameEntrance and ns.GameEntrance(d)
    if game then return game, true end
end

-- Ruta hasta la entrada para tu faccion: la grabada con /dqa route o la de
-- Data/Dungeons.lua (routes = { Alliance = { { mapID, x, y }, ... } }); si no,
-- el punto de vuelo mas cercano a la entrada (ns.FlightRoute). O nil.
function ns.Route(d)
    local faction = UnitFactionGroup("player")
    local mine = Collected().routes and Collected().routes[d.key]
    local stops = (mine and mine[faction]) or (d.routes and d.routes[faction])
    if stops and #stops > 0 then return stops end
    return ns.FlightRoute and ns.FlightRoute(d) -- la de cualquier mazmorra: volar y la entrada
end

-- Wowhead en el idioma del cliente (si lo tiene) o en ingles
local WOWHEAD_LANG = { deDE = "de", esES = "es", esMX = "es", frFR = "fr", itIT = "it", ptBR = "pt",
    ruRU = "ru", koKR = "ko", zhCN = "cn", zhTW = "tw" }
function ns.WowheadURL(id)
    -- En el idioma de la ventana: si has elegido aleman, la pagina en aleman
    local lang = ns.db.wowheadLang ~= "en" and WOWHEAD_LANG[ns.UILANG or GetLocale()]
    return "https://www.wowhead.com/forever/" .. (lang and (lang .. "/") or "") .. "quest=" .. id
end

function ns.IsVerified(id)
    local q = ns.Quests[id]
    local mine = Collected().quests and Collected().quests[id]
    return (q and q.verified) or mine ~= nil
end

-- ==========================================
-- REFRESCO (con throttle)
-- ==========================================
-- QUEST_LOG_UPDATE llega a rafagas: se agrupan en un solo refresco.

local pending = false
function ns.RequestRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        ns.Refresh()
    end)
end

function ns.Refresh()
    if ns.RefreshUI then ns.RefreshUI() end
    if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
end

-- ==========================================
-- EVENTOS
-- ==========================================

local events = {}
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event, ...) events[event](...) end)
local function On(event, fn)
    events[event] = fn
    frame:RegisterEvent(event)
end
ns.On = On

On("PLAYER_LOGIN", function()
    ns.db = ns.MigrateDB(DungeonQuestAtlasDB, DEFAULTS)
    DungeonQuestAtlasDB = ns.db
    ns.char = ns.MigrateDB(DungeonQuestAtlasCharDB, CHAR_DEFAULTS)
    DungeonQuestAtlasCharDB = ns.char
    DungeonQuestAtlasCollectorDB = DungeonQuestAtlasCollectorDB or {}
    DungeonQuestAtlasCollectorDB.quests = DungeonQuestAtlasCollectorDB.quests or {}
    DungeonQuestAtlasCollectorDB.entrances = DungeonQuestAtlasCollectorDB.entrances or {}
    DungeonQuestAtlasCollectorDB.routes = DungeonQuestAtlasCollectorDB.routes or {}

    -- Las opciones del juego, en el idioma del juego (L sigue en el del cliente
    -- aqui); el selector de idioma solo cambia la ventana del addon
    if ns.CreateOptions then ns.CreateOptions() end
    ns.ApplyLanguage(ns.db.language)
    if ns.CreateMinimapButton then ns.CreateMinimapButton() end
    if ns.SetupMapPins then ns.SetupMapPins() end
    if ns.Target() and ns.OnMarkersChanged then ns.OnMarkersChanged() end
    -- Los textos de las misiones que ya llevas (el registro tarda en llenarse)
    if C_Timer then C_Timer.After(5, ns.CollectLog) end
end)

for _, event in ipairs({ "QUEST_REMOVED", "QUEST_LOG_UPDATE",
    "QUEST_DATA_LOAD_RESULT", "ITEM_DATA_LOAD_RESULT", "PLAYER_LEVEL_UP", "GROUP_ROSTER_UPDATE" }) do
    On(event, ns.RequestRefresh)
end

-- Coger una mision: su texto, desde el registro (por si no se vio la oferta)
On("QUEST_ACCEPTED", function(questID)
    if ns.Quests[questID] and not ns.QuestText(questID).desc then ns.CollectFromLog(questID) end
    ns.RequestRefresh()
end)

-- Entregar un paso de una cadena: el inicio del siguiente (Core/Waypoints.lua)
On("QUEST_TURNED_IN", function(questID)
    ns.RequestRefresh()
    ns.GuideNextStep(questID)
end)

On("QUEST_DETAIL", function()
    ns.CollectQuestDetail(ns.db.collect) -- el texto, siempre
    ns.CheckTalkArrival()
end)

-- Ventana de entrega: el PNJ con el que termina
On("QUEST_COMPLETE", function()
    if ns.db.collect then ns.CollectQuestEnder() end
    ns.CheckTalkArrival()
end)

-- Hablar con el PNJ de un marcador lo quita (los de bajo tierra, solo asi)
for _, event in ipairs({ "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_PROGRESS" }) do
    On(event, function() ns.CheckTalkArrival() end) -- Navigation.lua carga despues
end

-- ==========================================
-- COMANDOS
-- ==========================================

local function Help()
    ns.Print(L.COMMANDS)
    for _, entry in ipairs(ns.CommandList()) do print("  |cffffff00" .. entry[1] .. "|r  " .. entry[2]) end
end

function ns.CommandList()
    return {
        { "/dqa", L.CMD_TOGGLE },
        { "/dqa config", L.CMD_CONFIG },
        { "/dqa collect on|off", L.CMD_COLLECT },
        { "/dqa export", L.CMD_EXPORT },
        { "/dqa entrance <key>", L.CMD_ENTRANCE },
        { "/dqa route <key> [clear]", L.CMD_ROUTE },
        { "/dqa clear", L.CMD_CLEAR },
        { "/dqa debug", L.CMD_DEBUG },
    }
end

function ns.HandleCommand(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        ns.ToggleMainFrame()
    elseif cmd == "config" or cmd == "options" then
        ns.OpenOptions()
    elseif cmd == "collect" then
        local arg = rest:lower()
        if arg == "on" or arg == "off" then
            ns.db.collect = arg == "on"
        else
            ns.db.collect = not ns.db.collect
        end
        ns.Print(ns.db.collect and L.COLLECT_ON or L.COLLECT_OFF)
    elseif cmd == "export" then
        ns.ShowExport()
    elseif cmd == "entrance" then
        ns.SaveEntrance((rest:gsub("[\"']", "")))
    elseif cmd == "route" then
        ns.SaveRouteStop(rest)
    elseif cmd == "clear" then
        ns.ClearMarkers()
        ns.Print(L.MARKERS_CLEARED)
    elseif cmd == "debug" then
        ns.db.debug = not ns.db.debug
        ns.Print(ns.db.debug and L.DEBUG_ON or L.DEBUG_OFF)
    else
        Help()
    end
end

SLASH_DUNGEONQUESTATLAS1 = "/dqa"
SLASH_DUNGEONQUESTATLAS2 = "/dungeonquest"
SlashCmdList.DUNGEONQUESTATLAS = ns.HandleCommand
