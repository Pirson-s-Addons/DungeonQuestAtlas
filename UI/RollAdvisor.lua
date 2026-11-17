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

local PANEL_WIDTH = 210
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

-- Lineas del consejo para un objeto (las usan la placa y el tooltip)
function ns.RollAdviceLines(link)
    if not (ns.db and ns.db.rollAdvisor and link and ns.UpgradeAdvice) then return {} end
    local ok, advice = pcall(ns.UpgradeAdvice, link)
    if not ok then return {} end
    local lines = {}
    local me = advice.me
    if me and me.blocked then
        lines[#lines + 1] = Colored(type(me.blocked) == "number" and L.UP_LEVEL:format(me.blocked) or L.UP_CANT_USE, "ffff4040")
    elseif ns.IsUpgrade(me) then
        lines[#lines + 1] = Arrow() .. " " .. Colored(L.UP_YOU, "ffffd100") .. "  "
            .. Colored(me.empty and L.UP_EMPTY or ("+" .. Pct(me) .. "%"), "ff20ff20")
        local stats = StatsText(me.stats)
        if stats ~= "" then lines[#lines + 1] = "   " .. stats end
    elseif me then
        lines[#lines + 1] = Colored(L.UP_NOT_FOR_YOU .. (me.pct < 0 and (" (" .. Pct(me) .. "%)") or ""), "ff999999")
    end

    local helped = 0
    for _, m in ipairs(advice.members) do
        if ns.IsUpgrade(m.result) then
            helped = helped + 1
            lines[#lines + 1] = Arrow() .. " " .. Colored(m.name, ClassHex(m.class)) .. "  "
                .. Colored(m.result.empty and L.UP_EMPTY or ("+" .. Pct(m.result) .. "%"), "ff20ff20")
        end
    end
    if helped == 0 and #advice.members > 0 then lines[#lines + 1] = Colored(L.UP_NOBODY, "ff999999") end
    if #advice.unknown > 0 then
        local names = {}
        for i, u in ipairs(advice.unknown) do names[i] = Colored(u.name, ClassHex(u.class)) end
        lines[#lines + 1] = Colored(L.UP_NO_DATA:format(table.concat(names, ", ")), "ff999999")
    end

    local questID, reward = QuestBetter(link, me)
    if questID then
        lines[#lines + 1] = Colored(L.UP_QUEST:format(ns.QuestTitle(questID), Pct(reward)), "ffffd100")
    end
    local also = AlsoDrops(ItemIDOf(link))
    if also then lines[#lines + 1] = Colored(L.UP_ALSO:format(also), "ffb0a090") end
    return lines
end

-- ------------------------------------------
-- Tooltip
-- ------------------------------------------

local function AddToTooltip(tooltip, link)
    local lines = ns.RollAdviceLines(link)
    if #lines == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("|T" .. ns.LOGO .. ":14:14|t " .. L.UP_HEADER, 0.84, 0.59, 1)
    for _, line in ipairs(lines) do tooltip:AddLine(line, 1, 1, 1, true) end
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

local function CreatePanel(rollFrame)
    local panel = ns.CreateDarkBox(rollFrame, 10)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint("TOPLEFT", rollFrame, "TOPRIGHT", 4, 0)
    panel:SetFrameStrata(rollFrame:GetFrameStrata())
    panel.text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.text:SetPoint("TOPLEFT", 8, -7)
    panel.text:SetWidth(PANEL_WIDTH - 16)
    panel.text:SetJustifyH("LEFT")
    panel.text:SetSpacing(2)
    local history = CreateFrame("Button", nil, panel)
    history:SetSize(16, 16)
    history:SetPoint("TOPRIGHT", -5, -5)
    history:SetNormalTexture(ns.LOGO)
    history:SetHighlightTexture(ns.LOGO, "ADD")
    history:SetScript("OnClick", function() ns.ToggleRollHistory() end)
    ns.AddTooltip(history, L.ROLLS_TOOLTIP)
    rollFrame.dqaPanel = panel
    return panel
end

local function UpdatePanel(rollFrame)
    local rollID = rollFrame.rollID
    local shown = ns.db and ns.db.rollAdvisor and rollID and rollFrame:IsShown()
    local panel = rollFrame.dqaPanel
    if not shown then
        if panel then panel:Hide() end
        return
    end
    local ok, link = pcall(GetLootRollItemLink, rollID)
    link = ok and ns.PlainText(link)
    local lines = link and ns.RollAdviceLines(link) or {}
    if #lines == 0 then
        if panel then panel:Hide() end
        return
    end
    panel = panel or CreatePanel(rollFrame)
    panel.text:SetText(table.concat(lines, "\n"))
    panel:SetHeight(panel.text:GetStringHeight() + 14)
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
