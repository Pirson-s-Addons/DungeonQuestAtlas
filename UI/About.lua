local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- VISTA PRINCIPAL: ACERCA DE
-- ==========================================
-- Igual que en WoW Translator: la entrada raiz del addon en Opciones presenta
-- el addon (logo, version, autor, enlaces y comandos) y los ajustes cuelgan de
-- ella como subcategorias.

local MARGIN_X = 16
local BRAND = "|cffd597ff"
local GOLD = "|cffffff00"
local HEADER = "|cffC47FF3"

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function SectionHeader(panel, y, text)
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", MARGIN_X, y)
    fs:SetText(HEADER .. text .. "|r")
    return y - 26
end

-- Un addon no puede abrir un enlace ni escribir en el portapapeles: la caja
-- deja la URL seleccionada para que el jugador pulse Ctrl+C.
local function UrlBox(panel, y, label, url)
    local caption = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    caption:SetPoint("TOPLEFT", MARGIN_X, y)
    caption:SetText(label)

    local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    box:SetWidth(326)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", MARGIN_X + 120, y + 4)
    box:SetAutoFocus(false)
    box:SetTextColor(1, 1, 1)
    box:SetText(url)
    box:SetCursorPosition(0)
    -- Cualquier edicion se descarta: la caja esta solo para copiar de ella
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= url then self:SetText(url) end
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local select = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    select:SetWidth(84)
    select:SetHeight(20)
    select:SetPoint("LEFT", box, "RIGHT", 10, 0)
    select:SetText(L.SELECT)
    select:SetScript("OnClick", function()
        box:SetFocus()
        box:HighlightText()
    end)
    AddTooltip(select, L.SELECT_TOOLTIP)

    return y - 32
end

-- info: { name, listName, logo, github, curseforge, commands = { { "/cmd", desc }, ... } }
-- listName: nombre para la lista de Opciones si el completo no cabe.
-- Registra la categoria raiz y la devuelve para colgar de ella los ajustes.
function ns.CreateAbout(info)
    local panel = CreateFrame("Frame")
    panel:Hide() -- nace oculto: si no, el Show() al abrir la categoria no dispara OnShow

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetWidth(128)
    logo:SetHeight(128)
    logo:SetPoint("TOPLEFT", MARGIN_X + 8, -16)
    logo:SetTexture(info.logo)

    local name = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 20, -18)
    name:SetText(BRAND .. info.name .. "|r")

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -10)
    version:SetText(GOLD .. L.VERSION .. "|r " .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    local author = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -6)
    author:SetText(GOLD .. L.AUTHOR .. "|r " .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or "Pirson"))

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", MARGIN_X, -160)
    desc:SetWidth(560)
    desc:SetJustifyH("LEFT")
    desc:SetText(L.ABOUT_DESC)

    local y = SectionHeader(panel, -200, L.LINKS)
    y = UrlBox(panel, y, "GitHub", info.github)
    y = UrlBox(panel, y, "CurseForge", info.curseforge)
    y = SectionHeader(panel, y - 14, L.COMMANDS)

    for _, entry in ipairs(info.commands) do
        local cmd = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cmd:SetPoint("TOPLEFT", MARGIN_X + 8, y)
        cmd:SetText(GOLD .. entry[1] .. "|r")

        local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", MARGIN_X + 160, y)
        text:SetWidth(400)
        text:SetJustifyH("LEFT")
        text:SetText(entry[2])

        y = y - 20
    end

    -- Logo y morado del addon en la lista de Opciones
    local category = Settings.RegisterCanvasLayoutCategory(panel,
        "|T" .. info.logo .. ":16:16|t  " .. BRAND .. (info.listName or info.name) .. "|r")
    Settings.RegisterAddOnCategory(category)
    return category
end
