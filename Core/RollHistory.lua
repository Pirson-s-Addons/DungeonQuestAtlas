local _, ns = ...

-- ==========================================
-- HISTORIAL DE TIRADAS (como el "Loot Rolls" del juego antiguo)
-- ==========================================
-- Cada objeto que sale a tirada, dentro o fuera de una mazmorra: lo que eligio cada uno
-- (Necesidad, Codicia, Desencantar o Pasar), el numero que saco y quien lo gano. Sale del
-- chat de botin, en el idioma del cliente (ns.RollPattern, Core/RunLog.lua). Se guarda por
-- personaje (ns.char.rollHistory, el mas nuevo el primero). Al salir el objeto se apunta
-- tambien a quien mejoraba (Core/Upgrades.lua): asi se ve quien lo pidio sin necesitarlo.
-- La ventana es UI/RollHistory.lua.

local MAX_ITEMS = 50
local KEEP_OPEN = 10 * 60 -- segundos: un mensaje de un objeto mas viejo empieza otra entrada

local function Now() return GetServerTime and GetServerTime() or time() end
local function ItemIDOf(link) return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil end

-- Nombre corto (sin reino ni apellido) para cruzar el chat con las unidades del grupo
local function Short(name) return type(name) == "string" and name:match("^[^%s%-]+") or name end
ns.RollShortName = Short

local function List()
    if not ns.char then return end
    ns.char.rollHistory = ns.char.rollHistory or {}
    return ns.char.rollHistory
end

local function Changed()
    if ns.RefreshRollHistory then ns.RefreshRollHistory() end
end

-- A quien mejoraba: { [nombre corto] = % (o false si no), ... } solo de quien se sabe
local function UpgradeSnapshot(link)
    if not (ns.db and ns.db.rollAdvisor and ns.UpgradeAdvice) then return end
    local ok, advice = pcall(ns.UpgradeAdvice, link)
    if not ok then return end
    local up = {}
    local function Put(name, result)
        if name and result then up[Short(name)] = (ns.IsUpgrade(result) and math.floor(result.pct + 0.5)) or false end
    end
    Put(ns.UnitFullName("player"), advice.me)
    for _, m in ipairs(advice.members) do Put(m.name, m.result) end
    return up
end

-- La entrada abierta de ese objeto (o una nueva)
local function EntryFor(id, link, rollID)
    local list = List()
    if not list then return end
    for _, e in ipairs(list) do
        if (rollID and e.rollID == rollID) or (not rollID and e.id == id and not e.done and Now() - e.at < KEEP_OPEN) then
            return e
        end
    end
    local e = { id = id, link = link, at = Now(), rollID = rollID, rolls = {} }
    table.insert(list, 1, e)
    while #list > MAX_ITEMS do table.remove(list) end
    return e
end

-- Por nombre corto: tus "You have selected..." y el "... by Pirson" de tu tirada son la misma fila
local function Roll(e, who)
    for _, r in ipairs(e.rolls) do
        if Short(r.who) == Short(who) then
            if #who > #r.who then r.who = who end
            return r
        end
    end
    local ok, _, class = pcall(UnitClass, Short(who)) -- con el nombre: vale para los del grupo
    local r = { who = who, class = ok and ns.PlainText(class) or nil }
    e.rolls[#e.rolls + 1] = r
    return r
end

local function OnStart(rollID)
    local ok, link = pcall(GetLootRollItemLink, rollID)
    link = ok and ns.PlainText(link)
    local id = ItemIDOf(link)
    if not id then return end
    local e = EntryFor(id, link, rollID)
    local run = ns.RunActive and ns.RunActive()
    local function Snapshot()
        e.up = UpgradeSnapshot(link)
        -- Tambien en la partida, para el historial de partidas
        if run and e.up then
            run.upgrades = run.upgrades or {}
            run.upgrades[id] = e.up
        end
        Changed()
    end
    Snapshot()
    -- El objeto puede no estar aun en la cache del cliente: otra vez cuando llegue
    if not (e.up and next(e.up)) and C_Timer then C_Timer.After(2, Snapshot) end
end

-- Formato del juego -> { tipo, posicion de la tirada, del objeto, del jugador } (sin jugador: tu).
-- Los tuyos, "todos pasan" y el bonus de rol antes que los generales: "You passed on: %s" tambien
-- encaja en "%s passed on: %s".
local MESSAGES = {
    { "LOOT_ROLL_ALL_PASSED", "allpass", nil, 1 },
    { "LOOT_ROLL_NEED_SELF", "need", nil, 1 },
    { "LOOT_ROLL_GREED_SELF", "greed", nil, 1 },
    { "LOOT_ROLL_DISENCHANT_SELF", "disenchant", nil, 1 },
    { "LOOT_ROLL_PASSED_SELF_AUTO", "pass", nil, 1 },
    { "LOOT_ROLL_PASSED_SELF", "pass", nil, 1 },
    { "LOOT_ROLL_YOU_WON", "won", nil, 1 },
    { "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS", "need", 1, 3, 4 },
    { "LOOT_ROLL_ROLLED_NEED", "need", 1, 2, 3 },
    { "LOOT_ROLL_ROLLED_GREED", "greed", 1, 2, 3 },
    { "LOOT_ROLL_ROLLED_DE", "disenchant", 1, 2, 3 },
    { "LOOT_ROLL_NEED", "need", nil, 2, 1 },
    { "LOOT_ROLL_GREED", "greed", nil, 2, 1 },
    { "LOOT_ROLL_DISENCHANT", "disenchant", nil, 2, 1 },
    { "LOOT_ROLL_PASSED_AUTO", "pass", nil, 2, 1 },
    { "LOOT_ROLL_PASSED_AUTO_FEMALE", "pass", nil, 2, 1 },
    { "LOOT_ROLL_PASSED", "pass", nil, 2, 1 },
    { "LOOT_ROLL_WON", "won", nil, 2, 1 },
}

-- Un mensaje del chat de botin (tambien para los tests). true si era de tiradas.
function ns.RollHistoryMessage(message)
    local raw = message
    message = ns.PlainText(message)
    if raw ~= nil and message == nil then ns.Debug("botin: linea secreta, no se puede leer") end
    if type(message) ~= "string" or not ns.RollPattern then return end
    for _, def in ipairs(MESSAGES) do
        local pattern, order = ns.RollPattern(_G[def[1]])
        local caps = pattern and ns.MatchLootLine(pattern, message)
        if caps then
            local args = {}
            for k, v in ipairs(caps) do args[order[k]] = v end
            local link = args[def[4]]
            local id = ItemIDOf(link)
            if not id then return true end
            local e = EntryFor(id, link)
            if not e then return true end
            local kind = def[2]
            if kind == "allpass" then
                e.done, e.allPassed = true, true
            else
                local who = def[5] and args[def[5]] or ns.UnitFullName("player")
                local r = Roll(e, who)
                if kind == "won" then
                    r.won, e.done, e.winner = true, true, who
                else
                    r.kind = kind
                    if def[3] then r.roll = tonumber(args[def[3]]) end
                end
            end
            Changed()
            return true
        end
    end
    -- Con /dqa debug, la linea que no caso, con los codigos a la vista: su forma real en el juego
    ns.Debug("botin sin casar: %s", (message:gsub("|", "||")))
end

-- Pidio con Necesidad algo que no le mejoraba mientras a otro si: devuelve "Nombre (+22%), ..." o nil
function ns.NeedWithoutUpgrade(up, who)
    if type(up) ~= "table" then return end
    if up[Short(who)] ~= false then return end -- le mejoraba o no se sabe
    local others = {}
    for name, pct in pairs(up) do
        if pct then others[#others + 1] = { name = name, pct = pct } end
    end
    if #others == 0 then return end
    table.sort(others, function(a, b) return a.pct > b.pct end)
    for i, o in ipairs(others) do others[i] = ("%s (+%d%%)"):format(o.name, o.pct) end
    return table.concat(others, ", ")
end

-- ------------------------------------------
-- Historial de botin del juego (C_LootHistory)
-- ------------------------------------------
-- Dentro de las mazmorras el chat llega secreto a los addons: las lineas de tirada no se
-- pueden leer. El historial de botin del juego (el de la etiqueta [Botin] del chat) da cada
-- objeto con la tirada de cada jugador, y su evento no pasa por el chat. Es la fuente
-- principal; el chat queda para cuando no este.

local STATE = { [0] = "need", [1] = "need", [2] = "greed", [3] = "greed", [5] = "pass" } -- 4: aun no ha elegido

function ns.RollHistoryDrop(encounterID, lootListKey)
    local get = C_LootHistory and C_LootHistory.GetSortedInfoForDrop
    if not get then return end
    local ok, info = pcall(get, encounterID, lootListKey)
    if not (ok and type(info) == "table") then return end
    local link = ns.PlainText(info.itemHyperlink)
    local id = ItemIDOf(link)
    if not id then return end
    local key = tostring(encounterID) .. ":" .. tostring(lootListKey)
    local list, e = List(), nil
    for _, entry in ipairs(list or {}) do
        if entry.lootKey == key then e = entry break end
    end
    -- La entrada que abrio la tirada (START_LOOT_ROLL), sin otra copia ya enlazada, o una nueva
    if not e then
        for i = #(list or {}), 1, -1 do -- la mas vieja primero: las copias salen en orden
            local entry = list[i]
            if entry.id == id and not entry.lootKey and Now() - entry.at < KEEP_OPEN then e = entry break end
        end
    end
    e = e or EntryFor(id, link)
    if not e then return end
    e.lootKey, e.link = key, e.link or link
    local rolls, won = {}, {}
    for _, r in ipairs(info.rollInfos or {}) do
        local who = ns.PlainText(r.playerName)
        local kind = STATE[ns.PlainText(r.state)]
        if who and kind then
            local row = { who = who, class = ns.PlainText(r.playerClass), kind = kind, roll = ns.PlainText(r.roll) }
            if ns.PlainText(r.isWinner) then row.won, e.done, e.winner = true, true, who end
            rolls[#rolls + 1] = row
            if kind ~= "pass" and row.roll then won[#won + 1] = { who = who, roll = row.roll, kind = kind } end
        end
    end
    if #rolls > 0 then e.rolls = rolls end
    if ns.PlainText(info.allPassed) then e.done, e.allPassed = true, true end
    -- Tambien en la partida (tooltip "Tiradas de todos:" del historial de partidas)
    local run = ns.RunActive and ns.RunActive()
    if run and #won > 0 then
        run.rolls = run.rolls or {}
        run.rolls[id] = won
    end
    Changed()
    return e
end

local function OnEncounter(encounterID)
    local get = C_LootHistory and C_LootHistory.GetSortedDropsForEncounter
    local ok, drops = pcall(get or error, encounterID)
    if not (ok and type(drops) == "table") then return end
    for _, drop in ipairs(drops) do
        local key = ns.PlainText(drop.lootListKey)
        if key then ns.RollHistoryDrop(encounterID, key) end
    end
end

-- Todo lo que el juego guarda de esta sesion (al abrir la ventana: rellena las ya tiradas)
function ns.SyncLootHistory()
    local all = C_LootHistory and C_LootHistory.GetAllEncounterInfos
    local ok, infos = pcall(all or error)
    if not (ok and type(infos) == "table") then return end
    for _, info in ipairs(infos) do
        local id = ns.PlainText(info.encounterID)
        if id then OnEncounter(id) end
    end
end

local frame = CreateFrame("Frame")
local EVENTS = {
    START_LOOT_ROLL = OnStart,
    CHAT_MSG_LOOT = ns.RollHistoryMessage,
    LOOT_HISTORY_UPDATE_DROP = ns.RollHistoryDrop,
    LOOT_HISTORY_UPDATE_ENCOUNTER = OnEncounter,
}
frame:SetScript("OnEvent", function(_, event, ...) if ns.char then EVENTS[event](...) end end)
for event in pairs(EVENTS) do pcall(frame.RegisterEvent, frame, event) end
