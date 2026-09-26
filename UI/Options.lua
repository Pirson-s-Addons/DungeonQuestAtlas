local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, "General": panel propio
-- con la plantilla de todos los addons de Pirson.

local HEADER = "|cffC47FF3"
local X = 16
local general

local function Header(panel, y, text)
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", X, y)
    fs:SetText(HEADER .. text .. "|r")
end

local function Separator(panel, y)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.1)
    line:SetSize(580, 1)
    line:SetPoint("TOPLEFT", X, y)
end

local function TomTomLoaded()
    return C_AddOns.IsAddOnLoaded("TomTom") and true or false
end

local function CreateGeneral()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel:Hide() -- nace oculto: si no, el Show() al abrir la categoria no dispara OnShow
    local widgets = {}

    -- get/set opcionales para las opciones que no son un booleano de db
    local function Checkbox(key, label, tooltip, y, onChange, get, set)
        local cb = CreateFrame("CheckButton", "DungeonQuestAtlas_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X, y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        get = get or function() return db[key] end
        set = set or function(v) db[key] = v end
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            if onChange then onChange() end
        end)
        ns.AddTooltip(cb, tooltip)
        cb.Refresh = function(self) self:SetChecked(get()) end
        widgets[#widgets + 1] = cb
        return cb
    end

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.OPTIONS_TITLE)

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(ns.LOGO)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    -- Ventana -----------------------------------------------------------------
    Header(panel, -56, L.HEADER_WINDOW)
    Checkbox("hideCompleted", L.HIDE_COMPLETED, L.HIDE_COMPLETED_TOOLTIP, -81, ns.RefreshUI)
    Checkbox("autoFaction", L.AUTO_FACTION, L.AUTO_FACTION_TOOLTIP, -111)

    -- "Etiqueta: valor", con el minimo y el maximo debajo
    local function Slider(key, label, tooltip, y, min, max, step, format, onChange)
        local name = "DungeonQuestAtlas_" .. key
        local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", X + 10, y)
        slider:SetWidth(400)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(format(min))
        _G[name .. "High"]:SetText(format(max))
        local function Label() _G[name .. "Text"]:SetText(label .. ": " .. format(db[key])) end
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            if value == db[key] then return end
            db[key] = value
            Label()
            onChange()
        end)
        ns.AddTooltip(slider, tooltip)
        slider.Refresh = function(self)
            self:SetValue(db[key])
            Label()
        end
        widgets[#widgets + 1] = slider
        return slider
    end

    Slider("scale", L.SCALE, L.SCALE_TOOLTIP, -165, 0.6, 1.5, 0.05,
        function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end, ns.ApplyScale)
    Separator(panel, -205)

    -- Mapa y enlaces ------------------------------------------------------------
    Header(panel, -225, L.HEADER_MAP)
    Checkbox("minimap", L.SHOW_MINIMAP, L.SHOW_MINIMAP_TOOLTIP, -250, ns.UpdateMinimapButton,
        function() return not db.minimap.hide end, function(v) db.minimap.hide = not v end)
    -- Desplegable con etiqueta a la izquierda: options = { { valor, texto }, ... }
    local function Dropdown(key, label, tooltip, y, options)
        local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", X + 4, y)
        fs:SetText(label)
        local dd = CreateFrame("Frame", "DungeonQuestAtlas_" .. key, panel, "UIDropDownMenuTemplate")
        dd:SetPoint("LEFT", fs, "RIGHT", 0, -2)
        UIDropDownMenu_SetWidth(dd, 200)
        ns.AddTooltip(dd, tooltip)
        local function Text()
            for _, o in ipairs(options) do if o[1] == db[key] then return o[2] end end
        end
        UIDropDownMenu_Initialize(dd, function()
            for _, o in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = o[2]
                info.checked = db[key] == o[1]
                info.disabled = o.disabled and o.disabled()
                info.func = function()
                    db[key] = o[1]
                    UIDropDownMenu_SetText(dd, o[2])
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        dd.Refresh = function(self) UIDropDownMenu_SetText(self, Text()) end
        widgets[#widgets + 1] = dd
        return dd
    end

    -- Sin TomTom cargado, su opcion sale desactivada en la lista
    Dropdown("waypointMode", L.GUIDE, L.GUIDE_TOOLTIP, -287, {
        { "own", L.GUIDE_OWN },
        { "native", L.GUIDE_NATIVE },
        { "tomtom", L.GUIDE_TOMTOM, disabled = function() return not TomTomLoaded() end },
    })
    Dropdown("wowheadLang", L.WOWHEAD_LANG, L.WOWHEAD_LANG_TOOLTIP, -322, {
        { "auto", L.LANG_AUTO },
        { "en", L.LANG_ENGLISH },
    })
    Slider("pinSize", L.PIN_SIZE, L.PIN_SIZE_TOOLTIP, -375, 10, 32, 1,
        function(v) return tostring(math.floor(v + 0.5)) end, ns.ApplyPinSize)
    Separator(panel, -415)

    -- Recolector ----------------------------------------------------------------
    Header(panel, -435, L.HEADER_COLLECTOR)
    Checkbox("collect", L.COLLECT, L.COLLECT_TOOLTIP, -460)
    Checkbox("debug", L.DEBUG, L.DEBUG_TOOLTIP, -490)
    Separator(panel, -530)

    local function Refresh()
        for _, widget in ipairs(widgets) do widget:Refresh() end
    end
    panel:SetScript("OnShow", Refresh)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -550)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        ns.ResetOptions()
        ns.ApplyScale()
        ns.ApplyPinSize()
        ns.UpdateMinimapButton()
        ns.RefreshUI()
        Refresh()
    end)

    return panel
end

function ns.CreateOptions()
    local root = ns.CreateAbout({
        name = "Dungeon Quest Atlas Forever",
        listName = "Dungeon Quest Atlas",
        logo = ns.LOGO,
        github = "https://github.com/Pirson-s-Addons/DungeonQuestAtlas",
        curseforge = "https://www.curseforge.com/wow/addons/dungeon-quest-atlas-forever",
        commands = ns.CommandList(),
    })
    general = Settings.RegisterCanvasLayoutSubcategory(root, CreateGeneral(), L.GENERAL)
end

function ns.OpenOptions()
    if general then Settings.OpenToCategory(general:GetID()) end
end
