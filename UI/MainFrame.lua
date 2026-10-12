local _, ns = ...
local L = ns.L

-- ==========================================
-- VENTANA PRINCIPAL: como la Guia de aventuras
-- ==========================================
-- Marco de Blizzard con retrato (PortraitFrameTemplate), del tamano del Diario.
-- Arriba, las migas ("Principal > Mazmorra", NavBar del juego), el idioma y el
-- buscador. Tres vistas:
--   portada: "Mazmorras", los filtros y la cuadricula de tarjetas;
--   mazmorra: el libro del Diario, la cabecera y los jefes a la izquierda y, a
--   la derecha, lo que digan las pestanas de su borde derecho (ui.sideTabs):
--   Resumen, Botin y Modelo (de la mazmorra o del jefe elegido) y Misiones (con
--   Misiones, la izquierda pasa a ser la lista de misiones);
--   mapa ("Ver mapa"): el plano de la mazmorra, "Principal > Mazmorra > Mapa".
-- Pestanas abajo, las secciones de la Guia: Viajes, Registro de viajero,
-- Mazmorras, Bandas y Tutoriales (SECTIONS). Mazmorras es la de antes (portada,
-- libro y mapa); cada una de las demas vive en su fichero de UI/ y cumple el
-- contrato de seccion (ver SECTIONS).
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
        if ui.bookFaction and ui.bookFaction.GenerateMenu then ui.bookFaction:GenerateMenu() end
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

local PANELS = { "overview", "loot", "model", "quests" }
-- Pestanas guardadas por versiones anteriores
local OLD_TABS = { bosses = "loot" }

-- Secciones (pestanas de abajo). Contrato de las que tienen create:
--   local section = ns.CreateXxxSection(parent) -- parent: el area de contenido
--   section.frame       marco con SetAllPoints(parent); se muestra y se esconde aqui
--   section:Refresh()   en cada ns.RefreshUI mientras se ve
--   section:Crumbs()    opcional: migas tras "Principal", { { name =, OnClick = }, ... }
--   section:Home()      opcional: lo que hace "Principal" (volver a su portada)
--   section.search      opcional: true si usa el buscador (ns.GetSearch())
local SECTIONS = {
    { key = "journeys", label = "TAB_JOURNEYS", create = "CreateJourneysSection" },
    { key = "events", label = "TAB_EVENTS", create = "CreateEventsSection" },
    { key = "dungeons", label = "TAB_DUNGEONS" },
    { key = "raids", label = "TAB_RAIDS", create = "CreateRaidsSection" },
    { key = "tutorials", label = "TAB_TUTORIALS", create = "CreateTutorialsSection" },
}

function ns.GetSearch()
    return filters.search
end

local ShowTab

-- Migas tras "Principal": { { name =, OnClick =, listFunc = }, ... }. listFunc
-- (opcional) pone la flecha del desplegable, como en el Diario: devuelve
-- { { text =, id =, func = }, ... } (NavButtonTemplate_SetupDropdown). key evita
-- rehacerlas en cada refresco.
local function SetNav(key, crumbs)
    local nav = ui.nav
    if nav.key == key then return end
    nav.key, nav.crumbs = key, crumbs
    if nav.fallback then return nav:Reset(crumbs) end
    NavBar_Reset(nav)
    for _, c in ipairs(crumbs or {}) do
        NavBar_AddButton(nav, { name = c.name, OnClick = c.OnClick or function() end, listFunc = c.listFunc })
    end
end

-- Entrada de un desplegable de las migas: la NavBar quita las migas de detras
-- antes de llamarla, asi que se rehacen aunque la clave no cambie
local function NavEntry(text, id, action)
    return { text = text, id = id, func = function() ui.nav.key = nil; action() end }
end

local function DungeonCrumbList()
    local list = {}
    for i, d in ipairs(ns.Dungeons) do
        list[i] = NavEntry(ns.DungeonName(d), i, function() ns.SelectDungeon(d) end)
    end
    return list
end

-- Mazmorras: su nombre (desplegable con todas) y, con un jefe elegido, el jefe
-- (desplegable con los suyos); en la vista del mapa, "Mapa"
local function UpdateNav(d, map, boss)
    if not d then return SetNav("dungeons") end
    local crumbs = { { name = ns.DungeonName(d), listFunc = DungeonCrumbList, OnClick = function()
        ui.boss = nil
        ShowTab(ns.char.tab)
    end } }
    local bosses = ns.Bosses[d.key] or {}
    if boss and bosses[boss] and not map then
        crumbs[2] = { name = ns.BossName(bosses[boss], d), listFunc = function()
            local list = {}
            for i, b in ipairs(bosses) do list[i] = NavEntry(ns.BossName(b, d), i, function() ns.SelectBoss(i) end) end
            return list
        end }
    end
    if map then crumbs[#crumbs + 1] = { name = L.MAP } end
    SetNav("dungeons>" .. d.key .. ">" .. (map and "map" or tostring(boss)), crumbs)
end

local function SelectTab(name)
    for _, sec in ipairs(SECTIONS) do
        local tab = ui.tabs[sec.key]
        if PanelTemplates_SelectTab and PanelTemplates_DeselectTab then
            if sec.key == name then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
        end
        tab.selected = sec.key == name
    end
end

local function SelectSideTab(name)
    for key, tab in pairs(ui.sideTabs) do tab:Select(key == name) end
end

-- Seccion que no es Mazmorras: su marco y sus migas (key nil: ninguna)
local function RefreshSection(key)
    for k, sec in pairs(ui.sections) do sec.frame:SetShown(k == key) end
    local sec = key and ui.sections[key]
    ui.search:SetShown(not key or (sec and sec.search) and true or false)
    if not key then return end
    if not sec then return SetNav(key) end
    sec:Refresh()
    local crumbs = sec.Crumbs and sec:Crumbs() or nil
    local names = {}
    for i, c in ipairs(crumbs or {}) do names[i] = c.name end
    SetNav(key .. ">" .. table.concat(names, ">"), crumbs)
end

function ns.RefreshUI()
    if not (frame and frame:IsShown()) then return end
    local section = ns.char.section or "dungeons"
    SelectTab(section)
    if section ~= "dungeons" then
        ui.home:Hide(); ui.book:Hide(); ui.map:Hide()
        return RefreshSection(section)
    end
    RefreshSection(nil)
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
        return
    end

    local d = SelectedDungeon()
    if not d then
        d = DefaultDungeon()
        ns.char.dungeon = d and d.key
    end
    if not d then return end
    -- El jefe elegido es de su mazmorra; Modelo sin jefe: el primero
    if ui.bossDungeon ~= d.key then ui.boss, ui.bossDungeon = nil, d.key end
    local tab = OLD_TABS[ns.char.tab] or ns.char.tab
    if not tContains(PANELS, tab) then tab = "overview" end
    ns.char.tab = tab
    if tab == "model" and not ui.boss and #(ns.Bosses[d.key] or {}) > 0 then ui.boss = 1 end
    UpdateNav(d, map, tab ~= "quests" and ui.boss)
    if map then
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

    -- Izquierda: los jefes (con Misiones, la lista de misiones). Derecha: la pestana
    ui.bossList:SetShown(tab ~= "quests")
    if tab ~= "quests" then ui.bossList:SetDungeon(d, ui.boss) end
    for _, key in ipairs(PANELS) do ui.panels[key]:SetShown(key == tab) end
    ui.bookFaction:SetShown(tab ~= "model")
    SelectSideTab(tab)
    ui.panels[tab]:SetDungeon(d, ui.boss)
end

local function ShowHome()
    ns.char.view = "home"
    ns.RefreshUI()
end

-- Pestana de abajo; Mazmorras vuelve siempre a su portada
function ns.ShowSection(key)
    ns.char.section = key
    if key == "dungeons" then ns.char.view = "home" end
    ns.RefreshUI()
end

-- "Principal": la portada de la seccion en la que estas
local function NavHome()
    local sec = ui.sections[ns.char.section or "dungeons"]
    if sec then
        if sec.Home then sec:Home() end
        return ns.RefreshUI()
    end
    ShowHome()
end

function ShowTab(name)
    if name == "home" then return ShowHome() end
    if not tContains(PANELS, name) then name = "overview" end
    ns.char.section = "dungeons"
    ns.char.tab = name
    ns.char.view = "dungeon"
    ns.RefreshUI()
end

-- Elige un jefe de la mazmorra abierta (nil: la mazmorra), en la misma pestana
function ns.SelectBoss(index)
    ui.boss = index
    ns.RefreshUI()
end

-- Tarjeta de la portada: abre la mazmorra en la ultima pestana usada
function ns.SelectDungeon(d)
    if ui then ui.boss = nil end -- el resumen de la mazmorra, no el de un jefe
    ns.char.section = "dungeons"
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
        NavBar_Initialize(nav, "NavButtonTemplate", { name = L.HOME, OnClick = NavHome }, nav.home, nav.overflow)
        return nav
    end
    nav = CreateFrame("Frame", nil, frame)
    nav:SetPoint("TOPLEFT", 64, -28)
    nav:SetSize(380, 24)
    local homeButton = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    homeButton:SetSize(100, 22)
    homeButton:SetPoint("LEFT")
    homeButton:SetText(L.HOME)
    homeButton:SetScript("OnClick", NavHome)
    local crumb = nav:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    crumb:SetPoint("LEFT", homeButton, "RIGHT", 8, 0)
    nav.fallback = true
    function nav:Reset(crumbs)
        local names = {}
        for i, c in ipairs(crumbs or {}) do names[i] = "> " .. c.name end
        crumb:SetText(table.concat(names, " "))
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

    -- Filtros: tipo (arriba a la derecha, como "World of Warcraft" en el Diario),
    -- faccion (emblemas) y "Mi nivel", de derecha a izquierda
    if ns.db.autoFaction and not filters.started then filters.faction = UnitFactionGroup("player") end
    filters.started = true -- la de tu personaje solo al abrir, no al cambiar de idioma
    local faction = ns.CreateFactionToggle(home, 24)
    local kind = FilterDropdown(home, 170, { { "all", L.KIND_ALL }, { "classic", L.KIND_CLASSIC },
        { "forever", L.KIND_FOREVER } }, "kind")
    kind:SetPoint("TOPRIGHT", -18, -14)
    faction:SetPoint("RIGHT", kind, "LEFT", -14, 0)
    local rangeLabel = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rangeLabel:SetPoint("RIGHT", faction, "LEFT", -12, 0)
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
    -- El icono y el nombre: el resumen de la mazmorra (sin jefe), como en el Diario
    iconButton:SetScript("OnClick", function() ui.boss = nil; ShowTab("overview") end)
    ns.AddTooltip(iconButton, L.TAB_OVERVIEW)
    ui.title = book:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 2, -17)
    ui.title:SetPoint("RIGHT", book, "LEFT", 380, 0)
    ui.title:SetJustifyH("LEFT")
    ui.title:SetWordWrap(false)
    ui.title:SetTextColor(unpack(ns.TITLE_LIGHT))
    ui.subtitle = book:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.subtitle:SetPoint("TOPLEFT", iconButton, "BOTTOMRIGHT", 2, 8)
    ui.subtitle:SetPoint("RIGHT", book, "LEFT", 380, 0)
    ui.subtitle:SetWordWrap(false)

    -- Paginas: la izquierda, los jefes o las misiones; la derecha, la pestana
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
    -- Franja de arriba de la pagina derecha: la faccion (donde el Diario pone la
    -- dificultad) y, en Botin, el tipo de objeto. El contenido va debajo.
    local bar = CreateFrame("Frame", nil, rightPage)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(26)
    bar:SetFrameLevel(rightPage:GetFrameLevel() + 10)
    ui.bookFaction = FilterDropdown(bar, 140, { { nil, L.FACTION_ALL }, { "Alliance", L.FACTION_ALLIANCE },
        { "Horde", L.FACTION_HORDE } }, "faction")
    ui.bookFaction:SetPoint("RIGHT")
    local body = CreateFrame("Frame", nil, rightPage)
    body:SetPoint("TOPLEFT", 0, -34)
    body:SetPoint("BOTTOMRIGHT")

    ui.bossList = ns.CreateBossList(Page(leftPage), ns.SelectBoss)
    ui.panels = {
        overview = ns.CreateOverviewPanel(Page(body)),
        loot = ns.CreateLootPanel(Page(rightPage), bar),
        model = ns.CreateModelPanel(Page(rightPage)),
        quests = ns.CreateQuestPanel(Page(leftPage), Page(body)),
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

-- Pestanas de abajo: las secciones (PanelTabButtonTemplate, las de la Guia)
local TAB_MAX_W = math.floor((FRAME_W - 11 - 4 * 3 - 10) / 5)
local function CreateTabs()
    ui.tabs = {}
    local previous
    for i, sec in ipairs(SECTIONS) do
        local tab = CreateFrame("Button", "DungeonQuestAtlasFrameTab" .. i, frame, "PanelTabButtonTemplate")
        tab:SetText(L[sec.label])
        -- Las 5 caben bajo la ventana: las largas se recortan ("Registro de...",
        -- como en el Diario) y su tooltip dice el nombre entero
        if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0, nil, nil, TAB_MAX_W) end
        tab:HookScript("OnEnter", function(self)
            local text = self.GetFontString and self:GetFontString()
            if text and text.IsTruncated and text:IsTruncated() then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(L[sec.label])
                GameTooltip:Show()
            end
        end)
        tab:HookScript("OnLeave", GameTooltip_Hide)
        if previous then
            tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0)
        else
            tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 11, 2)
        end
        tab:SetScript("OnClick", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end
            ns.ShowSection(sec.key)
        end)
        ui.tabs[sec.key] = tab
        previous = tab
    end
end

-- Pestanas del borde derecho del libro, las del Diario (EncounterTabTemplate):
-- Resumen (calavera), Botin (cofre), Modelo (criatura) y Misiones ("!" del juego)
local SIDE_ICON = { overview = "TabOverview", loot = "TabLoot", model = "TabModel" }
local QUEST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"

local function CreateSideTabs()
    ui.sideTabs = {}
    local labels = { overview = L.TAB_OVERVIEW, loot = L.LOOT, model = L.TAB_MODEL, quests = L.TAB_QUESTS }
    local previous
    for _, key in ipairs(PANELS) do
        local tab = CreateFrame("Button", nil, ui.book)
        tab:SetSize(63, 57)
        tab:SetFrameLevel(ui.book:GetFrameLevel() + 20) -- encima del borde de la ventana
        if previous then
            tab:SetPoint("TOP", previous, "BOTTOM", 0, 2)
        else
            tab:SetPoint("TOPLEFT", ui.book, "TOPRIGHT", -12, -35)
        end
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        ns.SetEJTexture(hl, "TabHighlight")
        hl:SetBlendMode("ADD")
        tab.icon = tab:CreateTexture(nil, "OVERLAY")
        if SIDE_ICON[key] then
            tab.icon:SetSize(48, 43)
            tab.icon:SetPoint("RIGHT", -6, 0)
        else
            tab.icon:SetSize(26, 26)
            tab.icon:SetPoint("CENTER", -2, 0)
            tab.icon:SetTexture(QUEST_ICON)
        end
        function tab:Select(on)
            self.selected = on
            ns.SetEJTexture(self.bg, on and "TabDown" or "TabUp")
            if SIDE_ICON[key] then
                ns.SetEJTexture(self.icon, SIDE_ICON[key] .. (on and "Down" or "Up"))
            else
                self.icon:SetDesaturated(not on)
                self.icon:SetAlpha(on and 1 or 0.75)
            end
        end
        tab:Select(false)
        tab:SetScript("OnClick", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end
            ShowTab(key)
        end)
        ns.AddTooltip(tab, labels[key])
        ui.sideTabs[key] = tab
        previous = tab
    end
end

-- Secciones que no son Mazmorras: cada una en su fichero de UI/
local function CreateSections(area)
    ui.sections = {}
    for _, sec in ipairs(SECTIONS) do
        local create = sec.create and ns[sec.create]
        if create then
            local obj = create(area)
            obj.frame:Hide()
            ui.sections[sec.key] = obj
        end
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
    CreateSections(area)
    CreateTabs()
    CreateSideTabs()
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
    if not frame:IsShown() and (ns.char.section or "dungeons") == "dungeons" then ns.char.view = "home" end
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
    ns.char.section = "dungeons"
    ns.char.dungeon = d.key
    ns.char.view = "map"
    if frame:IsShown() then ns.RefreshUI() else frame:Show() end
end

-- Abre la ventana en la pagina de una mazmorra (entradas del mapa del mundo)
function ns.OpenDungeon(d)
    if not frame then CreateMainFrame() end
    ns.char.section = "dungeons"
    ns.char.dungeon = d.key
    ns.char.view = "dungeon"
    if frame:IsShown() then ns.RefreshUI() else frame:Show() end
end

-- Salta a un jefe (chinchetas del mapa de la mazmorra: su botin). tab: la
-- pestana lateral ("loot" si no se dice)
function ns.ShowBoss(d, index, tab)
    if not frame then CreateMainFrame() end
    ns.char.dungeon = d.key
    ui.boss, ui.bossDungeon = index, d.key
    frame:Show()
    ShowTab(tab or "loot")
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
