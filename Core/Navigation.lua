local _, ns = ...
local L = ns.L

-- ==========================================
-- GUIA PROPIA: MARCADORES Y FLECHA
-- ==========================================
-- Sin TomTom ni HereBeDragons. Todo se calcula en el mapa del continente, con
-- APIs del cliente: la posicion del jugador (GetPlayerMapPosition), la del
-- marcador pasada de su zona al continente (GetMapRectOnMap) y el tamano del
-- continente en yardas (GetMapWorldSize). Asi no hacen falta tablas de mapas.
--
-- marker = { mapID, x, y (0-100), title, kind = "start"|"end"|"entrance",
--            npcID, under }
-- Se guardan por personaje (sobreviven a /reload). Uno es el objetivo de la flecha.
-- npcID: el marcador es un PNJ; tambien se quita al hablar con el. under: esta
-- bajo tierra (cueva, sotano): estar encima a 10 m no es haber llegado, asi que
-- solo se quita al hablar con el (o a mano).

local ARRIVAL_YARDS = 10
-- Hablar con un PNJ cuyo GUID no se puede leer (valor secreto) cuenta como
-- llegar a un marcador de PNJ que este a menos de esto
local TALK_YARDS = 40
local CONTINENT = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
local atan2 = math.atan2 or math.atan

local function Markers()
    return ns.char.markers
end
ns.Markers = Markers

-- Avisa a la flecha y a los pines del mapa
local function Changed()
    if ns.OnMarkersChanged then ns.OnMarkersChanged() end
end

function ns.Target()
    return ns.char.target and Markers()[ns.char.target]
end

function ns.SetTarget(marker)
    ns.char.target = nil
    for i, m in ipairs(Markers()) do
        if m == marker then ns.char.target = i end
    end
    Changed()
end

-- El mismo sitio no se repite: se reutiliza y pasa a ser el objetivo
function ns.AddMarker(point, title, kind)
    for _, m in ipairs(Markers()) do
        if m.mapID == point.mapID and m.x == point.x and m.y == point.y then
            m.title, m.kind = title, kind or m.kind
            m.npcID, m.under = point.npcID, point.under
            ns.SetTarget(m)
            return m
        end
    end
    local marker = { mapID = point.mapID, x = point.x, y = point.y, title = title, kind = kind,
        npcID = point.npcID, under = point.under }
    table.insert(Markers(), marker)
    ns.SetTarget(marker)
    return marker
end

-- Si era el objetivo, la flecha pasa al ultimo que quede
function ns.RemoveMarker(marker)
    local target = ns.Target()
    for i, m in ipairs(Markers()) do
        if m == marker then
            table.remove(Markers(), i)
            break
        end
    end
    if target == marker then target = Markers()[#Markers()] end
    ns.SetTarget(target)
end

function ns.ClearMarkers()
    wipe(Markers())
    ns.char.target = nil
    Changed()
end

-- ------------------------------------------
-- Geometria
-- ------------------------------------------

-- El continente que contiene a un mapa (o el propio mapa si ya es uno)
function ns.ContinentOf(mapID)
    local info = C_Map.GetMapInfo(mapID)
    while info and info.mapType and info.mapType > CONTINENT and info.parentMapID and info.parentMapID ~= 0 do
        mapID = info.parentMapID
        info = C_Map.GetMapInfo(mapID)
    end
    return mapID
end

-- Punto (0-1) de un mapa a otro que lo contiene. nil si no cae dentro.
function ns.TranslatePoint(mapID, x, y, toMapID)
    if mapID == toMapID then return x, y end
    local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(mapID, toMapID)
    if not minX or maxX == minX or maxY == minY then return nil end
    x, y = minX + x * (maxX - minX), minY + y * (maxY - minY)
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x, y
end

-- Del jugador al marcador, en yardas: dx hacia el este, dy hacia el sur, y la
-- distancia. nil si no hay posicion (instancia u otro continente).
function ns.NavigationVector(marker)
    local continent = ns.ContinentOf(marker.mapID)
    local tx, ty = ns.TranslatePoint(marker.mapID, marker.x / 100, marker.y / 100, continent)
    local pos = continent and C_Map.GetPlayerMapPosition(continent, "player")
    if not (tx and pos) then return nil end
    local px, py = pos:GetXY()
    if not px or (px == 0 and py == 0) then return nil end
    local width, height = C_Map.GetMapWorldSize(continent)
    local dx, dy = (tx - px) * width, (ty - py) * height
    return dx, dy, math.sqrt(dx * dx + dy * dy)
end

-- Rumbo al marcador (radianes, antihorario desde el norte, como GetPlayerFacing)
function ns.Bearing(dx, dy)
    return atan2(-dx, -dy)
end

-- Angulo para la flecha: rumbo menos hacia donde miras. nil sin orientacion
-- (GetPlayerFacing no da nada en instancias).
function ns.ArrowAngle(dx, dy)
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not facing then return nil end
    return ns.Bearing(dx, dy) - facing
end

local function Arrive(marker)
    ns.Print(L.ARRIVED:format(marker.title or "?"))
    ns.RemoveMarker(marker)
end

-- Estas en el mapa del marcador (o en uno dentro de el). Entranas esta bajo
-- las Ruinas de Lordaeron: arriba, en Tirisfal, la distancia sale casi 0.
-- Los marcados sobre un continente (cuevas) no se comprueban.
local function OnMarkerMap(marker)
    local info = C_Map.GetMapInfo(marker.mapID)
    if not info or (info.mapType or 0) <= CONTINENT then return true end
    local mapID = C_Map.GetBestMapForUnit("player")
    while mapID and mapID ~= 0 do
        if mapID == marker.mapID then return true end
        local parent = C_Map.GetMapInfo(mapID)
        mapID = parent and parent.parentMapID
    end
    return false
end

-- Llamado por la flecha en cada actualizacion: al llegar se quita el marcador
function ns.CheckArrival(marker, distance)
    if distance and distance <= ARRIVAL_YARDS and not marker.under and OnMarkerMap(marker) then
        Arrive(marker)
        return true
    end
    return false
end

-- Al abrir la ventana de un PNJ (charla o mision): si es el de un marcador,
-- has llegado. Es lo unico que quita los de bajo tierra.
function ns.CheckTalkArrival()
    local npcID = ns.NpcIDFromGUID(UnitGUID("npc"))
    for _, marker in ipairs(Markers()) do
        if marker.npcID then
            local near = not npcID and select(3, ns.NavigationVector(marker))
            if marker.npcID == npcID or (near and near <= TALK_YARDS) then
                Arrive(marker)
                return
            end
        end
    end
end
