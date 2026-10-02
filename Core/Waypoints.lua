local _, ns = ...
local L = ns.L

-- ==========================================
-- WAYPOINTS
-- ==========================================
-- Segun la opcion "Guia": la flecha y los marcadores del addon (por defecto,
-- Core/Navigation.lua), el pin del mapa del juego o TomTom. Si el pin o TomTom
-- no se pueden usar, se cae a la guia propia, que siempre funciona.
-- Los datos van en 0-100; las APIs quieren 0-1.
-- point = { mapID = uiMapID, x = 0-100, y = 0-100 }

local function FormatCoords(point)
    return ("%.1f, %.1f"):format(point.x, point.y)
end
ns.FormatCoords = FormatCoords

function ns.ZoneName(mapID)
    local info = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or (mapID and ("#" .. mapID)) or L.UNKNOWN
end

-- ==========================================
-- ENTRADAS DE MAZMORRA (del propio juego)
-- ==========================================
-- El mapa de Forever pinta las entradas con C_EncounterJournal.
-- GetDungeonEntrancesForMap (DungeonEntranceDataProvider). Se recorren una vez
-- todos los mapas y se indexan por journalInstanceID; cada mazmorra se busca
-- por su instanceID (GetInstanceForGameMap) o, las nuevas, por nombre.

local entrances, builtAt -- [journalInstanceID] = { mapID, x, y, name }

local function WorldRoot()
    local mapID = (C_Map.GetFallbackWorldMapID and C_Map.GetFallbackWorldMapID()) or C_Map.GetBestMapForUnit("player")
    local info = mapID and C_Map.GetMapInfo(mapID)
    while info and info.parentMapID and info.parentMapID ~= 0 do
        mapID = info.parentMapID
        info = C_Map.GetMapInfo(mapID)
    end
    return mapID
end

local function BuildEntrances()
    entrances, builtAt = {}, GetTime()
    if not (C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap and C_Map.GetMapChildrenInfo) then
        return
    end
    local root = WorldRoot()
    if not root then return end
    local maps = C_Map.GetMapChildrenInfo(root, nil, true) or {}
    for _, map in ipairs(maps) do
        for _, e in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(map.mapID) or {}) do
            -- La misma entrada sale en la zona y en el continente: se queda la
            -- del mapa con mas detalle (Enum.UIMapType: continente 2 < zona 3).
            local known = entrances[e.journalInstanceID]
            if not known or (known.mapType or 0) < (map.mapType or 0) then
                local x, y = e.position:GetXY()
                entrances[e.journalInstanceID] = { mapID = map.mapID, mapType = map.mapType,
                    x = math.floor(x * 1000 + 0.5) / 10, y = math.floor(y * 1000 + 0.5) / 10, name = e.name }
            end
        end
    end
    local n = 0
    for _ in pairs(entrances) do n = n + 1 end
    ns.Debug("entradas del juego: %d en %d mapas", n, #maps)
end

function ns.GameEntrance(d)
    -- Una vez; si salio vacio (datos del mapa aun sin cargar), se reintenta a los 30 s
    if not entrances or (not next(entrances) and GetTime() - builtAt > 30) then BuildEntrances() end
    local journalID = d.instanceID and C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap
        and C_EncounterJournal.GetInstanceForGameMap(d.instanceID)
    if journalID and entrances[journalID] then return entrances[journalID] end
    local names = { ns.DungeonName(d):lower(), d.name:lower() }
    for _, e in pairs(entrances) do
        local name = e.name:lower()
        if name == names[1] or name == names[2] then return e end
    end
end

local function TomTomWaypoint(point, title)
    if not (TomTom and TomTom.AddWaypoint) then return false end
    local ok = pcall(TomTom.AddWaypoint, TomTom, point.mapID, point.x / 100, point.y / 100,
        { title = title, persistent = false, minimap = true, world = true })
    return ok
end

local function NativeWaypoint(point)
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then return false end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(point.mapID) then return false end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(point.mapID, point.x / 100, point.y / 100))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    return true
end

-- Devuelve "own", "native", "tomtom" o nil (sin coordenadas).
-- kind: "start", "end" o "entrance" (el icono del marcador).
function ns.SetWaypoint(point, title, kind)
    if not (point and point.mapID and point.x and point.y) then
        ns.Print(L.WP_NO_COORDS:format(title))
        return nil
    end
    local where = title .. " — " .. ns.ZoneName(point.mapID) .. " " .. FormatCoords(point)
    local mode = ns.db.waypointMode

    if mode == "tomtom" and TomTomWaypoint(point, title) then
        ns.Print(L.WP_TOMTOM:format(where))
        return "tomtom"
    end
    if mode == "native" and NativeWaypoint(point) then
        local link = C_Map.GetUserWaypointHyperlink and C_Map.GetUserWaypointHyperlink()
        ns.Print(L.WP_SET:format(where) .. (link and (" " .. link) or ""))
        return "native"
    end
    ns.AddMarker(point, title, kind)
    ns.Print(L.WP_OWN:format(where))
    return "own"
end

-- Abre el mapa del mundo en ese mapa, para ver el pin recien puesto.
-- C_Map.OpenWorldMap tiene restricciones (en combate puede no abrir): con pcall.
function ns.OpenMapAt(mapID)
    if not (mapID and WorldMapFrame) then return end
    if C_Map.OpenWorldMap then
        pcall(C_Map.OpenWorldMap, mapID)
    elseif ShowUIPanel then
        pcall(ShowUIPanel, WorldMapFrame)
    end
    if WorldMapFrame:IsShown() and WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID) end
end

-- PNJ u objeto de una mision. Si esta dentro de la mazmorra (sin coordenadas,
-- o en un mapa que no admite pin), se marca la entrada. Devuelve el modo de
-- SetWaypoint y el punto que se ha marcado.
function ns.MarkPlace(place, title, d, kind)
    local noPin = place and (not place.mapID
        or (C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(place.mapID)))
    if noPin and d then
        local entrance = ns.Entrance(d)
        if entrance then
            ns.Print(L.WP_INSIDE:format(title, ns.DungeonName(d)))
            return ns.SetWaypoint(entrance, ns.DungeonName(d), "entrance"), entrance
        end
    end
    return ns.SetWaypoint(place, title, kind), place
end

-- ==========================================
-- GUIA POR LA CADENA
-- ==========================================
-- Al entregar un paso de una cadena, se marca el inicio del siguiente y se
-- avisa en el chat (opcion "chainGuide"). Si el siguiente lo da el mismo PNJ
-- con el que acabas de entregar, solo se avisa: ya estas alli.

local function DungeonOfQuest(id)
    for _, d in ipairs(ns.Dungeons) do
        if tContains(d.quests, id) then return d end
    end
end

function ns.GuideNextStep(questID)
    if not ns.db.chainGuide then return end
    local q = ns.Quests[questID]
    local chain = q and type(q.chain) == "table" and q.chain or {}
    for i, id in ipairs(chain) do
        local nextID = chain[i + 1]
        if id == questID and nextID and not C_QuestLog.IsQuestFlaggedCompleted(nextID) then
            local place = ns.QuestPlaces(nextID, "starts")[1]
            local who = place and ns.PlaceName(place) or L.UNKNOWN
            ns.Print(L.NEXT_STEP:format(ns.QuestTitle(nextID), who))
            local sameNpc = place and place.npcID and tContains(q.ends or {}, "npc:" .. place.npcID)
            if place and not sameNpc then ns.MarkPlace(place, who, DungeonOfQuest(nextID), "start") end
            return
        end
    end
end

-- ==========================================
-- RUTA HASTA LA ENTRADA
-- ==========================================
-- Las paradas de ns.Route y la entrada, como marcadores de la guia propia (el
-- pin del juego y TomTom no encadenan puntos). Se anaden al reves: la flecha
-- va a la ultima anadida (la parada 1) y, al llegar, RemoveMarker pasa a la
-- ultima que queda (la 2), y asi hasta la entrada.
function ns.StartRoute(d)
    local stops = d and ns.Route(d)
    if not stops then return end
    local name = ns.DungeonName(d)
    local entrance = ns.Entrance(d)
    if entrance then ns.AddMarker(entrance, name, "entrance") end
    for i = #stops, 1, -1 do
        ns.AddMarker(stops[i], L.ROUTE_STOP:format(name, i, #stops), "route")
    end
    ns.Print(L.ROUTE_STARTED:format(name, #stops))
end
