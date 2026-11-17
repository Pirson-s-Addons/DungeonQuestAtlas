local _, ns = ...
local L = ns.L

-- ==========================================
-- AVISO DE MISIONES QUE FALTAN
-- ==========================================
-- Fuera, mirando tu posición cada pocos segundos: al acercarte a la entrada de
-- una mazmorra de tu nivel, todas las que aún puedes coger (una vez por mazmorra
-- y sesión); al acercarte a quien da alguna, solo esas (una vez por misión y
-- sesión). Dentro solo recuerda las que llevas en el registro.

local MAX_LINKS = 5 -- más, y la línea del chat no se lee
local ENTRANCE_YARDS = 250 -- "cerca de la entrada"
local GIVER_YARDS = 80     -- "cerca de quien la da"
local TICK = 3
local warned, warnedQuest = {}, {}

local function Link(id)
    return GetQuestLink and GetQuestLink(id) or ("|cffffff00[" .. ns.QuestTitle(id) .. "]|r")
end

local function Links(ids)
    local parts = {}
    for i = 1, math.min(#ids, MAX_LINKS) do parts[i] = Link(ids[i]) end
    if #ids > MAX_LINKS then parts[#parts + 1] = L.QUEST_ALERT_MORE:format(#ids - MAX_LINKS) end
    return table.concat(parts, " ")
end

-- Las de tu facción que puedes coger ya (QuestStatus ya descarta clase, raza,
-- profesión, nivel y cadena) y las que llevas; sin repetibles
local function Collect(d, faction, available, inLog)
    for _, id in ipairs(d.quests) do
        local q = ns.Quests[id] or {}
        if ns.MatchesFaction(q, faction) and not q.repeatable then
            local status = ns.QuestStatus(id)
            if status == ns.STATUS_AVAILABLE then
                if available then available[#available + 1] = id end
            elseif (status == ns.STATUS_IN_LOG or status == ns.STATUS_READY) and inLog and not tContains(inLog, id) then
                inLog[#inLog + 1] = id
            end
        end
    end
end

local function Check()
    if not (ns.db and ns.db.questAlert) then return end
    local name, kind, _, _, _, _, _, instanceID = GetInstanceInfo()
    local faction = UnitFactionGroup("player")

    -- Dentro: las alas que comparten instancia (Monasterio, La Masacre...) van juntas
    if kind == "party" then
        if warned[instanceID] then return end
        warned[instanceID] = true
        local inLog = {}
        for _, d in ipairs(ns.Dungeons) do
            if d.instanceID == instanceID then Collect(d, faction, nil, inLog) end
        end
        if #inLog > 0 then ns.Print(L.QUEST_ALERT_INSIDE:format(#inLog, name) .. " " .. Links(inLog)) end
        return
    end
    if kind ~= "none" then return end

    -- Tu posición en el continente (en yardas con su tamaño); sin ella, nada
    local mapID = C_Map.GetBestMapForUnit("player")
    local continent = mapID and ns.ContinentOf(mapID)
    local pos = continent and C_Map.GetPlayerMapPosition(continent, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or (px == 0 and py == 0) then return end
    local width, height = C_Map.GetMapWorldSize(continent)
    local function Near(point, yards)
        return ns.WithinYards(point, continent, px, py, width, height, yards)
    end

    local level = UnitLevel("player")
    for _, d in ipairs(ns.Dungeons) do
        if ns.InRange(d, level) and ns.MatchesFaction(d, faction) then
            local entrance = ns.Entrance(d)
            if not warned[d.key] and entrance and Near(entrance, ENTRANCE_YARDS) then
                warned[d.key] = true
                local available = {}
                Collect(d, faction, available)
                for _, id in ipairs(available) do warnedQuest[id] = true end
                if #available > 0 then
                    ns.Print(L.QUEST_ALERT:format(#available, ns.DungeonName(d)) .. " " .. Links(available))
                    ns.Print(L.QUEST_ALERT_HINT:format("/dqa " .. d.key:lower()))
                end
            elseif not warned[d.key] then
                -- Cerca de quien da alguna: primero la distancia (barata), luego su estado
                local near
                for _, id in ipairs(d.quests) do
                    if not warnedQuest[id] then
                        for _, place in ipairs(ns.QuestPlaces(id, "starts")) do
                            if place.mapID and not place.inside and Near(place, GIVER_YARDS) then
                                near = near or {}
                                near[#near + 1] = id
                                break
                            end
                        end
                    end
                end
                if near then
                    local available = {}
                    Collect(d, faction, available)
                    local here = {}
                    for _, id in ipairs(near) do
                        warnedQuest[id] = true
                        if tContains(available, id) then here[#here + 1] = id end
                    end
                    if #here > 0 then
                        ns.Print(L.QUEST_ALERT_NEAR:format(#here, ns.DungeonName(d)) .. " " .. Links(here))
                        ns.Print(L.QUEST_ALERT_HINT:format("/dqa " .. d.key:lower()))
                    end
                end
            end
        end
    end
end
ns.CheckQuestAlert = Check

-- Un punto { mapID, x, y } (0-100) a menos de tantas yardas del jugador, que está en
-- (px, py) del continente. Cada punto se pasa al continente una vez.
local onContinent = setmetatable({}, { __mode = "k" })
function ns.WithinYards(point, continent, px, py, width, height, yards)
    local c = onContinent[point]
    if not c or c.continent ~= continent then
        local x, y
        if ns.ContinentOf(point.mapID) == continent then
            x, y = ns.TranslatePoint(point.mapID, point.x / 100, point.y / 100, continent)
        end
        c = { continent = continent, x = x, y = y }
        onContinent[point] = c
    end
    if not c.x or not width or width == 0 then return false end
    local dx, dy = (c.x - px) * width, (c.y - py) * height
    return dx * dx + dy * dy <= yards * yards
end

-- Al entrar en el mundo el registro y las misiones hechas tardan en llegar: el
-- primer vistazo a los 3 s, y luego cada TICK segundos mientras estés fuera
local elapsed = -3
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < TICK then return end
    elapsed = 0
    Check()
end)
ticker:RegisterEvent("PLAYER_ENTERING_WORLD")
ticker:SetScript("OnEvent", function() elapsed = -3 end)
