local _, ns = ...

-- ==========================================
-- INTEGRACIONES OPCIONALES (OptionalDeps)
-- ==========================================
-- Todo con pcall: si el otro addon no esta, cambia su API o falla, aqui no pasa
-- nada. Ninguna de estas APIs es publica ni documentada: se leen en tiempo de
-- ejecucion, sin copiar nada de sus bases de datos.

local function IsLoaded(name)
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name) or false
end

-- AtlasLoot ----------------------------------------------------------------

function ns.AtlasLootAvailable()
    return IsLoaded("AtlasLoot") and type(AtlasLoot) == "table"
end

-- ponytail: abre AtlasLoot, pero no en la mazmorra: no tiene API publica para
-- elegir instancia. Cuando AtlasLoot for Forever la tenga, se selecciona aqui.
function ns.OpenAtlasLoot(d)
    if not ns.AtlasLootAvailable() then return false end
    local gui = AtlasLoot.GUI
    if gui and gui.Toggle and pcall(gui.Toggle, gui) then return true end
    local slash = SlashCmdList and SlashCmdList.ATLASLOOT
    return slash and pcall(slash, "") or false
end

-- Questie ------------------------------------------------------------------
-- Respaldo para las misiones sin datos propios: startedBy / finishedBy -> primer
-- PNJ -> su primera aparicion. Questie guarda la zona como areaID y ZoneDB la
-- pasa a uiMapID. Coordenadas ya en 0-100.

local cache = {}
local FIELD = { starts = "startedBy", ends = "finishedBy" }

local function QuestieLookup(questID, which)
    local db = QuestieLoader:ImportModule("QuestieDB")
    local zones = QuestieLoader:ImportModule("ZoneDB")
    local by = db.QueryQuestSingle(questID, FIELD[which])
    local npcID = by and by[1] and by[1][1]
    if not npcID then return nil end
    for areaID, spawns in pairs(db.QueryNPCSingle(npcID, "spawns") or {}) do
        local spawn = spawns[1]
        local mapID = zones:GetUiMapIdByAreaId(areaID)
        if spawn and mapID then
            return { npcID = npcID, mapID = mapID, x = spawn[1], y = spawn[2], name = db.QueryNPCSingle(npcID, "name") }
        end
    end
end

function ns.QuestiePlace(questID, which)
    local key = which .. questID
    if cache[key] ~= nil then return cache[key] or nil end
    if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
    local ok, place = pcall(QuestieLookup, questID, which)
    if not ok then ns.Debug("Questie: %s", tostring(place)) end
    cache[key] = ok and place or false
    return cache[key] or nil
end
