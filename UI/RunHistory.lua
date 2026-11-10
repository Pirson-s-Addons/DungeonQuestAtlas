local _, ns = ...
local L = ns.L

-- ==========================================
-- HISTORIAL DE PARTIDAS
-- ==========================================
-- Las partidas de este personaje (Core/RunLog.lua), con el aspecto de la ventana
-- principal: marco con el logo y el libro del Diario. A la izquierda las partidas (botones
-- de jefe del Diario); a la derecha, en tinta, el detalle de la elegida: resumen, grupo,
-- jefes (con su botin en el tooltip), objetos a Necesidad y bichos.

local unpack = unpack or table.unpack
local BOOK = ns.BOOK
local TOP = 26 -- alto de la barra del titulo del marco

local win, runList, detailList, deleteButton, trackButton, empty, runTitle, runDate
local selected

local function Header(text) return { header = text } end

-- Sobre el papel solo tinta (UI/Theme.lua): nada de colores de clase ni de calidad
local function Plain(link) return type(link) == "string" and (link:match("%[(.-)%]") or link) or "" end

local function ClassIcon(texture, class)
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not coords then return false end
    texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    texture:SetTexCoord(unpack(coords))
    return true
end

local function BossCount(run, d)
    local total, killed = 0, 0
    for _, boss in ipairs(d and ns.RunBosses(d) or {}) do
        if boss.kind == nil then
            total = total + 1
            if run.bosses[boss.name] then killed = killed + 1 end
        end
    end
    return killed, total
end

local function DetailRows(run)
    local d = ns.DungeonByKey[run.key]
    local rows = {
        { left = L.RUN_TIME, right = ns.FormatRunTime(ns.RunDuration(run)) .. (run.closed and "" or ("  (" .. L.RUN_IN_PROGRESS .. ")")) },
        { left = L.RUN_DEATHS, right = tostring(run.deaths) },
        { left = L.RUN_TRASH, right = tostring(run.trashCount) },
        { left = L.RUN_XP, right = tostring(run.xp) },
        { left = L.RUN_GOLD, right = ns.FormatRunMoney(run.money) },
    }
    if run.outside > 0 then rows[#rows + 1] = { left = L.RUN_OUTSIDE, right = ns.FormatRunTime(run.outside) } end

    local party = {}
    for name in pairs(run.party) do party[#party + 1] = name end
    table.sort(party)
    if #party > 0 then
        rows[#rows + 1] = Header(L.RUN_GROUP)
        for _, name in ipairs(party) do rows[#rows + 1] = { left = name, class = run.party[name] } end
    end

    if d then
        rows[#rows + 1] = Header(L.RUN_BOSSES)
        for _, boss in ipairs(ns.RunBosses(d)) do
            local killedAt = run.bosses[boss.name]
            local status = killedAt and ns.FormatRunTime(math.max(0, killedAt - (run.first or killedAt)))
                or ((boss.kind == "rare" and not run.found[boss.name]) and L.RUN_NOT_FOUND or L.RUN_NOT_KILLED)
            rows[#rows + 1] = { boss = boss, dungeon = d, killed = killedAt ~= nil, left = ns.BossName(boss, d),
                right = status, loot = ns.RunLootOf(run, boss.name) }
        end
    end

    if #run.needs > 0 then
        rows[#rows + 1] = Header(L.RUN_NEED)
        for _, need in ipairs(run.needs) do
            rows[#rows + 1] = { left = Plain(need.link), link = need.link, itemID = need.id,
                right = need.won and L.RUN_WON or L.RUN_NOT_WON, dim = not need.won }
        end
    end

    local trash = {}
    for name, entry in pairs(run.trash) do trash[#trash + 1] = { name = name, entry = entry } end
    table.sort(trash, function(a, b)
        if a.entry.n ~= b.entry.n then return a.entry.n > b.entry.n end
        return a.name < b.name
    end)
    if #trash > 0 then
        rows[#rows + 1] = Header(L.RUN_TRASH)
        for _, t in ipairs(trash) do
            rows[#rows + 1] = { left = t.name .. "  x" .. t.entry.n, right = t.entry.xp > 0 and (t.entry.xp .. " XP") or "" }
        end
    end
    return rows
end

local function DetailTooltip(self)
    local item = self.item
    if item.boss then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(item.left, 1, 0.82, 0)
        if #item.loot == 0 then GameTooltip:AddLine(L.RUN_NO_LOOT, 0.6, 0.6, 0.6) end
        for _, loot in ipairs(item.loot) do GameTooltip:AddDoubleLine(loot.link, loot.who or "", 1, 1, 1, 0.8, 0.8, 0.8) end
        GameTooltip:Show()
    elseif item.link and not ns.BROKEN_TOOLTIP[item.itemID] then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(item.link)
        GameTooltip:Show()
    end
end

local function RunDate(run)
    return date("%d/%m %H:%M", run.started)
end

local function Select(run)
    selected = run
    ns.RefreshRunHistory()
end

-- Pagina izquierda: una partida por boton de jefe del Diario, con el icono de la mazmorra
local function CreateRunList(page)
    ns.CreatePaperHeader(page, L.RUN_HISTORY):SetPoint("TOPLEFT", 0, 0)
    local listArea = CreateFrame("Frame", nil, page)
    listArea:SetPoint("TOPLEFT", 0, -32)
    listArea:SetPoint("BOTTOMRIGHT")
    empty = ns.PaperText(page, "QuestFont")
    empty:SetPoint("TOPLEFT", 0, -44)
    empty:SetPoint("RIGHT", -10, 0)
    empty:SetJustifyH("CENTER")
    runList = ns.CreateScrollList(listArea, 54, function(row)
        ns.SetupJournalButton(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        ns.PlaceInHole(row.icon, row)
        row.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
        row.label:SetPoint("TOPLEFT", 72, -11) -- fuera del borde curvo del hueco
        row.label:SetPoint("RIGHT", -12, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        ns.RowText(row.label)
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.info:SetPoint("RIGHT", -12, 0)
        row.info:SetJustifyH("LEFT")
        row.info:SetWordWrap(false)
        ns.RowText(row.info)
        row.info:SetTextColor(unpack(ns.PARCHMENT_SUB))
        row:SetScript("OnClick", function(self)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
            Select(self.run)
        end)
    end, function(row, run)
        row.run = run
        local d = ns.DungeonByKey[run.key]
        if d then ns.SetDungeonArt(row.icon, d, "icon") end
        row.label:SetText(d and ns.DungeonName(d) or run.key)
        local killed, total = BossCount(run, d)
        row.info:SetText(RunDate(run) .. "  ·  " .. ns.FormatRunTime(ns.RunDuration(run)) .. "  ·  " .. killed .. "/" .. total)
        ns.SetJournalButtonSelected(row, run == selected)
    end)
end

-- Pagina derecha: el detalle de la partida elegida, en tinta sobre el papel
local function CreateDetail(page)
    runTitle = ns.PaperText(page, "GameFontNormal")
    ns.SetPaperTitleFont(runTitle, 18)
    runTitle:SetPoint("TOPLEFT", 0, -2)
    runTitle:SetPoint("RIGHT", -6, 0)
    runTitle:SetWordWrap(false)
    runDate = ns.PaperText(page, "GameFontNormalSmall", ns.INK_LIGHT)
    runDate:SetPoint("TOPLEFT", runTitle, "BOTTOMLEFT", 0, -4)

    deleteButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    deleteButton:SetSize(160, 24)
    deleteButton:SetPoint("BOTTOMRIGHT", -8, 0)
    deleteButton:SetScript("OnClick", function() StaticPopup_Show("DUNGEONQUESTATLAS_DELETE_RUN") end)
    trackButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    trackButton:SetSize(160, 24)
    trackButton:SetPoint("RIGHT", deleteButton, "LEFT", -6, 0)
    trackButton:SetScript("OnClick", ns.ShowRunTracker)

    local listArea = CreateFrame("Frame", nil, page)
    listArea:SetPoint("TOPLEFT", 0, -44)
    listArea:SetPoint("BOTTOMRIGHT", 0, 32)
    detailList = ns.CreateScrollList(listArea, 24, function(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 2, 0)
        row.portrait = row:CreateTexture(nil, "ARTWORK")
        row.portrait:SetAllPoints(row.icon)
        row.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        row.cross = row:CreateTexture(nil, "OVERLAY")
        row.cross:SetAllPoints(row.icon)
        row.cross:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        row.right = ns.PaperText(row, "GameFontHighlight")
        row.right:SetPoint("RIGHT", -6, 0)
        row.right:SetJustifyH("RIGHT")
        row.left = ns.PaperText(row, "GameFontHighlight")
        row.left:SetWordWrap(false)
        -- Las cabeceras, aparte: un SetFont en la misma linea se quedaba al reutilizar la fila
        row.header = ns.PaperText(row, "GameFontNormal", ns.INK_HEADER)
        ns.SetPaperTitleFont(row.header, 15)
        row.header:SetPoint("LEFT", 4, 0)
        row.header:SetPoint("RIGHT", -6, 0)
        row.header:SetWordWrap(false)
        row.line = row:CreateTexture(nil, "ARTWORK")
        row.line:SetColorTexture(ns.INK_HEADER[1], ns.INK_HEADER[2], ns.INK_HEADER[3], 0.45)
        row.line:SetHeight(1)
        row.line:SetPoint("BOTTOMLEFT", 0, 2)
        row.line:SetPoint("BOTTOMRIGHT", 0, 2)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.08)
        row:SetScript("OnEnter", DetailTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end, function(row, item)
        row.item = item
        local icon, portrait = false, item.boss ~= nil
        if portrait then
            ns.SetBossPortrait(row.portrait, item.boss)
            row.portrait:SetDesaturated(item.killed)
        elseif item.class then
            icon = ClassIcon(row.icon, item.class)
        elseif item.itemID then
            local tex = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.itemID)
            if tex then
                row.icon:SetTexture(tex)
                row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                icon = true
            end
        end
        row.icon:SetShown(icon)
        row.portrait:SetShown(portrait)
        row.cross:SetShown(item.killed == true)
        row.line:SetShown(item.header ~= nil)
        row.left:ClearAllPoints()
        row.left:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
        row.left:SetPoint("LEFT", (icon or portrait) and 28 or 4, 0)
        row.header:SetText(item.header or "")
        row.right:SetTextColor(unpack((item.dim or (item.boss and not item.killed)) and ns.INK_LIGHT or ns.INK))
        row.left:SetText(item.header and "" or (item.left or ""))
        row.right:SetText(item.right or "")
    end)
end

local function CreateHistory()
    win = CreateFrame("Frame", "DungeonQuestAtlasRunHistory", UIParent, "PortraitFrameTemplate")
    win:SetSize(6 + BOOK.width + 6, TOP + BOOK.height + 7)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    tinsert(UISpecialFrames, "DungeonQuestAtlasRunHistory")
    if win.SetTitle then win:SetTitle("|cffd597ff" .. L.RUN_HISTORY .. "|r") end
    if win.SetPortraitToAsset then win:SetPortraitToAsset(ns.LOGO) end

    local book = CreateFrame("Frame", nil, win)
    book:SetPoint("TOPLEFT", 6, -TOP)
    book:SetPoint("BOTTOMRIGHT", -6, 7)
    local bg = book:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSkin(bg, "book")

    local left = CreateFrame("Frame", nil, book)
    left:SetPoint("TOPLEFT", 22, -22)
    left:SetPoint("BOTTOMRIGHT", book, "BOTTOMLEFT", 382, 16)
    CreateRunList(left)
    local right = CreateFrame("Frame", nil, book)
    right:SetPoint("TOPLEFT", BOOK.spine + 20, -22)
    right:SetPoint("BOTTOMRIGHT", -26, 18)
    CreateDetail(right)

    StaticPopupDialogs.DUNGEONQUESTATLAS_DELETE_RUN = {
        text = L.RUN_DELETE_CONFIRM,
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self) (self.text or self.Text):SetText(L.RUN_DELETE_CONFIRM) end,
        OnAccept = function() ns.DeleteRun(selected) end,
    }
    win:Hide()
end

function ns.DeleteRun(run)
    for i, entry in ipairs(ns.char.runLog) do
        if entry == run then
            table.remove(ns.char.runLog, i)
            break
        end
    end
    if selected == run then selected = nil end
    if ns.RefreshRunHistory then ns.RefreshRunHistory() end
end

function ns.RefreshRunHistory()
    if not (win and win:IsShown()) then return end
    local runs = ns.char.runLog
    if selected == nil or not tContains(runs, selected) then selected = runs[1] end
    empty:SetShown(#runs == 0)
    empty:SetText(L.RUN_NONE)
    runList:SetItems(runs)
    detailList:SetItems(selected and DetailRows(selected) or {})
    local d = selected and ns.DungeonByKey[selected.key]
    runTitle:SetText(selected and (d and ns.DungeonName(d) or selected.key) or "")
    runDate:SetText(selected and RunDate(selected) or "")
    deleteButton:SetText(L.RUN_DELETE)
    deleteButton:SetShown(selected ~= nil)
    trackButton:SetText(L.RUN_TRACK)
    trackButton:SetShown(selected ~= nil and not selected.closed and ns.RunInside() ~= nil)
end

function ns.ToggleRunHistory()
    if not win then CreateHistory() end
    win:SetShown(not win:IsShown())
    ns.RefreshRunHistory()
end

-- La cara del personaje en la portada, a la izquierda del buscador de botin
local historyButton
function ns.CreateRunHistoryButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(28, 28)
    local portrait = button:CreateTexture(nil, "ARTWORK")
    portrait:SetAllPoints()
    button:SetScript("OnShow", function() SetPortraitTexture(portrait, "player") end)
    SetPortraitTexture(portrait, "player")
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.2)
    button:SetScript("OnClick", ns.ToggleRunHistory)
    ns.AddTooltip(button, L.RUN_HISTORY_TOOLTIP)
    historyButton = button
    ns.UpdateRunHistoryButton()
    return button
end

-- Opcion "Cara del historial en la portada" (/dqa runs lo abre igual)
function ns.UpdateRunHistoryButton()
    if historyButton then historyButton:SetShown(ns.db.runHistoryButton ~= false) end
end
