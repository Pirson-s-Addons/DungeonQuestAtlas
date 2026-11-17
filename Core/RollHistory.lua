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
    message = ns.PlainText(message)
    if type(message) ~= "string" or not ns.RollPattern then return end
    for _, def in ipairs(MESSAGES) do
        local pattern, order = ns.RollPattern(_G[def[1]])
        local caps = pattern and { message:match(pattern) }
        if caps and caps[1] then
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

local frame = CreateFrame("Frame")
local EVENTS = {
    START_LOOT_ROLL = OnStart,
    CHAT_MSG_LOOT = ns.RollHistoryMessage,
}
frame:SetScript("OnEvent", function(_, event, ...) if ns.char then EVENTS[event](...) end end)
for event in pairs(EVENTS) do pcall(frame.RegisterEvent, frame, event) end
