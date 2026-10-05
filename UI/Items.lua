local _, ns = ...
local L = ns.L

-- ==========================================
-- OBJETOS: filas de botin del Diario de mazmorras
-- ==========================================
-- Para el botin de los jefes y las recompensas de mision, con el marco de las
-- filas de botin del Diario. Nombre, calidad, icono y tipo los da el cliente,
-- en su idioma; si aun no tiene el objeto, lo pide e ITEM_DATA_LOAD_RESULT
-- refresca la ventana (Core.lua).
-- Raton encima: tooltip (Shift compara con lo equipado). Mayus+clic: enlace al
-- chat. Ctrl+clic: probador.

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
ns.ITEM_ROW_HEIGHT = 45

local function GetItemInfo(id)
    local get = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    return get(id)
end

-- { name, link, quality, icon, kind } o, sin cargar aun, lo que se sepa ya
function ns.ItemInfo(id)
    local name, link, quality, _, _, _, subType, _, equipLoc, icon = GetItemInfo(id)
    if not name then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if instant then _, _, subType, equipLoc, icon = instant(id) end
    end
    -- "Dos manos, Hacha" / "Cuero" / "Pocion": ranura y tipo en el idioma del juego
    local slot = equipLoc and equipLoc ~= "" and _G[equipLoc]
    local kind = slot and subType and subType ~= "" and slot ~= subType and (slot .. ", " .. subType) or slot or subType
    return { name = name, link = link, quality = quality, icon = icon or QUESTION, kind = kind }
end

function ns.QualityColor(quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    return color and color.hex or "|cffffffff"
end

local function ShowTooltip(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.itemID)
    if IsModifiedClick and IsModifiedClick("COMPAREITEMS") and GameTooltip_ShowCompareItem then
        GameTooltip_ShowCompareItem(GameTooltip)
    end
    GameTooltip:AddLine(L.LOOT_HINT, 0.5, 0.5, 0.5, true)
    GameTooltip:Show()
end

local function OnClick(self)
    local link = self.itemID and select(2, GetItemInfo(self.itemID))
    if link and HandleModifiedItemClick then HandleModifiedItemClick(link) end
end

-- Anade el marco de fila de botin, icono, nombre, tipo y un texto a la
-- derecha (probabilidad) a un boton (nuevo o fila de una lista)
function ns.SetupItemButton(button)
    button.frame = button:CreateTexture(nil, "BORDER")
    button.frame:SetAllPoints()
    ns.SetEJTexture(button.frame, "LootFrame")
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(40, 40)
    button.icon:SetPoint("LEFT", 3, 0)
    button.iconBorder = button:CreateTexture(nil, "OVERLAY")
    button.iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
    button.iconBorder:SetAllPoints(button.icon)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -2, 2)
    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    button.name:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 8, -5)
    button.name:SetPoint("RIGHT", -10, 0)
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(false)
    -- Sobre la fila de botin del Diario (oscura): texto claro
    button.extra = ns.PaperText(button, "GameFontBlack", ns.TEXT_ON_DARK)
    button.extra:SetPoint("BOTTOMRIGHT", -12, 7)
    button.info = ns.PaperText(button, "GameFontBlack", ns.TEXT_ON_DARK)
    button.info:SetPoint("BOTTOMLEFT", button.icon, "BOTTOMRIGHT", 8, 4)
    button.info:SetPoint("RIGHT", button.extra, "LEFT", -8, 0)
    button.info:SetWordWrap(false)
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(button.icon)
    hl:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", OnClick)
    -- GameTooltip llama a UpdateTooltip mientras se ve: pulsar Shift compara al momento
    button.UpdateTooltip = ShowTooltip
end

-- extra: texto a la derecha ("12.5%"); count: cuantos da
function ns.SetItemButton(button, id, count, extra)
    button.itemID = id
    local info = ns.ItemInfo(id)
    button.icon:SetTexture(info.icon)
    button.count:SetText(count and count > 1 and count or "")
    button.name:SetText(ns.QualityColor(info.quality) .. (info.name or ("#" .. id)) .. "|r")
    local color = info.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[info.quality]
    if color and color.r then
        button.iconBorder:SetVertexColor(color.r, color.g, color.b)
        button.iconBorder:Show()
    else
        button.iconBorder:Hide()
    end
    button.info:SetText(info.kind or "")
    button.extra:SetText(extra or "")
end

-- Tarjeta de recompensa, como las de la ventana de misiones del juego
-- (QuestInfoRewardItemCodeTemplate): el icono con el borde de su calidad y el
-- nombre sobre la placa de objeto de mision, en dos lineas si hace falta.
-- Media columna de ancho; quien la crea la coloca.
ns.REWARD_CARD_HEIGHT = 40

function ns.CreateRewardCard(parent)
    local card = CreateFrame("Button", nil, parent)
    card:SetHeight(ns.REWARD_CARD_HEIGHT)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(ns.REWARD_CARD_HEIGHT - 1, ns.REWARD_CARD_HEIGHT - 1)
    card.icon:SetPoint("LEFT")
    card.iconBorder = card:CreateTexture(nil, "OVERLAY")
    card.iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
    card.iconBorder:SetAllPoints(card.icon)
    -- La placa del juego mide 128x64 con aire transparente alrededor
    local plate = card:CreateTexture(nil, "BACKGROUND")
    plate:SetTexture("Interface\\QuestFrame\\UI-QuestItemNameFrame")
    plate:SetPoint("LEFT", card.icon, "RIGHT", -10, 0)
    plate:SetPoint("RIGHT", 6, 0)
    plate:SetHeight(64)
    card.count = card:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    card.count:SetPoint("BOTTOMRIGHT", card.icon, "BOTTOMRIGHT", -2, 2)
    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.name:SetPoint("LEFT", card.icon, "RIGHT", 6, 0)
    card.name:SetPoint("RIGHT", -6, 0)
    card.name:SetJustifyH("LEFT")
    card.name:SetMaxLines(2)
    local hl = card:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(card.icon)
    hl:SetColorTexture(1, 1, 1, 0.15)
    card:SetScript("OnEnter", ShowTooltip)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card:SetScript("OnClick", OnClick)
    card.UpdateTooltip = ShowTooltip
    return card
end

-- Un objeto (id, cuantos) o, sin id, un texto con icono (la XP, el dinero)
function ns.SetRewardCard(card, id, count, icon, text)
    card.itemID = id
    local info = id and ns.ItemInfo(id)
    card.icon:SetTexture(info and info.icon or icon)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.count:SetText(count and count > 1 and count or "")
    local color = info and info.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[info.quality]
    card.iconBorder:SetShown(color and color.r ~= nil or false)
    if color and color.r then card.iconBorder:SetVertexColor(color.r, color.g, color.b) end
    card.name:SetText(info and (ns.QualityColor(info.quality) .. (info.name or ("#" .. id)) .. "|r") or text)
end

function ns.CreateItemButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(ns.ITEM_ROW_HEIGHT)
    ns.SetupItemButton(button)
    return button
end
