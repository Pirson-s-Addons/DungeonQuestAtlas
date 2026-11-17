local _, ns = ...
local L = ns.L

-- ==========================================
-- VENTANA DEL HISTORIAL DE TIRADAS
-- ==========================================
-- Como el "Loot Rolls" del juego antiguo: cada objeto (el mas nuevo arriba) se despliega con
-- [+]/[-] y debajo va cada jugador con su eleccion (dado, moneda, desencantar o pasar), el
-- numero que saco y una marca en el que lo gano. Un aviso marca a quien pidio Necesidad sin
-- que le mejorase mientras a otro si (solo lo ves tu). Datos: Core/RollHistory.lua.
-- Se abre con /dqa rolls, con su tecla o con el logo de la placa de las tiradas.

local ROW = 22
local ICONS = {
    need = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
    greed = "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
    disenchant = "Interface\\Buttons\\UI-GroupLoot-DE-Up",
    pass = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
}
local ORDER = { need = 1, greed = 2, disenchant = 3, pass = 4 }

local win, list, empty
local expanded = {} -- [entrada] = true/false; sin tocar, solo la mas nueva abierta

local function IsOpen(e, i)
    if expanded[e] == nil then return i == 1 end
    return expanded[e]
end

local function SortedRolls(e)
    local rolls = {}
    for _, r in ipairs(e.rolls) do rolls[#rolls + 1] = r end
    table.sort(rolls, function(a, b)
        if (a.won or false) ~= (b.won or false) then return a.won == true end
        local oa, ob = ORDER[a.kind] or 5, ORDER[b.kind] or 5
        if oa ~= ob then return oa < ob end
        return (a.roll or 0) > (b.roll or 0)
    end)
    return rolls
end

local function Rows()
    local rows = {}
    for i, e in ipairs(ns.char and ns.char.rollHistory or {}) do
        rows[#rows + 1] = { entry = e, index = i }
        if IsOpen(e, i) then
            for _, r in ipairs(SortedRolls(e)) do rows[#rows + 1] = { roll = r, entry = e } end
            if e.allPassed then rows[#rows + 1] = { note = L.ROLL_ALL_PASSED, entry = e } end
        end
    end
    return rows
end

local function OnEnter(self)
    local item = self.item
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if item.roll then
        local others = ns.NeedWithoutUpgrade(item.entry.up, item.roll.who)
        if not (item.roll.kind == "need" and others) then return GameTooltip:Hide() end
        GameTooltip:SetText(item.roll.who, 1, 0.82, 0)
        GameTooltip:AddLine(L.UP_NEED_NOT_UPGRADE:format(others), 1, 1, 1, true)
    elseif item.entry and item.entry.link then
        if ns.BROKEN_TOOLTIP and ns.BROKEN_TOOLTIP[item.entry.id] then return end
        GameTooltip:SetHyperlink(item.entry.link)
        local helped = {}
        for name, pct in pairs(item.entry.up or {}) do
            if pct then helped[#helped + 1] = ("%s (+%d%%)"):format(name, pct) end
        end
        if #helped > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|T" .. ns.LOGO .. ":14:14|t " .. L.UP_HEADER, 0.84, 0.59, 1)
            GameTooltip:AddLine(table.concat(helped, ", "), 0.2, 1, 0.2, true)
        end
    end
    GameTooltip:Show()
end

local function OnClick(self)
    local item = self.item
    if not (item.entry and not item.roll and not item.note) then return end
    if IsModifiedClick and IsModifiedClick("CHATLINK") and item.entry.link then
        return ChatEdit_InsertLink(item.entry.link)
    end
    expanded[item.entry] = not IsOpen(item.entry, item.index)
    ns.RefreshRollHistory()
end

local function Setup(row)
    row.toggle = row:CreateTexture(nil, "ARTWORK")
    row.toggle:SetSize(14, 14)
    row.toggle:SetPoint("LEFT", 2, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 20, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetSize(14, 14)
    row.check:SetPoint("LEFT", 22, 0)
    row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    row.kind = row:CreateTexture(nil, "ARTWORK")
    row.kind:SetSize(18, 18)
    row.kind:SetPoint("RIGHT", -30, 0)
    row.number = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.number:SetPoint("RIGHT", -4, 0)
    row.number:SetWidth(26)
    row.number:SetJustifyH("RIGHT")
    row.warn = row:CreateTexture(nil, "ARTWORK")
    row.warn:SetSize(14, 14)
    row.warn:SetPoint("RIGHT", row.kind, "LEFT", -4, 0)
    row.warn:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", OnClick)
    row:SetScript("OnEnter", OnEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
end

local function Update(row, item)
    row.item = item
    local isItem = not (item.roll or item.note)
    row.toggle:SetShown(isItem)
    row.icon:SetShown(isItem)
    row.check:SetShown(item.roll ~= nil and item.roll.won == true)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", isItem and 46 or 40, 0)
    row.label:SetPoint("RIGHT", -52, 0)
    row.warn:Hide()
    row.kind:Hide()
    row.number:SetText("")
    if isItem then
        local e = item.entry
        row.toggle:SetTexture(IsOpen(e, item.index) and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
        row.icon:SetTexture(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id) or 134400)
        row.label:SetFontObject("GameFontNormal")
        row.label:SetText(e.link or ("item:" .. e.id))
        row.number:SetText(date("%H:%M", e.at))
        row.number:SetWidth(40)
    elseif item.note then
        row.label:SetFontObject("GameFontDisableSmall")
        row.label:SetText(item.note)
    else
        local r = item.roll
        local c = r.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[r.class]
        row.label:SetFontObject("GameFontHighlight")
        row.label:SetText(c and ("|c" .. c.colorStr .. r.who .. "|r") or r.who)
        row.number:SetWidth(26)
        row.number:SetText(r.roll and tostring(r.roll) or "")
        if r.kind then
            row.kind:SetTexture(ICONS[r.kind])
            row.kind:Show()
        end
        row.warn:SetShown(r.kind == "need" and ns.NeedWithoutUpgrade(item.entry.up, r.who) ~= nil)
    end
end

local function Create()
    win = ns.CreateDarkBox(UIParent, 14)
    win:SetSize(300, 360)
    win:SetPoint("RIGHT", -260, 40)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    _G.DungeonQuestAtlasRollHistory = win
    tinsert(UISpecialFrames, "DungeonQuestAtlasRollHistory")

    local logo = win:CreateTexture(nil, "ARTWORK")
    logo:SetSize(20, 20)
    logo:SetPoint("TOPLEFT", 10, -9)
    logo:SetTexture(ns.LOGO)
    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
    title:SetText(L.ROLLS_TITLE)
    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)

    local area = CreateFrame("Frame", nil, win)
    area:SetPoint("TOPLEFT", 8, -36)
    area:SetPoint("BOTTOMRIGHT", -8, 10)
    list = ns.CreateScrollList(area, ROW, Setup, Update)
    empty = win:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOPLEFT", area, 10, -10)
    empty:SetPoint("RIGHT", area, -10, 0)
    empty:SetJustifyH("CENTER")
    empty:SetText(L.ROLLS_NONE)
    win:Hide()
end

function ns.RefreshRollHistory()
    if not (win and win:IsShown()) then return end
    local rows = Rows()
    empty:SetShown(#rows == 0)
    list:SetItems(rows)
end

-- Desde el boton de una tirada: abierta (sin cerrarla si ya lo estaba) y con ese objeto
-- desplegado; la ventana se rellena sola mientras cada uno tira
function ns.ShowRollHistory(rollID)
    if not win then Create() end
    for _, e in ipairs(ns.char and ns.char.rollHistory or {}) do
        if rollID and e.rollID == rollID then expanded[e] = true end
    end
    if ns.SyncLootHistory then ns.SyncLootHistory() end
    win:Show()
    ns.RefreshRollHistory()
end

function ns.ToggleRollHistory()
    if not win then Create() end
    if not win:IsShown() and ns.SyncLootHistory then ns.SyncLootHistory() end
    win:SetShown(not win:IsShown())
    ns.RefreshRollHistory()
end
