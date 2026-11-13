local _, ns = ...

-- ==========================================
-- PARTIDAS DE MAZMORRA
-- ==========================================
-- Cada copia de una mazmorra es una partida (ns.char.runLog, la mas nueva la primera):
-- tiempo, XP de los bichos, dinero, muertes, bichos, jefes, botin, grupo y objetos a
-- Necesidad. Empieza con el primer combate dentro, el primer muerto de tu grupo o el primer jefe
-- (un cadaver visto no: los hay de adorno). Salir y volver a la misma copia
-- sigue la misma partida; otra copia (zoneUID del GUID) empieza otra.
-- Forever cierra el registro de combate: los muertos salen de PARTY_KILL, UNIT_DIED
-- (si no llegan secretos), los cadaveres que se ven (Core/BossKills.lua) y los jefes de
-- ns.MarkBossKilled. La XP es la diferencia de UnitXP. Lo secreto se ignora.
-- La ventana en pantalla es UI/RunTracker.lua y el historial UI/RunHistory.lua.

local MAX_RUNS = 100
local RESUME_OPEN, RESUME_DONE = 90 * 60, 20 * 60 -- plazo para volver a la misma partida
local XP_WINDOW = 2       -- segundos: la XP que llega con un muerto es suya
local FIRST_CHIME = 4     -- segundos hasta repetir el aviso de un raro; luego el doble cada vez
local NEED_ROLL = 1       -- RollOnLoot(id, 1): Necesidad

local inside              -- instanceID de la mazmorra en la que estas (o nil)
local checkCopy = false   -- falta mirar si esta copia es la de la partida abierta
local lastZone            -- zoneUID del ultimo PNJ visto en esta visita (la copia en la que estas)
local doubt = false       -- has vuelto tras salir vivo (quiza la reiniciaron): lo decide el primer GUID o el primer combate
local seen, rares, names = {}, {}, {} -- bichos vistos vivos, raros encontrados, npcID -> nombre
local critters = {}       -- npcID de alimanas (nivel 1): ni empiezan la partida ni cuentan
local wing                -- ala (clave) del primer jefe visto en esta visita: SM, La Masacre, Cumbre
local lastKill, pendingXP
local prevXP, prevMax, prevMoney
local ignoreXPUntil = 0   -- la XP de una mision entregada dentro no es de bichos
local preXP, preMoney = 0, 0 -- lo ganado dentro antes de que empiece la partida (el primer muerto se ve tarde)

local function Now() return GetServerTime and GetServerTime() or time() end

local function Log() return ns.char and ns.char.runLog end

local function Active()
    local log = Log()
    local run = log and log[1]
    return run and not run.closed and run or nil
end
ns.RunActive = Active

function ns.RunInside() return inside end

-- Nombre de un PNJ visto dentro, tal como lo da el cliente (o nil)
function ns.RunSeenName(npcID)
    local name = names[npcID]
    return type(name) == "string" and name ~= "" and name or nil
end

local function Changed()
    if ns.RefreshRunTracker then ns.RefreshRunTracker() end
    if ns.RefreshRunHistory then ns.RefreshRunHistory() end
end

local function Same(a, b)
    return type(a) == "string" and type(b) == "string" and a:lower() == b:lower()
end

-- El jefe o raro (de cualquier ala de esta instancia) de ese npcID o nombre
local function BossFor(npcID, name)
    for _, d in ipairs(ns.DungeonsOf(inside)) do
        for _, boss in ipairs(ns.Bosses[d.key] or {}) do
            if (boss.kind == nil or boss.kind == "rare")
                and ((npcID and boss.npcID == npcID) or (name and (Same(name, boss.name) or Same(name, ns.BossName(boss, d))))) then
                return boss, d
            end
        end
    end
end

-- Los jefes de la ventana y del historial: primero los de verdad, luego los raros
function ns.RunBosses(d)
    local bosses, found = {}, {}
    for _, boss in ipairs(ns.Bosses[d.key] or {}) do
        if not boss.faction or boss.faction == UnitFactionGroup("player") then
            if boss.kind == nil then bosses[#bosses + 1] = boss
            elseif boss.kind == "rare" then found[#found + 1] = boss end
        end
    end
    for _, boss in ipairs(found) do bosses[#bosses + 1] = boss end
    return bosses
end

-- Terminada: todos los que salen siempre (ni raros ni invocados) muertos
local function IsDone(run, d)
    local any = false
    for _, boss in ipairs(ns.Bosses[d.key] or {}) do
        if boss.kind == nil and not boss.summon and not boss.optional
            and (not boss.faction or boss.faction == UnitFactionGroup("player")) then
            any = true
            if not run.bosses[boss.name] then return false end
        end
    end
    return any
end

-- Segundos del primer muerto al ultimo jefe (o hasta ahora, si sigue en curso)
function ns.RunDuration(run)
    if not run.first then return 0 end
    local finish = run.finished or (run.closed and (run.last or run.first)) or run.leftAt or Now()
    return math.max(0, finish - run.first)
end

function ns.FormatRunTime(seconds)
    seconds = math.floor(seconds)
    if seconds >= 3600 then
        return ("%d:%02d:%02d"):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
    end
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

function ns.FormatRunMoney(copper)
    return GetMoneyString and GetMoneyString(copper or 0, true) or tostring(copper or 0)
end

function ns.RunIsMaxLevel()
    return GetMaxPlayerLevel ~= nil and UnitLevel("player") >= GetMaxPlayerLevel()
end

local function UpdateParty(run)
    if not run then return end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = ns.PlainText(UnitName(unit))
            local _, class = UnitClass(unit)
            class = ns.PlainText(class)
            if name then run.party[name] = class or run.party[name] or "" end
        end
    end
end

local function Close(run)
    run.closed, run.killed, run.leftAt = true, nil, nil
    for _, need in ipairs(run.needs) do need.base = nil end
    wipe(seen)
    wipe(rares)
    local log = Log()
    if run.trashCount == 0 and next(run.bosses) == nil and log[1] == run then table.remove(log, 1) end
    lastKill = nil
end

local function ResumeLimit(run) return run.finished and RESUME_DONE or RESUME_OPEN end

local function StartRun(zone)
    zone = zone or lastZone -- empezada por el combate: la copia del ultimo PNJ visto
    local d = (wing and ns.DungeonByKey[wing]) or ns.CurrentDungeon()
    if not d then return end
    local run = {
        key = d.key, instance = inside, zone = zone, started = Now(), deaths = 0, xp = 0, money = 0, trashCount = 0,
        outside = 0, trash = {}, bosses = {}, found = {}, loot = {}, needs = {}, party = {}, killed = {},
    }
    run.xp, run.money, preXP, preMoney = preXP, preMoney, 0, 0
    for name in pairs(rares) do run.found[name] = true end
    local log = Log()
    table.insert(log, 1, run)
    while #log > MAX_RUNS do table.remove(log) end
    UpdateParty(run)
    return run
end

-- Vuelta tras salir vivo: misma copia (sigue, sin el tiempo de fuera) u otra (se cierra)
local function Resolve(same)
    doubt = false
    local run = Active()
    if not run then return end
    ns.Debug(same and "partida: misma copia, sigue" or "partida: otra copia, empieza otra")
    if not same then Close(run)
    elseif run.leftAt then run.outside, run.leftAt = run.outside + Now() - run.leftAt, nil end
    Changed()
end

-- Con el primer bicho que se ve al entrar: otra copia cierra la partida abierta
local function CheckCopy(zone)
    if not zone then return end
    lastZone = zone
    local run = Active()
    if run and run.instance == inside and not run.zone and not doubt then run.zone = zone end
    if not checkCopy then return end
    checkCopy = false
    if not (run and run.instance == inside and run.zone) then return end
    if run.zone ~= zone then
        Close(run)
        doubt = false
        Changed()
    elseif doubt then
        Resolve(true)
    end
end

local function AddKill(npcID, spawn, zone)
    if doubt then Resolve(false) end -- sin GUID que diga que es la misma copia
    local run = Active()
    if not run then run = StartRun(zone) end
    if not run then return end
    run.zone = run.zone or zone
    local key = npcID .. ":" .. tostring(spawn)
    if run.killed[key] then return end
    run.killed[key] = true
    local now = Now()
    run.first, run.last = run.first or now, now
    local name = names[npcID]
    if BossFor(npcID, name) then return Changed() end -- los jefes van por ns.RunLogBossKilled
    name = name or "?"
    local entry = run.trash[name] or { n = 0, xp = 0 }
    run.trash[name] = entry
    entry.n = entry.n + 1
    run.trashCount = run.trashCount + 1
    lastKill = { entry = entry, at = GetTime() }
    if pendingXP and GetTime() - pendingXP.at <= XP_WINDOW then -- la XP llego antes que el aviso (ya en run.xp)
        entry.xp = entry.xp + pendingXP.amount
    end
    pendingXP = nil
    Changed()
end

-- Lo llama ns.MarkBossKilled con cada jefe nuevo muerto
function ns.RunLogBossKilled(d, boss)
    if not inside then return end
    if doubt then Resolve(false) end
    local run = Active() or StartRun()
    if not run then return end
    if next(run.bosses) == nil then run.key = d.key end -- alas: la del primer jefe
    local now = Now()
    run.bosses[boss.name], run.first, run.last, run.lastBoss = now, run.first or now, now, boss.name
    run.found[boss.name] = true
    rares[boss.name] = nil
    if not run.finished and IsDone(run, d) then run.finished = now end
    Changed()
end

-- ------------------------------------------
-- Raros
-- ------------------------------------------

local function Chime()
    if ns.db.rareChime and PlaySound and SOUNDKIT and SOUNDKIT.MAP_PING then pcall(PlaySound, SOUNDKIT.MAP_PING, "Master") end
end

local function RareFound(boss)
    if rares[boss.name] then return end
    rares[boss.name] = { wait = FIRST_CHIME, nextAt = GetTime() + FIRST_CHIME }
    local run = Active()
    if run then run.found[boss.name] = true end
    Chime()
    Changed()
end

-- Encontrado vivo y sin atender (brilla y suena)
function ns.RunRareAlive(name)
    local rare = rares[name]
    return rare ~= nil and not rare.ack
end

function ns.RunRareFound(name)
    local run = Active()
    return rares[name] ~= nil or (run ~= nil and run.found[name] == true)
end

function ns.RunAckRare(name)
    if rares[name] then
        rares[name].ack = true
        Changed()
    end
end

local function ChimeTick()
    for _, rare in pairs(rares) do
        if not rare.ack and GetTime() >= rare.nextAt then
            rare.wait = rare.wait * 2
            rare.nextAt = GetTime() + rare.wait
            return Chime() -- uno por vuelta, aunque haya dos raros
        end
    end
end

-- Lo llama ns.CheckBossUnit con cada unidad que se ve dentro
function ns.RunLogUnit(unit, instance, zone, npcID, spawn, dead)
    if not (inside and npcID and instance == inside) then return end
    CheckCopy(zone)
    if ns.PlainText(UnitIsFriend("player", unit)) == true then return end
    names[npcID] = ns.PlainText(UnitName(unit)) or names[npcID]
    if ns.PlainText(UnitLevel(unit)) == 1 then critters[npcID] = true; return end -- ratas, cucarachas...
    local key = npcID .. ":" .. tostring(spawn)
    -- Muerto y enemigo dentro de tu copia: tuyo (PARTY_KILL y UNIT_DIED pueden no llegar
    -- o llegar secretos, y entonces la partida no empezaba hasta el primer jefe)
    -- Solo con la partida en marcha: un cadaver puesto de adorno no empieza el tiempo
    if dead then
        local run = Active()
        if run and run.first and not doubt then AddKill(npcID, spawn, zone) end
        return
    end
    seen[key] = true
    local boss, d = BossFor(npcID, names[npcID])
    if not boss then return end
    -- Alas que comparten instancia: la del primer jefe que se ve, aunque aun no haya muerto ninguno
    wing = wing or d.key
    local run = Active()
    if run and run.instance == inside and next(run.bosses) == nil and run.key ~= d.key then
        run.key = d.key
        Changed()
    end
    if boss.kind == "rare" then RareFound(boss) end
end

-- ------------------------------------------
-- Botin y tiradas
-- ------------------------------------------

local function ItemIDOf(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

local function ItemCount(id)
    local ok, count = pcall(C_Item.GetItemCount, id, true)
    count = ok and ns.PlainText(count)
    return type(count) == "number" and count or 0
end

local function AddLoot(run, link, bossName)
    local id = ItemIDOf(link)
    if not id then return end
    for _, loot in ipairs(run.loot) do
        if loot.id == id and (loot.boss == bossName or not bossName) then return end
    end
    run.loot[#run.loot + 1] = { id = id, link = link, boss = bossName }
end

function ns.RunLootOf(run, bossName)
    local list = {}
    for _, loot in ipairs(run.loot) do
        if loot.boss == bossName then list[#list + 1] = loot end
    end
    return list
end

local function RollLink(rollID)
    if not GetLootRollItemLink then return end
    local ok, link = pcall(GetLootRollItemLink, rollID)
    return ok and ns.PlainText(link) or nil
end

local function OnNeed(rollID, rollType)
    local run = Active()
    if rollType ~= NEED_ROLL or not run then return end
    local link = RollLink(rollID)
    local id = ItemIDOf(link)
    if id then run.needs[#run.needs + 1] = { id = id, link = link, base = ItemCount(id) } end
end
if hooksecurefunc and RollOnLoot then hooksecurefunc("RollOnLoot", OnNeed) end

-- Ganada si ha entrado en las bolsas: no depende del chat, que dentro puede llegar secreto
local function CheckNeeds()
    local run = Active()
    if not run then return end
    local changed = false
    for _, need in ipairs(run.needs) do
        if not need.won and need.base and ItemCount(need.id) > need.base then
            need.won, changed = true, true
        end
    end
    if changed then Changed() end
end

local function LootOpened()
    local run = Active()
    if not (run and GetNumLootItems and GetLootSourceInfo and GetLootSlotLink) then return end
    for slot = 1, GetNumLootItems() do
        local link = ns.PlainText(GetLootSlotLink(slot))
        local quality = select(5, GetLootSlotInfo(slot))
        if link and type(ns.PlainText(quality)) == "number" and quality >= 2 then
            local sources = { GetLootSourceInfo(slot) } -- guid, cantidad, guid, cantidad...
            for i = 1, #sources, 2 do
                local _, _, npcID = ns.ParseCreatureGUID(sources[i])
                local boss = npcID and BossFor(npcID, names[npcID])
                if boss then AddLoot(run, link, boss.name) end
            end
        end
    end
end

-- "%s recibe botin: %s." -> patron de Lua, en el idioma del cliente
local function Pattern(format)
    return format and "^" .. format:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0"):gsub("%%s", "(.+)") .. "$" or nil
end

local function LootMessage(message)
    local run = Active()
    message = ns.PlainText(message)
    if not (run and type(message) == "string") then return end
    local others, own = Pattern(LOOT_ITEM), Pattern(LOOT_ITEM_SELF)
    local who, link
    if others then who, link = message:match(others) end
    if not link and own then
        link = message:match(own)
        who = link and ns.PlainText(UnitName("player"))
    end
    local id = ItemIDOf(link)
    if not (id and who) then return end
    for _, loot in ipairs(run.loot) do
        if loot.id == id and not loot.who then
            loot.who = who
            return Changed()
        end
    end
end

-- ------------------------------------------
-- Entrar y salir
-- ------------------------------------------

local function SyncCounters()
    prevXP, prevMax = ns.PlainText(UnitXP("player")), ns.PlainText(UnitXPMax("player"))
    prevMoney = ns.PlainText(GetMoney())
end

local function UpdateZone()
    if not ns.char then return end
    local _, kind, _, _, _, _, _, instanceID = GetInstanceInfo()
    local now = kind == "party" and instanceID or nil
    local run = Active()
    if inside and inside ~= now and run and run.instance == inside then
        -- Muerto (liberar el espiritu) vuelves a la misma copia; vivo, quiza a otra (reinicio)
        run.leftAt, run.leftAlive = Now(), ns.PlainText(UnitIsDeadOrGhost("player")) ~= true
    end
    if now ~= inside then doubt, lastZone = false, nil end
    if now and now ~= inside then
        checkCopy = true
        if run and run.instance == now and (not run.leftAt or Now() - run.leftAt <= ResumeLimit(run)) then
            if run.leftAlive then doubt = true -- el tiempo sigue parado hasta saberlo
            elseif run.leftAt then run.outside, run.leftAt = run.outside + Now() - run.leftAt, nil end
            run.leftAlive = nil
        elseif run then
            Close(run)
        end
    end
    if now ~= inside then preXP, preMoney, pendingXP, wing = 0, 0, nil, nil end
    inside = now
    SyncCounters()
    Changed()
end

local function ExpireRuns()
    local run = Active()
    if run and run.leftAt and Now() - run.leftAt > ResumeLimit(run) then
        Close(run)
        Changed()
    end
end

local function OnXP()
    local xp, max = ns.PlainText(UnitXP("player")), ns.PlainText(UnitXPMax("player"))
    if not (xp and max and prevXP and prevMax) then return SyncCounters() end
    local gained = xp >= prevXP and xp - prevXP or prevMax - prevXP + xp -- ha subido de nivel
    prevXP, prevMax = xp, max
    if not inside or gained <= 0 or GetTime() < ignoreXPUntil then return end
    local run = Active()
    if not run then
        pendingXP = { amount = gained, at = GetTime() }
        preXP = preXP + gained
        return
    end
    run.xp = run.xp + gained
    if lastKill and GetTime() - lastKill.at <= XP_WINDOW then lastKill.entry.xp = lastKill.entry.xp + gained end
    Changed()
end

local function OnMoney()
    local money = ns.PlainText(GetMoney())
    if not (money and prevMoney) then return SyncCounters() end
    local gained = money - prevMoney
    prevMoney = money
    local run = Active()
    if inside and gained > 0 then
        if not run then preMoney = preMoney + gained; return end
        run.money = run.money + gained
        Changed()
    end
end

local function OnGUID(guid, onlyKnown)
    if not inside then return end
    local instance, zone, npcID, spawn = ns.ParseCreatureGUID(guid)
    if not (npcID and instance == inside) or critters[npcID] then return end
    CheckCopy(zone)
    if not onlyKnown or seen[npcID .. ":" .. tostring(spawn)] or BossFor(npcID, names[npcID]) then
        AddKill(npcID, spawn, zone)
    end
end

-- El primer combate dentro empieza la partida (o el tiempo de una abierta que aun no lo
-- tiene): no depende de leer GUID ni cadaveres, que pueden llegar secretos
local function StartOnCombat()
    if not inside then return end
    if doubt then Resolve(false) end -- tras salir vivo, sin GUID: el primer combate es de otra copia
    local run = Active()
    if run and run.first then return end
    run = run or StartRun()
    if not run then return end
    run.first = Now()
    ns.Debug("partida: empieza con el combate")
    Changed()
end

local HANDLERS = {
    PLAYER_ENTERING_WORLD = UpdateZone,
    ZONE_CHANGED_NEW_AREA = UpdateZone,
    PLAYER_XP_UPDATE = OnXP,
    PLAYER_LEVEL_UP = OnXP,
    PLAYER_MONEY = OnMoney,
    QUEST_TURNED_IN = function() ignoreXPUntil = GetTime() + 1.5 end,
    -- El primer combate dentro empieza la partida: no depende de leer GUID ni cadaveres,
    -- que pueden llegar secretos (entonces no empezaba hasta el primer jefe)
    PLAYER_REGEN_DISABLED = function() StartOnCombat() end,
    PLAYER_DEAD = function()
        local run = Active()
        if inside and run then
            run.deaths = run.deaths + 1
            Changed()
        end
    end,
    GROUP_ROSTER_UPDATE = function()
        UpdateParty(Active())
        Changed()
    end,
    PARTY_KILL = function(_, target) OnGUID(target) end,
    UNIT_DIED = function(guid) OnGUID(guid, true) end, -- solo lo que se ha visto pelear
    LOOT_OPENED = LootOpened,
    START_LOOT_ROLL = function(rollID)
        local run = Active()
        local link = run and RollLink(rollID)
        if link then AddLoot(run, link, run.lastBoss) end
    end,
    CHAT_MSG_LOOT = LootMessage,
    -- "X se ha reiniciado." (fuera de la mazmorra): la partida abierta se cierra ya,
    -- sin esperar al primer bicho de la copia nueva
    CHAT_MSG_SYSTEM = function(message)
        local run = Active()
        message = ns.PlainText(message)
        local reset = Pattern(INSTANCE_RESET_SUCCESS)
        if run and run.leftAt and reset and type(message) == "string" and message:match(reset) then
            Close(run)
            Changed()
        end
    end,
    BAG_UPDATE_DELAYED = CheckNeeds,
}

function ns.RunLogEvent(event, ...) -- tambien para los tests
    if ns.char then HANDLERS[event](...) end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, ...) ns.RunLogEvent(event, ...) end)
for event in pairs(HANDLERS) do pcall(events.RegisterEvent, events, event) end -- un evento que no existe da error

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(30, function() if ns.char then ExpireRuns() end end)
    C_Timer.NewTicker(1, function()
        ChimeTick()
        -- Por si PLAYER_REGEN_DISABLED no llega
        if ns.char and inside and ns.PlainText(UnitAffectingCombat("player")) == true then StartOnCombat() end
    end)
end
