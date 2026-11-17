local _, ns = ...
local L = ns.L

-- ==========================================
-- CONSEJO EN LAS TIRADAS DE BOTIN
-- ==========================================
-- Junto a cada marco de tirada del juego, una placa con lo que hace el objeto (Core/Upgrades.lua):
--   * a ti: % de mejora y las estadisticas que cambian (o si no puedes llevarlo);
--   * al resto del grupo: a quien mejora y cuanto (y de quien aun no se sabe el equipo);
--   * si una mision de esta mazmorra que aun puedes hacer da algo mejor para ese hueco;
--   * donde mas sale el objeto (otro jefe u otra mazmorra).
-- Lo mismo va en el tooltip del objeto de la tirada (GameTooltip:SetLootRollItem).
-- El boton de la placa abre el historial de tiradas (UI/RollHistory.lua).

local PANEL_WIDTH = 236
local MAX_STATS = 3

local function ItemIDOf(link) return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil end

local function Arrow()
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("bags-greenarrow") then
        return "|A:bags-greenarrow:12:12|a"
    end
    return "|cff20ff20+|r"
end

local function ClassHex(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return c and c.colorStr or "ffffffff"
end

local function Colored(text, hex) return "|c" .. hex .. text .. "|r" end

-- "+8 Agilidad  -3 Fuerza"
local function StatsText(stats)
    local parts = {}
    for i = 1, math.min(MAX_STATS, #stats) do
        local s = stats[i]
        local name = _G[s.key]
        name = type(name) == "string" and name or s.key
        local value = math.floor(s.value * 10 + 0.5) / 10
        parts[#parts + 1] = Colored((value > 0 and "+" or "") .. value .. " " .. name, value > 0 and "ff20ff20" or "ffff4040")
    end
    return table.concat(parts, "  ")
end

local function Pct(result) return math.floor(result.pct + 0.5) end

-- Una mision de esta mazmorra, que aun puedes hacer, con una recompensa mejor para ese hueco
local function QuestBetter(link, mine)
    local d = ns.RunInside and ns.RunInside() and ns.CurrentDungeon and ns.CurrentDungeon()
    if not (d and mine and mine.pct) then return end
    local me = ns.MyUpgradeInfo()
    local best, bestQuest
    for _, id in ipairs(ns.DungeonQuests(d, UnitFactionGroup("player"))) do
        local status = ns.QuestStatus(id)
        local q = ns.Quests[id]
        if q and status ~= ns.STATUS_COMPLETED and status ~= ns.STATUS_BLOCKED then
            for _, list in ipairs({ q.rewards or {}, q.choice or {} }) do
                for _, itemID in ipairs(list) do
                    local result = ns.EvaluateItem("item:" .. itemID, me)
                    if result and result.pct and result.pct > mine.pct + 1 and (not best or result.pct > best.pct) then
                        best, bestQuest = result, id
                        best.itemID = itemID
                    end
                end
            end
        end
    end
    if best and best.pct >= 1 then return bestQuest, best end
end

-- Otro sitio donde sale (no el jefe que acabas de matar)
local function AlsoDrops(itemID)
    local run = ns.RunActive and ns.RunActive()
    for _, e in ipairs(ns.ItemSources and ns.ItemSources(itemID) or {}) do
        local where = ns.DungeonName(e.d)
        if e.quest then
            return "|cffffd100!|r " .. ns.QuestTitle(e.quest) .. " - " .. where
        end
        local boss = e.d.size and e.d.bosses[e.boss] or ns.Bosses[e.d.key][e.boss]
        local isThis = run and boss and boss.name == run.lastBoss and e.d.key == run.key
        if boss and not isThis then
            return (e.d.size and (boss.name or "?") or ns.BossName(boss, e.d)) .. " - " .. where
        end
    end
end

-- Ranuras que no son equipo que mejore a nadie (bolsas, municion, camisas, tabardos)
local NOT_GEAR = { [""] = true, INVTYPE_NON_EQUIP_IGNORE = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true,
    INVTYPE_AMMO = true, INVTYPE_BODY = true, INVTYPE_TABARD = true }

-- Equipo de verdad: materiales, recetas, pociones... no llevan consejo
function ns.IsGearForAdvice(link)
    local instant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if not instant then return false end
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or link
    local _, _, _, equipLoc, _, classID = instant(id)
    -- Solo armas (2) y armaduras (4) que se ponen en una ranura de equipo
    return (classID == 2 or classID == 4) and type(equipLoc) == "string" and not NOT_GEAR[equipLoc]
end

-- Filas del consejo para un objeto (las usan la placa y el tooltip), por secciones:
--   { left = texto, right = texto }  nombre a la izquierda, % a la derecha
--   { note = texto }                 texto de ancho completo que puede ocupar varias lineas
-- y "sep" entre secciones (tu / el grupo / misiones y otros sitios)
local GREEN, RED, GREY, GOLD_TEXT, BEIGE = "ff3ce13c", "ffff5050", "ff9a9a9a", "ffffd100", "ffc8b48c"
local QUEST_ICON = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12|t "
local DROP_ICON = "|TInterface\\Icons\\INV_Misc_Bag_10:12:12:0:0:64:64:5:59:5:59|t "

function ns.RollAdviceRows(link)
    if not (ns.db and ns.db.rollAdvisor and link and ns.UpgradeAdvice) then return {} end
    if not ns.IsGearForAdvice(link) then return {} end
    local ok, advice = pcall(ns.UpgradeAdvice, link)
    if not ok then return {} end
    local rows = {}
    local function Add(row) rows[#rows + 1] = row end

    -- Tu
    local me, you = advice.me, Colored(L.UP_YOU, GOLD_TEXT)
    if me and me.blocked then
        Add({ left = you, right = Colored(type(me.blocked) == "number" and L.UP_LEVEL:format(me.blocked) or L.UP_CANT_USE, RED) })
    elseif ns.IsUpgrade(me) then
        Add({ left = Arrow() .. " " .. you, right = Colored(me.empty and L.UP_EMPTY or ("+" .. Pct(me) .. "%"), GREEN) })
        local stats = StatsText(me.stats)
        if stats ~= "" then Add({ note = stats }) end
    elseif me then
        Add({ left = you .. "  " .. Colored(L.UP_NOT_FOR_YOU, GREY),
            right = me.pct < 0 and Colored(Pct(me) .. "%", RED) or "" })
    end

    -- El grupo: a quien mas le mejora, arriba
    local group = {}
    for _, m in ipairs(advice.members) do
        if ns.IsUpgrade(m.result) then
            group[#group + 1] = { left = Arrow() .. " " .. Colored(m.name, ClassHex(m.class)),
                right = Colored(m.result.empty and L.UP_EMPTY or ("+" .. Pct(m.result) .. "%"), GREEN),
                pct = m.result.empty and 1000 or m.result.pct }
        end
    end
    table.sort(group, function(a, b) return a.pct > b.pct end)
    if #rows > 0 and (#group > 0 or #advice.members > 0 or #advice.unknown > 0) then Add("sep") end
    for _, row in ipairs(group) do Add(row) end
    if #group == 0 and #advice.members > 0 then Add({ note = Colored(L.UP_NOBODY, GREY) }) end
    if #advice.unknown > 0 then
        local names = {}
        for i, u in ipairs(advice.unknown) do names[i] = Colored(u.name, ClassHex(u.class)) end
        Add({ note = Colored(L.UP_NO_DATA:format(table.concat(names, ", ")), GREY) })
    end

    -- Una mision de aqui con algo mejor y donde mas sale
    local questID, reward = QuestBetter(link, me)
    local also = AlsoDrops(ItemIDOf(link))
    if #rows > 0 and (questID or also) then Add("sep") end
    if questID then
        Add({ note = QUEST_ICON .. Colored(L.UP_QUEST:format(ns.QuestTitle(questID), Pct(reward)), GOLD_TEXT) })
    end
    if also then Add({ note = DROP_ICON .. Colored(L.UP_ALSO:format(also), BEIGE) }) end
    return rows
end

-- Las mismas filas como texto (una por linea)
function ns.RollAdviceLines(link)
    local lines = {}
    for _, row in ipairs(ns.RollAdviceRows(link)) do
        if row ~= "sep" then
            lines[#lines + 1] = row.note or (row.left .. ((row.right ~= "" and ("  " .. row.right)) or ""))
        end
    end
    return lines
end

-- ------------------------------------------
-- Tooltip
-- ------------------------------------------

local function AddToTooltip(tooltip, link)
    local rows = ns.RollAdviceRows(link)
    if #rows == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("|T" .. ns.LOGO .. ":14:14|t " .. L.UP_HEADER, 0.84, 0.59, 1)
    for _, row in ipairs(rows) do
        if row == "sep" then
            tooltip:AddLine(" ")
        elseif row.note then
            tooltip:AddLine(row.note, 1, 1, 1, true)
        else
            tooltip:AddDoubleLine(row.left, row.right, 1, 1, 1, 1, 1, 1)
        end
    end
    tooltip:Show()
end

if GameTooltip and GameTooltip.SetLootRollItem and hooksecurefunc then
    hooksecurefunc(GameTooltip, "SetLootRollItem", function(tooltip, rollID)
        local ok, link = pcall(GetLootRollItemLink, rollID)
        link = ok and ns.PlainText(link)
        if link then AddToTooltip(tooltip, link) end
    end)
end

-- ------------------------------------------
-- Placa junto a cada marco de tirada
-- ------------------------------------------

local function RollFrames()
    local frames, seen = {}, {}
    local function Add(f)
        if type(f) == "table" and f.GetObjectType and not seen[f] then
            seen[f] = true
            frames[#frames + 1] = f
        end
    end
    for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do Add(_G["GroupLootFrame" .. i]) end
    if GroupLootContainer and type(GroupLootContainer.rollFrames) == "table" then
        for _, f in pairs(GroupLootContainer.rollFrames) do Add(f) end
    end
    return frames
end

-- Boton "Tiradas" junto a cada tirada (tambien de materiales): abre el historial en ese
-- objeto, que se va rellenando en directo con lo que tira cada uno, y los anteriores debajo
-- Pestaña encima de la tarjeta del objeto, en su esquina derecha: el dado y el texto
-- en dorado, con brillo al pasar el raton y hundido al pulsar
local GOLD, GOLD_LIT = { 0.62, 0.5, 0.28 }, { 1, 0.82, 0.35 }
local function CreateRollsButton(rollFrame)
    local b = CreateFrame("Button", nil, rollFrame, "BackdropTemplate")
    -- Pestaña encima de la tarjeta, en su esquina derecha (como la de una carpeta)
    b:SetSize(92, 24)
    b:SetPoint("BOTTOMRIGHT", rollFrame, "TOPRIGHT", -10, -4)
    b:SetFrameStrata(rollFrame:GetFrameStrata())
    b:SetFrameLevel(rollFrame:GetFrameLevel() + 2)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    b:SetBackdropColor(0.06, 0.05, 0.04, 0.92)
    b:SetBackdropBorderColor(unpack(GOLD))
    -- Fondo con un degradado suave, como las placas del juego
    local shade = b:CreateTexture(nil, "BACKGROUND", nil, 1)
    shade:SetPoint("TOPLEFT", 3, -3)
    shade:SetPoint("BOTTOMRIGHT", -3, 3)
    shade:SetColorTexture(1, 1, 1, 1)
    if shade.SetGradient and CreateColor then
        shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0.35, 0.27, 0.12, 0.35))
    else
        shade:SetAlpha(0)
    end
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 7, 0)
    icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetWordWrap(false)
    text:SetText(L.ROLLS_BUTTON)
    b:SetWidth(math.max(92, math.ceil(text:GetStringWidth()) + 42)) -- textos largos en otros idiomas
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 3, -3)
    hl:SetPoint("BOTTOMRIGHT", -3, 3)
    hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.45)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(GOLD_LIT))
        icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L.ROLLS_TITLE, 1, 0.82, 0)
        GameTooltip:AddLine(L.ROLLS_TOOLTIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(GOLD))
        icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
        GameTooltip:Hide()
    end)
    b:SetScript("OnMouseDown", function()
        icon:SetPoint("LEFT", 8, -1)
    end)
    b:SetScript("OnMouseUp", function()
        icon:SetPoint("LEFT", 7, 0)
    end)
    b:SetScript("OnClick", function()
        PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        ns.ShowRollHistory(rollFrame.rollID)
    end)
    rollFrame.dqaRolls = b
    return b
end

-- Placa del consejo, con el aspecto de un tooltip del juego: cabecera con el logo,
-- filas de nombre y % alineado a la derecha, y notas al final separadas por lineas finas
local PAD, ROW_GAP = 9, 3
local function CreatePanel(rollFrame)
    local panel = CreateFrame("Frame", nil, rollFrame, "BackdropTemplate")
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint("TOPLEFT", rollFrame, "TOPRIGHT", 4, -6)
    panel:SetFrameStrata(rollFrame:GetFrameStrata())
    panel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(0.03, 0.03, 0.06, 0.94)
    panel:SetBackdropBorderColor(0.62, 0.5, 0.28)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(16, 16)
    logo:SetPoint("TOPLEFT", PAD, -PAD + 1)
    logo:SetTexture(ns.LOGO)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", logo, "RIGHT", 5, 0)
    title:SetText(L.UP_HEADER)
    title:SetTextColor(0.84, 0.59, 1)
    panel.top = PAD + 20 -- donde empieza la linea bajo la cabecera
    panel.lines, panel.seps = {}, {}
    rollFrame.dqaPanel = panel
    return panel
end

local function Separator(panel, i, y)
    local sep = panel.seps[i]
    if not sep then
        sep = panel:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetColorTexture(0.62, 0.5, 0.28, 0.45)
        panel.seps[i] = sep
    end
    sep:ClearAllPoints()
    sep:SetPoint("TOPLEFT", PAD, -y)
    sep:SetPoint("TOPRIGHT", -PAD, -y)
    sep:Show()
end

local function Line(panel, i)
    local line = panel.lines[i]
    if not line then
        line = {}
        line.left = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.left:SetJustifyH("LEFT")
        line.right = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.right:SetJustifyH("RIGHT")
        panel.lines[i] = line
    end
    line.left:ClearAllPoints()
    line.right:ClearAllPoints()
    return line
end

local function FillPanel(panel, rows)
    for _, line in ipairs(panel.lines) do line.left:Hide(); line.right:Hide() end
    for _, sep in ipairs(panel.seps) do sep:Hide() end
    local width = PANEL_WIDTH - 2 * PAD
    Separator(panel, 1, panel.top) -- bajo la cabecera
    local y, nLine, nSep = panel.top + 6, 0, 1
    for _, row in ipairs(rows) do
        if row == "sep" then
            nSep = nSep + 1
            Separator(panel, nSep, y + 2)
            y = y + 7
        else
            nLine = nLine + 1
            local line = Line(panel, nLine)
            if row.note then
                line.left:SetPoint("TOPLEFT", PAD, -y)
                line.left:SetWidth(width)
                line.left:SetWordWrap(true)
                line.left:SetText(row.note)
                line.left:Show()
                y = y + line.left:GetStringHeight() + ROW_GAP
            else
                line.right:SetPoint("TOPRIGHT", -PAD, -y)
                line.right:SetText(row.right)
                line.right:Show()
                line.left:SetPoint("TOPLEFT", PAD, -y)
                line.left:SetWidth(width - line.right:GetStringWidth() - 8)
                line.left:SetWordWrap(false)
                line.left:SetText(row.left)
                line.left:Show()
                y = y + math.max(line.left:GetStringHeight(), 12) + ROW_GAP
            end
        end
    end
    panel:SetHeight(y + PAD - ROW_GAP)
end

local function UpdatePanel(rollFrame)
    local rollID = rollFrame.rollID
    local panel = rollFrame.dqaPanel
    if not (rollID and rollFrame:IsShown()) then
        if panel then panel:Hide() end
        if rollFrame.dqaRolls then rollFrame.dqaRolls:Hide() end
        return
    end
    -- El boton de tiradas sale siempre; la placa del consejo, solo con la opcion y si es equipo
    local rolls = rollFrame.dqaRolls or CreateRollsButton(rollFrame)
    rolls:Show()
    local ok, link = pcall(GetLootRollItemLink, rollID)
    link = ok and ns.PlainText(link)
    local rows = link and ns.db and ns.db.rollAdvisor and ns.RollAdviceRows(link) or {}
    if #rows == 0 then
        if panel then panel:Hide() end
        return
    end
    panel = panel or CreatePanel(rollFrame)
    FillPanel(panel, rows)
    panel:Show()
end

local hooked = {}
local function UpdateAll()
    for _, f in ipairs(RollFrames()) do
        if not hooked[f] then
            hooked[f] = true
            f:HookScript("OnShow", function(self) C_Timer.After(0, function() UpdatePanel(self) end) end)
        end
        UpdatePanel(f)
    end
end
ns.UpdateRollAdvice = UpdateAll

local queued = false
local frame = CreateFrame("Frame")
frame:RegisterEvent("START_LOOT_ROLL")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", function(_, event)
    if event == "START_LOOT_ROLL" then
        -- El marco del juego se rellena en este mismo evento; el objeto puede tardar en llegar
        C_Timer.After(0.1, UpdateAll)
        C_Timer.After(1.5, UpdateAll)
    elseif event == "GET_ITEM_INFO_RECEIVED" and not queued then
        for _, f in ipairs(RollFrames()) do
            if f:IsShown() and f.rollID then
                queued = true -- llegan muchos seguidos: un repaso basta
                return C_Timer.After(0.3, function() queued = false; UpdateAll() end)
            end
        end
    end
end)

-- ------------------------------------------
-- Mover las tiradas de botin
-- ------------------------------------------
-- El juego coloca GroupLootContainer solo, apilado sobre las barras de abajo
-- (marco gestionado: no sale en el Modo edicion). Con una posicion guardada
-- (ns.db.lootRollPos = { x, y }: su borde de abajo, desde la esquina inferior
-- izquierda de la pantalla), cada vez que el juego lo coloca se vuelve a poner
-- ahi. No se toca ningun campo del marco del juego (no se contamina su codigo):
-- solo se reancla despues. Opciones > Seguimiento: "Mover tiradas de botin".

local applying = false
local function ApplyRollPosition()
    local pos = ns.db and ns.db.lootRollPos
    local container = GroupLootContainer
    -- Con mando las tiradas se manejan con su navegacion: no se mueven desde el addon
    if not (pos and container) or applying or ns.GamepadUI() then return end
    applying = true
    container:ClearAllPoints()
    container:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    applying = false
end
ns.ApplyLootRollPosition = ApplyRollPosition

if GroupLootContainer and hooksecurefunc then
    hooksecurefunc(GroupLootContainer, "SetPoint", ApplyRollPosition)
    GroupLootContainer:HookScript("OnShow", ApplyRollPosition)
end

-- Ancla para arrastrar: del tamano de una tirada, en su sitio actual
local mover
function ns.ToggleLootRollMover()
    if InCombatLockdown() then return ns.Print(L.ROLL_MOVE_COMBAT) end
    if mover and mover:IsShown() then return mover:Hide() end
    if not mover then
        mover = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        mover:SetSize(260, 64)
        mover:SetFrameStrata("DIALOG")
        mover:SetMovable(true)
        mover:SetClampedToScreen(true)
        mover:EnableMouse(true)
        mover:RegisterForDrag("LeftButton")
        mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        mover:SetBackdropColor(0.25, 0.1, 0.4, 0.75)
        mover:SetBackdropBorderColor(0.84, 0.59, 1, 1)
        local text = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOP", 0, -8)
        text:SetWidth(244)
        text:SetText(L.ROLL_MOVE_TITLE .. "\n|cffaaaaaa" .. L.ROLL_MOVE_HINT .. "|r")
        local function Save()
            local x, y = mover:GetCenter()
            local scale = mover:GetEffectiveScale() / UIParent:GetEffectiveScale()
            ns.db.lootRollPos = { x = x * scale, y = mover:GetBottom() * scale }
            ApplyRollPosition()
        end
        mover:SetScript("OnDragStart", mover.StartMoving)
        mover:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            Save()
        end)
        mover:SetScript("OnMouseUp", function(self, button)
            if button ~= "RightButton" then return end
            if IsShiftKeyDown() then
                ns.db.lootRollPos = nil -- el juego vuelve a colocarlas
                ns.Print(L.ROLL_MOVE_RESET)
            end
            self:Hide()
        end)
        mover:RegisterEvent("PLAYER_REGEN_DISABLED")
        mover:SetScript("OnEvent", mover.Hide)
    end
    mover:ClearAllPoints()
    local pos = ns.db.lootRollPos
    if pos then
        mover:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    elseif GroupLootContainer and GroupLootContainer:GetBottom() then
        mover:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", GroupLootContainer:GetCenter(), GroupLootContainer:GetBottom())
    else
        mover:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
    mover:Show()
end
