local _, ns = ...
local L = ns.L

-- ==========================================
-- AMENAZA DE CADA ENEMIGO EN MAZMORRAS
-- ==========================================
-- Tu % de amenaza en cada enemigo con placa, en dos sitios (cada uno con su casilla en
-- Opciones > Seguimiento):
--   * threatPlates: un numero junto a la barra de vida de cada placa enemiga;
--   * threatList: una lista debajo de la ventana de la partida (UI/RunTracker.lua), con
--     quien lo tiene si no eres tu. Marco aparte: la ventana de la partida queda protegida
--     en combate y no puede cambiar de alto.
-- Fuente: UnitDetailedThreatSituation("player" o un aliado, placa). Segun la documentacion de
-- Forever (SecretWhenUnitThreatValuesRestricted), con un aliado y una placa de un enemigo
-- normal no llega secreto; con un jefe puede llegar secreto: se ensena igual (SetText admite
-- valores secretos) pero en blanco, porque no se puede comparar para elegir el color.

local ROWS, BAR_HEIGHT, BAR_GAP, PAD = 8, 16, 3, 9
local GROUP = { "player", "party1", "party2", "party3", "party4" }
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local NO_COLOR = { 0.75, 0.75, 0.75 }

local function Secret(v) return issecretvalue and issecretvalue(v) end

-- Sitio de cada cosa, como las filas de DR Tracker Forever: uno de los 8 puntos del marco al que
-- va pegada (Opciones > Seguimiento, muestra con puntos). { punto propio, punto del marco, x, y }
local POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local AROUND = {
    plate = { -- el % junto a la barra de vida
        TOPLEFT = { "BOTTOMLEFT", "TOPLEFT", 0, 1 }, TOP = { "BOTTOM", "TOP", 0, 1 }, TOPRIGHT = { "BOTTOMRIGHT", "TOPRIGHT", 0, 1 },
        LEFT = { "RIGHT", "LEFT", -3, 0 }, RIGHT = { "LEFT", "RIGHT", 3, 0 },
        BOTTOMLEFT = { "TOPLEFT", "BOTTOMLEFT", 0, -1 }, BOTTOM = { "TOP", "BOTTOM", 0, -1 }, BOTTOMRIGHT = { "TOPRIGHT", "BOTTOMRIGHT", 0, -1 },
    },
    list = { -- la lista junto a la ventana de la partida
        TOPLEFT = { "BOTTOMLEFT", "TOPLEFT", 0, 2 }, TOP = { "BOTTOM", "TOP", 0, 2 }, TOPRIGHT = { "BOTTOMRIGHT", "TOPRIGHT", 0, 2 },
        LEFT = { "TOPRIGHT", "TOPLEFT", -2, 0 }, RIGHT = { "TOPLEFT", "TOPRIGHT", 2, 0 },
        BOTTOMLEFT = { "TOPLEFT", "BOTTOMLEFT", 0, -2 }, BOTTOM = { "TOP", "BOTTOM", 0, -2 }, BOTTOMRIGHT = { "TOPRIGHT", "BOTTOMRIGHT", 0, -2 },
    },
}
local function Around(kind)
    local at = ns.db and ns.db[kind == "plate" and "threatPlateAt" or "threatListAt"]
    return AROUND[kind][at] or AROUND[kind][kind == "plate" and "BOTTOMRIGHT" or "BOTTOM"]
end

-- tanking, status, pct (cualquiera puede llegar secreto); nil si no hay amenaza en el
local function Threat(who, unit)
    if not UnitDetailedThreatSituation then return end
    local ok, tanking, status, pct = pcall(UnitDetailedThreatSituation, who, unit)
    if ok then return tanking, status, pct end
end

-- Tu amenaza en el enemigo: pct (puede ser secreto) y el color de su estado (0 gris ... 3 rojo).
-- El estado sale de UnitThreatSituation, que contra una placa no llega secreto aunque el % si.
local function ThreatInfo(unit)
    local _, detailStatus, pct = Threat("player", unit)
    -- Un valor secreto no se puede comparar ni con nil: primero se mira si lo es
    if not Secret(pct) and pct == nil then return nil end
    local status
    if UnitThreatSituation then
        local ok, st = pcall(UnitThreatSituation, "player", unit)
        if ok and not Secret(st) then status = st end
    end
    if status == nil and not Secret(detailStatus) then status = detailStatus end
    local r, g, b = unpack(NO_COLOR)
    if status ~= nil and GetThreatStatusColor then r, g, b = GetThreatStatusColor(status) end
    return pct, r, g, b, status
end

-- "87%" (con un valor secreto, el juego lo pinta igual con SetFormattedText)
local function SetPct(fs, pct)
    if Secret(pct) then return pcall(fs.SetFormattedText, fs, "%.0f%%", pct) end
    return pcall(fs.SetText, fs, math.floor(pct + 0.5) .. "%")
end

-- Quien del grupo lo tiene (nombre), si no eres tu y se puede saber
local function Tanker(unit)
    for _, who in ipairs(GROUP) do
        if UnitExists(who) then
            local tanking = Threat(who, unit)
            if not Secret(tanking) and tanking then
                if who == "player" then return nil end
                return ns.PlainText((UnitName(who)))
            end
        end
    end
end

local function InDungeon()
    local inside, kind = IsInInstance()
    return inside and (kind == "party" or kind == "raid")
end

-- ------------------------------------------
-- Numero en las placas: debajo de la barra de vida, a la derecha (lejos del nombre y de
-- las flechas del objetivo), con contorno para leerse sobre cualquier fondo
-- ------------------------------------------
local active = {}  -- [unit] = true: placas enemigas a la vista
local labels = {}  -- [placa] = marco con el texto (no se escribe nada en el marco del juego)

-- Etiqueta que se lee entre muchos enemigos: fondo oscuro, borde y numero del color del
-- estado, en negrita con contorno. Ancho fijo (cabe "100%"): el texto puede ser secreto y
-- entonces no se puede medir.
local BADGE_W, BADGE_H, BADGE_FONT = 38, 17, 13
local function CreateBadge(parent)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(BADGE_W, BADGE_H)
    badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    badge:SetBackdropColor(0, 0, 0, 0.8)
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badge.text:SetPoint("CENTER", 0, 0)
    local font = badge.text:GetFont()
    if font then badge.text:SetFont(font, BADGE_FONT, "OUTLINE") end
    badge.text:SetShadowOffset(0, 0)
    function badge:SetColor(r, g, b)
        self.text:SetTextColor(r, g, b)
        self:SetBackdropBorderColor(r, g, b, 0.9)
    end
    return badge
end

local function PlateLabel(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
    local label = labels[plate]
    if not label then
        label = CreateBadge(plate)
        label:SetFrameLevel(plate:GetFrameLevel() + 20) -- por encima de la barra y del nombre
        labels[plate] = label
    end
    -- En su punto de la barra de vida del juego si se ve; si otro addon la cambia, de la placa
    local bar = plate.UnitFrame and plate.UnitFrame.healthBar
    local o = Around("plate")
    label:ClearAllPoints()
    label:SetPoint(o[1], (bar and bar.IsShown and bar:IsShown()) and bar or plate, o[2], o[3], o[4])
    return label
end

local function UpdatePlate(unit)
    local label = PlateLabel(unit)
    if not label then return end
    local shown = false
    if ns.db.threatPlates and InDungeon() then
        local pct, r, g, b = ThreatInfo(unit)
        if (Secret(pct) or pct ~= nil) and SetPct(label.text, pct) then
            label:SetColor(r, g, b)
            shown = true
        end
    end
    label:SetShown(shown)
end

-- ------------------------------------------
-- Lista debajo de la ventana de la partida: el mismo marco que ella y una barra por
-- enemigo en combate, llena hasta tu % y del color de su estado, de mas a menos amenaza
-- ------------------------------------------
local list

local function CreateRow(parent, i)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(BAR_HEIGHT)
    bar:SetPoint("TOPLEFT", PAD, -28 - (i - 1) * (BAR_HEIGHT + BAR_GAP))
    bar:SetPoint("TOPRIGHT", -PAD, -28 - (i - 1) * (BAR_HEIGHT + BAR_GAP))
    bar:SetStatusBarTexture(BAR_TEXTURE)
    bar:SetMinMaxValues(0, 100)
    local edge = bar:CreateTexture(nil, "BACKGROUND", nil, -1) -- borde fino oscuro
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0, 0, 0, 0.9)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(BAR_TEXTURE)
    bg:SetVertexColor(0.16, 0.14, 0.12, 0.9)
    bar.pct = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.pct:SetPoint("RIGHT", -4, 0)
    bar.pct:SetJustifyH("RIGHT")
    bar.name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.name:SetPoint("LEFT", 4, 0)
    bar.name:SetPoint("RIGHT", bar.pct, "LEFT", -6, 0)
    bar.name:SetJustifyH("LEFT")
    bar.name:SetWordWrap(false)
    for _, fs in ipairs({ bar.pct, bar.name }) do
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    end
    bar:Hide()
    return bar
end

local function CreateList()
    list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    -- El mismo marco que la ventana de la partida (UI/RunTracker.lua)
    list:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    list:SetBackdropColor(0.05, 0.04, 0.03, 0.88)
    list:SetBackdropBorderColor(0.55, 0.43, 0.24)
    local title = list:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText(L.THREAT_TITLE)
    list.rows = {}
    for i = 1, ROWS do list.rows[i] = CreateRow(list, i) end
    list:Hide()
end

local entries = {}
local function UpdateList()
    local tracker = DungeonQuestAtlasRunTracker
    if not (ns.db.threatList and InDungeon() and tracker and tracker:IsShown()) then
        if list then list:Hide() end
        return
    end
    if not list then CreateList() end
    wipe(entries)
    for unit in pairs(active) do
        local fighting = UnitAffectingCombat(unit)
        if Secret(fighting) or fighting then
            local pct, r, g, b = ThreatInfo(unit)
            if Secret(pct) or pct ~= nil then
                entries[#entries + 1] = { unit = unit, pct = pct, r = r, g = g, b = b,
                    sort = Secret(pct) and -1 or pct } -- los secretos, al final
            end
        end
    end
    table.sort(entries, function(x, y) return x.sort > y.sort end)
    local n = math.min(#entries, ROWS)
    for i = 1, ROWS do
        local bar, e = list.rows[i], entries[i]
        if e then
            pcall(bar.SetValue, bar, e.pct) -- la barra admite valores secretos
            bar:SetStatusBarColor(e.r, e.g, e.b, 0.85)
            SetPct(bar.pct, e.pct)
            local name, tank = UnitName(e.unit), Tanker(e.unit)
            local suffix = tank and (" |cffb0b0b0- " .. tank .. "|r") or ""
            -- El nombre puede llegar secreto: se puede ensenar, pero no siempre unir a otro texto
            if not pcall(function() bar.name:SetText(name .. suffix) end) then pcall(bar.name.SetText, bar.name, name) end
            bar:Show()
        else
            bar:Hide()
        end
    end
    if n == 0 then list:Hide() return end
    local o = Around("list")
    list:SetScale(ns.db.threatListScale or 1) -- su tamano (Opciones > Seguimiento)
    list:ClearAllPoints()
    list:SetPoint(o[1], tracker, o[2], o[3], o[4])
    -- El mismo ancho que la ventana en pantalla, sea cual sea el tamano de la lista
    list:SetWidth(tracker:GetWidth() * tracker:GetEffectiveScale() / list:GetEffectiveScale())
    list:SetHeight(28 + n * (BAR_HEIGHT + BAR_GAP) - BAR_GAP + PAD)
    list:Show()
end

-- ------------------------------------------
-- Muestra con 8 puntos para Opciones > Seguimiento: clic en un punto, la cosa va ahi.
-- kind "plate" (una barra de vida con el %) o "list" (la ventana con la lista). Devuelve el
-- marco con :Refresh() (marca el punto y coloca la muestra) y :SetActive(on) (atenuada si su
-- casilla esta apagada)
-- ------------------------------------------
function ns.CreateThreatPicker(parent, kind, width, height)
    local key = kind == "plate" and "threatPlateAt" or "threatListAt"
    local box = CreateFrame("Frame", nil, parent)
    box:SetSize(width, height)
    local edge = box:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetColorTexture(1, 1, 1, 0.3)
    local fill = box:CreateTexture(nil, "BORDER")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    if kind == "plate" then
        fill:SetTexture(BAR_TEXTURE)
        fill:SetVertexColor(0.75, 0.12, 0.1, 0.9) -- barra de vida de un enemigo
    else
        fill:SetColorTexture(0.05, 0.04, 0.03, 0.88) -- la ventana de la partida
    end
    -- Lo que se coloca: el % (como en la placa) o una tira con el titulo de la lista
    local sample
    if kind == "plate" then
        sample = CreateBadge(box) -- la misma etiqueta que en las placas
        sample:SetFrameLevel(box:GetFrameLevel() + 5)
        sample.text:SetText("87%")
        sample:SetColor(1, 0.6, 0)
    else
        sample = CreateFrame("Frame", nil, box, "BackdropTemplate")
        sample:SetSize(64, 16)
        sample:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        sample:SetBackdropColor(0.62, 0.5, 0.28, 0.9)
        local text = sample:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        text:SetText(L.THREAT_TITLE)
    end
    local dots = {}
    for _, at in ipairs(POINTS) do
        local dot = CreateFrame("CheckButton", nil, box, "UIRadioButtonTemplate")
        dot:SetPoint("CENTER", box, at)
        dot:SetScript("OnClick", function()
            ns.db[key] = at
            box:Refresh()
            ns.UpdateThreat()
        end)
        ns.AddTooltip(dot, L.THREAT_POS_TOOLTIP)
        dots[at] = dot
    end
    function box:Refresh()
        for at, dot in pairs(dots) do dot:SetChecked(at == ns.db[key]) end
        local o = Around(kind)
        sample:ClearAllPoints()
        -- 8 px por fuera: si no, la tapan los puntos
        local push = (o[3] == 0 and o[4] == 0) and 0 or 8
        sample:SetPoint(o[1], box, o[2], (o[3] > 0 and push) or (o[3] < 0 and -push) or 0, (o[4] > 0 and push) or (o[4] < 0 and -push) or 0)
    end
    function box:SetActive(on)
        box:SetAlpha(on and 1 or 0.5)
        for _, dot in pairs(dots) do dot:SetEnabled(on) end
    end
    return box
end

-- ------------------------------------------
-- Eventos: placas que aparecen y se van, y un repaso cada 0,3 s en combate
-- ------------------------------------------
local function UpdateAll()
    if not ns.db then return end
    for unit in pairs(active) do UpdatePlate(unit) end
    UpdateList()
end
ns.UpdateThreat = UpdateAll

local ticker
local frame = CreateFrame("Frame")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local ok, enemy = pcall(UnitCanAttack, "player", unit)
        if ok and (Secret(enemy) or enemy) then
            active[unit] = true
            if ns.db then UpdatePlate(unit) end
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        active[unit] = nil
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        if plate and labels[plate] then labels[plate]:Hide() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not ticker and C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(0.3, UpdateAll) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ticker then ticker:Cancel(); ticker = nil end
        C_Timer.After(0.5, UpdateAll) -- fuera de combate la amenaza se borra
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(active)
        UpdateAll()
    end
end)
