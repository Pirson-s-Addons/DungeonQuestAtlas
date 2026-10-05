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

function ns.RefreshMapPins()
    if provider and provider:GetMap() and provider:GetMap():IsShown() then provider:RefreshAllData() end
end

-- El mapa del mundo puede cargarse despues que el addon
local function Setup()
    if not (WorldMapFrame and MapCanvasDataProviderMixin and MapCanvasPinMixin and CreateFromMixins) then return end
    CreatePinMixin()
    CreateProvider()
end

function ns.SetupMapPins()
    if WorldMapFrame then
        Setup()
    elseif EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", Setup)
    end
end
