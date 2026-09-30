local _, ns = ...
local L = ns.L

-- ==========================================
-- VENTANA PRINCIPAL: el Diario de mazmorras
-- ==========================================
-- Marco de Blizzard con retrato (PortraitFrameTemplate). Arriba el buscador y
-- los filtros; a la izquierda las mazmorras; a la derecha el libro del Diario
-- (UI-EJ-JournalBG) con sus pestanas laterales: Misiones, Jefes y Mazmorra.
-- En la pagina izquierda del libro, la cabecera de la mazmorra y la lista; en
-- la derecha, el detalle. Tamano fijo como el Diario (la escala va en
-- opciones); se arrastra, se cierra con Esc y recuerda su posicion. Nada
-- protegido: se puede usar en combate.

local unpack = unpack or table.unpack
local LIST_W = 262
local BOOK = ns.BOOK
local FRAME_W, FRAME_H = 6 + LIST_W + 6 + BOOK.width + 6, 60 + BOOK.height + 7
local LOGO = "Interface\\AddOns\\DungeonQuestAtlas\\img\\logo_dqa"
local QUEST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"

local frame, ui
local filters = { myRange = false, kind = "all", faction = nil, search = "" }

function ns.FactionFilter()
    return filters.faction
end

function ns.SetFilter(key, value)
    filters[key] = value
    if key == "faction" and ui and ui.faction then ui.faction:SetValue(value or "Both") end
    ns.RefreshUI()
end

-- Pasa la pagina del libro (si la opcion esta puesta y la ventana se ve)
local function TurnPage(forward)
    if ns.db.pageTurn and ui and ui.turner and frame:IsVisible() then ui.turner:Turn(forward) end
end

local function SelectedDungeon()
    return ns.char.dungeon and ns.DungeonByKey[ns.char.dungeon]
end

-- Al abrir por primera vez: la primera mazmorra de tu nivel
local function DefaultDungeon()
    local list = ns.FilterDungeons({ myRange = true, kind = "all", faction = filters.faction })
    return list[1] or ns.Dungeons[1]
end

local PANELS = { "quests", "bosses", "overview" }

function ns.RefreshUI()
    if not (frame and frame:IsShown()) then return end
    local d = SelectedDungeon()
    if not d then
        d = DefaultDungeon()
        ns.char.dungeon = d and d.key
    end
    local list = ns.FilterDungeons(filters)
    ui.dungeons:Refresh(list, d and d.key)
    ui.pending:SetText(L.DUNGEON_COUNT:format(#list) .. "\n|cffffd100" .. L.MM_PENDING:format(ns.PendingInRange()) .. "|r")
    ui.book:SetShown(d ~= nil)
    if not d then return end

    -- Cabecera de la pagina izquierda: icono, nombre, nivel y progreso
    ns.SetDungeonArt(ui.icon, d, "icon")
    ui.title:SetText(ns.DungeonName(d))
    local done, total = ns.DungeonProgress(d, filters.faction)
    ui.subtitle:SetText(("%s |c%s%d–%d|r"):format(L.LEVEL, ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player")),
        d.minLevel, d.maxLevel) .. (total > 0 and ("   " .. L.PROGRESS:format(done, total)) or ""))

    local tab = ui.panels[ns.char.tab] and ns.char.tab or "quests" -- la vieja "entrance" ya no existe
    ns.char.tab = tab
    for _, key in ipairs(PANELS) do
        ui.panels[key]:SetShown(key == tab)
        ui.tabs[key]:SetSelected(key == tab)
    end
    ui.panels[tab]:SetDungeon(d)
end

local function IndexOf(list, value)
    for i, v in ipairs(list) do if v == value then return i end end
    return 0
end

-- Hacia delante si la pestana nueva va despues (Misiones, Jefes, Mazmorra)
local function ShowTab(name)
    if not tContains(PANELS, name) then name = "quests" end
    if name ~= ns.char.tab then TurnPage(IndexOf(PANELS, name) > IndexOf(PANELS, ns.char.tab)) end
    ns.char.tab = name
    ns.RefreshUI()
end

-- Hacia delante si la mazmorra nueva va despues en la lista
function ns.SelectDungeon(d)
    local old = SelectedDungeon()
    if d and d ~= old then
        TurnPage(IndexOf(ns.Dungeons, d) > IndexOf(ns.Dungeons, old))
    end
    ns.char.dungeon = d and d.key
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
local function FilterDropdown(width, options, key)
    local dd = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
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

local function CreateToolbar()
    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetSize(LIST_W - 80, 20)
    search:SetPoint("TOPLEFT", 70, -33)
    search:SetAutoFocus(false)
    search:SetText(filters.search) -- al rehacer la ventana (otro idioma) sigue el filtro
    if search.Instructions then search.Instructions:SetText(L.SEARCH) end -- "Buscar" del juego, en el idioma elegido
    search:HookScript("OnTextChanged", function(self) ns.SetFilter("search", self:GetText()) end)
    ns.AddTooltip(search, L.SEARCH_TOOLTIP)

    local range = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    range:SetSize(26, 26)
    range:SetPoint("LEFT", search, "RIGHT", 12, 0)
    range:SetChecked(filters.myRange)
    range:SetScript("OnClick", function(self) ns.SetFilter("myRange", self:GetChecked() and true or false) end)
    ns.AddTooltip(range, L.MY_RANGE_TOOLTIP)
    local rangeLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    rangeLabel:SetPoint("LEFT", range, "RIGHT", 0, 1)
    rangeLabel:SetText(L.MY_RANGE)

    local kind = FilterDropdown(140, { { "all", L.KIND_ALL }, { "classic", L.KIND_CLASSIC }, { "forever", L.KIND_FOREVER } },
        "kind")
    kind:SetPoint("LEFT", rangeLabel, "RIGHT", 12, -1)
    -- Faccion: tres botones con los emblemas del juego (ambas, Alianza, Horda).
    -- La de tu personaje solo al abrir por primera vez, no al cambiar de idioma.
    if ns.db.autoFaction and not filters.started then filters.faction = UnitFactionGroup("player") end
    filters.started = true
    local A, H = ns.FACTION_CREST.Alliance, ns.FACTION_CREST.Horde
    local faction = ns.CreateIconToggleGroup(frame, 24, {
        { value = "Both", tooltip = L.FACTION_ALL, crests = { A, H } },
        { value = "Alliance", tooltip = L.FACTION_ALLIANCE, crests = { A } },
        { value = "Horde", tooltip = L.FACTION_HORDE, crests = { H } },
    }, function(value) ns.SetFilter("faction", value ~= "Both" and value or nil) end)
    faction:SetPoint("LEFT", kind, "RIGHT", 12, 1)
    faction:SetValue(filters.faction or "Both")

    -- Idioma de la ventana, a la derecha: el del juego o cualquiera de los 20
    local language = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    language:SetWidth(150)
    language:SetPoint("TOPRIGHT", -12, -30)
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

    -- "34 mazmorras" / "7 misiones pendientes...", en dos lineas entre medias
    ui.pending = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    ui.pending:SetPoint("LEFT", faction, "RIGHT", 12, 0)
    ui.pending:SetPoint("RIGHT", language, "LEFT", -10, 0)
    ui.pending:SetJustifyH("RIGHT")
    ui.pending:SetMaxLines(2)
    ui.range, ui.kind, ui.faction, ui.search, ui.language = range, kind, faction, search, language
end

local function CreateBook()
    local book = CreateFrame("Frame", nil, frame)
    book:SetSize(BOOK.width, BOOK.height)
    book:SetPoint("BOTTOMRIGHT", -6, 7)
    local bg = book:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(BOOK.file)
    bg:SetTexCoord(unpack(BOOK.coords))
    ui.book = book

    -- Cabecera de la pagina izquierda (como la del Diario en un encuentro)
    local shadow = book:CreateTexture(nil, "BORDER")
    shadow:SetSize(386, 39)
    shadow:SetPoint("TOPLEFT", 0, -11)
    ns.SetEJTexture(shadow, "LeftPageHeader")
    local iconButton = CreateFrame("Button", nil, book)
    iconButton:SetSize(64, 61)
    iconButton:SetPoint("TOPLEFT", 0, -3)
    ui.icon = iconButton:CreateTexture(nil, "BACKGROUND")
    ui.icon:SetSize(40, 40)
    ui.icon:SetPoint("CENTER")
    ui.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") -- como el Diario
    local ring = iconButton:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ns.SetEJTexture(ring, "BossModelButton")
    iconButton:SetScript("OnClick", function() ShowTab("overview") end)
    ns.AddTooltip(iconButton, L.TAB_OVERVIEW)
    ui.title = book:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 2, -17)
    ui.title:SetPoint("RIGHT", book, "LEFT", 380, 0)
    ui.title:SetJustifyH("LEFT")
    ui.title:SetWordWrap(false)
    ui.title:SetTextColor(unpack(ns.TITLE_LIGHT))
    ui.subtitle = ns.PaperText(book, "GameFontBlack")
    ui.subtitle:SetPoint("TOPLEFT", iconButton, "BOTTOMRIGHT", 2, 8)

    -- Paginas: cada panel tiene su parte en cada una
    local leftPage = CreateFrame("Frame", nil, book)
    leftPage:SetPoint("TOPLEFT", 22, -76)
    leftPage:SetPoint("BOTTOMRIGHT", book, "BOTTOMLEFT", 382, 16)
    local rightPage = CreateFrame("Frame", nil, book)
    rightPage:SetPoint("TOPLEFT", 412, -24)
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

    -- Hoja que pasa: el lomo en x=392, el pergamino dentro de las tapas
    ui.turner = ns.CreatePageTurner(book, 392, { left = 12, right = BOOK.width - 14, top = 8, bottom = BOOK.height - 10 })

    -- Pestanas laterales, en el borde derecho del libro
    ui.tabs = {}
    local previous
    for _, def in ipairs({
        { "quests", L.TAB_QUESTS, QUEST_ICON, QUEST_ICON },
        { "bosses", L.TAB_BOSSES, "TabLootIcon", "TabLootIconSelected" },
        { "overview", L.TAB_OVERVIEW, "TabModelIcon", "TabModelIconSelected" },
    }) do
        local tab = ns.CreateSideTab(book, def[2], def[3], def[4], function() ShowTab(def[1]) end)
        if previous then
            tab:SetPoint("TOP", previous, "BOTTOM", 0, 2)
        else
            tab:SetPoint("TOPLEFT", book, "TOPRIGHT", -12, -35)
        end
        ui.tabs[def[1]] = tab
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
    if frame.SetTitle then frame:SetTitle("Dungeon Quest Atlas |cff00ccffForever|r") end
    if frame.SetPortraitToAsset then frame:SetPortraitToAsset(LOGO) end
    ns.ApplyScale()

    CreateToolbar()

    local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 6, -60)
    inset:SetPoint("BOTTOMLEFT", 6, 7)
    inset:SetWidth(LIST_W)
    local listArea = CreateFrame("Frame", nil, inset)
    listArea:SetPoint("TOPLEFT", 4, -4)
    listArea:SetPoint("BOTTOMRIGHT", -2, 4)
    ui.dungeons = ns.CreateDungeonList(listArea, ns.SelectDungeon)

    CreateBook()
    ns.ui = ui
    ShowTab(ns.char.tab)
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

function ns.ToggleMainFrame()
    if not frame then CreateMainFrame() end
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
