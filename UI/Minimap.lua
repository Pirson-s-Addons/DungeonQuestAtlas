local _, ns = ...
local L = ns.L

-- ==========================================
-- BOTON DEL MINIMAPA (LibDataBroker + LibDBIcon)
-- ==========================================
-- Clic izquierdo: ventana. Clic derecho: opciones. Si faltan las librerias no
-- hay boton y el addon sigue funcionando con /dqa.

-- Imagenes del addon (img/*.tga, 32 bits con alfa, lado potencia de 2)
ns.IMG = "Interface\\AddOns\\DungeonQuestAtlas\\img\\"
ns.LOGO = ns.IMG .. "logo_dqa"
local NAME = "DungeonQuestAtlas"
local icon

function ns.CreateMinimapButton()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not (LDB and icon) then return end

    local launcher = LDB:NewDataObject(NAME, {
        type = "launcher",
        icon = ns.IMG .. "minimap_dqa",
        OnClick = function(_, button)
            if button == "RightButton" then ns.OpenOptions() else ns.ToggleMainFrame() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cffd597ffDungeon Quest Atlas|r |cff00ccffForever|r")
            tooltip:AddLine(L.MM_PENDING:format(ns.PendingInRange()), 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddLine(L.MM_LEFT, 0.8, 0.8, 0.8)
            tooltip:AddLine(L.MM_RIGHT, 0.8, 0.8, 0.8)
        end,
    })
    if not icon:IsRegistered(NAME) then icon:Register(NAME, launcher, ns.db.minimap) end
end

function ns.UpdateMinimapButton()
    if not icon then return end
    if ns.db.minimap.hide then icon:Hide(NAME) else icon:Show(NAME) end
end
