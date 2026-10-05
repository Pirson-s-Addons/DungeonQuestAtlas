local _, ns = ...

-- ==========================================
-- JEFES MUERTOS EN LA MAZMORRA ACTUAL
-- ==========================================
-- Dentro de una mazmorra, cada jefe de Data/Bosses.lua que muere se tacha en la
-- pestana Jefes (por personaje: ns.char.kills[clave][nombre ingles] = true).
-- Se detecta por varias vias, porque Forever (API de Retail 12) recorta el
-- registro de combate y marca algunos GUID como secretos:
--   - ENCOUNTER_END con exito: por el nombre del encuentro.
--   - Cualquier unidad muerta que se vea (objetivo, foco, placas, raton,
--     boss1-5): por el npcID de su GUID o por su nombre.
--   (COMBAT_LOG_EVENT_UNFILTERED no: Forever lo bloquea con ADDON_ACTION_FORBIDDEN,
--   que no es un error y pcall no lo para.)
--   - A mano: clic derecho en el jefe.
-- Las cruces se quitan (la mazmorra se da por terminada):
--   - al salir con todos los jefes muertos;
--   - tras LEFT_RESET fuera de la mazmorra (volver antes, p. ej. tras morir, no);
--   - DONE_RESET despues de matar al ultimo jefe, aunque sigas dentro;
--   - al entrar en otra copia de la instancia (otro zoneUID en los GUID).
-- Los plazos van con time() (hora real): cuentan tambien con la sesion cerrada.

local LEFT_RESET = 15 * 60
local DONE_RESET = 5 * 60
local currentInstance -- instanceID de la mazmorra en la que estas (o nil)
local finishedRun     -- la mazmorra en la que estas ya se dio por terminada

local function Kills(d)
    ns.char.kills[d.key] = ns.char.kills[d.key] or {}
    return ns.char.kills[d.key]
end

function ns.IsBossKilled(d, boss)
    return ns.char ~= nil and ns.char.kills[d.key] ~= nil and ns.char.kills[d.key][boss.name] == true
end

-- Cuentan los jefes de verdad: ni raros (no siempre salen), ni cofres, ni bichos
function ns.BossKillProgress(d)
    local done, total = 0, 0
    for _, boss in ipairs(ns.Bosses[d.key] or {}) do
        if boss.kind == nil then
            total = total + 1
            if ns.IsBossKilled(d, boss) then done = done + 1 end
        end
    end
    return done, total
end

local UpdateDone -- (mas abajo)
function ns.ToggleBossKill(d, boss)
    Kills(d)[boss.name] = not ns.IsBossKilled(d, boss) or nil
    UpdateDone(d)
    ns.RequestRefresh()
end

local function DungeonsOf(instanceID)
    local list = {}
    for _, d in ipairs(ns.Dungeons) do
        if instanceID and d.instanceID == instanceID then list[#list + 1] = d end
    end
    return list
end

-- Mazmorra en la que estas (o nil): la elegida en la ventana si es de esta
-- instancia (alas de SM, La Masacre, Stratholme), si no la primera
function ns.CurrentDungeon()
    local list = DungeonsOf(currentInstance)
    local chosen = ns.DungeonByKey[ns.char.dungeon]
    return tContains(list, chosen) and chosen or list[1]
end

local function Reset(instanceID)
    for _, d in ipairs(DungeonsOf(instanceID)) do
        ns.char.kills[d.key] = nil
        ns.char.done[d.key] = nil
    end
    ns.char.left[instanceID] = nil
    ns.RequestRefresh()
end

-- Todos los jefes de verdad muertos: desde cuando (para DONE_RESET)
function UpdateDone(d)
    local done, total = ns.BossKillProgress(d)
    ns.char.done[d.key] = total > 0 and done == total and (ns.char.done[d.key] or time()) or nil
end

-- Quita las cruces de las mazmorras que se dan por terminadas
function ns.ExpireBossKills()
    if not ns.char then return end
    local now = time()
    for instanceID, since in pairs(ns.char.left) do
        if instanceID ~= currentInstance and now - since >= LEFT_RESET then
            ns.Debug("fuera de la mazmorra %d min: cruces fuera", LEFT_RESET / 60)
            Reset(instanceID)
        end
    end
    for key, since in pairs(ns.char.done) do
        if now - since >= DONE_RESET then
            ns.Debug("ultimo jefe muerto hace %d min: cruces fuera", DONE_RESET / 60)
            ns.char.kills[key], ns.char.done[key] = nil, nil
            -- Sigues dentro: los cadaveres ya no vuelven a tachar nada hasta que salgas
            local d = ns.DungeonByKey[key]
            if d and d.instanceID == currentInstance then finishedRun = currentInstance end
            ns.RequestRefresh()
        end
    end
end

-- Un jefe de la mazmorra actual ha muerto: por npcID, por el ID del encuentro
-- (ENCOUNTER_END, el mismo que da el Diario) o por nombre (el del cliente, el
-- ingles o el del encuentro del Diario; sin distinguir mayusculas)
local function Same(a, b)
    return type(a) == "string" and type(b) == "string" and a:lower() == b:lower()
end

function ns.MarkBossKilled(npcID, name, encounterID, source)
    if finishedRun and finishedRun == currentInstance then return false end
    local marked = false
    for _, d in ipairs(DungeonsOf(currentInstance)) do
        for _, boss in ipairs(ns.Bosses[d.key] or {}) do
            local journal = ns.JournalBoss(d, boss)
            local match = (npcID and boss.npcID == npcID)
                or (encounterID and journal and journal.encounterID == encounterID)
                or (name and (Same(name, boss.name) or Same(name, ns.BossName(boss, d))
                    or (journal and (Same(name, journal.name) or Same(name, journal.encounter)))))
            if match and boss.kind ~= "trash" and not ns.IsBossKilled(d, boss) then
                Kills(d)[boss.name] = true
                UpdateDone(d)
                marked = true
                ns.Debug("jefe muerto (%s): %s", source or "?", boss.name)
            end
        end
    end
    if marked then ns.RequestRefresh() end
    return marked
end

-- "Creature-0-<servidor>-<instancia>-<zoneUID>-<npcID>-<spawn>"
function ns.ParseCreatureGUID(guid)
    guid = ns.PlainText(guid)
    if type(guid) ~= "string" then return end
    local kind, _, _, instance, zone, npcID = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return end
    return tonumber(instance), zone, tonumber(npcID)
end

-- Otra copia de la instancia (se ha reiniciado): cruces fuera. Solo con el
-- primer bicho que se ve al entrar: a mitad de la mazmorra, un zoneUID
-- distinto no puede borrar lo ya tachado.
local checkRun = false
local function CheckRun(instance, zone)
    if not (checkRun and zone and instance == currentInstance) then return end
    checkRun = false
    local runs = ns.char.runs
    if runs[instance] and runs[instance] ~= zone then
        ns.Debug("otra copia de la instancia: cruces fuera")
        Reset(instance)
    end
    runs[instance] = zone
end

-- Muerta: UnitIsDead o, si el juego lo da como secreto, la vida a 0
local function IsDead(unit)
    local dead = ns.PlainText(UnitIsDead(unit))
    if dead ~= nil then return dead end
    return ns.PlainText(UnitHealth(unit)) == 0
end

function ns.CheckBossUnit(unit)
    if not currentInstance or not UnitExists(unit) then return end
    local instance, zone, npcID = ns.ParseCreatureGUID(UnitGUID(unit))
    CheckRun(instance, zone)
    if not IsDead(unit) then return end
    local name = ns.PlainText(UnitName(unit))
    if not (npcID or name) then ns.Debug("%s muerto, pero nombre y GUID secretos", unit) end
    ns.MarkBossKilled(npcID, name, nil, unit)
end

-- Al cambiar de zona: si sales de una mazmorra con todos sus jefes muertos, se
-- reinicia para poder volver a hacerla
function ns.UpdateInstance()
    local _, kind, _, _, _, _, _, instanceID = GetInstanceInfo()
    local now = kind == "party" and instanceID or nil
    if currentInstance and currentInstance ~= now then
        ns.char.left[currentInstance] = time() -- para LEFT_RESET
        for _, d in ipairs(DungeonsOf(currentInstance)) do
            local done, total = ns.BossKillProgress(d)
            if total > 0 and done == total then
                Reset(currentInstance)
                ns.char.runs[currentInstance] = nil
            end
        end
        ns.RequestRefresh()
    end
    if now then ns.char.left[now] = nil end -- de vuelta a tiempo: las cruces siguen
    -- Al entrar, esta mazmorra queda elegida (su tarjeta abre su pagina)
    if now and now ~= currentInstance and not tContains(DungeonsOf(now), ns.DungeonByKey[ns.char.dungeon]) then
        local d = DungeonsOf(now)[1]
        if d then ns.char.dungeon = d.key end
    end
    if now and now ~= currentInstance then checkRun = true end
    if now ~= currentInstance then finishedRun = nil end
    currentInstance = now
    ns.ExpireBossKills()
end

if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(30, function() ns.ExpireBossKills() end) end

ns.On("PLAYER_ENTERING_WORLD", ns.UpdateInstance)
ns.On("ZONE_CHANGED_NEW_AREA", ns.UpdateInstance)

ns.On("ENCOUNTER_END", function(encounterID, name, _, _, success)
    ns.Debug("ENCOUNTER_END %s %s exito=%s", tostring(ns.PlainText(encounterID)), tostring(ns.PlainText(name)),
        tostring(ns.PlainText(success)))
    if ns.PlainText(success) == 1 then
        ns.MarkBossKilled(nil, ns.PlainText(name), ns.PlainText(encounterID), "encuentro")
    end
end)

for _, event in ipairs({ "UNIT_HEALTH", "NAME_PLATE_UNIT_ADDED" }) do
    ns.On(event, ns.CheckBossUnit)
end
ns.On("PLAYER_TARGET_CHANGED", function() ns.CheckBossUnit("target") end)
ns.On("UPDATE_MOUSEOVER_UNIT", function() ns.CheckBossUnit("mouseover") end)

-- Al saquear un cadaver: de quien es el botin (por su GUID)
ns.On("LOOT_OPENED", function()
    if not (currentInstance and GetNumLootItems and GetLootSourceInfo) then return end
    for slot = 1, GetNumLootItems() do
        local sources = { GetLootSourceInfo(slot) } -- guid, cantidad, guid, cantidad...
        for i = 1, #sources, 2 do
            local _, _, npcID = ns.ParseCreatureGUID(sources[i])
            if npcID then ns.MarkBossKilled(npcID, nil, nil, "botin") end
        end
    end
end)

-- PARTY_KILL (alguien del grupo mata algo), si el cliente lo tiene: registrar
-- un evento que no existe da error, de ahi el pcall
local partyKill = CreateFrame("Frame")
if pcall(partyKill.RegisterEvent, partyKill, "PARTY_KILL") then
    partyKill:SetScript("OnEvent", function(_, _, _, targetGUID)
        if not currentInstance then return end
        local _, _, npcID = ns.ParseCreatureGUID(targetGUID)
        if npcID then ns.MarkBossKilled(npcID, nil, nil, "grupo") end
    end)
end
