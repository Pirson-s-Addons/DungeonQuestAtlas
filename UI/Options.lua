local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, "General": panel propio
-- con la plantilla de todos los addons de Pirson.

local HEADER = "|cffC47FF3"
local X = 16
local general, tracker, adventure

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
    Checkbox("hideCompleted", L.HIDE_COMPLETED, L.HIDE_COMPLETED_TOOLTIP, -78, ns.RefreshUI)
    Checkbox("autoFaction", L.AUTO_FACTION, L.AUTO_FACTION_TOOLTIP, -104)
    Checkbox("hideOtherClasses", L.HIDE_OTHER_CLASSES, L.HIDE_OTHER_CLASSES_TOOLTIP, -130, ns.RefreshUI)
    -- Por personaje (UI/JournalMode.lua); a la derecha, bajo el logo
    Checkbox("journalMode", L.RPG_OPTION, L.RPG_OPTION_TOOLTIP, -130, nil,
        function() return ns.IsRPGMode() end, function(v) ns.SetJournalMode(v and "rpg" or "full") end)
        :SetPoint("TOPLEFT", X + 300, -130)

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

    Slider("scale", L.SCALE, L.SCALE_TOOLTIP .. "\n" .. L.RESIZE_HINT, -179, ns.SCALE_MIN, ns.SCALE_MAX, 0.05,
        function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end, ns.ApplyScale)
    Separator(panel, -214)

    -- Mapa y enlaces ------------------------------------------------------------
    Header(panel, -229, L.HEADER_MAP)
    Checkbox("minimap", L.SHOW_MINIMAP, L.SHOW_MINIMAP_TOOLTIP, -251, ns.UpdateMinimapButton,
        function() return not db.minimap.hide end, function(v) db.minimap.hide = not v end)
    Checkbox("chainGuide", L.CHAIN_GUIDE, L.CHAIN_GUIDE_TOOLTIP, -277)
    -- Debajo, en la izquierda: a la derecha pisaba el logo
    Checkbox("worldMapPlan", L.WORLD_MAP_PLAN, L.WORLD_MAP_PLAN_TOOLTIP, -303, ns.ApplyWorldMapPlan)
    -- A su derecha, bajo las entradas: el origen en el tooltip de los objetos (UI/ItemSource.lua)
    Checkbox("itemSourceTip", L.ITEM_SOURCE_TIP, L.ITEM_SOURCE_TIP_TOOLTIP, -303):SetPoint("TOPLEFT", X + 300, -303)
    -- Entradas en zonas y en continentes, a la derecha: abajo ya no cabe nada.
    -- Las mismas que el boton del mapa del mundo (clic derecho y clic).
    local entranceSize -- atenuado si no hay entradas en ningun mapa
    local function EntrancesChanged()
        ns.RefreshMapPins()
        entranceSize:Refresh()
    end
    Checkbox("mapEntrances", L.MAP_ENTRANCES, L.MAP_ENTRANCES_TOOLTIP, -251, EntrancesChanged)
        :SetPoint("TOPLEFT", X + 300, -251)
    Checkbox("mapEntrancesContinent", L.MAP_ENTRANCES_CONTINENT, L.MAP_ENTRANCES_CONTINENT_TOOLTIP, -277,
        EntrancesChanged):SetPoint("TOPLEFT", X + 300, -277)
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
    Dropdown("waypointMode", L.GUIDE, L.GUIDE_TOOLTIP, -337, {
        { "own", L.GUIDE_OWN },
        { "native", L.GUIDE_NATIVE },
        { "tomtom", L.GUIDE_TOMTOM, disabled = function() return not TomTomLoaded() end },
    })
    Dropdown("wowheadLang", L.WOWHEAD_LANG, L.WOWHEAD_LANG_TOOLTIP, -369, {
        { "auto", L.LANG_AUTO },
        { "en", L.LANG_ENGLISH },
    })
    -- Los dos tamanos lado a lado: abajo ya no cabe nada
    local function Px(v) return tostring(math.floor(v + 0.5)) end
    Slider("pinSize", L.PIN_SIZE, L.PIN_SIZE_TOOLTIP, -422, 10, 32, 1, Px, ns.ApplyPinSize):SetWidth(190)
    entranceSize = Slider("entranceSize", L.ENTRANCE_SIZE, L.ENTRANCE_SIZE_TOOLTIP, -422, 16, 56, 1, Px, ns.RefreshMapPins)
    entranceSize:SetWidth(190)
    entranceSize:SetPoint("TOPLEFT", X + 310, -422)
    local refreshSize = entranceSize.Refresh
    entranceSize.Refresh = function(self)
        refreshSize(self)
        local on = db.mapEntrances or db.mapEntrancesContinent
        self:SetEnabled(on)
        self:SetAlpha(on and 1 or 0.5)
    end
    Separator(panel, -455)

    -- Recolector ----------------------------------------------------------------
    Header(panel, -470, L.HEADER_COLLECTOR)
    Checkbox("collect", L.COLLECT, L.COLLECT_TOOLTIP, -492)
    Checkbox("debug", L.DEBUG, L.DEBUG_TOOLTIP, -518)
    Separator(panel, -552)

    local function Refresh()
        for _, widget in ipairs(widgets) do widget:Refresh() end
    end
    panel:SetScript("OnShow", Refresh)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -565) -- todo dentro del alto que da el juego
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        ns.ResetOptions()
        ns.ApplyScale()
        ns.ApplyPinSize()
        ns.RefreshMapPins()
        ns.ApplyWorldMapPlan()
        ns.SetMapBossScale(ns.db.mapBossScale)
        ns.UpdateMinimapButton()
        ns.SetLanguage(ns.db.language) -- vuelve al idioma del juego
        ns.RefreshUI()
        Refresh()
    end)

    return panel
end

-- Subcategoria "Seguimiento de mazmorras" (UI/RunTracker.lua)
local function CreateTrackerPanel()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.OPT_TRACKER)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(ns.LOGO)
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    local boxes = {}
    local function Refresh()
        for _, cb in ipairs(boxes) do
            cb:SetChecked(db[cb.key])
            if cb.dependent then
                cb:SetEnabled(not db.trackerNever)
                cb:SetAlpha(db.trackerNever and 0.5 or 1)
            end
        end
    end
    local function Box(key, label, tooltip, y, dependent)
        local cb = CreateFrame("CheckButton", "DungeonQuestAtlas_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X + (dependent and 20 or 0), y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb.key, cb.dependent = key, dependent
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            Refresh()
            ns.RefreshRunTracker()
            if ns.UpdateRunHistoryButton then ns.UpdateRunHistoryButton() end
        end)
        ns.AddTooltip(cb, tooltip)
        boxes[#boxes + 1] = cb
    end

    Header(panel, -56, L.OPT_TRACKER)
    Box("trackerNever", L.OPT_TRACKER_NEVER, L.OPT_TRACKER_NEVER_TOOLTIP, -78)
    Box("trackerSolo", L.OPT_TRACKER_SOLO, L.OPT_TRACKER_SOLO_TOOLTIP, -104, true)
    Box("rareChime", L.OPT_RARE_SOUND, L.OPT_RARE_SOUND_TOOLTIP, -130)
    Box("rareGlow", L.OPT_RARE_GLOW, L.OPT_RARE_GLOW_TOOLTIP, -156)
    Box("runHistoryButton", L.OPT_HISTORY_BUTTON, L.OPT_HISTORY_BUTTON_TOOLTIP, -182)
    Separator(panel, -216)
    Header(panel, -231, L.OPT_TRACKER_SHOW)
    Box("trackerHideTime", L.OPT_HIDE_TIME, L.OPT_HIDE_TOOLTIP, -253, true)
    Box("trackerHideXP", L.OPT_HIDE_XP, L.OPT_HIDE_TOOLTIP, -279, true)
    Box("trackerHideGold", L.OPT_HIDE_GOLD, L.OPT_HIDE_TOOLTIP, -305, true)
    Box("trackerHideBosses", L.OPT_HIDE_BOSSES, L.OPT_HIDE_TOOLTIP, -331, true)
    Separator(panel, -365)

    panel:SetScript("OnShow", Refresh)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -378)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        for _, cb in ipairs(boxes) do db[cb.key] = ns.DEFAULTS[cb.key] end
        Refresh()
        ns.RefreshRunTracker()
        if ns.UpdateRunHistoryButton then ns.UpdateRunHistoryButton() end
    end)
    return panel
end

-- Subcategoria "Modo aventura" (UI/JournalMode.lua) y el icono de Onyxia de la portada
local function CreateAdventurePanel()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.MODE_RPG)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(ns.LOGO)
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    local widgets = {}
    local function Refresh()
        local rpg = ns.IsRPGMode()
        for _, w in ipairs(widgets) do
            if w.Refresh then w:Refresh() end
            if w.dependent then
                w:SetEnabled(rpg)
                w:SetAlpha(rpg and 1 or 0.5)
            end
        end
    end
    local function Box(label, tooltip, y, dependent, get, set)
        local name = "DungeonQuestAtlas_Adventure" .. (#widgets + 1)
        local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X + (dependent and 20 or 0), y)
        _G[name .. "Text"]:SetText(label)
        cb.dependent = dependent
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            Refresh()
            ns.RefreshUI()
        end)
        cb.Refresh = function(self) self:SetChecked(get()) end
        ns.AddTooltip(cb, tooltip)
        widgets[#widgets + 1] = cb
        return cb
    end
    local function Flag(key) return function() return db[key] end, function(v) db[key] = v end end
    local function Button(label, tooltip, x, y, onClick)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(180, 24)
        b:SetPoint("TOPLEFT", X + x, y)
        b:SetText(label)
        b:SetScript("OnClick", onClick)
        ns.AddTooltip(b, tooltip)
        b.dependent = true
        widgets[#widgets + 1] = b
    end

    Header(panel, -56, L.MODE_RPG)
    Box(L.RPG_OPTION, L.RPG_OPTION_TOOLTIP, -78, false,
        function() return ns.IsRPGMode() end, function(v) ns.SetJournalMode(v and "rpg" or "full") end)
    Box(L.RPG_ACCOUNT, L.RPG_ACCOUNT_TOOLTIP, -104, true, Flag("rpgAccount"))
    Box(L.RPG_SHOW_QUESTS, L.RPG_SHOW_QUESTS_TOOLTIP, -130, true, Flag("rpgShowQuests"))
    Button(L.RPG_EXPORT, L.RPG_EXPORT_TOOLTIP, 24, -164, ns.ShowExportProgress)
    Button(L.RPG_IMPORT, L.RPG_IMPORT_TOOLTIP, 214, -164, ns.ShowImportProgress)
    Separator(panel, -200)

    Header(panel, -215, L.HEADER_HOME)
    Box(L.ONYXIA_OPTION, L.ONYXIA_OPTION_TOOLTIP, -237, false,
        function() return ns.OnyxiaIconShown() end, function(v) db.onyxiaIcon = v and "show" or "hide" end)
    Separator(panel, -271)

    panel:SetScript("OnShow", Refresh)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -284)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        for _, key in ipairs({ "rpgAccount", "rpgShowQuests", "onyxiaIcon" }) do db[key] = ns.DEFAULTS[key] end
        Refresh()
        ns.RefreshUI()
    end)
    return panel
end

function ns.CreateOptions()
    local root = ns.CreateAbout({
        name = "Dungeon Quest Atlas Forever",
        listName = "Dungeon Quest Atlas",
        logo = ns.LOGO,
        github = "https://github.com/Pirson-s-Addons/DungeonQuestAtlas",
        issues = ns.ISSUES_URL,
        curseforge = "https://www.curseforge.com/wow/addons/dungeon-quest-atlas",
        commands = ns.CommandList(),
    })
    general = Settings.RegisterCanvasLayoutSubcategory(root, CreateGeneral(), L.GENERAL)
    tracker = Settings.RegisterCanvasLayoutSubcategory(root, CreateTrackerPanel(), L.OPT_TRACKER)
    adventure = Settings.RegisterCanvasLayoutSubcategory(root, CreateAdventurePanel(), L.MODE_RPG)
end

function ns.OpenTrackerOptions()
    if tracker and not InCombatLockdown() then Settings.OpenToCategory(tracker:GetID()) end
end

function ns.OpenOptions()
    if general then Settings.OpenToCategory(general:GetID()) end
end
