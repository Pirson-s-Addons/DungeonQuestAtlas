local _, ns = ...
local L = ns.L

-- ==========================================
-- MODO DE LA GUIA: ATLAS COMPLETO O MODO AVENTURA
-- ==========================================
-- Cada personaje lo elige en una ventana que sale una vez al entrar al juego
-- (y con /dqa mode; tambien en Opciones). ns.char.journalMode: "full" o "rpg".
--   - Atlas completo: todo abierto, como siempre.
--   - Modo aventura: cada mazmorra empieza bloqueada (tarjeta a oscuras con
--     candado, su pagina no se abre) hasta que este personaje mata a su jefe
--     final. Una barra en la portada mide el viaje: QUEST_POINTS por mision de
--     mazmorra hecha y PAGE_POINTS por pagina desbloqueada.
-- Los desbloqueos se apuntan siempre (ns.char.unlocked), tambien en el atlas
-- completo: pasar a aventura mas tarde no pierde lo ya hecho.

local QUEST_POINTS, PAGE_POINTS = 5, 10

-- Jefe final de cada mazmorra: el ultimo jefe de verdad de Data/Bosses.lua,
-- salvo donde la lista pone otro detras (nombre ingles)
local FINAL = {
    DM = "Edwin VanCleef",
    RFD = "Amnennar the Coldbringer",
    LORDAERON = "Rath'mael",
    STOCKS = "Bazil Thredd",
}

function ns.FinalBoss(d)
    local want, last = FINAL[d.key], nil
    for _, boss in ipairs(ns.Bosses[d.key] or {}) do
        if boss.kind == nil then
            if boss.name == want then return boss end
            last = boss
        end
    end
    return last
end

function ns.IsRPGMode()
    return ns.char ~= nil and ns.char.journalMode == "rpg"
end

-- Las que aun no tienen jefes (no abren en la beta) no se bloquean: no habria
-- con que abrirlas
function ns.IsDungeonLocked(d)
    return d ~= nil and ns.IsRPGMode() and not ns.IsUnlocked(d.key) and ns.FinalBoss(d) ~= nil
end

-- Desbloqueada por este personaje o, con "Desbloqueos de cuenta", por cualquiera
-- de la cuenta (ns.db.unlocked se apunta siempre)
function ns.IsUnlocked(key)
    return ns.char.unlocked[key] or (ns.db.rpgAccount and ns.db.unlocked[key]) or false
end

-- "Ver misiones de las bloqueadas": su pagina se abre, pero solo en Misiones
function ns.CanPeekQuests(d)
    return ns.db.rpgShowQuests and ns.IsDungeonLocked(d)
end

-- Bloqueada del todo: su pagina no se abre por ningun camino
function ns.IsPageClosed(d)
    return ns.IsDungeonLocked(d) and not ns.db.rpgShowQuests
end

function ns.SetJournalMode(mode)
    ns.char.journalMode = mode == "rpg" and "rpg" or "full"
    ns.RefreshUI()
end

-- Tooltip y chat de una tarjeta bloqueada
function ns.LockedHint(d)
    local boss = ns.FinalBoss(d)
    return L.RPG_LOCKED_TIP:format(boss and ns.BossName(boss, d) or "?")
end

-- ------------------------------------------
-- Barra del viaje (cabecera de la portada)
-- ------------------------------------------

function ns.JourneyProgress()
    local faction = UnitFactionGroup("player")
    local quests, questTotal, pages, pageTotal = 0, 0, 0, 0
    for _, d in ipairs(ns.Dungeons) do
        if ns.FinalBoss(d) then
            pageTotal = pageTotal + 1
            if ns.IsUnlocked(d.key) then pages = pages + 1 end
        end
        local done, total = ns.DungeonProgress(d, faction)
        quests, questTotal = quests + done, questTotal + total
    end
    return quests * QUEST_POINTS + pages * PAGE_POINTS, questTotal * QUEST_POINTS + pageTotal * PAGE_POINTS,
        quests, questTotal, pages, pageTotal
end

function ns.CreateJourneyBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetSize(300, 12)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.95, 0.72, 0.15)
    bar:SetMinMaxValues(0, 1)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    local edge = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    edge:SetPoint("TOPLEFT", -3, 3)
    edge:SetPoint("BOTTOMRIGHT", 3, -3)
    edge:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10 })
    edge:SetBackdropBorderColor(0.85, 0.68, 0.32)
    bar.text = edge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)

    function bar:Update()
        local points, max, quests, questTotal, pages, pageTotal = ns.JourneyProgress()
        self.info = { quests, questTotal, pages, pageTotal }
        self:SetValue(max > 0 and points / max or 0)
        self.text:SetText(L.RPG_JOURNEY:format(points, max, max > 0 and math.floor(points / max * 100) or 0))
    end
    bar:SetScript("OnEnter", function(self)
        local i = self.info or { 0, 0, 0, 0 }
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(L.RPG_JOURNEY_TITLE, 1, 0.82, 0)
        GameTooltip:AddLine(L.RPG_JOURNEY_QUESTS:format(i[1], i[2]), 1, 1, 1)
        GameTooltip:AddLine(L.RPG_JOURNEY_PAGES:format(i[3], i[4]), 1, 1, 1)
        GameTooltip:AddLine(L.RPG_JOURNEY_POINTS:format(QUEST_POINTS, PAGE_POINTS), 0.6, 0.85, 0.6, true)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", GameTooltip_Hide)
    return bar
end

-- ------------------------------------------
-- Aviso de pagina desbloqueada
-- ------------------------------------------
-- Como un logro: aparece arriba, suena la fanfarria, se queda mientras tengas
-- el raton encima y se va solo. Clic: la pagina de esa mazmorra.

local toast
local function CreateToast()
    local t = CreateFrame("Button", "DungeonQuestAtlasUnlockToast", UIParent, "BackdropTemplate")
    t:SetSize(330, 84)
    t:SetPoint("TOP", 0, -150)
    t:SetFrameStrata("FULLSCREEN_DIALOG")
    t:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    t:SetBackdropColor(0.05, 0.04, 0.03, 0.96)
    t:Hide()
    local icon = t:CreateTexture(nil, "ARTWORK")
    icon:SetSize(56, 56)
    icon:SetPoint("LEFT", 16, 0)
    icon:SetTexture(ns.LOGO)
    t.header = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -6)
    t.header:SetPoint("RIGHT", -16, 0)
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    t.name:SetPoint("TOPLEFT", t.header, "BOTTOMLEFT", 0, -6)
    t.name:SetPoint("RIGHT", -16, 0)
    t.name:SetJustifyH("LEFT")
    t.name:SetMaxLines(2)

    local fadeIn = t:CreateAnimationGroup()
    local a = fadeIn:CreateAnimation("Alpha")
    a:SetFromAlpha(0); a:SetToAlpha(1); a:SetDuration(0.3)
    t.fadeIn = fadeIn
    local fadeOut = t:CreateAnimationGroup()
    local b = fadeOut:CreateAnimation("Alpha")
    b:SetFromAlpha(1); b:SetToAlpha(0); b:SetDuration(1)
    fadeOut:SetScript("OnFinished", function() t:Hide() end)
    t.fadeOut = fadeOut

    t:SetScript("OnUpdate", function(self, elapsed)
        if self:IsMouseOver() then return end
        self.left = self.left - elapsed
        if self.left <= 0 and not self.fadeOut:IsPlaying() then self.fadeOut:Play() end
    end)
    t:SetScript("OnEnter", function(self)
        self.fadeOut:Stop()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L.RPG_TOAST_HINT, 1, 1, 1)
        GameTooltip:Show()
    end)
    t:SetScript("OnLeave", GameTooltip_Hide)
    t:SetScript("OnClick", function(self)
        GameTooltip:Hide()
        self:Hide()
        if self.dungeon then ns.OpenDungeon(self.dungeon) end
    end)
    return t
end

local function ShowToast(d)
    toast = toast or CreateToast()
    toast.dungeon = d
    toast.header:SetText(L.RPG_UNLOCKED)
    toast.name:SetText(ns.DungeonName(d))
    toast.left = 6
    toast.fadeOut:Stop()
    toast:Show()
    toast.fadeIn:Play()
    -- Fanfarria de logro (UI_Alert_AchievementGained); si el cliente no la tiene, la de mision
    if not (pcall(PlaySound, 12891, "Master")) and SOUNDKIT then pcall(PlaySound, SOUNDKIT.IG_QUEST_LIST_COMPLETE) end
end

-- Lo llama Core/BossKills.lua con cada jefe que muere
function ns.OnBossKilled(d, boss)
    if ns.char.unlocked[d.key] or boss ~= ns.FinalBoss(d) then return end
    local was = ns.IsUnlocked(d.key)
    ns.char.unlocked[d.key] = true
    ns.db.unlocked[d.key] = true
    if ns.IsRPGMode() and not was then
        ns.Print("|cff40ff40" .. L.RPG_UNLOCKED_MSG:format(ns.DungeonName(d)) .. "|r")
        ShowToast(d)
    end
end

-- ------------------------------------------
-- Ventana para elegir el modo
-- ------------------------------------------

local chooser
local function OptionCard(parent, titleKey, descKey, mode)
    local c = CreateFrame("Button", nil, parent, "BackdropTemplate")
    c:SetSize(260, 220)
    c:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    c:SetBackdropColor(0.09, 0.07, 0.05, 0.96)
    c:SetBackdropBorderColor(0.55, 0.43, 0.24)
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetSize(56, 56)
    c.icon:SetPoint("TOP", 0, -16)
    c.icon:SetTexture(ns.LOGO)
    c.title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    c.title:SetPoint("TOP", c.icon, "BOTTOM", 0, -8)
    c.desc = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    c.desc:SetPoint("TOP", c.title, "BOTTOM", 0, -8)
    c.desc:SetWidth(230)
    c.desc:SetJustifyH("CENTER")
    c.titleKey, c.descKey = titleKey, descKey
    c.pick = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
    c.pick:SetSize(150, 24)
    c.pick:SetPoint("BOTTOM", 0, 14)
    local function Choose()
        ns.SetJournalMode(mode)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
        parent:Hide()
    end
    c.pick:SetScript("OnClick", Choose)
    c:SetScript("OnClick", Choose)
    c:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 0.82, 0.3) end)
    c:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.55, 0.43, 0.24) end)
    return c
end

local function CreateChooser()
    local f = CreateFrame("Frame", "DungeonQuestAtlasModeChooser", UIParent, "BackdropTemplate")
    f:SetSize(600, 330)
    f:SetPoint("CENTER", 0, 60)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    })
    f:SetBackdropColor(0.04, 0.035, 0.03, 0.97)
    tinsert(UISpecialFrames, "DungeonQuestAtlasModeChooser")
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", 20, -18)
    icon:SetTexture(ns.LOGO)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.sub:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -8)
    f.sub:SetTextColor(0.75, 0.72, 0.66)
    f.full = OptionCard(f, "MODE_FULL", "MODE_FULL_DESC", "full")
    f.full:SetPoint("BOTTOMLEFT", 30, 24)
    f.rpg = OptionCard(f, "MODE_RPG", "MODE_RPG_DESC", "rpg")
    f.rpg:SetPoint("BOTTOMRIGHT", -30, 24)
    -- Aventura: el logo apagado con un candado
    f.rpg.icon:SetDesaturated(true)
    local lock = f.rpg:CreateTexture(nil, "OVERLAY")
    lock:SetSize(26, 26)
    lock:SetPoint("BOTTOMRIGHT", f.rpg.icon, "BOTTOMRIGHT", 6, -4)
    lock:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    -- Cerrar (X o Esc) sin elegir: el atlas completo, y no vuelve a salir
    f:SetScript("OnHide", function()
        if ns.char.journalMode == nil then ns.SetJournalMode("full") end
    end)
    return f
end

function ns.ShowModeChooser()
    chooser = chooser or CreateChooser()
    chooser.title:SetText(L.MODE_TITLE)
    chooser.sub:SetText(L.MODE_SUB)
    for _, c in ipairs({ chooser.full, chooser.rpg }) do
        c.title:SetText(L[c.titleKey])
        c.desc:SetText(L[c.descKey])
        c.pick:SetText(L.MODE_CHOOSE)
    end
    chooser:Show()
end

-- ------------------------------------------
-- Exportar / importar el progreso
-- ------------------------------------------
-- Un codigo de texto con las mazmorras desbloqueadas ("DQA1:DM,RFD,..."): se
-- copia en un ordenador y se pega en otro. Importar suma, no quita nada.

local CODE_PREFIX = "DQA1:"

function ns.ExportProgress()
    local keys = {}
    for _, d in ipairs(ns.Dungeons) do
        if ns.IsUnlocked(d.key) then keys[#keys + 1] = d.key end
    end
    return CODE_PREFIX .. table.concat(keys, ",")
end

-- Devuelve cuantas son nuevas, o nil si el codigo no vale
function ns.ImportProgress(code)
    code = (code or ""):gsub("%s", "")
    if code:sub(1, #CODE_PREFIX) ~= CODE_PREFIX then return nil end
    local known = {}
    for _, d in ipairs(ns.Dungeons) do known[d.key] = true end
    local added = 0
    for key in code:sub(#CODE_PREFIX + 1):gmatch("[^,]+") do
        if not known[key] then return nil end
        if not ns.char.unlocked[key] then added = added + 1 end
        ns.char.unlocked[key] = true
        ns.db.unlocked[key] = true
    end
    if ns.RefreshUI then ns.RefreshUI() end
    return added
end

local function EditBoxOf(dialog)
    return dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
end

StaticPopupDialogs["DQA_EXPORT_PROGRESS"] = {
    text = "%s", button1 = OKAY, hasEditBox = true, editBoxWidth = 320,
    OnShow = function(self, data)
        local box = EditBoxOf(self)
        box:SetText(data or "")
        box:HighlightText()
        box:SetFocus()
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["DQA_IMPORT_PROGRESS"] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL, hasEditBox = true, editBoxWidth = 320,
    OnAccept = function(self)
        local box = EditBoxOf(self)
        local added = ns.ImportProgress(box:GetText())
        ns.Print(added and L.RPG_IMPORT_DONE:format(added) or ("|cffff6060" .. L.RPG_IMPORT_BAD .. "|r"))
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

function ns.ShowExportProgress()
    StaticPopup_Show("DQA_EXPORT_PROGRESS", L.RPG_EXPORT_TEXT, nil, ns.ExportProgress())
end

function ns.ShowImportProgress()
    StaticPopup_Show("DQA_IMPORT_PROGRESS", L.RPG_IMPORT_TEXT)
end

-- Primera vez de cada personaje: la ventana, unos segundos despues de entrar.
-- Y lo desbloqueado por este personaje pasa a la cuenta (desbloqueos de cuenta)
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    if ns.char and ns.db then
        for key in pairs(ns.char.unlocked) do ns.db.unlocked[key] = true end
    end
    C_Timer.After(3, function()
        if ns.char and ns.char.journalMode == nil then ns.ShowModeChooser() end
    end)
end)
