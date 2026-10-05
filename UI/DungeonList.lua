local _, ns = ...
local L = ns.L

-- ==========================================
-- PORTADA: cuadricula de mazmorras
-- ==========================================
-- Como la pestana Mazmorras de la Guia de aventuras: una tarjeta por mazmorra
-- con su arte (Core/Journal.lua, "card"), el marco del boton de instancia del
-- Diario y el nombre en dorado. Debajo del nombre, sus niveles en el color de
-- su dificultad, "Nueva" si es de Forever y las misiones hechas ("! 3/7"; la
-- marca verde si estan todas). Las filas de la lista llevan COLS tarjetas.

local COLS = 4
local CARD_W, CARD_H = 174, 96 -- el boton de instancia del Diario
local GAP_X, GAP_Y = 14, 12
local GREEN = "|cff40c040"

local function CreateCard(row, onSelect)
    local card = CreateFrame("Button", nil, row)
    card:SetSize(CARD_W, CARD_H)
    -- El marco del boton de instancia debajo y la ilustracion encima, dentro de
    -- su borde: si el centro del marco no es transparente, no la tapa
    local frame = card:CreateTexture(nil, "BACKGROUND")
    frame:SetAllPoints()
    ns.SetEJTexture(frame, "InstanceButton")
    card.art = card:CreateTexture(nil, "BORDER")
    card.art:SetPoint("TOPLEFT", 6, -6)
    card.art:SetPoint("BOTTOMRIGHT", -6, 6)
    -- Oscura abajo, para leer los niveles y el progreso
    local shade = card:CreateTexture(nil, "ARTWORK")
    shade:SetAllPoints(card.art)
    if CreateColor and shade.SetGradient then
        shade:SetColorTexture(1, 1, 1, 1)
        shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0.1))
    else
        shade:SetColorTexture(0, 0, 0, 0.35)
    end
    local hl = card:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    ns.SetEJTexture(hl, "DungeonButtonHighlight")
    hl:SetBlendMode("ADD")

    card.name = card:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    card.name:SetPoint("TOPLEFT", 10, -12)
    card.name:SetPoint("TOPRIGHT", -10, -12)
    card.name:SetJustifyH("CENTER")
    card.name:SetMaxLines(2)
    card.name:SetTextColor(1, 0.82, 0)
    card.info = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.info:SetPoint("BOTTOMLEFT", 12, 11)
    card.progress = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.progress:SetPoint("BOTTOMRIGHT", -12, 11)
    card:SetScript("OnClick", function(self)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        onSelect(self.dungeon)
    end)
    card:SetScript("OnEnter", function(self)
        local d = self.dungeon
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.DungeonName(d), 1, 0.82, 0)
        GameTooltip:AddLine(L.LEVEL .. " " .. d.minLevel .. "–" .. d.maxLevel, 1, 1, 1)
        local done, total = ns.DungeonProgress(d, ns.FactionFilter())
        if total > 0 then GameTooltip:AddLine(L.PROGRESS:format(done, total), 1, 1, 1) end
        local killed, bosses = ns.BossKillProgress(d)
        if killed > 0 then GameTooltip:AddLine(L.BOSSES_PROGRESS:format(killed, bosses), 1, 0.4, 0.4) end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end

local function UpdateCard(card, d)
    card.dungeon = d
    ns.SetDungeonArt(card.art, d, "card")
    card.name:SetText(ns.DungeonName(d))
    local info = ("|c%s%d–%d|r"):format(ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player")), d.minLevel, d.maxLevel)
    if d.isForever then info = info .. "  |cffd597ff" .. L.NEW_TAG .. "|r" end
    card.info:SetText(info)
    local done, total = ns.DungeonProgress(d, ns.FactionFilter())
    local progress = ""
    if total > 0 then
        local icon = done == total and ns.StatusMarkup(ns.STATUS_COMPLETED, 14) or ns.StatusMarkup(ns.STATUS_AVAILABLE, 14)
        progress = icon .. " " .. (done == total and GREEN or "|cffffffff") .. done .. "/" .. total .. "|r"
    end
    card.progress:SetText(progress)
end

function ns.CreateDungeonGrid(parent, onSelect)
    local list = ns.CreateScrollList(parent, CARD_H + GAP_Y, function(row)
        row.cards = {}
        for i = 1, COLS do
            local card = CreateCard(row, onSelect)
            card:SetPoint("TOPLEFT", (i - 1) * (CARD_W + GAP_X), 0)
            row.cards[i] = card
        end
    end, function(row, item)
        for i, card in ipairs(row.cards) do
            card:SetShown(item[i] ~= nil)
            if item[i] then UpdateCard(card, item[i]) end
        end
    end)
    return {
        Refresh = function(_, dungeons)
            local rows = {}
            for i, d in ipairs(dungeons) do
                local r = math.floor((i - 1) / COLS) + 1
                rows[r] = rows[r] or {}
                rows[r][#rows[r] + 1] = d
            end
            list:SetItems(rows)
        end,
    }
end

-- Ancho de la cuadricula (para centrarla)
ns.GRID_WIDTH = COLS * CARD_W + (COLS - 1) * GAP_X
