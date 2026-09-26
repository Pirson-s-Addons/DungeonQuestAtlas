local _, ns = ...
local L = ns.L

-- ==========================================
-- MISIONES (en el libro)
-- ==========================================
-- Pagina izquierda: las misiones de la mazmorra como botones del Diario.
-- Pagina derecha: el detalle en pergamino, con la fuente de las misiones del
-- juego: donde empieza y termina, cadena, objetivos, recompensas, descripcion.

local ICON = {
    COMPLETED = "Interface\\RaidFrame\\ReadyCheck-Ready",
    IN_LOG = "Interface\\GossipFrame\\ActiveQuestIcon",
    AVAILABLE = "Interface\\GossipFrame\\AvailableQuestIcon",
    BLOCKED = "Interface\\RaidFrame\\ReadyCheck-NotReady",
    UNVERIFIED = "Interface\\RaidFrame\\ReadyCheck-Waiting",
}
-- Colores del estado, legibles sobre papel
local STATUS = {
    COMPLETED = { "STATUS_COMPLETED", "|cff1a6b12" },
    IN_LOG = { "STATUS_IN_LOG", "|cff7a4d00" },
    AVAILABLE = { "STATUS_AVAILABLE", "|cff402608" },
    BLOCKED = { "STATUS_BLOCKED", "|cff8c1a0d" },
}
local FACTION_TEXTURE = {
    Alliance = "Interface\\FriendsFrame\\PlusManz-Alliance",
    Horde = "Interface\\FriendsFrame\\PlusManz-Horde",
}
local FACTION_ICON = {
    Alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|t",
    Horde = "|TInterface\\FriendsFrame\\PlusManz-Horde:16:16|t",
}
local FACTION_NAME = { Alliance = "FACTION_ALLIANCE", Horde = "FACTION_HORDE", Both = "FACTION_ALL" }
local SEP = "  ·  "
local LINK = "|cff5c1d00" -- enlaces sobre papel
local QUEST_ICON = "Interface\\Icons\\INV_Misc_Note_01" -- el pergamino de mision
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local function Icon(path, size)
    return ("|T%s:%d|t"):format(path, size or 14)
end

-- ------------------------------------------
-- Lista (pagina izquierda)
-- ------------------------------------------

local function CreateQuestList(parent, onSelect)
    local selected

    -- Como los botones de jefe: en el hueco redondo, el pergamino de mision;
    -- el estado, en una insignia en su esquina; la faccion, junto al nivel
    local function Setup(row)
        ns.SetupJournalButton(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(44, 44)
        row.icon:SetPoint("LEFT", 5, 0)
        row.icon:SetMask(MASK)
        row.icon:SetTexture(QUEST_ICON)
        row.status = row:CreateTexture(nil, "OVERLAY")
        row.status:SetSize(20, 20)
        row.status:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 5, -3)
        row.level = row:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
        row.level:SetPoint("RIGHT", -16, 0)
        row.faction = row:CreateTexture(nil, "ARTWORK")
        row.faction:SetSize(18, 18)
        row.faction:SetPoint("RIGHT", row.level, "LEFT", -4, 0)
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
        row.label:SetPoint("LEFT", 72, 0) -- fuera del borde curvo del hueco
        row.label:SetPoint("RIGHT", row.faction, "LEFT", -6, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row:SetScript("OnClick", function(self) onSelect(self.questID) end)
    end

    local function Update(row, item)
        local id = item.id
        local q = ns.Quests[id] or {}
        local status = ns.QuestStatus(id)
        row.questID = id
        row.status:SetTexture(ICON[status])
        local done = status == ns.STATUS_COMPLETED
        row.icon:SetDesaturated(done)
        row.faction:SetTexture(q.faction and FACTION_TEXTURE[q.faction])
        row.faction:SetShown(FACTION_TEXTURE[q.faction or ""] ~= nil)
        row.label:SetText(ns.QuestTitle(id) .. (ns.IsVerified(id) and "" or (" " .. Icon(ICON.UNVERIFIED, 12))))
        row.label:SetTextColor(ns.PARCHMENT_GOLD[1], ns.PARCHMENT_GOLD[2], ns.PARCHMENT_GOLD[3], done and 0.55 or 1)
        local level = ns.QuestLevel(q, id)
        row.level:SetText(level and ("|c%s%d|r"):format(ns.LevelColor(level, level, UnitLevel("player")), level) or "?")
        ns.SetJournalButtonSelected(row, id == selected)
    end

    local list = ns.CreateScrollList(parent, 54, Setup, Update)
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
    local title = Text("QuestTitleFont", 0)
    local meta = Text("GameFontBlack", 6)
    local unverified = Text("GameFontBlack", 4, ns.INK_LIGHT)

    -- Donde ---------------------------------------------------------------
    Section(L.WHERE)
    local starts = Text("QuestFont")
    local ends = Text("QuestFont", 4)
    local buttons = Add(CreateFrame("Frame", nil, content), 10)
    buttons:SetHeight(24)
    local function Button(text, anchor, tooltip, onClick)
        local b = CreateFrame("Button", nil, buttons, "UIPanelButtonTemplate")
        b:SetSize(108, 24)
        if anchor then b:SetPoint("LEFT", anchor, "RIGHT", 4, 0) else b:SetPoint("LEFT") end
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        ns.AddTooltip(b, tooltip)
        return b
    end
    -- El primero con coordenadas; sin ninguno, MarkPlace marca la entrada
    local function Mark(which)
        local list = ns.QuestPlaces(detail.questID, which)
        local place = list[1]
        for _, p in ipairs(list) do
            if p.mapID then place = p break end
        end
        ns.MarkPlace(place, place and ns.PlaceName(place) or ns.QuestTitle(detail.questID), detail.dungeon,
            which == "starts" and "start" or "end")
    end
    local markStart = Button(L.MARK_START, nil, L.MARK_START_TOOLTIP, function() Mark("starts") end)
    local markEnd = Button(L.MARK_END, markStart, L.MARK_END_TOOLTIP, function() Mark("ends") end)
    Button(L.WOWHEAD, markEnd, L.WOWHEAD_TOOLTIP, function()
        ns.ShowCopyDialog(ns.QuestTitle(detail.questID), ns.WowheadURL(detail.questID))
    end)

    -- Cadena: un boton por paso, reutilizados. Los pasos de mazmorra saltan a
    -- su mision; los demas dan su enlace de Wowhead.
    local chainHeader = Section(L.CHAIN)
    local chain = Add(CreateFrame("Frame", nil, content))
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
            b:SetScript("OnClick", function(self)
                if ns.Quests[self.questID] then
                    ns.ShowQuest(self.questID)
                else
                    ns.ShowCopyDialog(ns.QuestTitle(self.questID), ns.WowheadURL(self.questID))
                end
            end)
            links[i] = b
        end
        return links[i]
    end
    local chainNote = Text("GameFontBlack", 4, ns.INK_LIGHT)

    local objHeader = Section(L.OBJECTIVES)
    local obj = Text("QuestFont")
    obj.section = objHeader

    -- Recompensas: filas de botin del Diario, una columna; debajo XP y dinero
    local rewardHeader = Section(L.REWARDS)
    local rewards = Add(CreateFrame("Frame", nil, content))
    local labels, cards = {}, {}
    local function Label(i)
        labels[i] = labels[i] or ns.PaperText(rewards, "GameFontBlack")
        return labels[i]
    end
    local function Card(i)
        cards[i] = cards[i] or ns.CreateItemButton(rewards)
        return cards[i]
    end
    local function FillRewards(q, id)
        local y, nLabel, nCard = 0, 0, 0
        local function Line(text)
            nLabel = nLabel + 1
            local fs = Label(nLabel)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", 0, y - 2)
            fs:SetText(text)
            fs:Show()
            y = y - 20
        end
        local function Items(list)
            for _, itemID in ipairs(list) do
                nCard = nCard + 1
                local card = Card(nCard)
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", 0, y)
                card:SetPoint("RIGHT")
                ns.SetItemButton(card, itemID, q.counts and q.counts[itemID])
                card:Show()
                y = y - ns.ITEM_ROW_HEIGHT - 2
            end
        end
        local mine = DungeonQuestAtlasCollectorDB.quests[id]
        local choice = q.choice or (mine and mine.rewards) or {}
        if #choice > 1 then Line(L.CHOOSE_ONE) end
        Items(choice)
        if q.rewards and #q.rewards > 0 then
            if #choice > 0 then Line(L.ALSO_RECEIVE) end
            Items(q.rewards)
        end
        local xp, money = ns.QuestXP(q, id), ns.QuestMoney(q, id)
        local extra = {}
        if xp and xp > 0 then
            extra[#extra + 1] = L.XP:format(BreakUpLargeNumbers and BreakUpLargeNumbers(xp) or xp)
        end
        if money and money > 0 and GetCoinTextureString then extra[#extra + 1] = GetCoinTextureString(money) end
        if #extra > 0 then Line(table.concat(extra, SEP)) end
        for i = nLabel + 1, #labels do labels[i]:Hide() end
        for i = nCard + 1, #cards do cards[i]:Hide() end
        rewards:SetHeight(math.max(1, -y))
        return nLabel + nCard > 0
    end

    local descHeader = Section(L.DESCRIPTION)
    local desc = Text("QuestFont")
    desc.section = descHeader

    local function Layout()
        local width = math.max(100, scroll:GetWidth() - 10)
        content:SetWidth(width)
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
        content:SetHeight(height + 8)
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
                where = " (" .. ns.ZoneName(p.mapID) .. " " .. ns.FormatCoords(p) .. ")"
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
        self.questID = id
        scroll:SetShown(id ~= nil)
        if not id then return end
        local q = ns.Quests[id] or {}
        local text = ns.QuestText(id)
        local status, reason = ns.QuestStatus(id)

        title:SetText(ns.QuestTitle(id))
        local level = ns.QuestLevel(q, id)
        local parts = { ("%s %s"):format(L.LEVEL, level or "?") .. (q.minLevel and (" (" .. q.minLevel .. ")") or "") }
        if q.faction then
            parts[#parts + 1] = (FACTION_ICON[q.faction] and (FACTION_ICON[q.faction] .. " ") or "") .. L[FACTION_NAME[q.faction]]
        end
        parts[#parts + 1] = Icon(ICON[status]) .. " " .. STATUS[status][2] .. L[STATUS[status][1]]
            .. (reason and (": " .. reason) or "") .. "|r"
        meta:SetText(table.concat(parts, SEP))
        Set(unverified, not ns.IsVerified(id) and (Icon(ICON.UNVERIFIED, 12) .. " " .. L.UNVERIFIED) or nil)

        local startList, endList = ns.QuestPlaces(id, "starts"), ns.QuestPlaces(id, "ends")
        starts:SetText(Describe(L.STARTS, startList))
        ends:SetText(Describe(L.ENDS, endList))
        local entrance = self.dungeon and ns.Entrance(self.dungeon)
        markStart:SetEnabled(#startList > 0 and (startList[1].mapID or entrance) and true or false)
        markEnd:SetEnabled(#endList > 0 and (endList[1].mapID or entrance) and true or false)

        local steps = type(q.chain) == "table" and q.chain or {}
        local current = 0
        for i, stepID in ipairs(steps) do if stepID == id then current = i end end
        chainHeader.text:SetText(L.CHAIN:format(math.max(current, 1), math.max(#steps, 1)))
        chainHeader:SetShown(#steps > 1 or q.chain == true)
        chain:SetHeight(20 * #steps)
        chain:SetShown(#steps > 1)
        for i, link in ipairs(links) do link:SetShown(i <= #steps) end
        for i, stepID in ipairs(steps) do
            local link = Link(i)
            link.questID = stepID
            local label = ns.QuestTitle(stepID)
            label = stepID == id and ("|cff000000" .. label .. "|r") or (LINK .. label .. "|r")
            link:SetText("|cff402608" .. i .. ".|r " .. Icon(ICON[ns.QuestStatus(stepID)]) .. " " .. label)
            link:Show()
        end
        Set(chainNote, q.chain == true and L.CHAIN_UNKNOWN or nil)

        local objective = ns.QuestObjective(id)
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
        scroll:SetVerticalScroll(0)
    end

    return detail
end

-- ------------------------------------------
-- Panel: left = pagina izquierda (bajo la cabecera), right = pagina derecha
-- ------------------------------------------

function ns.CreateQuestPanel(left, right)
    local panel = { dungeon = nil, questID = nil }

    local listArea = CreateFrame("Frame", nil, left)
    listArea:SetAllPoints()
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
        -- Sin mision elegida: la primera. Una elegida que los filtros ocultan
        -- (un paso ya completado de su cadena) se sigue viendo.
        self.questID = self.questID or ids[1]
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
