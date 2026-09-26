local _, ns = ...
local L = ns.L

-- ==========================================
-- LISTA DE MAZMORRAS: estandartes con su arte
-- ==========================================
-- Cada fila es una franja del boton de la mazmorra en el Diario del juego
-- (Core/Journal.lua), oscurecida a la izquierda para leer el nombre dorado;
-- debajo, "17–26" en el color de su dificultad y "3/7" completadas.

local ROW_HEIGHT = 50
local GREEN = "|cff40c040"
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"

function ns.CreateDungeonList(parent, onSelect)
    local selectedKey

    local function Setup(row)
        row.art = row:CreateTexture(nil, "BACKGROUND")
        row.art:SetPoint("TOPLEFT", 3, -3)
        row.art:SetPoint("BOTTOMRIGHT", -3, 3)
        row.shade = row:CreateTexture(nil, "BORDER")
        row.shade:SetAllPoints(row.art)
        if CreateColor and row.shade.SetGradient then
            row.shade:SetColorTexture(1, 1, 1, 1)
            row.shade:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, 0.9), CreateColor(0, 0, 0, 0.15))
        else
            row.shade:SetColorTexture(0, 0, 0, 0.6)
        end
        row.border = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.border:SetAllPoints()
        row.border:SetBackdrop({ edgeFile = BORDER, edgeSize = 12 })
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row.art)
        ns.SetEJTexture(hl, "DungeonButtonHighlight")
        hl:SetBlendMode("ADD")

        row.progress = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.progress:SetPoint("BOTTOMRIGHT", -10, 9)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("TOPLEFT", 12, -9)
        row.label:SetPoint("RIGHT", -10, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.info:SetPoint("BOTTOMLEFT", 12, 9)
        row:SetScript("OnClick", function(self) onSelect(self.dungeon) end)
    end

    local function Update(row, d)
        row.dungeon = d
        ns.SetDungeonArt(row.art, d, "banner")
        row.label:SetText(ns.DungeonName(d))
        local color = ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player"))
        local info = ("|c%s%d–%d|r"):format(color, d.minLevel, d.maxLevel)
        if d.isForever then info = info .. "  |cffd597ff" .. L.NEW_TAG .. "|r" end
        row.info:SetText(info)
        local done, total = ns.DungeonProgress(d, ns.FactionFilter())
        row.progress:SetText(total == 0 and "" or ((done == total and GREEN or "|cffffffff") .. done .. "/" .. total .. "|r"))
        local selected = d.key == selectedKey
        row.border:SetBackdropBorderColor(selected and 1 or 0.55, selected and 0.82 or 0.5, selected and 0 or 0.45)
        row.label:SetTextColor(selected and 1 or 1, selected and 1 or 0.82, selected and 1 or 0)
    end

    local list = ns.CreateScrollList(parent, ROW_HEIGHT, Setup, Update)
    return {
        Refresh = function(_, dungeons, key)
            selectedKey = key
            list:SetItems(dungeons)
        end,
    }
end
