local _, ns = ...
local L = ns.L

-- ==========================================
-- FLECHA DE GUIA Y PIN DEL MINIMAPA
-- ==========================================
-- La flecha apunta al marcador objetivo segun hacia donde miras, con su nombre
-- y la distancia; al llegar, el marcador se quita solo. Arrastrar para moverla,
-- clic derecho para quitar el marcador. Solo se actualiza mientras se ve.
-- Clic izquierdo, si el marcador es un PNJ: lo selecciona y le pone una
-- estrella (/targetexact + /tm). Un
-- InsecureActionButtonTemplate hace la accion con el clic del jugador, fuera de
-- combate, sin volver protegida la flecha (se puede mover y ocultar en combate).
-- Arte propio (img/): la flecha 3D y el marcador (los mismos que Azeroth AI).

local INTERVAL = 0.05
local TWO_PI = 2 * math.pi
-- img/arrow_dqa: hoja de 1024x1024 con la flecha 3D ya renderizada desde FRAMES
-- angulos (9 columnas x 12 filas de 112x84, sentido antihorario desde "recto"; la
-- misma que Azeroth AI). Girar una sola imagen aplastaria la perspectiva: se
-- elige el fotograma del angulo.
local SHEET, COLUMNS, CELL_W, CELL_H, FRAMES = 1024, 9, 112, 84, 108

local function SetDirection(image, angle)
    local cell = math.floor(angle / TWO_PI * FRAMES + 0.5) % FRAMES
    local column, row = cell % COLUMNS, math.floor(cell / COLUMNS)
    image:SetTexCoord(column * CELL_W / SHEET, (column + 1) * CELL_W / SHEET,
        row * CELL_H / SHEET, (row + 1) * CELL_H / SHEET)
end
-- Marca de banda para el PNJ (1 = estrella). "!" no la quita si ya la tiene.
local RAID_MARK = 1

local arrow, minimapPin, elapsedSum = nil, nil, 0
local nameAt = 0 -- ultima vez que se pidio el nombre del PNJ al cliente
local FACE_YARDS = 40 -- a esta distancia, fuera de combate, sale la cara del PNJ (un clic lo selecciona)

-- Apariencia del PNJ para su cara: un modelo oculto con su npcID dice su displayID
-- (se guarda en ns.db.npcDisplays). Si el cliente aun no lo tiene, se vuelve a pedir.
local probe, probing, probeAt
local function NpcDisplay(npcID)
    local saved = ns.db.npcDisplays[npcID]
    if saved then return saved end
    if not probe then
        local ok, model = pcall(CreateFrame, "PlayerModel", nil, UIParent)
        if not ok or not model or not model.SetCreature then return end
        probe = model
        probe:SetSize(1, 1)
        probe:SetPoint("CENTER")
        probe:SetAlpha(0)
    end
    if probing ~= npcID or GetTime() - (probeAt or 0) > 5 then
        probing, probeAt = npcID, GetTime()
        probe:Show()
        pcall(probe.SetCreature, probe, npcID)
        return
    end
    local ok, display = pcall(probe.GetDisplayInfo, probe)
    if ok and type(display) == "number" and display > 0 then
        ns.db.npcDisplays[npcID] = display
        probing = nil
        probe:Hide()
        return display
    end
end

-- "Ve a <zona>" si no estas en el mapa del marcador (ni dentro de el)
local function Destination(target)
    if not target.mapID or not C_Map.GetBestMapForUnit then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    while mapID and mapID > 0 do
        if mapID == target.mapID then return end
        local info = C_Map.GetMapInfo(mapID)
        mapID = info and info.parentMapID
    end
    local info = C_Map.GetMapInfo(target.mapID)
    return info and info.name and L.ARROW_GET_TO:format(info.name)
end

-- Pin en el borde si el marcador queda fuera del minimapa
local function UpdateMinimapPin(dx, dy)
    local radius = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not radius or radius <= 0 then
        minimapPin:Hide()
        return
    end
    local sx, sy = dx, -dy -- este, norte
    if GetCVar("rotateMinimap") == "1" then
        local a = -(GetPlayerFacing() or 0)
        sx, sy = sx * math.cos(a) - sy * math.sin(a), sx * math.sin(a) + sy * math.cos(a)
    end
    local half = Minimap:GetWidth() / 2
    local px, py = sx / radius * half, sy / radius * half
    local len, limit = math.sqrt(px * px + py * py), half - 6
    local edge = len > limit
    if edge then px, py = px * limit / len, py * limit / len end
    minimapPin:SetAlpha(edge and 0.6 or 1)
    minimapPin:ClearAllPoints()
    minimapPin:SetPoint("CENTER", Minimap, "CENTER", px, py)
    minimapPin:Show()
end

local function Update(self, elapsed)
    elapsedSum = elapsedSum + elapsed
    if elapsedSum < INTERVAL then return end
    elapsedSum = 0

    local target = ns.Target()
    if not target then
        self:Hide()
        return
    end
    local dx, dy, distance = ns.NavigationVector(target)
    if ns.CheckArrival(target, distance) then return end

    -- Nombre del PNJ en el idioma del cliente: si al marcarlo aun no lo tenia
    -- en cache, llega luego (se pide cada segundo). /targetexact lo necesita.
    if target.npcID and GetTime() - nameAt > 1 then
        nameAt = GetTime()
        target.title = ns.PlaceName({ npcID = target.npcID, name = target.title })
    end
    -- El macro del clic izquierdo: solo cambia al cambiar de objetivo o de nombre
    local npc = target.npcID and target.title
    if self.npc ~= npc and not InCombatLockdown() then
        self.npc = npc
        self:SetAttribute("type1", npc and "macro" or nil)
        self:SetAttribute("macrotext1", npc and ("/targetexact %s\n/tm !%d"):format(npc, RAID_MARK) or nil)
    end

    self.title:SetText(target.title or "")
    if not distance then
        -- Dentro de una instancia o en otro continente
        self.distance:SetText(L.NO_GUIDANCE)
        self.image:SetAlpha(0.3)
        minimapPin:Hide()
        return
    end
    local yards = L.YARDS:format(math.floor(distance + 0.5))
    self.distance:SetText(target.under and (yards .. " · " .. L.UNDERGROUND) or yards)
    self.dest:SetText(Destination(target) or "")
    -- Cerca del PNJ y fuera de combate: su cara (el clic lo selecciona y lo marca)
    local display = target.npcID and NpcDisplay(target.npcID)
    local near = display and distance <= FACE_YARDS and not InCombatLockdown()
    if near and self.faceID ~= display and SetPortraitTextureFromCreatureDisplayID then
        self.faceID = display
        SetPortraitTextureFromCreatureDisplayID(self.face, display)
    end
    self.face:SetShown(near and self.faceID == display or false)
    self.faceRing:SetShown(self.face:IsShown())
    local angle = ns.ArrowAngle(dx, dy)
    self.image:SetAlpha(angle and 1 or 0.3)
    if angle then SetDirection(self.image, angle) end
    UpdateMinimapPin(dx, dy)
end

local function SavePosition()
    local point, _, relPoint, x, y = arrow:GetPoint()
    local pos = ns.db.arrow
    pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
end

local function CreateArrow()
    arrow = CreateFrame("Button", "DungeonQuestAtlasArrow", UIParent, "InsecureActionButtonTemplate")
    arrow:SetSize(72, 54)
    local pos = ns.db.arrow
    arrow:SetPoint(pos.point or "TOP", UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -140)
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    arrow:SetAttribute("useOnKeyDown", false)
    arrow:SetScript("OnDragStart", arrow.StartMoving)
    arrow:SetScript("OnDragStop", function()
        arrow:StopMovingOrSizing()
        SavePosition()
    end)
    -- PostClick: el OnClick es el de la plantilla, que lanza el macro
    arrow:SetScript("PostClick", function(_, button)
        local target = button == "RightButton" and ns.Target()
        if target then ns.RemoveMarker(target) end
    end)
    ns.AddTooltip(arrow, L.ARROW_TOOLTIP)

    arrow.image = arrow:CreateTexture(nil, "ARTWORK")
    arrow.image:SetAllPoints()
    arrow.image:SetTexture(ns.IMG .. "arrow_dqa")
    SetDirection(arrow.image, 0)

    arrow.title = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow.title:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
    arrow.distance = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow.distance:SetPoint("TOP", arrow.title, "BOTTOM", 0, -2)
    arrow.dest = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow.dest:SetPoint("TOP", arrow.distance, "BOTTOM", 0, -2)
    arrow.dest:SetTextColor(0.6, 0.85, 1)
    -- Cara del PNJ a la izquierda de la flecha, con el aro del minimapa
    arrow.face = arrow:CreateTexture(nil, "ARTWORK")
    arrow.face:SetSize(34, 34)
    arrow.face:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    arrow.face:Hide()
    local mask = arrow:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(arrow.face)
    arrow.face:AddMaskTexture(mask)
    -- El aro del minimapa con las medidas de las caras del plano (53 por cada 20 de cara)
    arrow.faceRing = arrow:CreateTexture(nil, "OVERLAY")
    arrow.faceRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    arrow.faceRing:SetSize(53 * 34 / 20, 53 * 34 / 20)
    arrow.faceRing:SetPoint("TOPLEFT", arrow.face, "TOPLEFT", -7 * 34 / 20, 5 * 34 / 20)
    arrow.faceRing:Hide()
    arrow:SetScript("OnUpdate", Update)

    minimapPin = CreateFrame("Frame", nil, Minimap)
    minimapPin:SetSize(ns.db.pinSize, ns.db.pinSize)
    minimapPin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    local gem = minimapPin:CreateTexture(nil, "ARTWORK")
    gem:SetAllPoints()
    gem:SetTexture(ns.IMG .. "pin_dqa")
    minimapPin:Hide()
end

-- Opcion "Tamano del marcador": minimapa y mapa del mundo
function ns.ApplyPinSize()
    if minimapPin then minimapPin:SetSize(ns.db.pinSize, ns.db.pinSize) end
    if ns.RefreshMapPins then ns.RefreshMapPins() end
end

-- Al anadir, quitar o cambiar el objetivo
function ns.OnMarkersChanged()
    if not arrow then CreateArrow() end
    local target = ns.Target()
    arrow:SetShown(target ~= nil)
    if not target then minimapPin:Hide() end
    elapsedSum = INTERVAL -- que se actualice ya
    if ns.RefreshMapPins then ns.RefreshMapPins() end
end
