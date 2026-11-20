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
        function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end, ns.ApplyScale):SetWidth(270)
    -- A su derecha: comparar con lo equipado sin pulsar Mayus (UI/Items.lua)
    Checkbox("autoCompare", L.AUTO_COMPARE, L.AUTO_COMPARE_TOOLTIP, -168):SetPoint("TOPLEFT", X + 300, -168)
    Checkbox("pickupGlow", L.PICKUP_GLOW, L.PICKUP_GLOW_TOOLTIP, -190, ns.RefreshUI):SetPoint("TOPLEFT", X + 300, -190)
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

    local boxes, pickers = {}, {}
    local function Refresh()
        for _, cb in ipairs(boxes) do
            cb:SetChecked(db[cb.key])
            if cb.dependent then
                cb:SetEnabled(not db.trackerNever)
                cb:SetAlpha(db.trackerNever and 0.5 or 1)
            end
        end
        -- Sitio del % y de la lista: atenuados con su casilla apagada
        for _, p in ipairs(pickers) do
            p:Refresh()
            p:SetActive(db[p.toggle])
            p.label:SetAlpha(db[p.toggle] and 1 or 0.5)
        end
        if panel.listSize then panel.listSize:Refresh() end
    end
    local function Box(key, label, tooltip, y, dependent, x)
        local cb = CreateFrame("CheckButton", "DungeonQuestAtlas_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X + (x or 0) + (dependent and 20 or 0), y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb.key, cb.dependent = key, dependent
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            Refresh()
            ns.RefreshRunTracker()
            if ns.UpdateRunHistoryButton then ns.UpdateRunHistoryButton() end
            if ns.UpdateThreat then ns.UpdateThreat() end
        end)
        ns.AddTooltip(cb, tooltip)
        boxes[#boxes + 1] = cb
    end

    Header(panel, -56, L.OPT_TRACKER)
    Box("trackerNever", L.OPT_TRACKER_NEVER, L.OPT_TRACKER_NEVER_TOOLTIP, -78)
    Box("trackerSolo", L.OPT_TRACKER_SOLO, L.OPT_TRACKER_SOLO_TOOLTIP, -104, true)
    Box("rareChime", L.OPT_RARE_SOUND, L.OPT_RARE_SOUND_TOOLTIP, -130)
    Box("rareGlow", L.OPT_RARE_GLOW, L.OPT_RARE_GLOW_TOOLTIP, -156)
    Box("rareToast", L.OPT_RARE_TOAST, L.OPT_RARE_TOAST_TOOLTIP, -130, nil, 340)
    Box("runHistoryButton", L.OPT_HISTORY_BUTTON, L.OPT_HISTORY_BUTTON_TOOLTIP, -182)
    Box("questAlert", L.OPT_QUEST_ALERT, L.OPT_QUEST_ALERT_TOOLTIP, -208)
    Box("rollAdvisor", L.OPT_ROLL_ADVISOR, L.OPT_ROLL_ADVISOR_TOOLTIP, -234)
    -- Amenaza de cada enemigo (UI/Threat.lua), en la columna derecha
    Box("threatPlates", L.OPT_THREAT_PLATES, L.OPT_THREAT_PLATES_TOOLTIP, -156, nil, 340)
    Box("threatList", L.OPT_THREAT_LIST, L.OPT_THREAT_LIST_TOOLTIP, -182, nil, 340)
    -- Las tiradas del juego, donde quieras (UI/RollAdvisor.lua)
    local moveRolls = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    moveRolls:SetSize(170, 22)
    moveRolls:SetPoint("TOPLEFT", X + 340, -236)
    moveRolls:SetText(L.ROLL_MOVE)
    moveRolls:SetScript("OnClick", function() ns.ToggleLootRollMover() end)
    ns.AddTooltip(moveRolls, L.ROLL_MOVE_TOOLTIP)
    Separator(panel, -268)
    Header(panel, -283, L.OPT_TRACKER_SHOW)
    Box("trackerHideTime", L.OPT_HIDE_TIME, L.OPT_HIDE_TOOLTIP, -305, true)
    Box("trackerHideXP", L.OPT_HIDE_XP, L.OPT_HIDE_TOOLTIP, -331, true)
    Box("trackerHideGold", L.OPT_HIDE_GOLD, L.OPT_HIDE_TOOLTIP, -357, true)
    Box("trackerHideBosses", L.OPT_HIDE_BOSSES, L.OPT_HIDE_TOOLTIP, -383, true)
    -- Donde van el % y la lista (UI/Threat.lua): muestra con un punto en cada esquina y lado,
    -- como en DR Tracker Forever; en la columna derecha, bajo "Mover tiradas de botin"
    local function Picker(kind, toggle, label, y, height, gap)
        local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", X + 344, y)
        text:SetText(label)
        local picker = ns.CreateThreatPicker(panel, kind, 140, height)
        picker:SetPoint("TOPLEFT", X + 380, y - gap) -- hueco para la muestra si va encima
        picker.toggle, picker.label = toggle, text
        pickers[#pickers + 1] = picker
    end
    Picker("plate", "threatPlates", L.THREAT_POS_PLATE, -263, 14, 35)
    Picker("list", "threatList", L.THREAT_POS_LIST, -338, 26, 28)
    -- Tamano de la lista de amenaza (toda: barras, letras y titulo; el ancho sigue a la ventana)
    local size = CreateFrame("Slider", "DungeonQuestAtlas_threatListScale", panel, "OptionsSliderTemplate")
    size:SetPoint("TOPLEFT", X + 10, -444)
    size:SetWidth(270)
    size:SetMinMaxValues(0.7, 1.6)
    size:SetValueStep(0.05)
    size:SetObeyStepOnDrag(true)
    local function Pct(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end
    _G[size:GetName() .. "Low"]:SetText(Pct(0.7))
    _G[size:GetName() .. "High"]:SetText(Pct(1.6))
    local function SizeLabel() _G[size:GetName() .. "Text"]:SetText(L.THREAT_LIST_SIZE .. ": " .. Pct(db.threatListScale)) end
    size:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / 0.05 + 0.5) * 0.05
        if value == db.threatListScale then return end
        db.threatListScale = value
        SizeLabel()
        if ns.UpdateThreat then ns.UpdateThreat() end
    end)
    ns.AddTooltip(size, L.THREAT_LIST_SIZE_TOOLTIP)
    function size:Refresh()
        self:SetValue(db.threatListScale)
        SizeLabel()
        self:SetEnabled(db.threatList) -- atenuado con la lista apagada
        self:SetAlpha(db.threatList and 1 or 0.5)
    end
    panel.listSize = size
    Separator(panel, -484)

    panel:SetScript("OnShow", Refresh)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -497)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        for _, cb in ipairs(boxes) do db[cb.key] = ns.DEFAULTS[cb.key] end
        db.threatPlateAt, db.threatListAt = ns.DEFAULTS.threatPlateAt, ns.DEFAULTS.threatListAt
        db.threatListScale = ns.DEFAULTS.threatListScale
        Refresh()
        if ns.UpdateThreat then ns.UpdateThreat() end
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
    Box(L.TIER_OPTION, L.TIER_OPTION_TOOLTIP, -263, false,
        function() return ns.TierIconShown() end, function(v) db.tierIcon = v and "show" or "hide" end)
    -- Tarjetas por fila de cada cuadricula (ns.GridLayout): una fila por pestana con un boton por
    -- opcion que dibuja la cuadricula en pequeno; la elegida, en dorado. Textos fijados al crear:
    -- el panel va en el idioma del cliente y L puede cambiar luego al idioma de la ventana.
    local gridTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    gridTitle:SetPoint("TOPLEFT", X, -300)
    gridTitle:SetText(L.GRID_MENU_TITLE)
    local GOLD, GREY = { 1, 0.82, 0 }, { 0.45, 0.45, 0.45 }
    local itemText = L.GRID_MENU_ITEM
    local tipText = L.GRID_COLS_TOOLTIP
    local function Columns(key, section, y)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", X + 20, y - 9)
        label:SetWidth(170)
        label:SetJustifyH("LEFT")
        label:SetText(section)
        local row = { buttons = {} }
        for cols = ns.GRID_COLS_MIN, ns.GRID_COLS_MAX do
            local b = CreateFrame("Button", nil, panel, "BackdropTemplate")
            b:SetSize(62, 32)
            b:SetPoint("TOPLEFT", X + 200 + (cols - ns.GRID_COLS_MIN) * 70, y)
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            b:SetBackdropColor(0, 0, 0, 0.55)
            -- La cuadricula en pequeno: cols tarjetas por fila, dos filas (con 2, tres de banners)
            b.cells = {}
            local areaW, areaH, gap = 46, 20, 2
            local rows = cols == 2 and 3 or 2
            local w = (areaW - (cols - 1) * gap) / cols
            local h = (areaH - (rows - 1) * gap) / rows
            for r = 0, rows - 1 do
                for c = 0, cols - 1 do
                    local cell = b:CreateTexture(nil, "ARTWORK")
                    cell:SetSize(w, h)
                    cell:SetPoint("TOPLEFT", 8 + c * (w + gap), -6 - r * (h + gap))
                    b.cells[#b.cells + 1] = cell
                end
            end
            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.08)
            b:SetScript("OnClick", function()
                if db[key] == cols then return end
                db[key] = cols
                if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
                row:Refresh()
                ns.RebuildMainFrame()
            end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(itemText:format(cols))
                GameTooltip:AddLine(tipText, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", GameTooltip_Hide)
            row.buttons[cols] = b
        end
        function row:Refresh()
            for cols, b in pairs(self.buttons) do
                local on = db[key] == cols
                local c = on and GOLD or GREY
                b:SetBackdropBorderColor(c[1], c[2], c[3], on and 1 or 0.6)
                for _, cell in ipairs(b.cells) do cell:SetColorTexture(c[1], c[2], c[3], on and 0.9 or 0.5) end
            end
        end
        widgets[#widgets + 1] = row
    end
    Columns("gridDungeons", L.TAB_DUNGEONS, -320)
    Columns("gridRaids", L.TAB_RAIDS, -360)
    Columns("gridEvents", L.TAB_EVENTS, -400)
    Separator(panel, -440)

    panel:SetScript("OnShow", Refresh)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -453)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        local grids = db.gridDungeons ~= ns.DEFAULTS.gridDungeons or db.gridRaids ~= ns.DEFAULTS.gridRaids
            or db.gridEvents ~= ns.DEFAULTS.gridEvents
        for _, key in ipairs({ "rpgAccount", "rpgShowQuests", "onyxiaIcon", "tierIcon", "gridDungeons", "gridRaids", "gridEvents" }) do
            db[key] = ns.DEFAULTS[key]
        end
        Refresh()
        if grids then ns.RebuildMainFrame() else ns.RefreshUI() end
    end)
    return panel
end

-- Subcategoria "Puntos de mejora" (Core/Upgrades.lua): cuanto vale cada estadistica en cada
-- especializacion de tu clase. Lo cambiado va a db.upgradePoints y solo cuenta para tus consejos.
-- Nombre de cada estadistica: el del juego (las claves de GetItemStats son cadenas globales)
local STATS = { { "str", "STRENGTH" }, { "agi", "AGILITY" }, { "sta", "STAMINA" }, { "int", "INTELLECT" },
    { "spi", "SPIRIT" }, { "ap", "ATTACK_POWER" }, { "rap", "RANGED_ATTACK_POWER" },
    { "fap", "FERAL_ATTACK_POWER" }, { "sp", "SPELL_DAMAGE_DONE" }, { "heal", "SPELL_HEALING_DONE" },
    { "crit", "CRIT_MELEE_RATING" }, { "scrit", "CRIT_SPELL_RATING" }, { "hit", "HIT_MELEE_RATING" },
    { "shit", "HIT_SPELL_RATING" }, { "def", "DEFENSE_SKILL_RATING" }, { "dodge", "DODGE_RATING" },
    { "parry", "PARRY_RATING" }, { "block", "BLOCK_RATING" }, { "blockv", "BLOCK_VALUE" },
    { "mp5", "MANA_REGENERATION" }, { "hp5", "HEALTH_REGEN" }, { "dps", "DAMAGE_PER_SECOND" },
    { "armor", "RESISTANCE0_NAME" } }
local function StatLabel(id, gameKey)
    local text = _G["ITEM_MOD_" .. gameKey .. "_SHORT"] or _G[gameKey]
    return (type(text) == "string" and text ~= "" and not text:find("%%")) and text or id
end
local function Num(v) return ("%g"):format(v) end

local function CreatePointsPanel()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.OPT_POINTS)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(ns.LOGO)
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", X, -40)
    help:SetWidth(440)
    help:SetJustifyH("LEFT")
    help:SetText(L.OPT_POINTS_HELP)

    -- Tu clase: su icono y su nombre en el color de la clase
    local className, class, classID
    if UnitClass then className, class, classID = UnitClass("player") end
    class = type(class) == "string" and class or ""
    local classIcon = panel:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(36, 36)
    classIcon:SetPoint("TOPLEFT", X, -94)
    if not (GetClassAtlas and class ~= "" and pcall(classIcon.SetAtlas, classIcon, GetClassAtlas(class:lower()))) then
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class])) end
    end
    local classText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    classText:SetPoint("LEFT", classIcon, "RIGHT", 12, 0)
    local color = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    classText:SetText(className or class)
    if color then classText:SetTextColor(color.r, color.g, color.b) end

    -- Especializaciones de tu clase (el druida feral, gato y oso por separado), en botones con
    -- su icono; el de tanque lleva el icono de su rol
    -- Nombre e icono de cada arbol: los de la ventana de talentos de Forever (los grupos del arbol
    -- de la clase, C_Traits, en su orden: Sagrado, Proteccion, Reprension). La API de
    -- especializaciones de Retail no los da aqui (salia "Paladin" e interrogaciones).
    local function TalentTrees()
        local trees = {}
        if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
            and C_Traits.GetGroupDisplayInfoByTreeID) then return trees end
        local ok, configID = pcall(C_ClassTalents.GetActiveConfigID)
        local info = ok and configID and select(2, pcall(C_Traits.GetConfigInfo, configID))
        local treeID = type(info) == "table" and info.treeIDs and info.treeIDs[1]
        local groups = treeID and select(2, pcall(C_Traits.GetGroupDisplayInfoByTreeID, treeID))
        if type(groups) ~= "table" then return trees end
        for _, g in ipairs(groups) do trees[#trees + 1] = g end
        table.sort(trees, function(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end)
        return trees
    end
    local choices, selected
    local function Choices()
        if choices then return choices end
        choices = {}
        local trees = TalentTrees()
        for i, s in ipairs(ns.UPGRADE_SPECS[class] or {}) do
            local name, icon = s.name, nil
            local tree = trees[i]
            if tree and type(tree.displayName) == "string" and tree.displayName ~= "" then
                name, icon = tree.displayName, tree.icon
            end
            if s.tank then
                choices[#choices + 1] = { profile = s, text = name, sub = _G[s.role] or s.role, icon = icon }
                choices[#choices + 1] = { profile = s.tank, text = name, sub = _G.TANK or "TANK", icon = icon, tank = true }
            else
                choices[#choices + 1] = { profile = s, text = name, icon = icon }
            end
        end
        return choices
    end

    local Refresh
    local specButtons = {}
    local SPEC_W, SPEC_H = 136, 40
    local function SpecButton(i)
        local b = CreateFrame("Button", nil, panel, "BackdropTemplate")
        b:SetSize(SPEC_W, SPEC_H)
        b:SetPoint("TOPLEFT", X + (i - 1) * (SPEC_W + 6), -142)
        b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(28, 28)
        b.icon:SetPoint("LEFT", 7, 0)
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b.role = b:CreateTexture(nil, "OVERLAY")
        b.role:SetSize(14, 14)
        b.role:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", 4, -4)
        b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 7, -1)
        b.name:SetPoint("RIGHT", -6, 0)
        b.name:SetJustifyH("LEFT")
        b.name:SetWordWrap(false)
        b.sub = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -2)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 3, -3)
        hl:SetPoint("BOTTOMRIGHT", -3, 3)
        hl:SetColorTexture(1, 1, 1, 0.08)
        b:SetScript("OnClick", function(self)
            selected = self.choice
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
            Refresh()
        end)
        return b
    end

    -- Estadisticas en secciones (cabecera morada); a la izquierda atributos y cuerpo a cuerpo,
    -- a la derecha hechizos y defensa. Nombre del juego con mayuscula inicial.
    local GROUPS = {
        { name = _G.STAT_CATEGORY_ATTRIBUTES or "Attributes", col = 1, stats = { str = 1, agi = 1, sta = 1, int = 1, spi = 1 } },
        { name = _G.MELEE or "Melee", col = 1, stats = { ap = 1, rap = 1, fap = 1, crit = 1, hit = 1, dps = 1 } },
        { name = _G.SPELLS or "Spells", col = 2, stats = { sp = 1, heal = 1, scrit = 1, shit = 1, mp5 = 1 } },
        { name = _G.DEFENSE or "Defense", col = 2, stats = { def = 1, dodge = 1, parry = 1, block = 1, blockv = 1, armor = 1, hp5 = 1 } },
    }
    local COL_W, ROW_H, TOP = 284, 24, -198
    local function Over(create)
        local key = selected.profile.key
        if create and not db.upgradePoints[key] then db.upgradePoints[key] = {} end
        return db.upgradePoints[key] or {}
    end
    local function Commit(row, box)
        local value = tonumber((box:GetText():gsub(",", ".")))
        if not box.cancel and value and value >= 0 and value <= 100 then
            local over = Over(true)
            over[row.id] = value ~= selected.profile[row.id] and value or nil
            if not next(over) then db.upgradePoints[selected.profile.key] = nil end
        end
        box.cancel = nil
        Refresh()
    end
    local function Capital(text) return (text:gsub("^%l", string.upper)) end
    local rows = {}
    for _, stat in ipairs(STATS) do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(COL_W - 12, ROW_H - 2)
        row.id = stat[1]
        row.band = row:CreateTexture(nil, "BACKGROUND")
        row.band:SetAllPoints()
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.label:SetPoint("LEFT", 8, 0)
        row.label:SetPoint("RIGHT", -118, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row.label:SetText(Capital(StatLabel(stat[1], stat[2])))
        row.box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        row.box:SetSize(52, 18)
        row.box:SetPoint("RIGHT", -58, 0)
        row.box:SetJustifyH("CENTER")
        row.box:SetAutoFocus(false)
        row.box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        row.box:SetScript("OnEscapePressed", function(self) self.cancel = true; self:ClearFocus() end)
        row.box:SetScript("OnEditFocusLost", function(self) Commit(row, self) end)
        ns.AddTooltip(row.box, function() return L.OPT_POINTS_DEFAULT:format(Num(selected.profile[row.id])) end)
        -- Cambiado: el de serie en gris y un boton para volver a el
        row.default = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        row.default:SetPoint("LEFT", row.box, "RIGHT", 6, 0)
        row.undo = CreateFrame("Button", nil, row)
        row.undo:SetSize(16, 16)
        row.undo:SetPoint("RIGHT", -2, 0)
        row.undo:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
        row.undo:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        row.undo:SetScript("OnClick", function()
            local over = Over()
            over[row.id] = nil
            if not next(over) then db.upgradePoints[selected.profile.key] = nil end
            Refresh()
        end)
        ns.AddTooltip(row.undo, function() return L.OPT_POINTS_DEFAULT:format(Num(selected.profile[row.id])) end)
        for _, g in ipairs(GROUPS) do if g.stats[row.id] then row.group = g end end
        rows[#rows + 1] = row
    end
    local headers = {}
    for i, g in ipairs(GROUPS) do
        headers[i] = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        headers[i]:SetText(HEADER .. g.name .. "|r")
    end
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetText(L.DEFAULTS)
    ns.AddTooltip(reset, L.OPT_POINTS_RESET_TOOLTIP)
    reset:SetScript("OnClick", function()
        if selected then db.upgradePoints[selected.profile.key] = nil end
        Refresh()
    end)
    local separator = panel:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(1, 1, 1, 0.1)
    separator:SetSize(580, 1)

    Refresh = function()
        if not selected then
            local mine = ns.MyUpgradeInfo().profile.key
            for _, c in ipairs(Choices()) do if c.profile.key == mine then selected = c end end
            selected = selected or Choices()[1]
        end
        if not selected then return end
        -- Botones de especializacion: el elegido con borde dorado y fondo claro
        for i, c in ipairs(Choices()) do
            local b = specButtons[i] or SpecButton(i)
            specButtons[i] = b
            b.choice = c
            b.icon:SetTexture(c.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            b.name:SetText(c.text)
            b.sub:SetText(c.sub or "")
            b.role:SetShown(c.tank == true)
            if c.tank then
                if not pcall(b.role.SetAtlas, b.role, "roleicon-tiny-tank") then
                    b.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
                    if GetTexCoordsForRoleSmallCircle then b.role:SetTexCoord(GetTexCoordsForRoleSmallCircle("TANK")) end
                end
            end
            local on = c == selected
            b:SetBackdropColor(on and 0.22 or 0.05, on and 0.17 or 0.04, on and 0.08 or 0.03, 0.92)
            b:SetBackdropBorderColor(on and 1 or 0.45, on and 0.82 or 0.36, on and 0.35 or 0.2)
            b.name:SetTextColor(on and 1 or 0.85, on and 0.82 or 0.85, on and 0 or 0.85)
            b.icon:SetDesaturated(not on)
            b:Show()
        end
        for i = #Choices() + 1, #specButtons do specButtons[i]:Hide() end
        -- Secciones con las estadisticas que usa la especializacion
        local over, y = Over(), { TOP, TOP }
        for i, g in ipairs(GROUPS) do
            local n = 0
            for _, row in ipairs(rows) do
                if row.group == g and type(selected.profile[row.id]) == "number" then n = n + 1 end
            end
            headers[i]:SetShown(n > 0)
            if n > 0 then
                local x = X + (g.col - 1) * (COL_W + 12)
                headers[i]:ClearAllPoints()
                headers[i]:SetPoint("TOPLEFT", x, y[g.col])
                y[g.col] = y[g.col] - 20
                local k = 0
                for _, row in ipairs(rows) do
                    local def = selected.profile[row.id]
                    if row.group == g and type(def) == "number" then
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT", x + 6, y[g.col])
                        local changed = over[row.id] ~= nil
                        row.band:SetColorTexture(1, 1, 1, k % 2 == 0 and 0.05 or 0.02)
                        row.box:SetText(Num(over[row.id] or def))
                        row.box:SetCursorPosition(0)
                        row.label:SetTextColor(1, changed and 0.82 or 1, changed and 0 or 1)
                        row.default:SetText(changed and Num(def) or "")
                        row.undo:SetShown(changed)
                        row:Show()
                        y[g.col] = y[g.col] - ROW_H
                        k = k + 1
                    end
                end
                y[g.col] = y[g.col] - 10
            end
        end
        for _, row in ipairs(rows) do
            if row.group == nil or type(selected.profile[row.id]) ~= "number" then row:Hide() end
        end
        local bottom = math.min(y[1], y[2])
        separator:ClearAllPoints()
        separator:SetPoint("TOPLEFT", X, bottom)
        reset:ClearAllPoints()
        reset:SetPoint("TOPLEFT", X, bottom - 13)
    end
    panel:SetScript("OnShow", Refresh)
    return panel
end

-- Subcategoria "Teclas y mando": los atajos de Bindings.xml con dos huecos cada uno, como
-- Opciones > Atajos de teclado del juego. Se guardan como atajos normales (SetBinding), asi
-- que tambien salen alli. Con mando vale cualquier boton y sus combinaciones (los botones
-- que el juego usa como Mayus/Ctrl/Alt: cvars GamePadEmulate*).
local BINDINGS = { "DUNGEONQUESTATLAS_TOGGLE", "DUNGEONQUESTATLAS_ITEM", "DUNGEONQUESTATLAS_ROLLS" }
local KEY_MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, UNKNOWN = true }
local MOUSE_KEYS = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function IsPadModifier(button)
    for _, cvar in ipairs({ "GamePadEmulateShift", "GamePadEmulateCtrl", "GamePadEmulateAlt" }) do
        if GetCVar(cvar) == button then return true end
    end
end

-- Orden de modificadores que espera el juego: ALT-CTRL-SHIFT-
function ns.KeyCombo(key)
    return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
end

local capture
local function Capture(binding, slot, onDone)
    if InCombatLockdown() then ns.Print(L.ROLL_MOVE_COMBAT) return end
    if not capture then
        capture = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
        capture:SetSize(420, 84)
        capture:SetPoint("CENTER", 0, 150)
        capture:SetFrameStrata("FULLSCREEN_DIALOG")
        capture:EnableKeyboard(true)
        capture:SetPropagateKeyboardInput(false)
        capture:EnableMouse(true)
        capture:Hide()
        capture.text = capture:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        capture.text:SetPoint("TOPLEFT", 14, -12)
        capture.text:SetPoint("BOTTOMRIGHT", -14, 12)
        local function Bind(key)
            capture:Hide()
            if key == "ESCAPE" or InCombatLockdown() then return end
            local combo = ns.KeyCombo(key)
            local previous = GetBindingAction(combo)
            local old = select(capture.slot, GetBindingKey(capture.binding))
            if old then SetBinding(old) end
            SetBinding(combo, capture.binding)
            SaveBindings(GetCurrentBindingSet())
            if previous ~= "" and previous ~= capture.binding then
                ns.Print(L.KEY_REPLACED:format(GetBindingText(combo), _G["BINDING_NAME_" .. previous] or previous))
            end
            if capture.onDone then capture.onDone() end
        end
        capture:SetScript("OnKeyDown", function(_, key) if not KEY_MODIFIERS[key] then Bind(key) end end)
        capture:SetScript("OnMouseDown", function(_, button)
            if MOUSE_KEYS[button] then Bind(MOUSE_KEYS[button]) else capture:Hide() end
        end)
        if capture.EnableGamePadButton then
            capture:EnableGamePadButton(true)
            capture:SetScript("OnGamePadButtonDown", function(_, button)
                if button == "PAD2" then return capture:Hide() end -- B cancela, como en el juego
                if not IsPadModifier(button) then Bind(button) end
            end)
        end
    end
    capture.binding, capture.slot, capture.onDone = binding, slot, onDone
    capture.text:SetText(L.KEY_CAPTURE:format(_G["BINDING_NAME_" .. binding] or binding))
    capture:Show()
end

local function CreateKeysPanel()
    local panel = CreateFrame("Frame")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.OPT_KEYS)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(ns.LOGO)
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", X, -44)
    hint:SetWidth(440)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.KEYS_HINT)

    Header(panel, -128, L.OPT_KEYS)
    local slots = {}
    local function Refresh()
        for _, b in ipairs(slots) do
            local key = select(b.slot, GetBindingKey(b.binding))
            b:SetText(key and GetBindingText(key) or ("|cff808080" .. (NOT_BOUND or "-") .. "|r"))
        end
    end
    for i, binding in ipairs(BINDINGS) do
        local y = -150 - (i - 1) * 32
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", X, y - 6)
        label:SetWidth(200)
        label:SetJustifyH("LEFT")
        label:SetText(_G["BINDING_NAME_" .. binding] or binding)
        for slot = 1, 2 do
            local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
            b:SetSize(170, 26)
            b:SetPoint("TOPLEFT", X + 210 + (slot - 1) * 180, y)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b.binding, b.slot = binding, slot
            b:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    if InCombatLockdown() then ns.Print(L.ROLL_MOVE_COMBAT) return end
                    local key = select(self.slot, GetBindingKey(self.binding))
                    if key then SetBinding(key); SaveBindings(GetCurrentBindingSet()) end
                    Refresh()
                else
                    Capture(self.binding, self.slot, Refresh)
                end
            end)
            ns.AddTooltip(b, L.KEY_SLOT_TOOLTIP)
            slots[#slots + 1] = b
        end
    end
    local bottom = -150 - #BINDINGS * 32 - 6
    Separator(panel, bottom)

    panel:SetScript("OnShow", Refresh)
    panel:RegisterEvent("UPDATE_BINDINGS") -- cambiadas en la ventana del juego
    panel:SetScript("OnEvent", function() if panel:IsShown() then Refresh() end end)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, bottom - 13)
    reset:SetText(L.KEYS_CLEAR)
    ns.AddTooltip(reset, L.KEYS_CLEAR_TOOLTIP)
    reset:SetScript("OnClick", function()
        if InCombatLockdown() then ns.Print(L.ROLL_MOVE_COMBAT) return end
        for _, binding in ipairs(BINDINGS) do
            for _, key in ipairs({ GetBindingKey(binding) }) do SetBinding(key) end
        end
        SaveBindings(GetCurrentBindingSet())
        Refresh()
    end)
    return panel
end

function ns.CreateOptions()
    local root = ns.CreateAbout({
        name = "Dungeon Quest Atlas Forever",
        listName = "Dungeon Quest", -- "Dungeon Quest Atlas" no cabe en la lista de Opciones: se partia en dos lineas
        logo = ns.LOGO,
        github = "https://github.com/Pirson-s-Addons/DungeonQuestAtlas",
        issues = ns.ISSUES_URL,
        curseforge = "https://www.curseforge.com/wow/addons/dungeon-quest-atlas",
        commands = ns.CommandList(),
    })
    general = Settings.RegisterCanvasLayoutSubcategory(root, CreateGeneral(), L.GENERAL)
    tracker = Settings.RegisterCanvasLayoutSubcategory(root, CreateTrackerPanel(), L.OPT_TRACKER)
    adventure = Settings.RegisterCanvasLayoutSubcategory(root, CreateAdventurePanel(), L.MODE_RPG)
    Settings.RegisterCanvasLayoutSubcategory(root, CreatePointsPanel(), L.OPT_POINTS)
    Settings.RegisterCanvasLayoutSubcategory(root, CreateKeysPanel(), L.OPT_KEYS)
end

function ns.OpenTrackerOptions()
    if tracker and not InCombatLockdown() then Settings.OpenToCategory(tracker:GetID()) end
end

function ns.OpenOptions()
    if general then Settings.OpenToCategory(general:GetID()) end
end
