local _, ns = ...
local L = ns.L
local unpack = unpack or table.unpack

-- ==========================================
-- SECCION: VIAJES
-- ==========================================
-- "Tu viaje": que puede hacer ahora este personaje. De arriba abajo: misiones listas
-- para entregar, mazmorras recomendadas para su nivel, el siguiente paso de las
-- cadenas que lleva a medias, sus reputaciones (Data/Reputations.lua; por defecto
-- las que tiene en curso) y, en pequeno, lo anunciado que aun no ha llegado
-- (ns.Raids y ns.Upcoming de Data/Raids.lua). Pestana de abajo de la ventana
-- (contrato de seccion: SECTIONS en UI/MainFrame.lua).

local LAUNCH = "2026-11-04"
local LOCK = "QuestSharing-QuestLog-Padlock"
local NEWS_ICON = "|TInterface\\Icons\\INV_Letter_15:18:18|t"
local NEWS_LANG = { esES = "es-es", esMX = "es-mx", deDE = "de-de", frFR = "fr-fr", itIT = "it-it", ptBR = "pt-br",
    ruRU = "ru-ru", koKR = "ko-kr", zhTW = "zh-tw", plPL = "pl-pl" }
local ICON = "Interface\\Icons\\Achievement_Reputation_01"
local CARD_H, GAP, ROW_H = 84, 10, 34
local STEP_H = 44                -- filas de misiones y mazmorras
local MAX_DUNGEONS, MAX_CHAINS = 4, 6
local GOLD = { 0.32, 0.22, 0.04 }
local STONE = { 0.13, 0.12, 0.11 }
-- Piezas de la tarjeta de renombre de Retail (Blizzard_Journeys.xml, rama forever:
-- RenownCardButtonTemplate). Ese fichero solo carga en mainline, asi que se
-- comprueba que el atlas este; si no, caja oscura y el aro del minimapa.
local CARD_ATLAS, RING_ATLAS = "ui-journeys-renown-button", "ui-journeys-renown-radial-bar"
local ICON_SIZE = 40

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

-- Icono de la faccion: el primero de f.icons que tenga el cliente (SetTexture da
-- false si el fichero no existe); si ninguno, el generico de reputacion
local function SetFactionIcon(texture, f)
    for _, name in ipairs(f.icons or {}) do
        if texture:SetTexture("Interface\\Icons\\" .. name) ~= false then return end
    end
    texture:SetTexture(ICON)
end

-- Tipo de una faccion para el filtro: de banda o mazmorra, de JcJ o del mundo
local function FactionType(f)
    if f.raid or f.dungeon then return "instance" end
    return f.pvp and "pvp" or "world"
end

-- Filtro de Renombres, por personaje: show = "active" (las que llevas en curso),
-- "known" (las que tienes) o "all"; hidden[tipo] = true oculta ese tipo. La faccion,
-- el selector compartido. trip: ya vio "Tu viaje" (antes el filtro empezaba en "all").
local function Filter()
    ns.char.journeyFilter = ns.char.journeyFilter or { hidden = {} }
    local flt = ns.char.journeyFilter
    flt.hidden = flt.hidden or {}
    if not flt.trip then flt.show, flt.trip = "active", true end
    return flt
end

-- Reputacion en curso: la tienes, le falta para el siguiente nivel y ya has hecho algo
local function InProgress(s)
    return s and s.max > 0 and (s.value > 0 or (s.reaction or 0) > 4)
end

-- Si una faccion pasa el filtro (locked: sin descubrir o de la otra faccion)
function ns.JourneyVisible(f, locked)
    local flt = Filter()
    if flt.hidden[FactionType(f)] then return false end
    local faction = ns.FactionFilter and ns.FactionFilter()
    if faction and f.side and f.side ~= faction then return false end
    if flt.show == "known" then return not locked end
    if flt.show == "active" then return not locked and InProgress(ns.FactionStanding(f.id)) and true or false end
    return true
end

-- ------------------------------------------
-- Datos
-- ------------------------------------------

-- Lo que el juego sabe de una faccion: nombre, nivel (reaction 1-8) y progreso
-- dentro del nivel. nil si no la conoce (sin descubrir). Retail 11+ tiene
-- C_Reputation.GetFactionDataByID; los clientes antiguos, GetFactionInfoByID.
function ns.FactionStanding(id)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local ok, data = pcall(C_Reputation.GetFactionDataByID, id)
        if ok and type(data) == "table" and data.name and data.name ~= "" then
            return { name = data.name, reaction = data.reaction,
                value = (data.currentStanding or 0) - (data.currentReactionThreshold or 0),
                max = (data.nextReactionThreshold or 0) - (data.currentReactionThreshold or 0) }
        end
    end
    if GetFactionInfoByID then
        local ok, name, _, reaction, barMin, barMax, barValue = pcall(GetFactionInfoByID, id)
        if ok and name and name ~= "" then
            return { name = name, reaction = reaction, value = (barValue or 0) - (barMin or 0),
                max = (barMax or 0) - (barMin or 0) }
        end
    end
end

-- "AAAA-MM-DD" -> segundos (mediodia, para no caer en el dia de al lado)
local function ParseDate(s)
    local y, m, d = (s or ""):match("^(%d+)-(%d+)-(%d+)$")
    if y then return time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }), tonumber(y),
        tonumber(m), tonumber(d) end
end

-- Fecha en el idioma del cliente: L.JOURNEY_DATE con {d} dia, {m} mes con nombre
-- (el del juego si lo tiene), {n} mes en numero y {y} ano
function ns.FormatDate(s)
    local _, y, m, d = ParseDate(s)
    if not y then return s end
    local names = CALENDAR_FULLDATE_MONTH_NAMES
    local month = names and names[m] or tostring(m)
    return (L.JOURNEY_DATE:gsub("{(%a)}", { d = tostring(d), m = month, n = tostring(m), y = tostring(y) }))
end

-- "dentro de 58 dias", "hoy" o "Ya disponible"
function ns.Countdown(s)
    local t = ParseDate(s)
    if not t then return "" end
    local days = math.floor((t - time()) / 86400 + 0.5)
    if days > 0 then return L.JOURNEY_IN_DAYS:format(days) end
    return days == 0 and L.JOURNEY_TODAY or L.JOURNEY_OUT
end

local function RaidName(r)
    return ns.DungeonName(r)
end

local SEASON = {
    spring2027 = function() return L.JOURNEY_SPRING:format(2027) end,
    summer2027 = function() return L.JOURNEY_SUMMER:format(2027) end,
}

-- Linea de tiempo: { date (o when, texto), title, detail, raids = true si es de
-- bandas, links = { { name, open = function } } (lo que se abre desde la noticia) }
function ns.JourneyTimeline()
    local entries = {}
    local new, newLinks = {}, {}
    for _, d in ipairs(ns.Dungeons) do
        if d.isForever and not d.instanceID then
            new[#new + 1] = ns.DungeonName(d)
            newLinks[#newLinks + 1] = { name = ns.DungeonName(d),
                info = ("|c%s%d–%d|r"):format(ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player")), d.minLevel, d.maxLevel),
                art = function(t) ns.SetDungeonArt(t, d, "card") end,
                banner = function(t) ns.SetDungeonArt(t, d, "lore") end,
                open = function() ns.OpenDungeon(d) end }
        end
    end
    entries[1] = { date = LAUNCH, title = L.JOURNEY_LAUNCH, links = newLinks,
        detail = #new > 0 and L.JOURNEY_LAUNCH_DUNGEONS:format(table.concat(new, ", ")) or nil }

    -- Bandas con nombre, juntas por fecha (o temporada)
    local groups, links, order = {}, {}, {}
    for _, r in ipairs(ns.Raids or {}) do
        local when = r.unlock or r.season or "?"
        if not groups[when] then groups[when] = {}; links[when] = {}; order[#order + 1] = when end
        local g = groups[when]
        g[#g + 1] = L.JOURNEY_SIZE:format(RaidName(r), r.size or 0)
        local l = links[when]
        l[#l + 1] = { name = RaidName(r), info = L.RAID_PLAYERS:format(r.size or 0),
            art = function(t) ns.SetRaidArt(t, r, "card") end,
            banner = function(t) ns.SetRaidArt(t, r, "page") end,
            open = function() ns.ShowRaid(r) end }
    end
    for _, when in ipairs(order) do
        local e = { title = L.JOURNEY_RAIDS_OPEN:format(table.concat(groups[when], ", ")), raids = true,
            links = links[when] }
        if ParseDate(when) then e.date = when else e.when = SEASON[when] and SEASON[when]() or when end
        entries[#entries + 1] = e
    end
    entries[#entries + 1] = { when = L.JOURNEY_WINTER, title = L.JOURNEY_HARDCORE }

    -- Anuncios sin nombre
    for _, u in ipairs(ns.Upcoming or {}) do
        local parts = {}
        local raids = u.raids or {}
        if type(raids[1]) == "number" then
            parts[#parts + 1] = L.JOURNEY_NEW_RAIDS:format(#raids, table.concat(raids, " / "))
        elseif #raids > 0 then
            parts[#parts + 1] = L.JOURNEY_REVAMP_RAIDS
        end
        if (u.dungeons or 0) > 0 then parts[#parts + 1] = L.JOURNEY_NEW_DUNGEONS:format(u.dungeons) end
        entries[#entries + 1] = { when = SEASON[u.season] and SEASON[u.season]() or u.season,
            title = table.concat(parts, " · "), raids = #raids > 0 }
    end
    return entries
end

-- ------------------------------------------
-- Que hacer ahora
-- ------------------------------------------

-- Mazmorra de una mision o, si es un paso de fuera, la de su cadena
local function DungeonOf(id)
    local chain = type(ns.Quests[id].chain) == "table" and ns.Quests[id].chain or {}
    for _, step in ipairs({ id, unpack(chain) }) do
        for _, d in ipairs(ns.Dungeons) do
            if tContains(d.quests, step) then return d end
        end
    end
end

-- Abre la hoja de una mision donde este: Registro de viajero o Mazmorras
function ns.OpenJourneyQuest(id)
    local q = ns.Quests[id]
    if q.event then return ns.ShowEventQuest(q.event, id) end
    local d = DungeonOf(id)
    if d then ns.char.dungeon = d.key end
    ns.ShowQuest(id)
end

local function InLog(id)
    return C_QuestLog.GetLogIndexForQuestID(id) ~= nil
end

-- Paso en el que vas de una cadena (y su posicion), o nil si no la has empezado o la
-- has acabado. Va tras el ultimo hecho: un paso opcional saltado no te devuelve atras.
local function ChainStep(chain)
    local last = 0
    for i, id in ipairs(chain) do
        if C_QuestLog.IsQuestFlaggedCompleted(id) then last = i
        elseif InLog(id) then last = i - 1 end
    end
    local id = chain[last + 1]
    if not id then return end
    local started = last > 0 or InLog(id)
    for _, before in ipairs(ns.Quests[id] and ns.Quests[id].after or {}) do
        started = started or C_QuestLog.IsQuestFlaggedCompleted(before)
    end
    if started then return id, last + 1 end
end

local function EventOpen(q)
    local ev = q.event and ns.EventByKey[q.event]
    return not ev or ev.item ~= nil or ns.EventActive(ev)
end

local function ByLevel(a, b)
    if a.level ~= b.level then return a.level < b.level end
    return a.id < b.id
end

-- Lo que puede hacer este personaje ahora: { ready, dungeons, chains, news }
function ns.JourneyPlan()
    local plan = { ready = {}, dungeons = {}, chains = {}, news = {} }
    local faction, here = UnitFactionGroup("player"), C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local function Mine(q) return ns.MatchesFaction(q, faction) and ns.IsMyClass(q) end
    local seen = {}
    for id, q in pairs(ns.Quests) do
        if Mine(q) then
            if ns.QuestStatus(id) == ns.STATUS_READY then
                plan.ready[#plan.ready + 1] = { id = id, level = q.level or 0 }
            end
            local key = type(q.chain) == "table" and table.concat(q.chain, ",")
            if key and not seen[key] then
                seen[key] = true
                local nextID, step = ChainStep(q.chain)
                local nq = nextID and ns.Quests[nextID]
                if nq and Mine(nq) and EventOpen(nq) and ns.QuestStatus(nextID) ~= ns.STATUS_READY then
                    plan.chains[#plan.chains + 1] = { id = nextID, level = nq.level or 0, step = step, total = #q.chain }
                end
            end
        end
    end
    table.sort(plan.ready, ByLevel)
    table.sort(plan.chains, ByLevel)
    for i = #plan.chains, MAX_CHAINS + 1, -1 do plan.chains[i] = nil end

    local level = UnitLevel("player")
    for _, d in ipairs(ns.Dungeons) do
        if ns.InRange(d, level) and not ns.IsDungeonHidden(d) then
            local pick, near = 0, 0
            for _, id in ipairs(ns.DungeonQuests(d, faction, true)) do
                if Mine(ns.Quests[id] or {}) and ns.QuestStatus(id) == ns.STATUS_AVAILABLE then
                    pick = pick + 1
                    local place = ns.QuestPlaces(id, "starts")[1]
                    if place and here and place.mapID == here then near = near + 1 end
                end
            end
            if pick > 0 then plan.dungeons[#plan.dungeons + 1] = { d = d, pick = pick, near = near } end
        end
    end
    table.sort(plan.dungeons, function(a, b)
        if a.near ~= b.near then return a.near > b.near end
        if a.pick ~= b.pick then return a.pick > b.pick end
        return a.d.minLevel < b.d.minLevel
    end)
    for i = #plan.dungeons, MAX_DUNGEONS + 1, -1 do plan.dungeons[i] = nil end

    for _, n in ipairs(ns.News or {}) do
        if not n.ends or ParseDate(n.ends) > time() then plan.news[#plan.news + 1] = n end
    end
    return plan
end

-- ------------------------------------------
-- Interfaz
-- ------------------------------------------

local function Header(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.1)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -6)
    line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    return fs
end

local function SubHeader(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    return fs
end

-- Fila de "Tu viaje": icono de estado, titulo, detalle y, si hay sitio que marcar, boton
local function CreateStepRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(STEP_H)
    local box = ns.CreateDarkBox(row, 12)
    box:SetAllPoints()
    box:SetFrameLevel(row:GetFrameLevel())
    row.mark = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.mark:SetPoint("LEFT", 12, 0)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.title:SetPoint("TOPLEFT", 38, -8)
    row.title:SetPoint("RIGHT", -134, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.detail:SetPoint("RIGHT", -134, 0)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(false)
    row.detail:SetTextColor(unpack(ns.TEXT_ON_DARK))
    row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.action:SetSize(116, 24)
    row.action:SetPoint("RIGHT", -10, 0)
    row.action:SetFrameLevel(row:GetFrameLevel() + 2)
    row.action:SetScript("OnClick", function(self)
        local e = self:GetParent().entry
        local mode, point = ns.MarkPlace(e.place, ns.PlaceName(e.place), e.dungeon, e.kind)
        if mode and point then ns.OpenMapAt(point.mapID) end
    end)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 4, -4)
    hl:SetPoint("BOTTOMRIGHT", -4, 4)
    hl:SetColorTexture(1, 0.82, 0, 0.08)
    row:SetScript("OnClick", function(self)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        self.entry.open()
    end)
    return row
end

local function CreateCard(parent)
    local card = ns.CreateDarkBox(parent, 14)
    card:SetHeight(CARD_H)
    -- Fondo de piedra de Retail si el cliente lo trae (la caja oscura queda, invisible)
    if HasAtlas(CARD_ATLAS) then
        card.art = card:CreateTexture(nil, "BORDER")
        card.art:SetAllPoints()
        card.art:SetAtlas(CARD_ATLAS)
    end
    -- Icono redondo con su aro: el de Retail o el del minimapa (medidas de LibDBIcon:
    -- aro de 53 con el hueco de 20 en 7,-5, escaladas al icono)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(ICON_SIZE, ICON_SIZE)
    card.icon:SetPoint("LEFT", 22, 0)
    card.icon:SetTexture(ICON)
    local mask = card:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(card.icon)
    card.icon:AddMaskTexture(mask)
    local ring = card:CreateTexture(nil, "OVERLAY")
    if HasAtlas(RING_ATLAS) then
        ring:SetAtlas(RING_ATLAS)
        ring:SetSize(ICON_SIZE * 1.5, ICON_SIZE * 1.5)
        ring:SetPoint("CENTER", card.icon)
    else
        local k = ICON_SIZE / 20
        ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        ring:SetSize(53 * k, 53 * k)
        ring:SetPoint("TOPLEFT", card.icon, -7 * k, 5 * k)
    end
    card.ring = ring
    -- Emblema de la Alianza o de la Horda (las de las dos, sin emblema)
    card.side = card:CreateTexture(nil, "OVERLAY")
    card.side:SetSize(22, 22)
    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 18, -2)
    card.name:SetPoint("RIGHT", -60, 0)
    card.name:SetJustifyH("LEFT")
    card.name:SetWordWrap(false)
    card.standing = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.standing:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -5)
    card.bar = CreateFrame("StatusBar", nil, card)
    card.bar:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 18, -2)
    card.bar:SetPoint("RIGHT", -22, 0)
    card.bar:SetHeight(5)
    card.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    card.bar:SetStatusBarColor(1, 0.75, 0.1)
    local barBg = card.bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(0, 0, 0, 0.6)
    card.lock = card:CreateTexture(nil, "OVERLAY")
    card.lock:SetSize(20, 20)
    card.lock:SetPoint("TOPRIGHT", -14, -12)
    card.lock:SetAtlas(LOCK)
    card.side:SetPoint("TOPRIGHT", -38, -11)
    card:EnableMouse(true)
    card:SetScript("OnEnter", function(self)
        local f = self.faction
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.name:GetText(), 1, 0.82, 0)
        if f.side then
            GameTooltip:AddLine(ns.FactionMarkup(f.side) .. " " .. L[f.side == "Alliance" and "FACTION_ALLIANCE" or "FACTION_HORDE"], 1, 1, 1)
        end
        if f.zone then GameTooltip:AddLine(L.JOURNEY_ZONE:format(f.mapID and ns.ZoneName(f.mapID) or f.zone), 1, 1, 1) end
        local raid
        for _, r in ipairs(ns.Raids or {}) do if r.key == f.raid then raid = r end end
        if raid then GameTooltip:AddLine(L.JOURNEY_LINKED_RAID:format(RaidName(raid)), 1, 1, 1) end
        local d = f.dungeon and ns.DungeonByKey[f.dungeon]
        if d then GameTooltip:AddLine(L.JOURNEY_LINKED_DUNGEON:format(ns.DungeonName(d)), 1, 1, 1) end
        if f.pvp then GameTooltip:AddLine(L.JOURNEY_PVP, 1, 1, 1) end
        if f.rewards then GameTooltip:AddLine(L.JOURNEY_REWARDS:format(f.rewards), 0.8, 0.8, 0.8) end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end

local function UpdateCard(card, f)
    card.faction = f
    local s = ns.FactionStanding(f.id)
    local mine = UnitFactionGroup and UnitFactionGroup("player")
    local locked = not s or (f.side and f.side ~= mine)
    local c = locked and STONE or GOLD
    if card.art then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
        card.art:SetDesaturated(locked)
        local v = locked and 0.55 or 1
        card.art:SetVertexColor(v, v, v)
    else
        card:SetBackdropColor(c[1], c[2], c[3], 0.95)
        card:SetBackdropBorderColor(locked and 0.4 or 0.75, locked and 0.38 or 0.6, locked and 0.35 or 0.3)
    end
    SetFactionIcon(card.icon, f)
    card.icon:SetDesaturated(locked)
    card.ring:SetDesaturated(locked)
    card.lock:SetShown(locked)
    local atlas = f.side and ns.FACTION_ATLAS[f.side]
    if atlas then card.side:SetAtlas(atlas) end
    card.side:SetShown(atlas ~= nil)
    card.name:SetText(s and s.name or f.name)
    card.name:SetTextColor(locked and 0.75 or 1, locked and 0.75 or 1, locked and 0.75 or 1)
    if locked then
        card.standing:SetText(L.JOURNEY_LOCKED)
        card.bar:Hide()
        return true
    end
    local label = _G["FACTION_STANDING_LABEL" .. (s.reaction or 0)] or ""
    local text = label
    if s.max > 0 then
        text = text .. "  |cffffffff" .. s.value .. "/" .. s.max .. "|r"
        local nextLabel = _G["FACTION_STANDING_LABEL" .. ((s.reaction or 0) + 1)]
        if nextLabel then text = text .. "  |cffa0a0a0" .. L.TRIP_REP_LEFT:format(s.max - s.value, nextLabel) .. "|r" end
    end
    card.standing:SetText(text)
    card.bar:SetShown(s.max > 0)
    card.bar:SetMinMaxValues(0, math.max(1, s.max))
    card.bar:SetValue(s.value)
    return false
end

local function CreateTimelineRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    local box = ns.CreateDarkBox(row, 12)
    box:SetAllPoints()
    box:SetFrameLevel(row:GetFrameLevel())
    row.when = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.when:SetPoint("LEFT", 14, 0)
    row.when:SetWidth(170)
    row.when:SetJustifyH("LEFT")
    row.when:SetWordWrap(false)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.title:SetPoint("LEFT", 190, 0)
    row.title:SetPoint("RIGHT", -12, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 4, -4)
    hl:SetPoint("BOTTOMRIGHT", -4, 4)
    hl:SetColorTexture(1, 0.82, 0, 0.08)
    row:SetScript("OnClick", function(self)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        parent.section:OpenNews(self.index)
    end)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.title:GetText(), 1, 0.82, 0, 1, true)
        if self.entry.detail then GameTooltip:AddLine(self.entry.detail, 1, 1, 1, true) end
        GameTooltip:AddLine(L.CLICK_DETAILS, 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

-- Fila de una entrada de ns.JourneyPlan
local function StepEntry(key, item)
    if key == "news" then
        local url = item.article and ("https://news.blizzard.com/%s/article/%d"):format(NEWS_LANG[ns.UILANG] or "en-us", item.article)
        local title = L[item.title]
        return { mark = NEWS_ICON, title = title, detail = L[item.text]:format(item.ends and ns.FormatDate(item.ends) or ""),
            open = function() if url then ns.ShowCopyDialog(title, url) end end }
    end
    if key == "dungeons" then
        local d = item.d
        local detail = L.TRIP_TO_PICK:format(item.pick)
        if item.near > 0 then detail = detail .. " · " .. L.TRIP_NEAR:format(item.near) end
        return { mark = ns.StatusMarkup(ns.STATUS_AVAILABLE, 18), detail = detail,
            title = ("%s  |c%s%d–%d|r"):format(ns.DungeonName(d), ns.LevelColor(d.minLevel, d.maxLevel, UnitLevel("player")), d.minLevel, d.maxLevel),
            open = function() ns.OpenDungeon(d) end }
    end
    local id, status, reason = item.id, ns.QuestStatus(item.id)
    local which = key == "ready" and "ends" or "starts"
    local place = ns.QuestPlaces(id, which)[1]
    local detail
    if place then detail = (key == "ready" and L.TRIP_TURN_IN or L.TRIP_NEXT_AT):format(ns.PlaceName(place)) end
    if item.step then
        local step = L.TRIP_STEP:format(item.step, item.total)
        detail = reason or (detail and (step .. " · " .. detail)) or step
    end
    return { mark = ns.StatusMarkup(status, 18), title = ns.QuestTitle(id), detail = detail or "",
        place = status ~= ns.STATUS_IN_LOG and place or nil, dungeon = DungeonOf(id),
        kind = key == "ready" and "end" or "start", button = key == "ready" and L.MARK_END or L.MARK_START,
        open = function() ns.OpenJourneyQuest(id) end }
end

function ns.CreateJourneysSection(parent)
    local section = {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    section.frame = frame
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.07, 0.06, 0.05, 1)

    -- Lista (renombres y proximamente) en su marco: con una noticia abierta se
    -- esconde entera, barra de scroll incluida
    local listFrame = CreateFrame("Frame", nil, frame)
    listFrame:SetAllPoints()
    local scroll = ns.CreateScrollFrame(listFrame)
    scroll:SetPoint("TOPLEFT", 16, -12)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    content.section = section -- las filas abren su noticia

    local trip = Header(content, L.RPG_JOURNEY_TITLE)
    trip:SetPoint("TOPLEFT", 4, -4)
    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetText(L.TRIP_EMPTY)
    -- Las tres listas de lo que se puede hacer; una vacia no ocupa sitio
    local groups = { { key = "ready", head = SubHeader(content, L.TRIP_READY), rows = {} },
        { key = "dungeons", head = SubHeader(content, L.TRIP_RECOMMENDED), rows = {} },
        { key = "chains", head = SubHeader(content, L.TRIP_CHAINS), rows = {} },
        { key = "news", head = SubHeader(content, L.TRIP_NEWS), rows = {} } }
    local renown = Header(content, L.JOURNEY_RENOWN)
    local cards = {}
    for i in ipairs(ns.Reputations) do cards[i] = CreateCard(content) end
    local none = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    none:SetText(L.JOURNEY_NONE)
    local upcoming = Header(content, L.JOURNEY_UPCOMING)
    local rows = {}

    -- Filtro arriba a la derecha (como "Temporada actual" en Retail): que mostrar
    -- y, debajo, casillas por tipo. Se guarda por personaje.
    local SHOW = { { "active", L.TRIP_SHOW_ACTIVE }, { "known", L.JOURNEY_SHOW_KNOWN }, { "all", L.JOURNEY_SHOW_ALL } }
    local TYPES = { { "world", L.JOURNEY_TYPE_WORLD }, { "instance", L.JOURNEY_TYPE_INSTANCE }, { "pvp", L.JOURNEY_TYPE_PVP } }
    -- En la fila de "Renombres", a la derecha: arriba, en la barra, pisaba el
    -- selector de idioma; fijo sobre la lista, las tarjetas al bajar
    local filter = CreateFrame("DropdownButton", nil, content, "WowStyle1DropdownTemplate")
    filter:SetWidth(190)
    local function FilterLabel()
        local flt = Filter()
        for _, o in ipairs(SHOW) do if o[1] == flt.show then return o[2] end end
        return SHOW[1][2]
    end
    local function Changed()
        if filter.OverrideText then filter:OverrideText(FilterLabel()) end
        section:Refresh()
    end
    if filter.SetupMenu then
        filter:SetupMenu(function(_, root)
            for _, o in ipairs(SHOW) do
                root:CreateRadio(o[2], function() return Filter().show == o[1] end,
                    function() Filter().show = o[1]; Changed() end)
            end
            root:CreateDivider()
            root:CreateTitle(L.JOURNEY_TYPE)
            for _, o in ipairs(TYPES) do
                root:CreateCheckbox(o[2], function() return not Filter().hidden[o[1]] end,
                    function() local h = Filter().hidden; h[o[1]] = not h[o[1]] or nil; Changed() end)
            end
        end)
    end
    ns.AddTooltip(filter, L.JOURNEY_FILTER_TOOLTIP)
    local factionToggle = ns.CreateFactionToggle(content, 22)
    factionToggle:SetPoint("RIGHT", filter, "LEFT", -12, 0)
    section.filter, section.cards = filter, cards
    section.SetFilter = function(_, show) Filter().show = show; Changed() end

    local function Layout()
        local width = math.max(400, ns.Width(scroll, 740))
        content:SetWidth(width)
        local half = (width - GAP) / 2
        local y = -36
        local any = false
        empty:ClearAllPoints()
        empty:SetPoint("TOPLEFT", 8, y)
        if section.plan and #section.plan.ready + #section.plan.dungeons + #section.plan.chains == 0 then y = y - 26 end
        for _, g in ipairs(groups) do
            local count = section.plan and #section.plan[g.key] or 0
            g.head:SetShown(count > 0)
            if count > 0 then
                any = any or g.key ~= "news"
                g.head:ClearAllPoints()
                g.head:SetPoint("TOPLEFT", 6, y)
                y = y - 20
                for i = 1, count do
                    g.rows[i]:ClearAllPoints()
                    g.rows[i]:SetPoint("TOPLEFT", 0, y)
                    g.rows[i]:SetWidth(width - 4)
                    y = y - STEP_H - 4
                end
                y = y - 8
            end
        end
        empty:SetShown(not any)
        renown:ClearAllPoints()
        renown:SetPoint("TOPLEFT", 4, y - 8)
        filter:ClearAllPoints()
        filter:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, y - 6)
        y = y - 42
        local n = 0
        for _, card in ipairs(cards) do
            if card:IsShown() then
                local col = n % 2
                card:ClearAllPoints()
                card:SetWidth(half)
                card:SetPoint("TOPLEFT", col * (half + GAP), y)
                if col == 1 then y = y - CARD_H - GAP end
                n = n + 1
            end
        end
        if n % 2 == 1 then y = y - CARD_H - GAP end
        none:ClearAllPoints()
        none:SetPoint("TOPLEFT", 8, y)
        none:SetShown(n == 0)
        if n == 0 then y = y - 24 end
        upcoming:ClearAllPoints()
        upcoming:SetPoint("TOPLEFT", 4, y - 14)
        y = y - 48
        for _, row in ipairs(rows) do
            if row:IsShown() then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, y)
                row:SetWidth(width - 4)
                y = y - ROW_H - 4
            end
        end
        content:SetHeight(-y + 8)
    end
    scroll:SetScript("OnSizeChanged", Layout)

    -- Noticia abierta en la misma ventana ("Principal > Noticia"): estandarte con
    -- el arte de lo que anuncia, titulo, fecha y cuenta atras encima; debajo el
    -- texto y una tarjeta (como las de Mazmorras) por cada banda o mazmorra
    local news = CreateFrame("Frame", nil, frame)
    news:SetAllPoints()
    news:Hide()
    -- Con scroll: con muchas tarjetas no cabe en la ventana
    local newsScroll = ns.CreateScrollFrame(news)
    newsScroll:SetPoint("TOPLEFT", 16, -12)
    newsScroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local body = CreateFrame("Frame", nil, newsScroll)
    body:SetSize(1, 1)
    newsScroll:SetScrollChild(body)
    local banner = body:CreateTexture(nil, "BACKGROUND")
    banner:SetPoint("TOPLEFT")
    banner:SetPoint("TOPRIGHT")
    banner:SetHeight(170)
    local bannerShade = body:CreateTexture(nil, "BORDER")
    bannerShade:SetAllPoints(banner)
    if CreateColor and bannerShade.SetGradient then
        bannerShade:SetColorTexture(1, 1, 1, 1)
        bannerShade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.92), CreateColor(0, 0, 0, 0.15))
    else
        bannerShade:SetColorTexture(0, 0, 0, 0.5)
    end
    local bannerEdge = body:CreateTexture(nil, "ARTWORK")
    bannerEdge:SetPoint("TOPLEFT", banner, "BOTTOMLEFT")
    bannerEdge:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT")
    bannerEdge:SetHeight(2)
    bannerEdge:SetColorTexture(1, 0.82, 0, 0.5)
    local newsWhen = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newsWhen:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 22, 14)
    local newsTitle = body:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    ns.SetTitleFont(newsTitle, 26)
    newsTitle:SetTextColor(1, 0.82, 0)
    newsTitle:SetPoint("BOTTOMLEFT", newsWhen, "TOPLEFT", 0, 8)
    newsTitle:SetPoint("RIGHT", banner, "RIGHT", -22, 0)
    newsTitle:SetJustifyH("LEFT")
    newsTitle:SetMaxLines(2)
    local newsText = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    newsText:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 22, -16)
    newsText:SetPoint("RIGHT", banner, "RIGHT", -22, 0)
    newsText:SetJustifyH("LEFT")
    newsText:SetSpacing(3)
    newsText:SetTextColor(unpack(ns.TEXT_ON_DARK))
    local LINK_W, LINK_H, LINK_GAP = 174, 96, 12
    local links = {}

    local function CreateLinkCard()
        local card = CreateFrame("Button", nil, body)
        card:SetSize(LINK_W, LINK_H)
        local border = card:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        ns.SetEJTexture(border, "InstanceButton")
        card.art = card:CreateTexture(nil, "BORDER")
        card.art:SetPoint("TOPLEFT", 6, -6)
        card.art:SetPoint("BOTTOMRIGHT", -6, 6)
        local shade = card:CreateTexture(nil, "ARTWORK")
        shade:SetAllPoints(card.art)
        if CreateColor and shade.SetGradient then
            shade:SetColorTexture(1, 1, 1, 1)
            shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0.1))
        else
            shade:SetColorTexture(0, 0, 0, 0.35)
        end
        local hl = card:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        ns.SetEJTexture(hl, "DungeonButtonHighlight")
        hl:SetBlendMode("ADD")
        card.name = card:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
        ns.SetTitleFont(card.name, 16)
        card.name:SetPoint("TOPLEFT", 10, -12)
        card.name:SetPoint("TOPRIGHT", -10, -12)
        card.name:SetJustifyH("CENTER")
        card.name:SetMaxLines(2)
        card.name:SetTextColor(1, 0.82, 0)
        card.info = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.info:SetPoint("BOTTOMLEFT", 12, 11)
        card:SetScript("OnClick", function(self)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
            self.open()
        end)
        return card
    end

    function section:OpenNews(index)
        self.newsIndex = index
        ns.RefreshUI()
    end

    local function ShowNews(e, changed)
        local list = e.links or {}
        if list[1] and list[1].banner then
            list[1].banner(banner)
        else
            banner:SetTexture("Interface\\EncounterJournal\\UI-EJ-BACKGROUND-Default")
            banner:SetTexCoord(0, 0.77, 0.15, 0.5)
        end
        newsTitle:SetText(e.title)
        local when = e.date and ns.FormatDate(e.date) or e.when or ""
        if e.date then when = when .. "   |cff99d9ff" .. ns.Countdown(e.date) .. "|r" end
        newsWhen:SetText(when)
        newsText:SetText(e.detail or "")
        local top = e.detail and (newsText:GetStringHeight() + 30) or 16
        for i, link in ipairs(list) do
            local card = links[i] or CreateLinkCard()
            links[i] = card
            local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 6 + col * (LINK_W + LINK_GAP), -top - row * (LINK_H + LINK_GAP))
            card.name:SetText(link.name)
            card.info:SetText(link.info or "")
            if link.art then link.art(card.art) end
            card.open = link.open
            card:Show()
        end
        for i = #list + 1, #links do links[i]:Hide() end
        local rows = math.ceil(#list / 4)
        body:SetWidth(math.max(400, ns.Width(newsScroll, 740)))
        body:SetHeight(170 + top + rows * (LINK_H + LINK_GAP) + 10)
        if changed then newsScroll:SetVerticalScroll(0) end -- arriba solo al abrir otra
    end

    function section:Crumbs()
        local e = self.newsIndex and ns.JourneyTimeline()[self.newsIndex]
        return e and { { name = e.when or ns.FormatDate(e.date) } } or nil
    end

    function section:Home()
        self.newsIndex = nil
    end

    function section:Refresh()
        local e = self.newsIndex and ns.JourneyTimeline()[self.newsIndex]
        if not e then self.newsIndex = nil end
        news:SetShown(e ~= nil)
        listFrame:SetShown(e == nil)
        filter:SetShown(e == nil)
        factionToggle:SetShown(e == nil)
        factionToggle:Sync()
        if e then
            local changed = self.shownNews ~= self.newsIndex
            self.shownNews = self.newsIndex
            return ShowNews(e, changed)
        end
        if filter.OverrideText then filter:OverrideText(FilterLabel()) end
        section.plan = ns.JourneyPlan()
        for _, g in ipairs(groups) do
            local list = {}
            for _, item in ipairs(section.plan[g.key]) do list[#list + 1] = StepEntry(g.key, item) end
            for i, e in ipairs(list) do
                local row = g.rows[i] or CreateStepRow(content)
                g.rows[i] = row
                row.entry = e
                row.mark:SetText(e.mark)
                row.title:SetText(e.title)
                row.detail:SetText(e.detail)
                row.action:SetShown(e.place ~= nil)
                row.action:SetText(e.button or "")
                row:Show()
            end
            for i = #list + 1, #g.rows do g.rows[i]:Hide() end
        end
        for i, f in ipairs(ns.Reputations) do
            local locked = UpdateCard(cards[i], f)
            cards[i]:SetShown(ns.JourneyVisible(f, locked))
        end
        -- Solo lo que aun no ha llegado; row.index es su sitio en la linea de tiempo
        local n = 0
        for i, e in ipairs(ns.JourneyTimeline()) do
            if not (e.date and ns.Countdown(e.date) == L.JOURNEY_OUT) then
                n = n + 1
                local row = rows[n] or CreateTimelineRow(content)
                rows[n] = row
                row.entry, row.index = e, i
                row.when:SetText(e.date and (ns.FormatDate(e.date) .. "  |cff99d9ff" .. ns.Countdown(e.date) .. "|r") or e.when or "")
                row.title:SetText(e.title)
                row:Show()
            end
        end
        for i = n + 1, #rows do rows[i]:Hide() end
        Layout()
    end

    -- Reputacion que cambia mientras se ve
    frame:RegisterEvent("UPDATE_FACTION")
    frame:SetScript("OnEvent", function() if frame:IsVisible() then section:Refresh() end end)
    return section
end
