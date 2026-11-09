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
    if slot == "" then slot = nil end -- recetas: hueco "INVTYPE_NON_EQUIP_IGNORE" vacio (", Peleteria")
    local kind = slot and subType and subType ~= "" and slot ~= subType and (slot .. ", " .. subType) or slot or subType
    return { name = name, link = link, quality = quality, icon = icon or QUESTION, kind = kind }
end

-- ------------------------------------------
-- Favoritos (por cuenta): clic derecho en un objeto
-- ------------------------------------------
function ns.IsFavorite(itemID)
    return itemID ~= nil and ns.db ~= nil and ns.db.favorites[itemID] == true
end

function ns.ToggleFavorite(itemID)
    ns.db.favorites[itemID] = not ns.IsFavorite(itemID) or nil
    if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
    if GameTooltip:IsShown() and GameTooltip:GetOwner() and GameTooltip:GetOwner().UpdateTooltip then
        GameTooltip:GetOwner():UpdateTooltip()
    end
    ns.RefreshUI()
end

-- Estrella dorada en la esquina del icono
function ns.CreateFavoriteStar(parent, icon)
    local star = parent:CreateTexture(nil, "OVERLAY", nil, 2)
    star:SetSize(18, 18)
    star:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 5, 5)
    if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("PetJournal-FavoritesIcon")
        and star:SetAtlas("PetJournal-FavoritesIcon") ~= false) then
        star:SetTexture("Interface\\Common\\ReputationStar")
        star:SetTexCoord(0, 0.5, 0, 0.5)
    end
    star:Hide()
    return star
end

function ns.QualityColor(quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    return color and color.hex or "|cffffffff"
end

-- Objetos cuyo tooltip cierra el cliente de Forever (BC_ASSERT "format - mixing of
-- ordered and unordered argument specifications", datos rotos de Blizzard; pcall no
-- sirve): solo nombre y tipo. 273042: botas del Devorador de mana (Dalaran), beta 70291.
local BROKEN_TOOLTIP = { [273042] = true }

local function ShowTooltip(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if BROKEN_TOOLTIP[self.itemID] then
        local item = ns.ItemInfo(self.itemID)
        GameTooltip:AddLine(ns.QualityColor(item.quality) .. (item.name or ("#" .. self.itemID)) .. "|r")
        if item.kind then GameTooltip:AddLine(item.kind, 1, 1, 1) end
    else
        GameTooltip:SetItemByID(self.itemID)
    end
    if IsModifiedClick and IsModifiedClick("COMPAREITEMS") and GameTooltip_ShowCompareItem then
        GameTooltip_ShowCompareItem(GameTooltip)
    end
    if self.tipLine then GameTooltip:AddLine(self.tipLine, 0.25, 1, 0.25, true) end
    GameTooltip:AddLine(L.LOOT_HINT, 0.5, 0.5, 0.5, true)
    if ns.IsFavorite then GameTooltip:AddLine(ns.IsFavorite(self.itemID) and L.FAV_REMOVE or L.FAV_ADD, 0.5, 0.5, 0.5, true) end
    GameTooltip:Show()
end

local function OnClick(self, button)
    if button == "RightButton" then -- favoritos (UI/LootSearch.lua)
        if self.itemID and ns.ToggleFavorite then ns.ToggleFavorite(self.itemID) end
        return
    end
    if self.onPlainClick and not IsModifiedClick() then return self.onPlainClick(self, button) end
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
    -- El tipo, sobre la parte oscura de la fila: claro. Lo de la derecha (%, jefe)
    -- cae donde la fila del Diario ya se ha desvanecido sobre el papel: tinta.
    button.extra = ns.PaperText(button, "GameFontBlack", ns.INK)
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
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- GameTooltip llama a UpdateTooltip mientras se ve: pulsar Shift compara al momento
    button.UpdateTooltip = ShowTooltip
    button.star = ns.CreateFavoriteStar(button, button.icon)
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
    button.star:SetShown(ns.IsFavorite(id))
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
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.UpdateTooltip = ShowTooltip
    card.star = ns.CreateFavoriteStar(card, card.icon)
    return card
end

-- Un objeto (id, cuantos) o, sin id, un texto con icono (la XP, el dinero)
-- Tarjeta de objeto con sitio conocido (ns.ItemPlaces): lleva la gema y un clic lo marca
local function MarkItem(card)
    local info = ns.ItemInfo(card.itemID)
    local mode, point = ns.MarkPlace(ns.ItemPlaces[card.itemID], info.name or ("#" .. card.itemID), nil, "item")
    if mode and point then ns.OpenMapAt(point.mapID) end
end

function ns.CreatePlaceCard(parent)
    local card = ns.CreateRewardCard(parent)
    card.pin = card:CreateTexture(nil, "OVERLAY")
    card.pin:SetSize(16, 16)
    card.pin:SetPoint("TOPLEFT", card.icon, "TOPLEFT", -3, 3)
    card.pin:SetTexture(ns.IMG .. "pin_dqa")
    return card
end

function ns.SetPlaceCard(card, itemID, count)
    ns.SetRewardCard(card, itemID, count)
    local known = ns.ItemPlaces[itemID] ~= nil
    card.pin:SetShown(known)
    card.tipLine = known and L.ITEM_PLACE_HINT or nil
    card.onPlainClick = known and MarkItem or nil
end

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
    card.star:SetShown(id ~= nil and ns.IsFavorite(id))
end

function ns.CreateItemButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(ns.ITEM_ROW_HEIGHT)
    ns.SetupItemButton(button)
    return button
end
