local _, ns = ...
local L = ns.L

-- ==========================================
-- PINES EN EL MAPA DEL MUNDO
-- ==========================================
-- Un proveedor de datos del mapa, como los de Blizzard (MapCanvasDataProviderMixin):
-- pinta todos los marcadores en el mapa que estes viendo (su zona o el
-- continente). Clic izquierdo: la flecha guia a ese. Clic derecho: quitarlo.

local TEMPLATE = "DungeonQuestAtlasPinTemplate"
local provider

-- El mixin lo pide la plantilla de UI/MapPins.xml por su nombre global. Se crea
-- al entrar al juego: MapCanvasPinMixin es de Blizzard_MapCanvas.
local function CreatePinMixin()
    DungeonQuestAtlasPinMixin = CreateFromMixins(MapCanvasPinMixin)
    function DungeonQuestAtlasPinMixin:OnLoad()
        self:UseFrameLevelType("PIN_FRAME_LEVEL_TOPMOST")
        self:SetScalingLimits(1, 1.0, 1.2)
    end

    function DungeonQuestAtlasPinMixin:OnAcquired(marker, x, y)
        self.marker = marker
        local size = ns.db.pinSize
        self:SetSize(size, size)
        self:SetPosition(x, y)
        -- Halo solo en el recien marcado y solo unos segundos: luego, la gema sola
        local h = ns.highlight
        local left = h and h.marker == marker and h.untilTime - GetTime() or 0
        if not (self.Glow and self.Pulse) then return end
        self.Glow:SetSize(size * 1.6, size * 1.6)
        self.Glow:SetShown(left > 0)
        if left <= 0 then
            self.Pulse:Stop()
            return
        end
        self.Pulse:Play()
        if C_Timer then
            C_Timer.After(left, function()
                if self.marker == marker then
                    self.Pulse:Stop()
                    self.Glow:Hide()
                end
            end)
        end
    end

    function DungeonQuestAtlasPinMixin:OnMouseEnter()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.marker.title or "?")
        GameTooltip:AddLine(ns.ZoneName(self.marker.mapID) .. " " .. ns.FormatCoords(self.marker), 1, 1, 1)
        GameTooltip:AddLine(L.PIN_TOOLTIP, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end

    function DungeonQuestAtlasPinMixin:OnMouseLeave()
        GameTooltip:Hide()
    end

    -- Por defecto el clic derecho pasa al mapa (alejar); aqui quita el marcador
    function DungeonQuestAtlasPinMixin:ShouldMouseButtonBePassthrough()
        return false
    end

    -- El mapa lo llama al soltar el clic encima del pin
    function DungeonQuestAtlasPinMixin:OnMouseClickAction(button)
        if button == "RightButton" then
            ns.RemoveMarker(self.marker)
        else
            ns.SetTarget(self.marker)
        end
    end
end

local function CreateProvider()
    provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
    end

    function provider:RefreshAllData()
        self:RemoveAllData()
        local mapID = self:GetMap():GetMapID()
        if not mapID then return end
        for _, marker in ipairs(ns.Markers()) do
            local x, y = ns.TranslatePoint(marker.mapID, marker.x / 100, marker.y / 100, mapID)
            if x then self:GetMap():AcquirePin(TEMPLATE, marker, x, y) end
        end
    end

    WorldMapFrame:AddDataProvider(provider)
end

-- ==========================================
-- ENTRADAS DE MAZMORRA EN EL MAPA DEL MUNDO
-- ==========================================
-- Idea de Leatrix Maps (sin su codigo): el portal de cada mazmorra en el mapa de
-- su zona y en el del continente. Clic: su plano encima del mapa del mundo
-- (UI/DungeonMap.lua); clic derecho: su pagina en la ventana del addon.

local ENTRANCE_TEMPLATE = "DungeonQuestAtlasEntrancePinTemplate"
local entranceProvider

local function SetPortal(texture)
    if texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("dungeon") then
        texture:SetAtlas("dungeon")
    else
        texture:SetTexture("Interface\\Icons\\Spell_Nature_AstralRecal")
    end
end

local function CreateEntrancePinMixin()
    DungeonQuestAtlasEntrancePinMixin = CreateFromMixins(MapCanvasPinMixin)
    local mixin = DungeonQuestAtlasEntrancePinMixin
    function mixin:OnLoad()
        self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
        self:SetScalingLimits(1, 1.0, 1.2)
        SetPortal(self.Icon)
        SetPortal(self.Highlight)
    end

    function mixin:OnAcquired(d, x, y)
        self.dungeon = d
        local size = ns.db.entranceSize -- el atlas trae aire alrededor: a 22 apenas se veia
        self:SetSize(size, size)
        self:SetPosition(x, y)
        -- Estrella que late unos segundos en la entrada a la que se llega desde su plano
        local h = ns.entranceHighlight
        local left = h and h.key == d.key and h.untilTime - GetTime() or 0
        if not (self.Glow and self.Pulse) then return end
        self.Glow:SetSize(size * 2.2, size * 2.2)
        self.Glow:SetShown(left > 0)
        if left <= 0 then
            self.Pulse:Stop()
            return
        end
        self.Pulse:Play()
        if C_Timer then
            C_Timer.After(left, function()
                if self.dungeon == d then
                    self.Pulse:Stop()
                    self.Glow:Hide()
                end
            end)
        end
    end

    function mixin:OnMouseEnter()
        local d = self.dungeon
        local color = ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player"))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.DungeonName(d) .. " |c" .. color .. "(" .. d.minLevel .. "-" .. d.maxLevel .. ")|r")
        GameTooltip:AddLine(LFG_TYPE_DUNGEON or L.TAB_DUNGEONS, 1, 1, 1)
        local done, total = ns.DungeonProgress(d, UnitFactionGroup("player"))
        if total > 0 then GameTooltip:AddLine(L.PROGRESS:format(done, total), 1, 0.82, 0) end
        GameTooltip:AddLine(" ")
        if ns.DungeonMaps(d) then GameTooltip:AddLine(L.ENTRANCE_CLICK, 0.8, 0.8, 0.8) end
        GameTooltip:AddLine(L.ENTRANCE_RCLICK, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end

    function mixin:OnMouseLeave()
        GameTooltip:Hide()
    end

    function mixin:ShouldMouseButtonBePassthrough()
        return false
    end

    -- Sin plano (las nuevas que aun no lo tienen), el clic izquierdo tambien abre la ventana
    function mixin:OnMouseClickAction(button)
        local d = self.dungeon
        if button == "LeftButton" and ns.DungeonMaps(d) then
            ns.ShowDungeonOnWorldMap(d)
            return
        end
        if not InCombatLockdown() then HideUIPanel(WorldMapFrame) end -- que se vea la ventana
        ns.OpenDungeon(d)
    end
end

-- En zonas y en continentes, segun las opciones: en el mapa de Azeroth serian demasiados
local function ShowsEntrances(mapID)
    local info = C_Map.GetMapInfo(mapID)
    local continent = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
    if not (info and info.mapType) then return false end
    if info.mapType == continent then return ns.db.mapEntrancesContinent end
    return info.mapType > continent and ns.db.mapEntrances
end

local function CreateEntranceProvider()
    entranceProvider = CreateFromMixins(MapCanvasDataProviderMixin)

    function entranceProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(ENTRANCE_TEMPLATE)
    end

    function entranceProvider:RefreshAllData()
        self:RemoveAllData()
        local mapID = self:GetMap():GetMapID()
        if not (mapID and ShowsEntrances(mapID)) then return end
        for _, d in ipairs(ns.Dungeons) do
            local e = ns.Entrance(d)
            local x, y
            if e then x, y = ns.TranslatePoint(e.mapID, e.x / 100, e.y / 100, mapID) end
            if x then self:GetMap():AcquirePin(ENTRANCE_TEMPLATE, d, x, y) end
        end
    end

    WorldMapFrame:AddDataProvider(entranceProvider)
end

function ns.RefreshMapPins()
    if ns.UpdateMapButton then ns.UpdateMapButton() end -- las opciones tambien cambian su icono
    if provider and provider:GetMap() and provider:GetMap():IsShown() then provider:RefreshAllData() end
    if entranceProvider and entranceProvider:GetMap() and entranceProvider:GetMap():IsShown() then
        entranceProvider:RefreshAllData()
    end
end

-- Boton redondo del mapa del mundo (idea de RareScanner, sin su codigo): un
-- desplegable con todos los ajustes de las entradas, con el menu del juego
-- (DropdownButton + SetupMenu). Va en la columna de botones de arriba a la
-- izquierda; si otro addon trae Krowi_WorldMapButtons, se apila con la suya para
-- no pisar su boton. Queda por debajo del plano de mazmorra (UI/DungeonMap.lua).
local ENTRANCE_SIZES = { 24, 28, 34, 40, 48, 56 }
local mapButton

function ns.UpdateMapButton()
    if not mapButton then return end
    local any = ns.db.mapEntrances or ns.db.mapEntrancesContinent
    mapButton.Icon:SetDesaturated(not any)
    mapButton.Icon:SetAlpha(any and 1 or 0.6)
end

local function Toggle(key)
    return function()
        ns.db[key] = not ns.db[key]
        ns.RefreshMapPins()
    end
end

local function SetupMenu(button)
    button:SetupMenu(function(_, root)
        root:CreateTitle(L.MAP_MENU_SHOW)
        root:CreateCheckbox(L.MAP_ENTRANCES, function() return ns.db.mapEntrances end, Toggle("mapEntrances"))
        root:CreateCheckbox(L.MAP_ENTRANCES_CONTINENT, function() return ns.db.mapEntrancesContinent end,
            Toggle("mapEntrancesContinent"))
        local sizes = root:CreateButton(L.ENTRANCE_SIZE)
        for _, size in ipairs(ENTRANCE_SIZES) do
            sizes:CreateRadio(tostring(size), function() return ns.db.entranceSize == size end, function()
                ns.db.entranceSize = size
                ns.RefreshMapPins()
            end)
        end
        root:CreateDivider()
        root:CreateButton(L.MAP_MENU_OPEN, function()
            if not InCombatLockdown() then HideUIPanel(WorldMapFrame) end
            ns.ToggleMainFrame()
        end)
        root:CreateButton(L.MAP_MENU_OPTIONS, function()
            if not InCombatLockdown() then HideUIPanel(WorldMapFrame) end
            ns.OpenOptions()
        end)
    end)
end

-- Columna de botones de Forever: arriba a la izquierda del lienzo, de 32 en 32,
-- debajo del de los pines de seguimiento del juego
local function PlaceAlone(button)
    local below = 0
    local pinButton = WorldMapTrackingPinButtonMixin and WorldMapTrackingPinButtonMixin.OnLoad
    for _, f in ipairs(WorldMapFrame.overlayFrames or {}) do
        if pinButton and f.OnLoad == pinButton then below = below + 1 end
    end
    button:SetPoint("TOPLEFT", WorldMapFrame:GetCanvasContainer(), "TOPLEFT", 3, -32 * below)
end

local function CreateMapButton()
    DungeonQuestAtlasMapButtonMixin = {}
    function DungeonQuestAtlasMapButtonMixin:OnLoad()
        SetPortal(self.Icon)
        SetupMenu(self)
    end
    function DungeonQuestAtlasMapButtonMixin:OnEnter()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cffd597ffDungeon Quest Atlas|r")
        GameTooltip:AddLine(L.MAP_BUTTON_TOOLTIP, 1, 1, 1)
        GameTooltip:Show()
    end
    function DungeonQuestAtlasMapButtonMixin:OnLeave() GameTooltip:Hide() end
    function DungeonQuestAtlasMapButtonMixin:Refresh() end -- la llama Krowi al cambiar de mapa

    local krowi = LibStub and LibStub("Krowi_WorldMapButtons-1.4", true)
    if krowi then
        mapButton = krowi:Add("DungeonQuestAtlasMapButtonTemplate", "DropdownButton")
    else
        mapButton = CreateFrame("DropdownButton", "DungeonQuestAtlasMapButton", WorldMapFrame,
            "DungeonQuestAtlasMapButtonTemplate")
        PlaceAlone(mapButton)
    end
    ns.UpdateMapButton()
end

-- Al abrir el mapa la primera vez: para entonces ya han cargado los demas addons
-- (si alguno trae Krowi_WorldMapButtons, el boton se pone en su columna)
local function MapButtonOnFirstShow()
    if mapButton or not WorldMapFrame.GetCanvasContainer then return end
    local ok, err = pcall(CreateMapButton)
    if not ok and ns.db.debug then print(ns.PREFIX .. tostring(err)) end
end

-- El mapa del mundo puede cargarse despues que el addon
local function Setup()
    if not (WorldMapFrame and MapCanvasDataProviderMixin and MapCanvasPinMixin and CreateFromMixins) then return end
    CreatePinMixin()
    CreateProvider()
    CreateEntrancePinMixin()
    CreateEntranceProvider()
    WorldMapFrame:HookScript("OnShow", MapButtonOnFirstShow)
end

function ns.SetupMapPins()
    if WorldMapFrame then
        Setup()
    elseif EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", Setup)
    end
end
