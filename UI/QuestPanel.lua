local _, ns = ...
local L = ns.L
local unpack = unpack or table.unpack

-- ==========================================
-- MISIONES
-- ==========================================
-- Pagina izquierda: las misiones de la mazmorra como botones del Diario, con
-- "(2/5)" si son de una cadena. Pagina derecha: la hoja de la mision como la
-- del juego, de un vistazo: titulo y estado, la cadena, los objetivos, las
-- donde empieza y termina, las recompensas (como la ventana de misiones del
-- juego) y la descripcion.

local UNVERIFIED = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local FACTION_NAME = { Alliance = "FACTION_ALLIANCE", Horde = "FACTION_HORDE", Both = "FACTION_ALL" }
local SEP = "  ·  "
local LINK = "|cff5c1d00" -- enlaces sobre papel
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local LEGEND_H = 40 -- dos lineas de leyenda en las paginas estrechas

local function Icon(path, size)
    return ("|T%s:%d|t"):format(path, size or 14)
end

-- Paso de la mision en su cadena: 2, 5 (nil si no es de una cadena conocida)
local function ChainStep(q, id)
    local steps = type(q.chain) == "table" and q.chain or {}
    for i, stepID in ipairs(steps) do
        if stepID == id and #steps > 1 then return i, #steps end
    end
end

-- "Completada", "Bloqueada: requiere nivel 14"... en el color del estado
local function StatusText(status, reason, where)
    return ns.STATUS_COLOR[status][where] .. L["STATUS_" .. status] .. (reason and (": " .. reason) or "") .. "|r"
end

-- Tooltip de una fila: titulo, estado, nivel, faccion y que hace el clic
local function QuestTooltip(row)
    local id = row.questID
    local q = ns.Quests[id] or {}
    local status, reason = ns.QuestStatus(id)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.QuestTitle(id), 1, 0.82, 0)
    GameTooltip:AddLine(ns.StatusMarkup(status, 16) .. " " .. StatusText(status, reason, "light"))
    local level = ns.QuestLevel(q, id)
    if level then GameTooltip:AddLine(L.LEVEL .. " " .. level, 1, 1, 1) end
    if q.minLevel then GameTooltip:AddLine(L.REQUIRES_LEVEL:format(q.minLevel), 1, 1, 1) end
    if ns.FACTION_ATLAS[q.faction or ""] then
        GameTooltip:AddLine(ns.FactionMarkup(q.faction) .. " " .. L[FACTION_NAME[q.faction]], 1, 1, 1)
    end
    if q.classes then GameTooltip:AddLine(L.CLASS_ONLY:format(ns.ClassNames(q, true)), 1, 1, 1) end
    local step, total = ChainStep(q, id)
    if step then GameTooltip:AddLine(L.CHAIN:format(step, total), 0.78, 0.72, 0.6) end
    if not ns.IsVerified(id) then GameTooltip:AddLine(Icon(UNVERIFIED, 12) .. " " .. L.UNVERIFIED, 0.6, 0.6, 0.6, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.CLICK_DETAILS, 0.5, 0.8, 1)
    GameTooltip:Show()
end

-- ------------------------------------------
-- Lista (pagina izquierda)
-- ------------------------------------------

-- Filas compactas de dos lineas sobre el papel: caja oscura con el icono de
-- estado del juego, el titulo y debajo "Requiere nivel 13 · Cadena 2/5"; a la
-- derecha la faccion, la clase y el nivel. Las de una cadena llevan una franja
-- azul a la izquierda. Las hechas, en verde suave (legibles, no transparentes).
local ROW_H = 44
local CHAIN_COLOR = { 0.4, 0.72, 1 }
local CHAIN_HEX = "|cff66b8ff"
local TITLE_COLOR = {
    COMPLETED = { 0.55, 0.85, 0.55 },
    BLOCKED = { 0.85, 0.55, 0.5 },
}

local function CreateQuestList(parent, onSelect)
    local selected

    local function Setup(row)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetPoint("TOPLEFT", 0, -1)
        row.bg:SetPoint("BOTTOMRIGHT", 0, 1)
        row.glow = row:CreateTexture(nil, "BORDER") -- la elegida: brillo dorado
        row.glow:SetAllPoints(row.bg)
        row.glow:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        row.glow:SetBlendMode("ADD")
        row.glow:SetVertexColor(1, 0.75, 0.2, 0.55)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row.bg)
        hl:SetColorTexture(1, 1, 1, 0.08)
        row.chainBar = row:CreateTexture(nil, "ARTWORK")
        row.chainBar:SetPoint("TOPLEFT", row.bg)
        row.chainBar:SetPoint("BOTTOMLEFT", row.bg)
        row.chainBar:SetWidth(4)
        row.chainBar:SetColorTexture(CHAIN_COLOR[1], CHAIN_COLOR[2], CHAIN_COLOR[3], 1)
        row.status = row:CreateTexture(nil, "ARTWORK")
        row.status:SetSize(24, 24)
        row.status:SetPoint("LEFT", 10, 0)
        row.level = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        row.level:SetPoint("RIGHT", -10, 0)
        row.faction = row:CreateTexture(nil, "ARTWORK")
        row.faction:SetSize(18, 18)
        row.faction:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
        -- Mision de clase: el circulo de su clase (el del marco de objetivo)
        row.class = row:CreateTexture(nil, "ARTWORK")
        row.class:SetSize(18, 18)
        row.class:SetPoint("RIGHT", row.faction, "LEFT", -2, 0)
        row.class:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.label:SetPoint("TOPLEFT", 42, -7)
        row.label:SetPoint("RIGHT", row.class, "LEFT", -4, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row.info = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.info:SetPoint("RIGHT", row.label, "RIGHT")
        row.info:SetJustifyH("LEFT")
        row.info:SetWordWrap(false)
        row.info:SetTextColor(0.78, 0.74, 0.66)
        row:SetScript("OnClick", function(self)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT) end
            onSelect(self.questID)
        end)
        row:SetScript("OnEnter", QuestTooltip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local function Update(row, item)
        local id = item.id
        local q = ns.Quests[id] or {}
        local status = ns.QuestStatus(id)
        local isSelected = id == selected
        row.questID = id
        row.bg:SetColorTexture(0.1, 0.07, 0.04, isSelected and 0.95 or 0.78)
        row.glow:SetShown(isSelected)
        ns.SetStatusIcon(row.status, status)
        local faction = ns.FACTION_ATLAS[q.faction or ""]
        if faction then row.faction:SetAtlas(faction) end
        row.faction:SetShown(faction ~= nil)
        local coords = q.classes and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[q.classes[1]]
        if coords then row.class:SetTexCoord(unpack(coords)) end
        row.class:SetShown(coords ~= nil)
        row.label:SetText(ns.QuestTitle(id))
        local color = TITLE_COLOR[status]
        if color then row.label:SetTextColor(unpack(color)) else row.label:SetTextColor(1, 0.82, 0) end
        -- Segunda linea: nivel minimo y, si es de una cadena, su paso en azul
        local info = {}
        if q.minLevel then info[#info + 1] = L.REQUIRES_LEVEL:format(q.minLevel) end
        local step, total = ChainStep(q, id)
        if step then
            info[#info + 1] = CHAIN_HEX .. L.CHAIN_SHORT:format(step, total) .. "|r"
        elseif q.chain == true then
            info[#info + 1] = CHAIN_HEX .. L.CHAIN_PART .. "|r"
        end
        row.info:SetText(table.concat(info, SEP))
        row.chainBar:SetShown(step ~= nil or q.chain == true)
        local level = ns.QuestLevel(q, id)
        row.level:SetText(level and ("|c%s%d|r"):format(ns.LevelColor(level, level, UnitLevel("player")), level) or "?")
    end

    local list = ns.CreateScrollList(parent, ROW_H, Setup, Update)
    return {
        -- El ScrollBox guarda tablas, no numeros sueltos
        Refresh = function(_, ids, questID)
            selected = questID
            local items = {}
            for i, id in ipairs(ids) do items[i] = { id = id } end
            list:SetItems(items)
        end,
    }
end

-- ------------------------------------------
-- Detalle (pagina derecha)
-- ------------------------------------------
-- Bloques uno debajo de otro; los ocultos no ocupan sitio. Los de una seccion
-- llevan block.section y se ocultan con su cabecera.

local function CreateDetail(parent)
    local scroll = ns.CreateScrollFrame(parent)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -18, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local blocks = {}
    local function Add(block, gap)
        block.gap = gap or 6
        blocks[#blocks + 1] = block
        return block
    end
    local function Text(font, gap, color)
        local fs = ns.PaperText(content, font, color)
        fs:SetSpacing(2)
        return Add(fs, gap)
    end
    local function Section(text)
        return Add(ns.CreatePaperHeader(content, text), 14)
    end

    local detail = { questID = nil }
    local title = Text("GameFontNormal", 0)
    ns.SetPaperTitleFont(title, 18)
    local meta = Text("GameFontBlack", 6)
    -- El estado en una placa oscura con su color claro (dorado, verde, rojo): sobre
    -- el papel ningun color de estado se lee bien
    local statusRow = Add(CreateFrame("Frame", nil, content), 6)
    statusRow:SetHeight(26)
    local statusBadge = ns.CreateDarkBox(statusRow, 10)
    statusBadge:SetPoint("TOPLEFT")
    statusBadge:SetHeight(26)
    local statusLine = statusBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLine:SetPoint("LEFT", 6, 0)
    local unverified = Text("GameFontBlack", 4, ns.INK_LIGHT)
    local requires = Text("GameFontNormal", 6) -- "Antes: <paso anterior>", si aun no esta hecho

    -- Cadena: un boton por paso, reutilizados. Cada paso abre su hoja.
    local chainHeader = Section(L.CHAIN)
    local chain = Add(CreateFrame("Frame", nil, content))
    local chainBg = chain:CreateTexture(nil, "BACKGROUND")
    chainBg:SetPoint("TOPLEFT", -4, 2)
    chainBg:SetPoint("BOTTOMRIGHT", 4, -2)
    chainBg:SetColorTexture(0.2, 0.35, 0.55, 0.14)
    local links = {}
    local function Link(i)
        if not links[i] then
            local b = CreateFrame("Button", nil, chain)
            b:SetHeight(20)
            b:SetPoint("TOPLEFT", 0, -20 * (i - 1))
            b:SetPoint("RIGHT")
            b:SetNormalFontObject("QuestFont")
            b:SetText(" ") -- crea el FontString para alinearlo a la izquierda
            b:GetFontString():ClearAllPoints()
            b:GetFontString():SetPoint("LEFT", 2, 0)
            b:GetFontString():SetShadowOffset(0, 0)
            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.12)
            -- Cualquier paso abre su hoja, tambien los de fuera de la mazmorra
            -- (Data/Quests.lua los trae con su inicio y final para marcarlos)
            b:SetScript("OnClick", function(self) ns.ShowQuest(self.questID) end)
            links[i] = b
        end
        return links[i]
    end
    local chainNote = Text("GameFontBlack", 4)

    local objHeader = Section(L.OBJECTIVES)
    local obj = Text("QuestFont")
    obj.section = objHeader

    -- Donde ---------------------------------------------------------------
    Section(L.WHERE)
    local starts = Text("QuestFont")
    local ends = Text("QuestFont", 4)
    -- Botones en filas de dos (cuatro en una no caben: "Marcar inicio" se salia)
    local PER_ROW, BUTTON_H, GAP = 2, 24, 4
    local buttons = Add(CreateFrame("Frame", nil, content), 10)
    buttons:SetHeight(BUTTON_H)
    local row = {}
    local function Button(text, tooltip, icon, onClick)
        local b = CreateFrame("Button", nil, buttons, "UIPanelButtonTemplate")
        b:SetHeight(24)
        b:SetText(text)
        ns.SetButtonIcon(b, icon)
        b:SetScript("OnClick", onClick)
        ns.AddTooltip(b, tooltip)
        row[#row + 1] = b
        return b
    end
    -- Los pasos de cadena de fuera no estan en la lista de la mazmorra: su PNJ
    -- sin coordenadas no esta dentro, asi que no se marca la entrada
    local function Dungeon()
        local d = detail.dungeon
        return d and tContains(d.quests, detail.questID) and d or nil
    end
    -- El primero con coordenadas; sin ninguno, MarkPlace marca la entrada
    local function Mark(which)
        local list = ns.QuestPlaces(detail.questID, which)
        local place = list[1]
        for _, p in ipairs(list) do
            if p.mapID then place = p break end
        end
        local mode, point = ns.MarkPlace(place, place and ns.PlaceName(place) or ns.QuestTitle(detail.questID),
            Dungeon(), which == "starts" and "start" or "end")
        -- Y el mapa abierto donde esta el pin
        if mode and point then ns.OpenMapAt(point.mapID) end
    end
    local markStart = Button(L.MARK_START, L.MARK_START_TOOLTIP, "Interface\\GossipFrame\\AvailableQuestIcon", function() Mark("starts") end)
    local markEnd = Button(L.MARK_END, L.MARK_END_TOOLTIP, "Interface\\GossipFrame\\ActiveQuestIcon", function() Mark("ends") end)
    Button(L.WOWHEAD, L.WOWHEAD_TOOLTIP, "Interface\\Icons\\INV_Misc_Note_01", function()
        ns.ShowCopyDialog(ns.QuestTitle(detail.questID), ns.WowheadURL(detail.questID))
    end)
    -- Compartir con el grupo, como el boton del registro de misiones del juego:
    -- hace falta llevarla, que se pueda compartir y estar en grupo
    local share = Button(L.SHARE, L.SHARE_TOOLTIP, "Interface\\Icons\\INV_Letter_15", function()
        local index = C_QuestLog.GetLogIndexForQuestID(detail.questID)
        if index and QuestLogPushQuest then
            QuestLogPushQuest(index)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN) end
        end
    end)
    share:SetMotionScriptsWhileDisabled(true) -- el tooltip explica por que esta apagado

    -- Recompensas: como la ventana de misiones del juego, una seccion mas del
    -- papel; tarjetas en dos columnas (objetos, XP y dinero)
    local rewardHeader = Section(L.REWARDS)
    local rewards = Add(CreateFrame("Frame", nil, content))
    rewards.section = rewardHeader
    local PAD, ROW = 0, ns.REWARD_CARD_HEIGHT + 6
    local labels, cards = {}, {}
    local function Label(i)
        if not labels[i] then
            labels[i] = ns.PaperText(rewards, "GameFontBlack")
        end
        return labels[i]
    end
    local function Card(i)
        cards[i] = cards[i] or ns.CreateRewardCard(rewards)
        return cards[i]
    end

    local function FillRewards(q, id)
        local y, nLabel, nCard, col = -2, 0, 0, 0
        local function EndRow()
            if col == 1 then y = y - ROW end
            col = 0
        end
        local function Line(text)
            EndRow()
            nLabel = nLabel + 1
            local fs = Label(nLabel)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", PAD, y)
            fs:SetText(text)
            fs:Show()
            y = y - 18
        end
        -- Dos por fila: la de la izquierda hasta el centro, la de la derecha desde el
        local function Put(itemID, count, icon, text)
            nCard = nCard + 1
            local card = Card(nCard)
            local half = (ns.Width(rewards, 330) - 6) / 2
            card:ClearAllPoints()
            card:SetWidth(half)
            card:SetPoint("TOPLEFT", PAD + col * (half + 6), y)
            ns.SetRewardCard(card, itemID, count, icon, text)
            card:Show()
            col = col + 1
            if col == 2 then y = y - ROW; col = 0 end
        end
        local mine = DungeonQuestAtlasCollectorDB.quests[id]
        local choice = q.choice or (mine and mine.rewards) or {}
        if #choice > 1 then Line(L.CHOOSE_ONE) end
        for _, itemID in ipairs(choice) do Put(itemID, q.counts and q.counts[itemID]) end
        local xp, money = ns.QuestXP(q, id), ns.QuestMoney(q, id)
        local given = q.rewards or {}
        local extras = #given + ((xp and xp > 0) and 1 or 0) + ((money and money > 0 and GetCoinTextureString) and 1 or 0)
        if extras > 0 and #choice > 0 then Line(L.ALSO_RECEIVE) end
        for _, itemID in ipairs(given) do Put(itemID, q.counts and q.counts[itemID]) end
        if xp and xp > 0 then
            Put(nil, nil, "Interface\\Icons\\XP_Icon", L.XP:format(BreakUpLargeNumbers and BreakUpLargeNumbers(xp) or xp))
        end
        if money and money > 0 and GetCoinTextureString then
            Put(nil, nil, "Interface\\Icons\\INV_Misc_Coin_01", GetCoinTextureString(money))
        end
        EndRow()
        for i = nLabel + 1, #labels do labels[i]:Hide() end
        for i = nCard + 1, #cards do cards[i]:Hide() end
        rewards:SetHeight(math.max(1, -y))
        return nCard > 0
    end

    local descHeader = Section(L.DESCRIPTION)
    local desc = Text("QuestFont")
    desc.section = descHeader

    -- El juego parte el texto en lineas al pintar: justo despues de SetWidth,
    -- GetStringHeight puede dar aun una sola linea y el final no se alcanza con
    -- la rueda. Por eso se vuelve a medir en el siguiente frame, ya pintado.
    local Layout
    local function Relayout() Layout(true) end
    function Layout(again)
        local width = math.max(100, ns.Width(scroll, 110) - 10)
        content:SetWidth(width)
        rewards:SetWidth(width)
        if detail.questID and rewards:IsShown() then FillRewards(ns.Quests[detail.questID] or {}, detail.questID) end
        -- Los cuatro botones caben siempre en la pagina
        local bw = math.floor((width - GAP * (PER_ROW - 1)) / PER_ROW)
        for i, b in ipairs(row) do
            local col, line = (i - 1) % PER_ROW, math.floor((i - 1) / PER_ROW)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", col * (bw + GAP), -line * (BUTTON_H + GAP))
            b:SetWidth(bw)
        end
        buttons:SetHeight(math.ceil(#row / PER_ROW) * (BUTTON_H + GAP) - GAP)
        local previous, height = nil, 6
        for _, block in ipairs(blocks) do
            block:ClearAllPoints()
            if block:IsShown() then
                if block.SetWidth then block:SetWidth(width) end
                local gap = previous and block.gap or 0
                if previous then
                    block:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -gap)
                else
                    block:SetPoint("TOPLEFT", 4, -6)
                end
                height = height + gap + (block.GetStringHeight and block:GetStringHeight() or block:GetHeight())
                previous = block
            end
        end
        content:SetHeight(height + 24) -- aire al final: el borde de la pagina no tapa la ultima linea
        if again ~= true and C_Timer then C_Timer.After(0, Relayout) end
    end
    scroll:SetScript("OnSizeChanged", Layout)

    -- "Empieza: Rahauro (Cima del Trueno 70.4, 29.6)" / "... (dentro de Sima Ignea)"
    local function Describe(label, list)
        local parts = {}
        for _, p in ipairs(list) do
            local where = ""
            if p.itemID then
                where = " " .. Icon(ns.ItemInfo(p.itemID).icon)
            elseif p.mapID then
                where = " (" .. ns.ZoneName(p.mapID) .. " " .. ns.FormatCoords(p)
                    .. (p.under and (", " .. L.UNDERGROUND) or "") .. ")"
            elseif p.inside and detail.dungeon then
                where = " (" .. L.INSIDE:format(ns.DungeonName(detail.dungeon)) .. ")"
            end
            parts[#parts + 1] = LINK .. ns.PlaceName(p) .. "|r" .. where
        end
        return label .. " " .. (#parts > 0 and table.concat(parts, ", ") or L.UNKNOWN)
    end

    -- Muestra u oculta un bloque y, con el, su cabecera de seccion
    local function Set(block, text)
        if text ~= nil and block.SetText then block:SetText(text) end
        local shown = text ~= nil and text ~= ""
        block:SetShown(shown)
        if block.section then block.section:SetShown(shown) end
    end

    function detail:Show(id)
        local changed = id ~= self.questID
        self.questID = id
        scroll:SetShown(id ~= nil)
        if not id then return end
        local q = ns.Quests[id] or {}
        local text = ns.QuestText(id)
        local status, reason = ns.QuestStatus(id)

        title:SetText(ns.QuestTitle(id))
        local level = ns.QuestLevel(q, id)
        -- "Nivel: 15 · Requiere nivel 9 · (A) Alianza"
        local parts = { ("%s %s"):format(L.LEVEL, level or "?") }
        if q.minLevel then parts[#parts + 1] = L.REQUIRES_LEVEL:format(q.minLevel) end
        if q.faction then
            local mark = ns.FactionMarkup(q.faction)
            parts[#parts + 1] = (mark ~= "" and (mark .. " ") or "") .. L[FACTION_NAME[q.faction]]
        end
        if q.classes then parts[#parts + 1] = L.CLASS_ONLY:format(ns.ClassNames(q, true)) end
        meta:SetText(table.concat(parts, SEP))
        statusLine:SetText(ns.StatusMarkup(status, 18) .. " " .. StatusText(status, reason, "light"))
        statusBadge:SetWidth(statusLine:GetStringWidth() + 14)
        Set(unverified, not ns.IsVerified(id) and (Icon(UNVERIFIED, 12) .. " " .. L.UNVERIFIED) or nil)

        local startList, endList = ns.QuestPlaces(id, "starts"), ns.QuestPlaces(id, "ends")
        starts:SetText(Describe(L.STARTS, startList))
        ends:SetText(Describe(L.ENDS, endList))
        local d = Dungeon()
        local entrance = d and ns.Entrance(d)
        markStart:SetEnabled(#startList > 0 and (startList[1].mapID or entrance) and true or false)
        markEnd:SetEnabled(#endList > 0 and (endList[1].mapID or entrance) and true or false)
        share:SetEnabled(C_QuestLog.GetLogIndexForQuestID(id) ~= nil and C_QuestLog.IsPushableQuest
            and C_QuestLog.IsPushableQuest(id) and IsInGroup() and true or false)

        local steps = type(q.chain) == "table" and q.chain or {}
        local current = ChainStep(q, id) or 0
        chainHeader.text:SetText(#steps > 1 and L.CHAIN:format(math.max(current, 1), #steps) or L.CHAIN_PART)
        chainHeader:SetShown(#steps > 1 or q.chain == true)
        chain:SetHeight(20 * #steps)
        chain:SetShown(#steps > 1)
        for i, link in ipairs(links) do link:SetShown(i <= #steps) end
        for i, stepID in ipairs(steps) do
            local link = Link(i)
            link.questID = stepID
            local label = ns.QuestTitle(stepID)
            label = stepID == id and ("|cff000000" .. label .. "|r") or (LINK .. label .. "|r")
            link:SetText("|cff402608" .. i .. ".|r " .. ns.StatusMarkup((ns.QuestStatus(stepID))) .. " " .. label)
            link:Show()
        end
        Set(chainNote, q.chain == true and L.CHAIN_UNKNOWN or nil)
        -- El paso anterior sin hacer: lo primero que hay que saber
        local previous = current > 1 and steps[current - 1]
        Set(requires, previous and ns.QuestStatus(previous) ~= ns.STATUS_COMPLETED
            and ("|cff8c1a0d" .. L.CHAIN_REQUIRES:format(ns.QuestTitle(previous)) .. "|r") or nil)

        local objective = ns.QuestObjective(id)
        -- La llevas: el progreso de cada objetivo ("Cabeza de Arugal: 0/1"), del juego
        local progress = {}
        if C_QuestLog.GetLogIndexForQuestID(id) and C_QuestLog.GetQuestObjectives then
            for _, o in ipairs(C_QuestLog.GetQuestObjectives(id) or {}) do
                local line = ns.PlainText(o.text)
                if line and line ~= "" then
                    progress[#progress + 1] = (o.finished and "|cff1a6b1a" or LINK) .. "- " .. line .. "|r"
                end
            end
        end
        if #progress > 0 then
            objective = L.OBJ_PROGRESS .. "\n" .. table.concat(progress, "\n") .. (objective and ("\n\n" .. objective) or "")
        end
        if not objective and q.need then
            -- El juego aun no tiene la mision: lo que hay que conseguir, con sus nombres del juego
            local need = {}
            for _, n in ipairs(q.need) do
                need[#need + 1] = "- " .. (ns.ItemInfo(n[1]).name or ("#" .. n[1])) .. (n[2] > 1 and (" x" .. n[2]) or "")
            end
            objective = table.concat(need, "\n")
        end
        Set(obj, objective)

        local hasRewards = FillRewards(q, id)
        rewards:SetShown(hasRewards)
        rewardHeader:SetShown(hasRewards)

        Set(desc, text.desc or L.NO_TEXT)

        Layout()
        -- Se refresca con cada QUEST_LOG_UPDATE o dato de objeto que llega:
        -- volver arriba solo al cambiar de mision, no mientras la lees
        if changed then scroll:SetVerticalScroll(0) end
    end

    return detail
end

-- ------------------------------------------
-- Panel: left = pagina izquierda (bajo la cabecera), right = pagina derecha
-- ------------------------------------------

function ns.CreateQuestPanel(left, right)
    local panel = { dungeon = nil, questID = nil }

    local listArea = CreateFrame("Frame", nil, left)
    listArea:SetPoint("TOPLEFT")
    listArea:SetPoint("BOTTOMRIGHT", 0, LEGEND_H)

    -- Leyenda: que significa cada icono, siempre a la vista bajo la lista
    local line = left:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.3)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, LEGEND_H - 4)
    line:SetPoint("BOTTOMRIGHT", -18, LEGEND_H - 4)
    local legend = ns.PaperText(left, "GameFontBlackSmall")
    legend:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -3)
    legend:SetPoint("RIGHT", line, "RIGHT")
    legend:SetJustifyH("CENTER")
    legend:SetSpacing(1)
    local keys = {}
    for _, status in ipairs(ns.STATUS_ORDER) do
        keys[#keys + 1] = ns.StatusMarkup(status, 14) .. " " .. L["STATUS_" .. status]
    end
    keys[#keys + 1] = "|TInterface\\Buttons\\WHITE8X8:12:4:0:0:8:8:0:8:0:8:102:184:255|t " .. L.CHAIN_PART
    legend:SetText(table.concat(keys, "   "))

    local empty = ns.PaperText(left, "QuestFont")
    empty:SetPoint("TOP", 0, -30)
    empty:SetText(L.NO_QUESTS)

    local detail = CreateDetail(right)
    local list = CreateQuestList(listArea, function(id) panel:SelectQuest(id) end)

    function panel:SetShown(shown)
        left:SetShown(shown)
        right:SetShown(shown)
    end

    function panel:Refresh()
        local ids = {}
        if self.dungeon then
            ids = ns.DungeonQuests(self.dungeon, ns.FactionFilter(), ns.db.hideCompleted)
        end
        -- Sin mision elegida: la primera que te queda por hacer (o la primera).
        -- Una elegida que los filtros ocultan (un paso ya completado de su
        -- cadena) se sigue viendo.
        if not self.questID then
            for _, id in ipairs(ids) do
                if ns.QuestStatus(id) ~= ns.STATUS_COMPLETED then self.questID = id break end
            end
            self.questID = self.questID or ids[1]
        end
        empty:SetShown(#ids == 0)
        list:Refresh(ids, self.questID)
        detail.dungeon = self.dungeon
        detail:Show(self.questID)
    end

    function panel:SetDungeon(d)
        if d ~= self.dungeon then self.questID = nil end
        self.dungeon = d
        self:Refresh()
    end

    function panel:SelectQuest(id)
        self.questID = id
        self:Refresh()
    end

    return panel
end
