local _, ns = ...
local L = ns.L

-- ==========================================
-- SECCION: REGISTRO DE VIAJERO
-- ==========================================
-- Pestana de abajo de la ventana (contrato de seccion: SECTIONS en UI/MainFrame.lua).
-- Como Mazmorras: una tarjeta por evento de mundo con la imagen de su festividad,
-- cuanto falta y el progreso; arriba el evento activo (o el proximo). Clic: el
-- libro del evento, con sus misiones a la izquierda y la hoja de la mision a la
-- derecha (la de Mazmorras: ns.CreateQuestList y ns.CreateQuestDetail).
-- Datos: Data/Events.lua.
--
-- Fechas: las del calendario del juego (C_Calendar, API de Retail: todo con
-- pcall); si no las da, las de los datos, marcadas "(aprox.)".

local unpack = unpack or table.unpack
local ALL = "ALL"
local HEADER_H = 74
local GREEN, GREY = "|cff40c040", "|cffa0a0a0"
local CLOCK = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:16:16|t "

-- ------------------------------------------
-- Fechas de cada evento
-- ------------------------------------------

local calendar = {} -- [clave del evento] = { start, finish, title } del calendario del juego

local function Epoch(t)
    return time({ year = t.year, month = t.month, day = t.monthDay or t.day, hour = t.hour or 0, min = t.minute or 0 })
end

local function Parse(text) -- "2026-09-21 10:00"
    local y, m, d, h, mi = text:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    return time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi) })
end

local byHoliday -- [holidayID del calendario] = evento
local function EventOfHoliday(id)
    if not byHoliday then
        byHoliday = {}
        for _, ev in ipairs(ns.EventList) do
            for _, h in ipairs(ev.holidays or {}) do byHoliday[h] = ev end
        end
    end
    return byHoliday[id]
end

-- Recorre este mes y los dos siguientes del calendario del juego. Para cada
-- evento se queda la primera ventana que aun no ha acabado.
function ns.ScanEventCalendar()
    local C = C_Calendar
    if not (C and C.GetMonthInfo and C.GetNumDayEvents and C.GetDayEvent) then return end
    local now = time()
    for offset = 0, 2 do
        local ok, info = pcall(C.GetMonthInfo, offset)
        for day = 1, ok and info and info.numDays or 0 do
            local okN, n = pcall(C.GetNumDayEvents, offset, day)
            for i = 1, okN and n or 0 do
                local okE, e = pcall(C.GetDayEvent, offset, day, i)
                local ev = okE and e and e.calendarType == "HOLIDAY" and e.startTime and e.endTime
                    and EventOfHoliday(e.eventID)
                if ev then
                    local s, f = Epoch(e.startTime), Epoch(e.endTime)
                    local cur = calendar[ev.key]
                    if f > now and (not cur or cur.finish <= now or s < cur.start) then
                        calendar[ev.key] = { start = s, finish = f, title = ns.PlainText(e.title) }
                    end
                end
            end
        end
    end
end

-- Primer domingo del mes (la Feria de la Luna Negra empieza ese dia en Retail)
local function FirstSunday(year, month)
    local first = time({ year = year, month = month, day = 1, hour = 0 })
    local wday = date("*t", first).wday -- 1 = domingo
    return first + ((8 - wday) % 7) * 86400
end

-- start, finish (epoch) de la ventana actual o la proxima, y approx = true si
-- no vienen del calendario del juego
function ns.EventWindow(ev, now)
    now = now or time()
    local c = calendar[ev.key]
    if c and c.finish > now then return c.start, c.finish, false end
    for _, w in ipairs(ev.dates or {}) do
        local s, f = Parse(w[1]), Parse(w[2])
        if f > now then return s, f, true end
    end
    local t = date("*t", now)
    if ev.monthly then
        for k = 0, 1 do
            local month, year = t.month + k, t.year
            if month > 12 then month, year = 1, year + 1 end
            local s = FirstSunday(year, month)
            if s + ev.hours * 3600 > now then return s, s + ev.hours * 3600, true end
        end
    end
    if ev.yearly then
        for k = -1, 1 do -- el del ano pasado puede seguir (Fiesta del Invierno en enero)
            local s = time({ year = t.year + k, month = ev.yearly[1], day = ev.yearly[2], hour = ev.yearly[3] or 10 })
            if s + ev.hours * 3600 > now then return s, s + ev.hours * 3600, true end
        end
    end
end

function ns.EventActive(ev, now)
    now = now or time()
    local s, f = ns.EventWindow(ev, now)
    return s ~= nil and s <= now and now < f
end

-- "19d 16h" / "5h 20m"
function ns.FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local d, h, m = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600), math.floor(seconds % 3600 / 60)
    if d > 0 then return L.EV_DAYS_HOURS:format(d, h) end
    return L.EV_HOURS_MINUTES:format(h, m)
end

-- Nombre del evento: el del calendario del juego o el de los datos en el idioma
-- de la ventana (en ingles en los idiomas sin cliente oficial)
function ns.EventName(ev)
    local c = calendar[ev.key]
    if c and c.title and c.title ~= "" and ns.UILANG == ns.LOCALE then return c.title end
    return ev.names[ns.UILANG] or ev.names.enUS
end

-- ------------------------------------------
-- Misiones
-- ------------------------------------------

-- Misiones de un evento (o de todos, "ALL") que se ven: la faccion del selector, tu nivel si
-- myLevel y el buscador
function ns.EventQuests(key, myLevel, search)
    local list, faction, level = {}, ns.FactionFilter and ns.FactionFilter(), UnitLevel("player")
    search = search and search ~= "" and search:lower() or nil
    for _, ev in ipairs(ns.EventList) do
        if key == ALL or ev.key == key then
            for _, id in ipairs(ev.quests) do
                local q = ns.Quests[id] or {}
                if ns.MatchesFaction(q, faction) and not (myLevel and q.minLevel and q.minLevel > level)
                    and (not search or ns.QuestTitle(id):lower():find(search, 1, true)) then
                    list[#list + 1] = id
                end
            end
        end
    end
    table.sort(list, function(a, b)
        local qa, qb = ns.Quests[a] or {}, ns.Quests[b] or {}
        if (qa.minLevel or 0) ~= (qb.minLevel or 0) then return (qa.minLevel or 0) < (qb.minLevel or 0) end
        return a < b
    end)
    return list
end

-- Hechas / total de un evento para tu faccion
function ns.EventProgress(key)
    local list, done = ns.EventQuests(key), 0
    for _, id in ipairs(list) do
        if ns.QuestStatus(id) == ns.STATUS_COMPLETED then done = done + 1 end
    end
    return done, #list
end

-- ------------------------------------------
-- Arte: la imagen de la festividad del calendario del juego
-- ------------------------------------------
-- Nombres del listfile (wago.tools, interface/calendar/holidays). Son de 128x128
-- con el dibujo en los 91 px de arriba a la izquierda (0,711).
local HOLIDAY = "Interface\\Calendar\\Holidays\\Calendar_"
local ART = {
    LUNAR = "LunarFestivalStart", LOVE = "LoveInTheAirStart", CHILDREN = "ChildrensWeekStart",
    MIDSUMMER = "MidsummerStart", HARVEST = "HarvestFestivalStart", HALLOWS = "HallowsEndStart",
    WINTER = "WinterVeilStart", NEWYEAR = "Fireworks", DARKMOON = "DarkmoonFaireElwynnStart",
}
local FALLBACK = "Interface\\EncounterJournal\\UI-EJ-BACKGROUND-Default"
local ART_SIZE = 0.7109375
-- Recorte de la tarjeta (174x96): franja del centro del dibujo
local CARD_CROP = { 0, ART_SIZE, 0.16, 0.16 + ART_SIZE * 96 / 174 }

local function SetEventArt(texture, ev, crop)
    local path = ART[ev.key] and HOLIDAY .. ART[ev.key]
    local exists = path and not (GetFileIDFromPath and not GetFileIDFromPath(path))
    if exists and texture:SetTexture(path) ~= false then
        texture:SetTexCoord(unpack(crop))
    else
        texture:SetTexture(FALLBACK)
        texture:SetTexCoord(0, 0.77, 0.1, 0.6)
    end
end

-- "18/10 – 02/11 (aprox.)"
local function DatesText(ev)
    local s, f, approx = ns.EventWindow(ev)
    if not s then return "" end
    return date("%d/%m", s) .. " – " .. date("%d/%m", f) .. (approx and (" " .. L.EV_APPROX) or "")
end

-- "Acaba dentro de: 5d 13h" en verde si esta activo
local function TimerText(ev, now)
    local s, f = ns.EventWindow(ev, now)
    if not s then return "" end
    if s <= now then return GREEN .. L.EV_ENDS_IN:format(ns.FormatDuration(f - now)) .. "|r" end
    return L.EV_STARTS_IN:format(ns.FormatDuration(s - now))
end

-- ------------------------------------------
-- Portada: una tarjeta por evento (como las de Mazmorras)
-- ------------------------------------------

local COLS, CARD_W, CARD_H, GAP_X, GAP_Y = 4, 174, 96, 14, 12

local function CreateCard(row, onSelect)
    local card = CreateFrame("Button", nil, row)
    card:SetSize(CARD_W, CARD_H)
    local frame = card:CreateTexture(nil, "BACKGROUND")
    frame:SetAllPoints()
    ns.SetEJTexture(frame, "InstanceButton")
    card.art = card:CreateTexture(nil, "BORDER")
    card.art:SetPoint("TOPLEFT", 6, -6)
    card.art:SetPoint("BOTTOMRIGHT", -6, 6)
    local shade = card:CreateTexture(nil, "ARTWORK")
    shade:SetAllPoints(card.art)
    if CreateColor and shade.SetGradient then
        shade:SetColorTexture(1, 1, 1, 1)
        shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0.25))
    else
        shade:SetColorTexture(0, 0, 0, 0.45)
    end
    local hl = card:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    ns.SetEJTexture(hl, "DungeonButtonHighlight")
    hl:SetBlendMode("ADD")
    card.name = card:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    ns.SetTitleFont(card.name, 18)
    card.name:SetPoint("TOPLEFT", 10, -12)
    card.name:SetPoint("TOPRIGHT", -10, -12)
    card.name:SetJustifyH("CENTER")
    card.name:SetMaxLines(2)
    card.name:SetTextColor(1, 0.82, 0)
    -- Abajo: cuanto falta (verde si esta activo) y el progreso, cada uno en su linea
    card.timer = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.timer:SetPoint("BOTTOMLEFT", 12, 11)
    card.progress = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.progress:SetPoint("BOTTOMRIGHT", -12, 11)
    card:SetScript("OnClick", function(self)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        onSelect(self.event)
    end)
    card:SetScript("OnEnter", function(self)
        local ev = self.event
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.EventName(ev), 1, 0.82, 0)
        GameTooltip:AddLine(DatesText(ev), 1, 1, 1)
        GameTooltip:AddLine(TimerText(ev, time()), 1, 1, 1)
        local done, total = ns.EventProgress(ev.key)
        GameTooltip:AddLine(L.PROGRESS:format(done, total), 1, 1, 1)
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end

local function UpdateCard(card, ev, now)
    card.event = ev
    SetEventArt(card.art, ev, CARD_CROP)
    card.name:SetText(ns.EventName(ev))
    -- La duracion sola: "Acaba dentro de" no cabe junto al progreso (lo dice el tooltip)
    local s, f = ns.EventWindow(ev, now)
    card.timer:SetText(s and (CLOCK .. (s <= now and (GREEN .. ns.FormatDuration(f - now) .. "|r")
        or ns.FormatDuration(s - now))) or "")
    local done, total = ns.EventProgress(ev.key)
    local progress = ""
    if total > 0 then
        local icon = done == total and ns.StatusMarkup(ns.STATUS_COMPLETED, 14) or ns.StatusMarkup(ns.STATUS_AVAILABLE, 14)
        progress = icon .. " " .. (done == total and GREEN or "|cffffffff") .. done .. "/" .. total .. "|r"
    end
    card.progress:SetText(progress)
end

-- ------------------------------------------
-- Seccion
-- ------------------------------------------

function ns.CreateEventsSection(parent)
    local section = { search = true }
    local state = { key = nil, questID = nil, myLevel = false }
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    section.frame = frame

    -- Portada ------------------------------------------------------------------
    local home = CreateFrame("Frame", nil, frame)
    home:SetAllPoints()
    local bg = home:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSkin(bg, "home")
    local band = home:CreateTexture(nil, "BORDER")
    band:SetPoint("TOPLEFT")
    band:SetPoint("TOPRIGHT")
    band:SetHeight(HEADER_H)
    band:SetColorTexture(0, 0, 0, 0.55)
    local title = home:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    ns.SetTitleFont(title, 24)
    title:SetPoint("TOPLEFT", 20, -12)
    title:SetText(L.TAB_EVENTS)
    local featured = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    featured:SetPoint("LEFT", title, "RIGHT", 18, 0)
    local timer = home:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timer:SetPoint("TOPRIGHT", -20, -18)
    featured:SetPoint("RIGHT", timer, "LEFT", -12, 0)
    featured:SetJustifyH("LEFT")
    featured:SetWordWrap(false)
    local progress = home:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    progress:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -10)
    local levelLabel = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelLabel:SetPoint("TOPRIGHT", -20, -48)
    levelLabel:SetText(L.MY_RANGE)
    local levelCheck = CreateFrame("CheckButton", nil, home, "UICheckButtonTemplate")
    levelCheck:SetSize(24, 24)
    levelCheck:SetPoint("RIGHT", levelLabel, "LEFT", 0, 0)
    levelCheck:SetScript("OnClick", function(self)
        state.myLevel = self:GetChecked() and true or false
        ns.RefreshUI()
    end)
    ns.AddTooltip(levelCheck, L.EV_MY_LEVEL_TOOLTIP)
    local homeFaction = ns.CreateFactionToggle(home, 22)
    homeFaction:SetPoint("RIGHT", levelCheck, "LEFT", -12, 0)

    local function Open(ev)
        state.key, state.questID = ev.key, nil
        ns.RefreshUI()
    end
    local gridArea = CreateFrame("Frame", nil, home)
    gridArea:SetPoint("TOP", 0, -(HEADER_H + 8))
    gridArea:SetPoint("BOTTOM", 0, 6)
    gridArea:SetWidth(COLS * CARD_W + (COLS - 1) * GAP_X + 24)
    local grid = ns.CreateScrollList(gridArea, CARD_H + GAP_Y, function(row)
        row.cards = {}
        for i = 1, COLS do
            local card = CreateCard(row, Open)
            card:SetPoint("TOPLEFT", (i - 1) * (CARD_W + GAP_X), 0)
            row.cards[i] = card
        end
    end, function(row, item)
        for i, card in ipairs(row.cards) do
            card:SetShown(item[i] ~= nil)
            if item[i] then UpdateCard(card, item[i], item.now) end
        end
    end)
    local empty = home:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    empty:SetPoint("CENTER", 0, -20)
    empty:SetText(L.EV_NONE)

    -- Libro de un evento: misiones a la izquierda, la hoja a la derecha ----------
    local book = CreateFrame("Frame", nil, frame)
    book:SetAllPoints()
    local bookBg = book:CreateTexture(nil, "BACKGROUND")
    bookBg:SetAllPoints()
    ns.SetSkin(bookBg, "book")
    local spine = ns.BOOK and ns.BOOK.spine or 392
    local head = book:CreateTexture(nil, "BORDER")
    head:SetPoint("TOPLEFT", 0, -11)
    head:SetSize(386, 60)
    if CreateColor and head.SetGradient then
        head:SetColorTexture(1, 1, 1, 1)
        head:SetGradient("HORIZONTAL", CreateColor(0.08, 0.05, 0.02, 0.92), CreateColor(0.08, 0.05, 0.02, 0.55))
    else
        head:SetColorTexture(0.08, 0.05, 0.02, 0.85)
    end
    -- La imagen de la festividad, cuadrada con borde (como un icono)
    local iconBox = ns.CreateDarkBox(book, 10)
    iconBox:SetSize(48, 48)
    iconBox:SetPoint("TOPLEFT", 10, -17)
    local icon = iconBox:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    local bookTitle = book:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bookTitle:SetPoint("TOPLEFT", iconBox, "TOPRIGHT", 10, -4)
    bookTitle:SetPoint("RIGHT", book, "LEFT", 300, 0) -- a la derecha, la faccion
    local bookFaction = ns.CreateFactionToggle(book, 20)
    bookFaction:SetPoint("TOPRIGHT", head, "TOPRIGHT", -10, -10)
    bookTitle:SetJustifyH("LEFT")
    bookTitle:SetWordWrap(false)
    bookTitle:SetTextColor(unpack(ns.TITLE_LIGHT))
    local bookInfo = book:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bookInfo:SetPoint("TOPLEFT", bookTitle, "BOTTOMLEFT", 0, -6)
    bookInfo:SetPoint("RIGHT", book, "LEFT", 380, 0)
    bookInfo:SetJustifyH("LEFT")
    bookInfo:SetWordWrap(false)

    local left = CreateFrame("Frame", nil, book)
    left:SetPoint("TOPLEFT", 22, -76)
    left:SetPoint("BOTTOMRIGHT", book, "BOTTOMLEFT", 382, 16)
    local list = ns.CreateQuestList(left, function(id)
        state.questID = id
        ns.RefreshUI()
    end)
    local none = ns.PaperText(left, "QuestFont")
    none:SetPoint("TOP", 0, -30)
    none:SetText(L.EV_NONE)
    local right = CreateFrame("Frame", nil, book)
    right:SetPoint("TOPLEFT", spine + 20, -24)
    right:SetPoint("BOTTOMRIGHT", -26, 18)
    local detail = ns.CreateQuestDetail(right)

    -- El calendario del juego llega tarde: se pide al abrir la seccion
    local asked
    frame:SetScript("OnEvent", function()
        ns.ScanEventCalendar()
        ns.RefreshUI()
    end)
    local function AskCalendar()
        if asked then return end
        asked = true
        pcall(frame.RegisterEvent, frame, "CALENDAR_UPDATE_EVENT_LIST")
        if C_Calendar and C_Calendar.OpenCalendar then pcall(C_Calendar.OpenCalendar) end
        ns.ScanEventCalendar()
    end

    -- Evento destacado: el activo que antes acaba o, si no hay, el proximo
    local function Featured(now)
        local best, bestActive, bestTime
        for _, ev in ipairs(ns.EventList) do
            local s, f = ns.EventWindow(ev, now)
            if s then
                local active = s <= now
                local t = active and f or s
                if (active and not bestActive) or (active == (bestActive or false) and (not bestTime or t < bestTime)) then
                    best, bestActive, bestTime = ev, active, t
                end
            end
        end
        return best, bestActive
    end

    local function RefreshHome(now, search)
        local ev, active = Featured(now)
        if ev then
            local s, f, approx = ns.EventWindow(ev, now)
            featured:SetText(ns.EventName(ev))
            timer:SetText(CLOCK .. (active and L.EV_ENDS_IN or L.EV_STARTS_IN):format(ns.FormatDuration((active and f or s) - now))
                .. (approx and (" " .. GREY .. L.EV_APPROX .. "|r") or ""))
        else
            featured:SetText("")
            timer:SetText("")
        end
        local done, total = ns.EventProgress(ALL)
        progress:SetText(L.PROGRESS:format(done, total))
        levelCheck:SetChecked(state.myLevel)
        homeFaction:Sync()

        -- Activos primero, luego por cuando empiezan. Con el buscador, los eventos
        -- cuyo nombre o alguna mision coincide.
        local order = {}
        local lower = search ~= "" and search:lower() or nil
        for _, e in ipairs(ns.EventList) do
            local match = not lower or ns.EventName(e):lower():find(lower, 1, true)
                or #ns.EventQuests(e.key, false, search) > 0
            if match and #ns.EventQuests(e.key, state.myLevel) > 0 then
                local s = ns.EventWindow(e, now)
                order[#order + 1] = { ev = e, active = s and s <= now, t = s or math.huge }
            end
        end
        table.sort(order, function(a, b)
            if (a.active or false) ~= (b.active or false) then return a.active or false end
            return a.t < b.t
        end)
        local rows = {}
        for i, o in ipairs(order) do
            local r = math.floor((i - 1) / COLS) + 1
            rows[r] = rows[r] or { now = now }
            rows[r][#rows[r] + 1] = o.ev
        end
        grid:SetItems(rows)
        empty:SetShown(#order == 0)
        section.cards = order
    end

    local function RefreshBook(ev, now)
        SetEventArt(icon, ev, { 0, ART_SIZE, 0, ART_SIZE })
        bookTitle:SetText(ns.EventName(ev))
        bookFaction:Sync()
        local done, total = ns.EventProgress(ev.key)
        bookInfo:SetText(DatesText(ev) .. "   " .. TimerText(ev, now) .. "   "
            .. ns.StatusMarkup(ns.STATUS_AVAILABLE, 14) .. " " .. L.PROGRESS:format(done, total))
        local ids = ns.EventQuests(ev.key, state.myLevel)
        if not tContains(ids, state.questID) then
            state.questID = nil
            for _, id in ipairs(ids) do
                if ns.QuestStatus(id) ~= ns.STATUS_COMPLETED then state.questID = id break end
            end
            state.questID = state.questID or ids[1]
        end
        list:Refresh(ids, state.questID)
        none:SetShown(#ids == 0)
        right:SetShown(state.questID ~= nil)
        -- Ancestros dentro de una mazmorra: "dentro de X" (su sitio es la entrada)
        local inside = state.questID and ns.EventDungeon and ns.EventDungeon[state.questID]
        detail.dungeon = inside and ns.DungeonByKey and ns.DungeonByKey[inside]
        if state.questID then detail:Show(state.questID) end
    end

    function section:Refresh()
        AskCalendar()
        local now = time()
        -- Escribir en el buscador vuelve a la portada, como en Mazmorras
        local search = ns.GetSearch and ns.GetSearch() or ""
        if search ~= "" and search ~= self.lastSearch then state.key = nil end
        self.lastSearch = search
        local ev = state.key and ns.EventByKey[state.key]
        if not ev then state.key = nil end
        home:SetShown(ev == nil)
        book:SetShown(ev ~= nil)
        if ev then RefreshBook(ev, now) else RefreshHome(now, search) end
    end

    function section:Crumbs()
        local ev = state.key and ns.EventByKey[state.key]
        if ev then return { { name = ns.EventName(ev) } } end
    end

    function section:Home()
        state.key = nil
    end

    section.state, section.home, section.book, section.detail = state, home, book, detail
    return section
end
