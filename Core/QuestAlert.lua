local _, ns = ...
local L = ns.L

-- ==========================================
-- AVISO DE MISIONES QUE FALTAN
-- ==========================================
-- Quien da las misiones de mazmorra suele estar fuera, así que el aviso útil es
-- al llegar a la zona de la entrada: las que aún puedes coger. Dentro solo
-- recuerda las que llevas en el registro. Una vez por mazmorra y sesión.

local MAX_LINKS = 5 -- más, y la línea del chat no se lee
local warned = {}

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

    local mapID = C_Map.GetBestMapForUnit("player")
    local level = UnitLevel("player")
    for _, d in ipairs(ns.Dungeons) do
        if d.entrance and d.entrance.mapID == mapID and not warned[d.key]
            and ns.InRange(d, level) and ns.MatchesFaction(d, faction) then
            warned[d.key] = true
            local available = {}
            Collect(d, faction, available)
            if #available > 0 then
                ns.Print(L.QUEST_ALERT:format(#available, ns.DungeonName(d)) .. " " .. Links(available))
                ns.Print(L.QUEST_ALERT_HINT:format("/dqa " .. d.key:lower()))
            end
        end
    end
end

-- Al entrar en el mundo el registro y las misiones hechas tardan en llegar
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function() C_Timer.After(3, Check) end)
