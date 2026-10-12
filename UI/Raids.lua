local _, ns = ...
local L = ns.L
local unpack = unpack or table.unpack

-- ==========================================
-- SECCION: BANDAS
-- ==========================================
-- Pestana de abajo de la ventana (contrato de seccion: SECTIONS en UI/MainFrame.lua).
-- Como la pestana Bandas de la Guia de aventuras: franja "Bandas" y una tarjeta
-- por banda anunciada de Forever (Data/Raids.lua) con su tamano y la fecha en la
-- que abre (o cuenta atras); detras, tarjetas "Proximamente" con candado para lo
-- anunciado sin nombre (ns.Upcoming). Pulsar una banda abre su libro, como el de
-- las mazmorras: cabecera y jefes a la izquierda y, a la derecha, la pestana
-- lateral elegida: Resumen, Botin, Modelo y, si la banda lo pide, Requisito de
-- acceso (la cadena de misiones de la llave, por faccion).

local COLS = 4
local CARD_W, CARD_H = 174, 96 -- el boton de instancia del Diario
local GAP_X, GAP_Y = 14, 12
local EJ = "Interface\\EncounterJournal\\"
local DEFAULT_BG = EJ .. "UI-EJ-BACKGROUND-Default"
local LOCK = "Interface\\PetBattles\\PetBattle-LockIcon"
local LOADSCREEN = "Interface\\Glues\\LoadingScreens\\"
-- Arte por banda (nombres del listfile de wowdev). card: tarjeta; page: la
-- franja ancha del resumen y el fondo del modelo. Se usa el primero que el
-- cliente tenga; si ninguno, el fondo generico del Diario.
local CROP = {
    button = { 0, 0.68359375, 0, 0.75 },
    bgCard = { 0, 0.77, 0.1, 0.6 }, bgPage = { 0, 0.77, 0.15, 0.55 },
    loadCard = { 0, 1, 0.2, 0.75 }, loadPage = { 0, 1, 0.25, 0.65 },
}
local ART = {
    ONYXIA = {
        card = { { EJ .. "UI-EJ-DUNGEONBUTTON-Onyxia", CROP.button }, { EJ .. "UI-EJ-BACKGROUND-OnyxiasLair", CROP.bgCard } },
        page = { { EJ .. "UI-EJ-BACKGROUND-OnyxiasLair", CROP.bgPage } },
    },
    HYJAL = {
        card = { { LOADSCREEN .. "LoadScreenHyjal", CROP.loadCard } },
        page = { { LOADSCREEN .. "LoadScreenHyjal", CROP.loadPage } },
    },
    BARROW = { -- una de sus entradas esta en Hyjal
        card = { { LOADSCREEN .. "LoadScreenHyjal", CROP.loadCard } },
        page = { { LOADSCREEN .. "LoadScreenHyjal", CROP.loadPage } },
    },
}
local PANELS = { "overview", "loot", "model", "attune" }
local SIDE_ICON = { overview = "TabOverview", loot = "TabLoot", model = "TabModel" }
local KEY_ICON = "Interface\\Icons\\INV_Misc_Key_14"
local RAID_ICON = "Interface\\LFGFrame\\LFGIcon-Raid"
local MODEL_DISTANCE = 2
local SEP = "  ·  "

-- ------------------------------------------
-- Datos: fecha, estado y arte
-- ------------------------------------------

-- "2026-12-09" -> 2026, 12, 9
local function ParseDate(s)
    local y, m, d = (s or ""):match("^(%d+)-(%d+)-(%d+)$")
    if y then return tonumber(y), tonumber(m), tonumber(d) end
end

-- "9 diciembre 2026": meses del juego si los tiene (CALENDAR_FULLDATE_MONTH_NAMES)
function ns.FormatRaidDate(s)
    local y, m, d = ParseDate(s)
    if not y then return "" end
    local months = CALENDAR_FULLDATE_MONTH_NAMES
    return L.RAID_DATE:format(d, months and months[m] or tostring(m), y)
end

-- Dias que faltan para la fecha (0 o menos: ya abierta); nil sin fecha o sin reloj
function ns.DaysUntil(s)
    local y, m, d = ParseDate(s)
    if not (y and time) then return end
    local target = time({ year = y, month = m, day = d, hour = 0 })
    return math.ceil((target - time()) / 86400)
end

-- Texto de cuando abre: "Disponible", "Faltan 58 dias" o la temporada
local function WhenText(raid)
    if raid.season then return L["RAID_SEASON_" .. raid.season] end
    local days = ns.DaysUntil(raid.unlock)
    if days and days <= 0 then return "|cff40c040" .. L.RAID_AVAILABLE .. "|r" end
    if days then return L.RAID_IN_DAYS:format(days) end
    return ns.FormatRaidDate(raid.unlock)
end

local function ZoneText(raid)
    if raid.zone == "hyjal" then return L.RAID_ZONE_HYJAL end
    return raid.zoneMapID and ns.ZoneName and ns.ZoneName(raid.zoneMapID) or nil
end

-- Banda en el Diario del juego (si Forever ya la tiene): por nombre, en todos los niveles
local ejIndex
local function JournalRaid(raid)
    if not ejIndex then
        ejIndex = {}
        if EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex then
            pcall(function()
                local current = EJ_GetCurrentTier and EJ_GetCurrentTier()
                for tier = 1, EJ_GetNumTiers() do
                    EJ_SelectTier(tier)
                    for i = 1, 100 do
                        local id, name, description, bg, button, lore = EJ_GetInstanceByIndex(i, true)
                        if not id then break end
                        ejIndex[name] = { description = description, bg = bg, button = button, lore = lore }
                    end
                end
                if current then EJ_SelectTier(current) end
            end)
        end
    end
    return ejIndex[ns.DungeonName(raid)] or ejIndex[raid.name]
end

local function Valid(t) return t ~= nil and t ~= 0 and t ~= "" end

-- El cliente tiene el fichero: GetFileIDFromPath si existe (un fichero que falta
-- no siempre hace que SetTexture devuelva false: salia la tarjeta en negro)
local function SetIfExists(texture, path)
    if type(path) == "string" and GetFileIDFromPath and not GetFileIDFromPath(path) then return false end
    return texture:SetTexture(path) ~= false
end

-- Arte de la banda: kind "card" (tarjeta) o "page" (resumen y modelo)
local chosen = {}
local function SetRaidArt(texture, raid, kind)
    local j = JournalRaid(raid)
    local list = {}
    if j and kind == "card" and Valid(j.button) then list[#list + 1] = { j.button, CROP.button } end
    if j and kind == "page" and Valid(j.lore) then list[#list + 1] = { j.lore, { 0, 0.7617187, 0, 0.5 } } end
    for _, c in ipairs((ART[raid.key] or {})[kind] or {}) do list[#list + 1] = c end
    list[#list + 1] = { DEFAULT_BG, kind == "card" and CROP.bgCard or CROP.bgPage }
    local key = raid.key .. kind
    local pick = chosen[key]
    for i = pick or 1, pick or #list do
        local c = list[i]
        if i == #list or SetIfExists(texture, c[1]) then
            if i == #list then texture:SetTexture(c[1]) end
            texture:SetTexCoord(unpack(c[2] or { 0, 1, 0, 1 }))
            chosen[key] = i
            return
        end
    end
end

ns.SetRaidArt = SetRaidArt -- tambien las tarjetas de las noticias de Viajes

-- Tarjetas "Proximamente": una por banda sin nombre de ns.Upcoming
local function UpcomingCards()
    local cards = {}
    for _, u in ipairs(ns.Upcoming or {}) do
        for _, r in ipairs(u.raids or {}) do
            local title = type(r) == "number" and L.RAID_UPCOMING_SIZE:format(r)
                or r == "revamp" and L.RAID_UPCOMING_REVAMP or L.RAID_UPCOMING_NEW
            cards[#cards + 1] = { upcoming = true, title = title, season = u.season }
        end
    end
    return cards
end

-- Bandas que pasan el buscador (y, sin buscar, las de Proximamente al final)
function ns.RaidCards(search)
    search = (search or ""):lower()
    local cards = {}
    for _, raid in ipairs(ns.Raids or {}) do
        local name = ns.DungeonName(raid)
        local match = search == "" or name:lower():find(search, 1, true) or raid.name:lower():find(search, 1, true)
        if not match then
            for _, b in ipairs(raid.bosses or {}) do
                if b.name:lower():find(search, 1, true) then match = true break end
            end
        end
        if match then cards[#cards + 1] = { raid = raid } end
    end
    if search == "" then
        for _, c in ipairs(UpcomingCards()) do cards[#cards + 1] = c end
    end
    return cards
end

-- Nombre de un jefe: el del juego por su npcID si se sabe
local function BossName(boss)
    return boss.npcID and ns.PlaceName and ns.PlaceName(boss) or boss.name
end

-- Misiones del requisito de acceso de tu faccion (o nil si la banda no lo pide)
function ns.RaidAttunement(raid, faction)
    local a = raid and raid.attunement
    if not a then return end
    return a[faction] or a[faction == "Horde" and "Horde" or "Alliance"]
end

-- Mazmorra en la que empieza una mision (pasos que van dentro: Profundidades...)
local function DungeonOfQuest(id)
    for _, d in ipairs(ns.Dungeons) do
        if tContains(d.quests or {}, id) then return d end
    end
end

-- ------------------------------------------
-- Portada: cuadricula de tarjetas
-- ------------------------------------------
-- Tarjeta: el nombre arriba (dos lineas como mucho, con hueco a la derecha para
-- el candado) y abajo dos lineas a la izquierda: tamano y "Nueva" / fecha o
-- cuenta atras. Nada comparte linea, asi no se pisa en ningun idioma.

local function CreateCard(row, onSelect)
    local card = CreateFrame("Button", nil, row)
    card:SetSize(CARD_W, CARD_H)
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
        shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.9), CreateColor(0, 0, 0, 0.15))
    else
        shade:SetColorTexture(0, 0, 0, 0.45)
    end
    card.hl = card:CreateTexture(nil, "HIGHLIGHT")
    card.hl:SetAllPoints()
    ns.SetEJTexture(card.hl, "DungeonButtonHighlight")
    card.hl:SetBlendMode("ADD")
    card.name = card:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    ns.SetTitleFont(card.name, 16) -- la fuente de la plantilla, a su tamano, se salia por arriba
    -- Ancho y alto fijos de dos lineas: anclado por los lados se quedaba en una
    card.name:SetPoint("TOP", 0, -14)
    card.name:SetSize(CARD_W - 52, 40)
    card.name:SetJustifyH("CENTER")
    card.name:SetJustifyV("TOP")
    card.name:SetWordWrap(true)
    card.name:SetMaxLines(2)
    card.name:SetTextColor(1, 0.82, 0)
    card.when = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.when:SetPoint("BOTTOMLEFT", 12, 10)
    card.when:SetPoint("BOTTOMRIGHT", -12, 10)
    card.when:SetJustifyH("LEFT")
    card.when:SetWordWrap(false)
    card.info = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.info:SetPoint("BOTTOMLEFT", card.when, "TOPLEFT", 0, 3)
    card.info:SetPoint("BOTTOMRIGHT", card.when, "TOPRIGHT", 0, 3)
    card.info:SetJustifyH("LEFT")
    card.info:SetWordWrap(false)
    card.lock = card:CreateTexture(nil, "OVERLAY")
    card.lock:SetSize(16, 16)
    card.lock:SetPoint("TOPRIGHT", -9, -9)
    card.lock:SetTexture(LOCK)
    card:SetScript("OnClick", function(self)
        if not self.raid then return end
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        onSelect(self.raid)
    end)
    card:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local raid = self.raid
        if raid then
            GameTooltip:SetText(ns.DungeonName(raid), 1, 0.82, 0)
            GameTooltip:AddLine(L.RAID_PLAYERS:format(raid.size), 1, 1, 1)
            GameTooltip:AddLine(L.RAID_OPENS:format(ns.FormatRaidDate(raid.unlock)), 1, 1, 1)
            if raid.bossCount then GameTooltip:AddLine(L.BOSS_COUNT:format(raid.bossCount), 1, 1, 1) end
        else
            GameTooltip:SetText(self.title, 1, 0.82, 0)
            GameTooltip:AddLine(L.RAID_TBA .. SEP .. L["RAID_SEASON_" .. self.season], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end

local function UpdateCard(card, item)
    local raid = item.raid
    card.raid, card.title, card.season = raid, item.title, item.season
    card.lock:SetShown(raid == nil)
    card.art:SetDesaturated(raid == nil)
    if raid then
        SetRaidArt(card.art, raid, "card")
        card.name:SetText(ns.DungeonName(raid))
        card.info:SetText(L.RAID_PLAYERS:format(raid.size)
            .. (raid.isForever and ("  |cffd597ff" .. L.NEW_TAG .. "|r") or ""))
        card.when:SetText(WhenText(raid))
    else
        card.art:SetTexture(DEFAULT_BG)
        card.art:SetTexCoord(unpack(CROP.bgCard))
        card.name:SetText(item.title)
        card.info:SetText(L["RAID_SEASON_" .. item.season])
        card.when:SetText("|cffb0b0b0" .. L.RAID_TBA .. "|r")
    end
end

local function CreateHome(parent, onSelect)
    local home = CreateFrame("Frame", nil, parent)
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
    title:SetText(L.TAB_RAIDS)
    home.subtitle = home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    home.subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)

    local gridArea = CreateFrame("Frame", nil, home)
    gridArea:SetPoint("TOP", 0, -66)
    gridArea:SetPoint("BOTTOM", 0, 6)
    gridArea:SetWidth(COLS * CARD_W + (COLS - 1) * GAP_X + 24) -- con la barra de scroll
    home.list = ns.CreateScrollList(gridArea, CARD_H + GAP_Y, function(row)
        row.cards = {}
        for i = 1, COLS do
            local card = CreateCard(row, onSelect)
            card:SetPoint("TOPLEFT", (i - 1) * (CARD_W + GAP_X), 0)
            row.cards[i] = card
        end
    end, function(row, item)
        for i, card in ipairs(row.cards) do
            card:SetShown(item[i] ~= nil)
            if item[i] then UpdateCard(card, item[i]) end
        end
    end)
    home.empty = home:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    home.empty:SetPoint("CENTER", 0, -20)
    home.empty:SetText(L.RAID_NO_RESULTS)
    return home
end

-- ------------------------------------------
-- Libro de una banda
-- ------------------------------------------

-- Pagina izquierda: los jefes con los botones del Diario
local function CreateBossList(parent, onSelect)
    local list = ns.CreateScrollList(parent, 54, function(row)
        ns.SetupJournalButton(row)
        row.portrait = row:CreateTexture(nil, "ARTWORK")
        ns.PlaceInHole(row.portrait, row)
        row.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
        row.label:SetPoint("TOPLEFT", 72, -11)
        row.label:SetPoint("RIGHT", -12, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        ns.RowText(row.label)
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        ns.RowText(row.info)
        row.info:SetTextColor(unpack(ns.PARCHMENT_SUB))
        row:SetScript("OnClick", function(self)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
            onSelect(self.index)
        end)
    end, function(row, item)
        row.index = item.index
        ns.SetBossPortrait(row.portrait, item.boss)
        row.label:SetText(BossName(item.boss))
        row.info:SetText(L.RAID_BOSS_N:format(item.index, item.total))
        ns.SetJournalButtonSelected(row, item.selected)
    end)
    return list
end

-- Resumen: la banda (o el jefe elegido) con su ilustracion, datos e historia
local function CreateOverview(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetAllPoints()
    local art = panel:CreateTexture(nil, "BACKGROUND")
    art:SetPoint("TOPLEFT", -6, 4)
    art:SetPoint("TOPRIGHT", 6, 4)
    art:SetHeight(180)
    local nameBg = panel:CreateTexture(nil, "ARTWORK")
    nameBg:SetSize(256, 64)
    nameBg:SetPoint("TOP", art, "TOP", 0, -20)
    ns.SetEJTexture(nameBg, "DungeonNameBg")
    local title = panel:CreateFontString(nil, "OVERLAY", "QuestFont_Super_Huge")
    title:SetPoint("CENTER", nameBg, "CENTER", 0, 4)
    title:SetWidth(330)
    title:SetWordWrap(false)
    title:SetTextColor(1, 0.82, 0)

    local scroll = ns.CreateScrollFrame(panel)
    scroll:SetPoint("TOPLEFT", art, "BOTTOMLEFT", 6, -10)
    scroll:SetPoint("BOTTOMRIGHT", -18, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    local facts = ns.PaperText(content, "QuestFont")
    facts:SetPoint("TOPLEFT")
    facts:SetSpacing(5)
    local note = ns.PaperText(content, "GameFontBlack", ns.INK)
    note:SetPoint("TOPLEFT", facts, "BOTTOMLEFT", 0, -10)
    note:SetSpacing(2)
    local lore = ns.PaperText(content, "QuestFont")
    lore:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -10)
    lore:SetSpacing(3)
    local function Fit()
        local width = math.max(100, scroll:GetWidth())
        content:SetWidth(width)
        for _, fs in ipairs({ facts, note, lore }) do fs:SetWidth(width) end
        content:SetHeight(facts:GetStringHeight() + note:GetStringHeight() + lore:GetStringHeight() + 30)
    end
    scroll:SetScript("OnSizeChanged", Fit)
    panel.title, panel.facts, panel.note = title, facts, note

    function panel:Set(raid, index)
        SetRaidArt(art, raid, "page")
        local boss = index and raid.bosses[index]
        title:SetText(boss and BossName(boss) or ns.DungeonName(raid))
        local lines = {}
        if boss then
            lines[1] = L.RAID_BOSS_N:format(index, #raid.bosses) .. SEP .. ns.DungeonName(raid)
        else
            lines[1] = L.RAID_PLAYERS:format(raid.size) .. (raid.isForever and (SEP .. L.KIND_FOREVER) or "")
            local when = WhenText(raid):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            lines[2] = L.RAID_OPENS:format(ns.FormatRaidDate(raid.unlock)) .. "  (" .. when .. ")"
            local zone = ZoneText(raid)
            if zone then lines[#lines + 1] = L.RAID_ZONE:format(zone) end
            if raid.bossCount then lines[#lines + 1] = L.BOSS_COUNT:format(raid.bossCount) end
        end
        facts:SetText(table.concat(lines, "\n"))
        note:SetText(raid.bossSource and L.RAID_BOSSES_NOTE or (#(raid.bosses or {}) == 0 and L.RAID_NO_BOSSES or ""))
        local j = JournalRaid(raid)
        lore:SetText(not boss and j and Valid(j.description) and j.description or "")
        Fit()
        if self.shown ~= (raid.key .. tostring(index)) then scroll:SetVerticalScroll(0) end
        self.shown = raid.key .. tostring(index)
    end
    return panel
end

-- Botin: el del jefe elegido o el de toda la banda; aun no se conoce ninguno
local function CreateLoot(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetAllPoints()
    local header = ns.CreatePaperHeader(panel, L.LOOT)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    local area = CreateFrame("Frame", nil, panel)
    area:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    area:SetPoint("BOTTOMRIGHT")
    local list = ns.CreateScrollList(area, ns.ITEM_ROW_HEIGHT + 2, ns.SetupItemButton, function(row, item)
        ns.SetItemButton(row, item[1], nil, item[2] and (item[2] .. "%"))
    end)
    local empty = ns.PaperText(panel, "QuestFont")
    empty:SetPoint("TOP", header, "BOTTOM", 0, -30)
    empty:SetWidth(320)
    empty:SetJustifyH("CENTER")
    empty:SetText(L.RAID_NO_LOOT)
    panel.empty = empty

    function panel:Set(raid, index)
        local items = {}
        for i, boss in ipairs(raid.bosses or {}) do
            if not index or i == index then
                for _, it in ipairs(boss.loot or {}) do items[#items + 1] = it end
            end
        end
        local boss = index and raid.bosses[index]
        header.text:SetText(boss and (L.LOOT .. SEP .. BossName(boss)) or L.LOOT)
        list:SetItems(items)
        empty:SetShown(#items == 0)
    end
    return panel
end

-- Modelo: el jefe en grande sobre el arte de la banda, con su nombre abajo
local function CreateModel(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetAllPoints()
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -8, 8)
    bg:SetPoint("BOTTOMRIGHT", 8, -6)
    local model = CreateFrame("PlayerModel", nil, panel)
    model:SetPoint("TOPLEFT", 0, -4)
    model:SetPoint("BOTTOMRIGHT", 0, 50)
    model:SetScript("OnModelLoaded", function(self)
        self:SetPortraitZoom(0)
        self:SetCamDistanceScale(self.distance or MODEL_DISTANCE)
    end)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.distance = math.max(0.5, math.min(4, (self.distance or MODEL_DISTANCE) - delta * 0.2))
        self:SetCamDistanceScale(self.distance)
    end)
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        self.facing = (self.facing or 0) + (x - self.dragX) / 80
        self.dragX = x
        self:SetFacing(self.facing)
    end)
    -- Sin modelo: el aviso, claro sobre una caja oscura (regla de contraste)
    local none = ns.CreateDarkBox(panel)
    none:SetSize(240, 40)
    none:SetPoint("CENTER", 0, 20)
    none.text = none:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    none.text:SetPoint("CENTER")
    none.text:SetText(L.RAID_NO_MODEL)
    local shadow = panel:CreateTexture(nil, "OVERLAY")
    shadow:SetPoint("BOTTOMLEFT", -8, -6)
    shadow:SetPoint("BOTTOMRIGHT", 8, -6)
    shadow:SetHeight(64)
    ns.SetEJTexture(shadow, "BossNameShadow")
    local title = panel:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
    ns.SetTitleFont(title, 22)
    title:SetTextColor(1, 0.82, 0)
    title:SetPoint("BOTTOM", 0, 22) -- centrado en la sombra, no pegado al borde
    title:SetPoint("LEFT", 8, 0)
    title:SetPoint("RIGHT", -8, 0)
    panel.title, panel.model, panel.none = title, model, none

    function panel:Set(raid, index)
        SetRaidArt(bg, raid, "page")
        local boss = raid.bosses and raid.bosses[index or 1]
        title:SetText(boss and BossName(boss) or "")
        local display = boss and boss.display
        model:SetShown(display ~= nil)
        none:SetShown(display == nil)
        if display and model.boss ~= boss then
            model.boss = boss
            model:ClearModel()
            model:SetDisplayInfo(display)
            model:SetPortraitZoom(0)
            model.distance = MODEL_DISTANCE
            model:SetCamDistanceScale(MODEL_DISTANCE)
            model.facing = 0.35
            model:SetFacing(model.facing)
        end
    end
    return panel
end

-- Requisito de acceso: la llave, el aviso y los pasos de tu faccion con su estado
-- Como Misiones en las mazmorras: los pasos en la pagina izquierda (en lugar de
-- los jefes) y la hoja de la mision elegida en la derecha
local function CreateAttune(leftPage, rightPage)
    local panel = CreateFrame("Frame", nil, leftPage)
    panel:SetAllPoints()
    local sheet = CreateFrame("Frame", nil, rightPage)
    sheet:SetAllPoints()
    local detail = ns.CreateQuestDetail(sheet)
    local frameSetShown = panel.SetShown
    function panel:SetShown(shown)
        frameSetShown(self, shown)
        sheet:SetShown(shown)
    end
    local header = ns.CreatePaperHeader(panel, L.RAID_TAB_ATTUNE)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    -- La cadena de la faccion del selector (Ambas: la de tu personaje)
    local faction = ns.CreateFactionToggle(panel, 18)
    faction:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 6)
    local key = ns.PaperText(panel, "GameFontBlack", ns.INK)
    key:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    key:SetPoint("RIGHT")
    local warn = ns.CreateDarkBox(panel, 10)
    warn:SetPoint("TOPLEFT", key, "BOTTOMLEFT", -2, -6)
    warn:SetPoint("RIGHT")
    warn.text = warn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warn.text:SetPoint("TOPLEFT", 8, -7)
    warn.text:SetPoint("RIGHT", -8, 0)
    warn.text:SetJustifyH("LEFT")
    warn.text:SetTextColor(unpack(ns.TEXT_ON_DARK))
    warn.text:SetText(L.RAID_ATTUNE_WARNING)
    local area = CreateFrame("Frame", nil, panel)
    area:SetPoint("TOPLEFT", warn, "BOTTOMLEFT", 2, -6)
    area:SetPoint("BOTTOMRIGHT")
    local steps
    steps = ns.CreateScrollList(area, 36, function(row)
        row.selected = row:CreateTexture(nil, "BACKGROUND")
        row.selected:SetAllPoints()
        row.selected:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.18)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.12)
        -- Icono de estado sobre un circulo oscuro: los colores, solo sobre fondo oscuro
        local dot = row:CreateTexture(nil, "BACKGROUND")
        dot:SetSize(26, 26)
        dot:SetPoint("LEFT", 2, 0)
        dot:SetColorTexture(0.08, 0.05, 0.02, 0.85)
        dot:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        row.status = row:CreateTexture(nil, "ARTWORK")
        row.status:SetSize(20, 20)
        row.status:SetPoint("CENTER", dot)
        row.title = ns.PaperText(row, "GameFontBlack", ns.INK)
        row.title:SetPoint("TOPLEFT", 34, -3)
        row.title:SetPoint("RIGHT", -4, 0)
        row.title:SetWordWrap(false)
        row.info = ns.PaperText(row, "GameFontBlackSmall", ns.INK_LIGHT)
        row.info:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
        row.info:SetPoint("RIGHT", -4, 0)
        row.info:SetWordWrap(false)
        row:SetScript("OnClick", function(self)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT) end
            panel:Select(self.questID)
        end)
        row:SetScript("OnEnter", function(self)
            local status, reason = ns.QuestStatus(self.questID)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.title:GetText(), 1, 0.82, 0)
            GameTooltip:AddLine(ns.StatusMarkup(status, 16) .. " " .. ns.STATUS_COLOR[status].light
                .. L["STATUS_" .. status] .. (reason and (": " .. reason) or "") .. "|r")
            GameTooltip:AddLine(L.CLICK_DETAILS, 0.5, 0.8, 1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end, function(row, item)
        local id = item.id
        local q = ns.Quests[id] or {}
        row.questID = id
        row.selected:SetShown(id == panel.questID)
        ns.SetStatusIcon(row.status, ns.QuestStatus(id))
        local title = ns.QuestTitle(id)
        row.title:SetText(item.n .. ". " .. title)
        local starts = ns.QuestPlaces(id, "starts")[1]
        local info = L.LEVEL .. " " .. (q.level or "?")
        if starts then info = info .. SEP .. L.STARTS .. " " .. ns.PlaceName(starts) end
        row.info:SetText(info)
    end)

    function panel:Set(raid)
        local a = raid.attunement
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(a.item) or a.itemName
        key:SetText(L.RAID_ATTUNE_KEY:format(name))
        warn:SetHeight(warn.text:GetStringHeight() + 14)
        local items = {}
        faction:Sync()
        local side = ns.FactionFilter and ns.FactionFilter() or UnitFactionGroup("player")
        for n, id in ipairs(ns.RaidAttunement(raid, side) or {}) do
            items[n] = { n = n, id = id }
        end
        -- Sin paso elegido (o de la otra faccion): el primero sin hacer
        local found = false
        for _, it in ipairs(items) do if it.id == self.questID then found = true end end
        if not found then
            self.questID = nil
            for _, it in ipairs(items) do
                if ns.QuestStatus(it.id) ~= ns.STATUS_COMPLETED then self.questID = it.id break end
            end
            self.questID = self.questID or (items[1] and items[1].id)
        end
        steps:SetItems(items)
        self.items = items
        detail.dungeon = self.questID and DungeonOfQuest(self.questID)
        detail:Show(self.questID)
    end

    function panel:Select(id)
        self.questID = id
        ns.RefreshUI()
    end
    return panel
end

local function CreatePage(parent, section)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    local bg = page:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSkin(bg, "book")
    local spine = ns.BOOK and ns.BOOK.spine or 392

    -- Cabecera de la pagina izquierda: icono, nombre y tamano/fecha (como el libro
    -- de las mazmorras); el icono vuelve al resumen de la banda
    local band = page:CreateTexture(nil, "BORDER")
    band:SetPoint("TOPLEFT", 0, -11)
    band:SetSize(386, 60)
    if CreateColor and band.SetGradient then
        band:SetColorTexture(1, 1, 1, 1)
        band:SetGradient("HORIZONTAL", CreateColor(0.08, 0.05, 0.02, 0.92), CreateColor(0.08, 0.05, 0.02, 0.55))
    else
        band:SetColorTexture(0.08, 0.05, 0.02, 0.85)
    end
    local iconButton = CreateFrame("Button", nil, page)
    iconButton:SetSize(64, 61)
    iconButton:SetPoint("TOPLEFT", 0, -3)
    page.icon = iconButton:CreateTexture(nil, "BACKGROUND")
    page.icon:SetSize(40, 40)
    page.icon:SetPoint("CENTER")
    page.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    local ring = iconButton:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ns.SetEJTexture(ring, "BossModelButton")
    iconButton:SetScript("OnClick", function()
        section.boss, section.tab = nil, "overview"
        ns.RefreshUI()
    end)
    ns.AddTooltip(iconButton, L.TAB_OVERVIEW)
    page.title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    page.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 2, -17)
    page.title:SetPoint("RIGHT", page, "LEFT", 380, 0)
    page.title:SetJustifyH("LEFT")
    page.title:SetWordWrap(false)
    page.title:SetTextColor(unpack(ns.TITLE_LIGHT))
    page.subtitle = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    page.subtitle:SetPoint("TOPLEFT", iconButton, "BOTTOMRIGHT", 2, 8)
    page.subtitle:SetPoint("RIGHT", page, "LEFT", 380, 0)
    page.subtitle:SetWordWrap(false)

    local left = CreateFrame("Frame", nil, page)
    left:SetPoint("TOPLEFT", 22, -76)
    left:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", 382, 16)
    page.bossArea = CreateFrame("Frame", nil, left)
    page.bossArea:SetAllPoints()
    page.bosses = CreateBossList(page.bossArea, function(index)
        section.boss = index
        if section.tab == "attune" then section.tab = "overview" end
        ns.RefreshUI()
    end)
    page.none = ns.PaperText(page.bossArea, "QuestFont")
    page.none:SetPoint("TOP", 0, -30)
    page.none:SetWidth(320)
    page.none:SetJustifyH("CENTER")
    page.none:SetText(L.RAID_NO_BOSSES)

    local right = CreateFrame("Frame", nil, page)
    right:SetPoint("TOPLEFT", spine + 20, -24)
    right:SetPoint("BOTTOMRIGHT", -26, 18)
    page.panels = { overview = CreateOverview(right), loot = CreateLoot(right), model = CreateModel(right),
        attune = CreateAttune(left, right) }

    -- Pestanas del borde derecho, las del Diario (como las del libro de mazmorras)
    page.tabs = {}
    local labels = { overview = L.TAB_OVERVIEW, loot = L.LOOT, model = L.TAB_MODEL, attune = L.RAID_TAB_ATTUNE }
    local previous
    for _, key in ipairs(PANELS) do
        local tab = CreateFrame("Button", nil, page)
        tab:SetSize(63, 57)
        tab:SetFrameLevel(page:GetFrameLevel() + 20) -- encima del borde de la ventana
        if previous then
            tab:SetPoint("TOP", previous, "BOTTOM", 0, 2)
        else
            tab:SetPoint("TOPLEFT", page, "TOPRIGHT", -12, -35)
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
            tab.icon:SetSize(30, 30)
            tab.icon:SetPoint("CENTER", -2, 0)
            tab.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
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
            section.tab = key
            ns.RefreshUI()
        end)
        ns.AddTooltip(tab, labels[key])
        page.tabs[key] = tab
        previous = tab
    end

    function page:SetRaid(raid, index, tab)
        -- Icono redondo (con mascara: SetTexCoord no vale): la cara del primer jefe
        -- con modelo o, si no, el icono de banda del buscador de grupos
        local face = nil
        for _, boss in ipairs(raid.bosses or {}) do if boss.display then face = boss break end end
        if face then ns.SetBossPortrait(self.icon, face) else self.icon:SetTexture(RAID_ICON) end
        self.title:SetText(ns.DungeonName(raid))
        self.subtitle:SetText(L.RAID_PLAYERS:format(raid.size) .. SEP .. WhenText(raid))
        local items, bosses = {}, raid.bosses or {}
        for i, boss in ipairs(bosses) do items[i] = { index = i, boss = boss, total = #bosses, selected = i == index } end
        self.bosses:SetItems(items)
        self.none:SetShown(#items == 0)
        -- La pestana de acceso solo si la banda lo pide
        local attune = raid.attunement ~= nil
        self.tabs.attune:SetShown(attune)
        if attune then
            self.tabs.attune.icon:SetTexture(C_Item and C_Item.GetItemIconByID
                and C_Item.GetItemIconByID(raid.attunement.item) or KEY_ICON)
        end
        if tab == "attune" and not attune then tab = "overview" end
        self.bossArea:SetShown(tab ~= "attune")
        for _, key in ipairs(PANELS) do
            self.panels[key]:SetShown(key == tab)
            self.tabs[key]:Select(key == tab)
        end
        self.panels[tab]:Set(raid, index)
        return tab
    end
    return page
end

-- ------------------------------------------
-- Seccion
-- ------------------------------------------

function ns.CreateRaidsSection(parent)
    local section = { search = true, tab = "overview" }
    section.frame = CreateFrame("Frame", nil, parent)
    section.frame:SetAllPoints()
    local home = CreateHome(section.frame, function(raid)
        section.raid, section.boss, section.tab = raid, nil, "overview"
        ns.RefreshUI()
    end)
    local page = CreatePage(section.frame, section)
    section.home, section.page = home, page

    -- Abre la pagina de una banda desde otra seccion (noticias de Viajes)
    function ns.ShowRaid(raid)
        section.raid, section.boss, section.tab = raid, nil, "overview"
        ns.ShowSection("raids")
    end

    function section:Refresh()
        -- Escribir en el buscador vuelve a la cuadricula, como en Mazmorras
        local search = ns.GetSearch and ns.GetSearch() or ""
        if search ~= "" and search ~= self.lastSearch then self.raid = nil end
        self.lastSearch = search
        home:SetShown(self.raid == nil)
        page:SetShown(self.raid ~= nil)
        if self.raid then
            self.tab = page:SetRaid(self.raid, self.boss, self.tab or "overview")
            return
        end
        local cards = ns.RaidCards(search)
        local rows = {}
        for i, c in ipairs(cards) do
            local r = math.floor((i - 1) / COLS) + 1
            rows[r] = rows[r] or {}
            rows[r][#rows[r] + 1] = c
        end
        home.list:SetItems(rows)
        home.empty:SetShown(#cards == 0)
        local first = ns.Raids and ns.Raids[1]
        home.subtitle:SetText(first and L.RAID_OPENS:format(ns.FormatRaidDate(first.unlock)) or "")
    end

    function section:Crumbs()
        if not self.raid then return end
        local raid = self.raid
        local crumbs = { { name = ns.DungeonName(raid), OnClick = function()
            section.boss, section.tab = nil, "overview"
            ns.RefreshUI()
        end } }
        local boss = self.boss and raid.bosses[self.boss]
        if boss then crumbs[2] = { name = BossName(boss) } end
        return crumbs
    end

    function section:Home()
        self.raid, self.boss = nil, nil
    end

    return section
end
