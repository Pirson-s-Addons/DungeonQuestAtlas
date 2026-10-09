local _, ns = ...
local L = ns.L

-- ==========================================
-- VENTANA PRINCIPAL: como la Guia de aventuras
-- ==========================================
-- Marco de Blizzard con retrato (PortraitFrameTemplate), del tamano del Diario.
-- Arriba, las migas ("Principal > Mazmorra", NavBar del juego), el idioma y el
-- buscador. Tres vistas:
--   portada: "Mazmorras", los filtros y la cuadricula de tarjetas;
--   mazmorra: el libro del Diario, lista a la izquierda y detalle a la derecha;
--   mapa ("Ver mapa"): el plano de la mazmorra, "Principal > Mazmorra > Mapa".
-- Pestanas abajo: Mazmorras (la portada), Resumen, Misiones y Jefes.
-- Se arrastra, se cierra con Esc, recuerda su posicion y cambia de tamano con
-- clic derecho mantenido. Nada protegido: se puede usar en combate.

local unpack = unpack or table.unpack
local BOOK = ns.BOOK
local FRAME_W, FRAME_H = 6 + BOOK.width + 6, 60 + BOOK.height + 7
local LOGO = "Interface\\AddOns\\DungeonQuestAtlas\\img\\logo_dqa"

local frame, ui
local filters = { myRange = false, kind = "all", faction = nil, search = "" }

function ns.FactionFilter()
    return filters.faction
end

function ns.SetFilter(key, value)
    filters[key] = value
    if key == "faction" and ui then
        if ui.faction then ui.faction:SetValue(value or "Both") end
        if ui.bookFaction then ui.bookFaction:SetValue(value or "Both") end
    end
    -- Buscar lleva a la portada, donde salen los resultados (como en el Diario)
    if key == "search" and value ~= "" then ns.char.view = "home" end
    ns.RefreshUI()
end

local function SelectedDungeon()
    return ns.char.dungeon and ns.DungeonByKey[ns.char.dungeon]
end

-- Si no hay ninguna elegida: la primera de tu nivel
local function DefaultDungeon()
    local list = ns.FilterDungeons({ myRange = true, kind = "all", faction = filters.faction })
    return list[1] or ns.Dungeons[1]
end

local PANELS = { "overview", "quests", "bosses" }
local TABS = { "home", "overview", "quests", "bosses" }

local ShowTab

-- Migas: "Principal", en la vista de mazmorra su nombre y, en la del mapa, "Mapa"
-- (el nombre de la mazmorra vuelve a su libro)
local function UpdateNav(d, map)
    local nav = ui.nav
    local key = d and (d.key .. (map and ">map" or "")) or nil
    if nav.key == key then return end
    nav.key = key
    if nav.fallback then return nav:Reset(d, map) end
    NavBar_Reset(nav)
    if d then NavBar_AddButton(nav, { name = ns.DungeonName(d), OnClick = function() ShowTab(ns.char.tab) end }) end
    if map then NavBar_AddButton(nav, { name = L.MAP, OnClick = function() end }) end
end

local function SelectTab(name)
    for i, key in ipairs(TABS) do
        local tab = ui.tabs[key]
        if PanelTemplates_SelectTab and PanelTemplates_DeselectTab then
            if key == name then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
        end
        tab.selected = key == name
    end
end

function ns.RefreshUI()
    if not (frame and frame:IsShown()) then return end
    local map = ns.char.view == "map" and ns.DungeonMaps(SelectedDungeon())
    local home = not map and ns.char.view ~= "dungeon"
    ui.home:SetShown(home)
    ui.book:SetShown(not home and not map)
    ui.map:SetShown(map and true or false)
    local list = ns.FilterDungeons(filters)
    ui.pending:SetText(L.DUNGEON_COUNT:format(#list) .. "   |cffffd100" .. L.MM_PENDING:format(ns.PendingInRange()) .. "|r")

    if home then
        ui.grid:Refresh(list)
        ui.noResults:SetShown(#list == 0)
        UpdateNav(nil)
        SelectTab("home")
        return
    end

    local d = SelectedDungeon()
    if not d then
        d = DefaultDungeon()
        ns.char.dungeon = d and d.key
    end
    if not d then return end
    UpdateNav(d, map)
    if map then
        SelectTab(nil)
        local plan = ui.map.plan
        if plan.dungeon ~= d then plan:SetDungeon(d, map) else plan:ShowFloor(plan.index) end -- jefes muertos al dia
        if ui.mapBoss ~= nil then plan:FocusBoss(ui.mapBoss or nil); ui.mapBoss = nil end
        return
    end

    -- Cabecera de la pagina izquierda: icono, nombre, nivel y progreso
    ns.SetDungeonArt(ui.icon, d, "icon")
    ui.title:SetText(ns.DungeonName(d))
    local done, total = ns.DungeonProgress(d, filters.faction)
    local killed, bossTotal = ns.BossKillProgress(d)
    local parts = { ("%s |c%s%d–%d|r"):format(L.LEVEL, ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player")),
        d.minLevel, d.maxLevel) }
    if total > 0 then parts[#parts + 1] = ns.StatusMarkup(ns.STATUS_AVAILABLE, 14) .. " " .. L.PROGRESS:format(done, total) end
    if killed > 0 then parts[#parts + 1] = "|cffff7060" .. L.BOSSES_PROGRESS:format(killed, bossTotal) .. "|r" end
    ui.subtitle:SetText(table.concat(parts, "   "))

    local tab = tContains(PANELS, ns.char.tab) and ns.char.tab or "quests"
    ns.char.tab = tab
    for _, key in ipairs(PANELS) do ui.panels[key]:SetShown(key == tab) end
    SelectTab(tab)
    ui.panels[tab]:SetDungeon(d)
end

local function ShowHome()
    ns.char.view = "home"
    ns.RefreshUI()
end

function ShowTab(name)
    if name == "home" then return ShowHome() end
    if not tContains(PANELS, name) then name = "quests" end
    ns.char.tab = name
    ns.char.view = "dungeon"
    ns.RefreshUI()
end

-- Tarjeta de la portada: abre la mazmorra en la ultima pestana usada
function ns.SelectDungeon(d)
    ns.char.dungeon = d and d.key
    ns.char.view = d and "dungeon" or "home"
    ns.RefreshUI()
end

function ns.ApplyScale()
    if frame then frame:SetScale(ns.db.scale) end
end

-- ------------------------------------------
-- Construccion
-- ------------------------------------------

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    local w = ns.db.window
    w.point, w.relPoint, w.x, w.y = point, relPoint, x, y
end

-- Desplegable moderno del juego: options = { { valor, texto }, ... }
local function FilterDropdown(parent, width, options, key)
    local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(width)
    if dd.SetupMenu then
        dd:SetupMenu(function(_, root)
            for _, o in ipairs(options) do
                root:CreateRadio(o[2], function() return filters[key] == o[1] end,
                    function() ns.SetFilter(key, o[1]) end)
            end
        end)
    end
    return dd
end

-- Migas: la NavBar del juego (la del Diario); si el cliente no la tiene, un
-- boton "Principal" y el nombre de la mazmorra al lado
local function CreateNav()
    local ok, nav = pcall(CreateFrame, "Frame", nil, frame, "NavBarTemplate")
    if ok and nav and NavBar_Initialize and nav.home then
        nav:SetPoint("TOPLEFT", 61, -22)
        nav:SetSize(380, 34)
        NavBar_Initialize(nav, "NavButtonTemplate", { name = L.HOME, OnClick = ShowHome }, nav.home, nav.overflow)
        return nav
    end
    nav = CreateFrame("Frame", nil, frame)
    nav:SetPoint("TOPLEFT", 64, -28)
    nav:SetSize(380, 24)
    local homeButton = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    homeButton:SetSize(100, 22)
    homeButton:SetPoint("LEFT")
    homeButton:SetText(L.HOME)
    homeButton:SetScript("OnClick", ShowHome)
    local crumb = nav:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    crumb:SetPoint("LEFT", homeButton, "RIGHT", 8, 0)
    nav.fallback = true
    function nav:Reset(d, map)
        crumb:SetText(d and ("> " .. ns.DungeonName(d) .. (map and (" > " .. L.MAP) or "")) or "")
    end
    return nav
end

local function CreateTopBar()
    ui.nav = CreateNav()

    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetSize(160, 20)
    search:SetPoint("TOPRIGHT", -14, -31)
    search:SetAutoFocus(false)
    search:SetText(filters.search) -- al rehacer la ventana (otro idioma) sigue el filtro
    if search.Instructions then search.Instructions:SetText(L.SEARCH) end
    search:HookScript("OnTextChanged", function(self) ns.SetFilter("search", self:GetText()) end)
    ns.AddTooltip(search, L.SEARCH_TOOLTIP)

    -- Idioma de la ventana: el del juego o cualquiera de los 20
    local language = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    language:SetWidth(140)
    language:SetPoint("RIGHT", search, "LEFT", -12, 0)
    if language.SetupMenu then
        language:SetupMenu(function(_, root)
            if root.SetScrollMode then root:SetScrollMode(22 * 16) end
            local function Radio(code, text)
                root:CreateRadio(text, function() return (ns.db.language or "auto") == code end,
                    function() ns.SetLanguage(code) end)
            end
            Radio("auto", L.LANG_AUTO)
            for _, lang in ipairs(ns.LANGUAGES) do Radio(lang[1], lang[2]) end
        end)
    end
    ns.AddTooltip(language, L.LANGUAGE_TOOLTIP)
    ui.search, ui.language = search, language
end

-- Portada: titulo "Mazmorras", filtros a la derecha y la cuadricula
local function CreateHome(area)
    local home = CreateFrame("Frame", nil, area)
    home:SetAllPoints()
    local bg = home:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSkin(bg, "home")
    local band = home:CreateTexture(nil, "BORDER") -- franja oscura del titulo, como en la Guia
    band:SetPoint("TOPLEFT")
    band:SetPoint("TOPRIGHT")
    band:SetHeight(54)
    band:SetColorTexture(0, 0, 0, 0.45)

    local title = home:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    ns.SetTitleFont(title, 24)
    title:SetPoint("TOPLEFT", 20, -10)
    title:SetText(L.TAB_DUNGEONS)
    ui.pending = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.pending:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)

    -- Filtros: faccion (emblemas), tipo y "Mi nivel", de derecha a izquierda
    if ns.db.autoFaction and not filters.started then filters.faction = UnitFactionGroup("player") end
    filters.started = true -- la de tu personaje solo al abrir, no al cambiar de idioma
    local A, H = ns.FACTION_CREST.Alliance, ns.FACTION_CREST.Horde
    local faction = ns.CreateIconToggleGroup(home, 24, {
        { value = "Both", tooltip = L.FACTION_ALL, crests = { A, H } },
        { value = "Alliance", tooltip = L.FACTION_ALLIANCE, crests = { A } },
        { value = "Horde", tooltip = L.FACTION_HORDE, crests = { H } },
    }, function(value) ns.SetFilter("faction", value ~= "Both" and value or nil) end)
    faction:SetPoint("TOPRIGHT", -18, -15)
    faction:SetValue(filters.faction or "Both")
    local kind = FilterDropdown(home, 150, { { "all", L.KIND_ALL }, { "classic", L.KIND_CLASSIC },
        { "forever", L.KIND_FOREVER } }, "kind")
    kind:SetPoint("RIGHT", faction, "LEFT", -14, 0)
    local rangeLabel = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rangeLabel:SetPoint("RIGHT", kind, "LEFT", -12, 0)
    rangeLabel:SetText(L.MY_RANGE)
    local range = CreateFrame("CheckButton", nil, home, "UICheckButtonTemplate")
    range:SetSize(26, 26)
    range:SetPoint("RIGHT", rangeLabel, "LEFT", 0, 0)
    range:SetChecked(filters.myRange)
    range:SetScript("OnClick", function(self) ns.SetFilter("myRange", self:GetChecked() and true or false) end)
    ns.AddTooltip(range, L.MY_RANGE_TOOLTIP)
    ui.range, ui.kind, ui.faction = range, kind, faction

    local gridArea = CreateFrame("Frame", nil, home)
    gridArea:SetPoint("TOP", 0, -66)
    gridArea:SetPoint("BOTTOM", 0, 6)
    gridArea:SetWidth(ns.GRID_WIDTH + 24) -- con la barra de scroll
    ui.grid = ns.CreateDungeonGrid(gridArea, ns.SelectDungeon)
    ui.noResults = home:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    ui.noResults:SetPoint("CENTER", 0, -20)
    ui.noResults:SetText(L.NO_RESULTS)
    ui.home = home
end

-- Vista de mazmorra: el libro del Diario, con la cabecera de la pagina izquierda
local function CreateBook(area)
    local book = CreateFrame("Frame", nil, area)
    book:SetAllPoints()
    local bg = book:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSkin(bg, "book")
    ui.book = book

    -- Franja oscura detras del nombre, el nivel y el progreso (colores claros)
    local band = book:CreateTexture(nil, "BORDER")
    band:SetPoint("TOPLEFT", 0, -11)
    band:SetSize(386, 60)
    if CreateColor and band.SetGradient then
        band:SetColorTexture(1, 1, 1, 1)
        band:SetGradient("HORIZONTAL", CreateColor(0.08, 0.05, 0.02, 0.92), CreateColor(0.08, 0.05, 0.02, 0.55))
    else
        band:SetColorTexture(0.08, 0.05, 0.02, 0.85)
    end
    local iconButton = CreateFrame("Button", nil, book)
    iconButton:SetSize(64, 61)
    iconButton:SetPoint("TOPLEFT", 0, -3)
    ui.icon = iconButton:CreateTexture(nil, "BACKGROUND")
    ui.icon:SetSize(40, 40)
    ui.icon:SetPoint("CENTER")
    ui.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    local ring = iconButton:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ns.SetEJTexture(ring, "BossModelButton")
    iconButton:SetScript("OnClick", function() ShowTab("overview") end)
    ns.AddTooltip(iconButton, L.TAB_OVERVIEW)
    ui.title = book:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 2, -17)
    ui.title:SetPoint("RIGHT", book, "LEFT", 300, 0) -- a la derecha, la faccion
    ui.title:SetJustifyH("LEFT")
    ui.title:SetWordWrap(false)
    ui.title:SetTextColor(unpack(ns.TITLE_LIGHT))
    ui.subtitle = book:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.subtitle:SetPoint("TOPLEFT", iconButton, "BOTTOMRIGHT", 2, 8)
    ui.subtitle:SetPoint("RIGHT", book, "LEFT", 380, 0)
    ui.subtitle:SetWordWrap(false)
    -- Faccion tambien aqui (la misma que la de la portada): cambiar las misiones
    -- sin volver a Principal
    local A, H = ns.FACTION_CREST.Alliance, ns.FACTION_CREST.Horde
    ui.bookFaction = ns.CreateIconToggleGroup(book, 20, {
        { value = "Both", tooltip = L.FACTION_ALL, crests = { A, H } },
        { value = "Alliance", tooltip = L.FACTION_ALLIANCE, crests = { A } },
        { value = "Horde", tooltip = L.FACTION_HORDE, crests = { H } },
    }, function(value) ns.SetFilter("faction", value ~= "Both" and value or nil) end)
    ui.bookFaction:SetPoint("TOPRIGHT", band, "TOPRIGHT", -10, -12)
    ui.bookFaction:SetValue(filters.faction or "Both")

    -- Paginas: cada panel tiene su parte en cada una
    local leftPage = CreateFrame("Frame", nil, book)
    leftPage:SetPoint("TOPLEFT", 22, -76)
    leftPage:SetPoint("BOTTOMRIGHT", book, "BOTTOMLEFT", 382, 16)
    local rightPage = CreateFrame("Frame", nil, book)
    rightPage:SetPoint("TOPLEFT", BOOK.spine + 20, -24)
    rightPage:SetPoint("BOTTOMRIGHT", -26, 18)
    local function Page(parent)
        local page = CreateFrame("Frame", nil, parent)
        page:SetAllPoints()
        return page
    end
    ui.panels = {
        quests = ns.CreateQuestPanel(Page(leftPage), Page(rightPage)),
        bosses = ns.CreateBossPanel(Page(leftPage), Page(rightPage)),
        overview = ns.CreateOverviewPanel(Page(leftPage), Page(rightPage)),
    }
end

-- Vista del mapa: el plano entero y centrado (sin zoom: no se pierde nada), con
-- los botones de planta arriba a la izquierda. Arrastrar sin zoom mueve la ventana.
local function CreateMapView(area)
    local view = CreateFrame("Frame", nil, area)
    view:SetAllPoints()
    local bg = view:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.025, 0.02, 1)
    local plan = ns.CreateDungeonPlan(view, function(start)
        if start then frame:StartMoving() else frame:StopMovingOrSizing(); SavePosition() end
    end)
    plan.viewport:SetAllPoints()
    plan.floorBar:SetPoint("TOPLEFT", 10, -10)
    plan.floorBar:SetFrameLevel(plan.viewport:GetFrameLevel() + 10)
    view.plan = plan
    ui.map = view
end

-- Pestanas de abajo (PanelTabButtonTemplate, las de la Guia)
local function CreateTabs()
    ui.tabs = {}
    local labels = { home = L.TAB_DUNGEONS, overview = L.TAB_OVERVIEW, quests = L.TAB_QUESTS, bosses = L.TAB_BOSSES }
    local previous
    for i, key in ipairs(TABS) do
        local tab = CreateFrame("Button", "DungeonQuestAtlasFrameTab" .. i, frame, "PanelTabButtonTemplate")
        tab:SetText(labels[key])
        if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0) end
        if previous then
            tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0)
        else
            tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 11, 2)
        end
        tab:SetScript("OnClick", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end
            ShowTab(key)
        end)
        ui.tabs[key] = tab
        previous = tab
    end
end

local function CreateMainFrame()
    ui = {}
    frame = CreateFrame("Frame", "DungeonQuestAtlasFrame", UIParent, "PortraitFrameTemplate")
    frame:Hide()
    frame:SetSize(FRAME_W, FRAME_H)
    local w = ns.db.window
    frame:SetPoint(w.point or "CENTER", UIParent, w.relPoint or "CENTER", w.x or 0, w.y or 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)
    frame:SetScript("OnShow", ns.RefreshUI)
    tinsert(UISpecialFrames, "DungeonQuestAtlasFrame")
    -- Clic derecho mantenido y arrastrar: mas grande o mas pequena (la escala de opciones)
    ns.EnableRightDragScale(frame, { frame }, function(scale)
        ns.db.scale = scale
        SavePosition()
    end)
    if frame.SetTitle then frame:SetTitle("|cffd597ffDungeon Quest Atlas Forever|r") end
    if frame.SetPortraitToAsset then frame:SetPortraitToAsset(LOGO) end
    ns.ApplyScale()

    CreateTopBar()
    local area = CreateFrame("Frame", nil, frame)
    area:SetPoint("TOPLEFT", 6, -60)
    area:SetPoint("BOTTOMRIGHT", -6, 7)
    CreateHome(area)
    CreateBook(area)
    CreateMapView(area)
    CreateTabs()
    ns.ui = ui
end

-- Cambia el idioma de la ventana ("auto" = el del juego). Los textos se ponen
-- al construirla, asi que se rehace: la vieja se esconde y no se vuelve a usar
-- (una ventana suelta por cambio de idioma, que se hace muy de vez en cuando).
function ns.SetLanguage(code)
    ns.db.language = code
    ns.ApplyLanguage(code)
    if not frame then return end
    local shown = frame:IsShown()
    frame:Hide()
    CreateMainFrame()
    frame:SetShown(shown)
end

-- /dqa y el minimapa: siempre se abre en la portada "Mazmorras" (los saltos a
-- una mision o a un jefe, ns.ShowQuest / ns.ShowBoss, van a su pagina)
function ns.ToggleMainFrame()
    if not frame then CreateMainFrame() end
    if not frame:IsShown() then ns.char.view = "home" end
    frame:SetShown(not frame:IsShown())
end

-- Salta a una mision (pasos de una cadena)
function ns.ShowQuest(id)
    if not frame then CreateMainFrame() end
    for _, d in ipairs(ns.Dungeons) do
        if tContains(d.quests, id) then
            ns.char.dungeon = d.key
            break
        end
    end
    frame:Show()
    ShowTab("quests")
    ui.panels.quests:SelectQuest(id)
end

-- Boton "Ver mapa": el plano en la misma ventana; con bossIndex, en la planta de
-- ese jefe y con su chincheta resaltada
function ns.ShowDungeonMap(d, bossIndex)
    if not ns.DungeonMaps(d) then return end
    if not frame then CreateMainFrame() end
    ui.mapBoss = bossIndex or false -- false: "Ver mapa" sin jefe, quita el resalte
    ns.char.dungeon = d.key
    ns.char.view = "map"
    if frame:IsShown() then ns.RefreshUI() else frame:Show() end
end

-- Abre la ventana en la pagina de una mazmorra (entradas del mapa del mundo)
function ns.OpenDungeon(d)
    if not frame then CreateMainFrame() end
    ns.char.dungeon = d.key
    ns.char.view = "dungeon"
    if frame:IsShown() then ns.RefreshUI() else frame:Show() end
end

-- Salta a un jefe (chinchetas del mapa de la mazmorra)
function ns.ShowBoss(d, index)
    if not frame then CreateMainFrame() end
    ns.char.dungeon = d.key
    frame:Show()
    ShowTab("bosses")
    ui.panels.bosses:SelectBoss(index)
end

-- ==========================================
-- CAJA PARA COPIAR (Wowhead y /dqa export)
-- ==========================================
-- Un addon no puede abrir el navegador ni escribir en el portapapeles: el
-- texto queda seleccionado para Ctrl+C.

local dialog
function ns.ShowCopyDialog(titleText, text)
    if not dialog then
        dialog = CreateFrame("Frame", "DungeonQuestAtlasCopyDialog", UIParent, "BasicFrameTemplateWithInset")
        dialog:SetSize(520, 300)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetMovable(true)
        dialog:EnableMouse(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", dialog.StartMoving)
        dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
        tinsert(UISpecialFrames, "DungeonQuestAtlasCopyDialog")

        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dialog.title:SetPoint("TOP", 0, -5)

        local hint = dialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hint:SetPoint("BOTTOM", 0, 10)
        hint:SetText(L.COPY_HINT)

        local scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 14, -32)
        scroll:SetPoint("BOTTOMRIGHT", -32, 28)
        dialog.box = CreateFrame("EditBox", nil, scroll)
        dialog.box:SetMultiLine(true)
        dialog.box:SetFontObject("ChatFontNormal")
        dialog.box:SetSize(460, 240)
        dialog.box:SetAutoFocus(true)
        dialog.box:SetScript("OnEscapePressed", function() dialog:Hide() end)
        -- Solo para copiar: cualquier edicion se deshace
        dialog.box:SetScript("OnTextChanged", function(self, user)
            if user then self:SetText(dialog.text); self:HighlightText() end
        end)
        scroll:SetScrollChild(dialog.box)
    end
    dialog.text = text
    dialog.title:SetText(titleText)
    dialog.box:SetText(text)
    dialog:Show()
    dialog.box:SetFocus()
    dialog.box:HighlightText()
end
