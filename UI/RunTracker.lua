local _, ns = ...
local L = ns.L

-- ==========================================
-- VENTANA DE LA PARTIDA EN PANTALLA
-- ==========================================
-- Tiempo, XP, dinero y las caras de los jefes y raros de la mazmorra (Core/RunLog.lua).
-- Sale sola al entrar en grupo (o tambien en solitario, segun las opciones). Se
-- arrastra por cualquier sitio menos las caras; clic derecho, sus opciones.
-- Clic en una cara: la selecciona (a un raro, ademas, le pone la calavera). Va con
-- SecureActionButtonTemplate para que funcione en combate, que es cuando hace falta (la
-- plantilla insegura no hace nada en combate). A cambio la ventana queda protegida: en
-- combate no se mueve, no se abre ni se cierra ni cambia de alto; se aplica al acabar.

local WIDTH, FACE, GAP, PER_ROW = 240, 32, 5, 6
local SKULL = 8

local frame
local faces = {}
local builtFor        -- mazmorra con las caras puestas
local dismissed, forced = false, false

local function BossTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.BossName(self.boss, self.dungeon), 1, 0.82, 0)
    local run = ns.RunActive()
    if run then
        local list = ns.RunLootOf(run, self.boss.name)
        for _, loot in ipairs(list) do GameTooltip:AddDoubleLine(loot.link, loot.who or "", 1, 1, 1, 0.8, 0.8, 0.8) end
    end
    GameTooltip:AddLine(self.boss.kind == "rare" and L.RUN_RARE_HINT or L.RUN_BOSS_HINT, 0.25, 1, 0.25, true)
    GameTooltip:Show()
end

local function CreateFace(index)
    local face = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
    face:SetSize(FACE, FACE)
    face:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    face:SetAttribute("useOnKeyDown", false)
    face.glow = face:CreateTexture(nil, "BACKGROUND")
    face.glow:SetPoint("CENTER")
    face.glow:SetSize(FACE * 2, FACE * 2)
    face.glow:SetTexture("Interface\\Cooldown\\star4")
    face.glow:SetBlendMode("ADD")
    face.glow:SetVertexColor(1, 0.8, 0.2)
    local pulse = face:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local alpha = pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.35)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.5)
    face.pulse = pulse
    face.portrait = face:CreateTexture(nil, "ARTWORK")
    face.portrait:SetAllPoints()
    face.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    face.cross = face:CreateTexture(nil, "OVERLAY")
    face.cross:SetAllPoints()
    face.cross:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    face.rare = face:CreateTexture(nil, "OVERLAY")
    face.rare:SetSize(14, 14)
    face.rare:SetPoint("BOTTOMRIGHT", 2, -2)
    face.rare:SetAtlas("nameplates-icon-elite-silver")
    face:SetScript("OnEnter", BossTooltip)
    face:SetScript("OnLeave", GameTooltip_Hide)
    -- PostClick: el OnClick es el de la plantilla, que lanza el macro
    face:SetScript("PostClick", function(self, button)
        if button == "RightButton" then return ns.OpenTrackerOptions() end
        if self.boss and self.boss.kind == "rare" then ns.RunAckRare(self.boss.name) end
    end)
    faces[index] = face
    return face
end

-- El macro de una cara con el nombre del jefe en el idioma del cliente. El juego lo da
-- cuando tiene al PNJ en cache (ns.BossName lo pide); hasta entonces sale el ingles de
-- los datos y /targetexact no lo encuentra. Se repasa cada segundo fuera de combate.
local function SetMacro(face)
    local boss = face.boss
    -- el nombre visto en la unidad (UnitName) es el del cliente seguro; si no, el que da el juego
    local name = (boss.npcID and ns.RunSeenName and ns.RunSeenName(boss.npcID)) or ns.BossName(boss, face.dungeon)
    if face.macroName == name then return end
    face.macroName = name
    local macro = face.boss.kind == "rare" and ("/targetexact %s\n/tm !%d"):format(name, SKULL) or ("/targetexact %s"):format(name)
    face:SetAttribute("type1", "macro")
    face:SetAttribute("macrotext1", macro)
end

local function UpdateMacros()
    if InCombatLockdown() then return end
    for _, face in ipairs(faces) do
        if face.boss then SetMacro(face) end
    end
end

-- Cambiar los atributos de una accion no se puede en combate: se espera a que acabe
local function BuildFaces(d)
    if builtFor == d or InCombatLockdown() then return end
    builtFor = d
    local bosses = ns.RunBosses(d)
    for i, boss in ipairs(bosses) do
        local face = faces[i] or CreateFace(i)
        face.boss, face.dungeon = boss, d
        ns.SetBossPortrait(face.portrait, boss)
        face.rare:SetShown(boss.kind == "rare")
        face:ClearAllPoints()
        face:SetPoint("TOPLEFT", 10 + ((i - 1) % PER_ROW) * (FACE + GAP), -62 - math.floor((i - 1) / PER_ROW) * (FACE + GAP))
        face.macroName = nil
        SetMacro(face)
        face:Show()
    end
    for i = #bosses + 1, #faces do
        faces[i].boss = nil
        faces[i]:Hide()
    end
    frame.rows = math.ceil(#bosses / PER_ROW)
end

local function Stat(parent, x)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", x, -26)
    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -1)
    return { label = label, value = value }
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    local pos = ns.db.trackerPos
    pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
end

local function CreateTracker()
    local f = CreateFrame("Frame", "DungeonQuestAtlasRunTracker", UIParent, "BackdropTemplate")
    frame = f
    f:SetSize(WIDTH, 100)
    local pos = ns.db.trackerPos
    f:SetPoint(pos.point or "RIGHT", UIParent, pos.relPoint or "RIGHT", pos.x or -60, pos.y or 120)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() if not InCombatLockdown() then f:StartMoving() end end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SavePosition()
    end)
    f:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then ns.OpenTrackerOptions() end
    end)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.05, 0.04, 0.03, 0.88)
    f:SetBackdropBorderColor(0.55, 0.43, 0.24)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 10, -8)
    f.title:SetPoint("RIGHT", -24, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetScript("OnClick", function()
        dismissed, forced = true, false
        if not InCombatLockdown() then f:Hide() end -- en combate, al acabar (PLAYER_REGEN_ENABLED)
    end)
    f.time = Stat(f, 10)
    f.xp = Stat(f, 86)
    f.gold = Stat(f, 162)
    ns.AddTooltip(f, L.RUN_TRACKER_HINT)
    local elapsed = 0
    f:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 1 then return end
        elapsed = 0
        UpdateMacros()
        local run = ns.RunActive()
        f.time.value:SetText(ns.FormatRunTime(run and ns.RunDuration(run) or 0))
    end)
    f:Hide()
end

local function ShouldShow()
    local inside = ns.RunInside()
    if not inside then
        dismissed, forced = false, false
        return false
    end
    if not ns.CurrentDungeon() or dismissed then return false end
    if forced then return true end
    return not ns.db.trackerNever and ((IsInGroup and IsInGroup()) or ns.db.trackerSolo) and true or false
end

local function ShowStat(stat, shown, label, value)
    stat.label:SetShown(shown)
    stat.value:SetShown(shown)
    stat.label:SetText(label)
    stat.value:SetText(value)
end

function ns.RefreshRunTracker()
    if not ns.db then return end
    local combat = InCombatLockdown()
    if not ShouldShow() then
        if frame and not combat then frame:Hide() end
        return
    end
    if not frame then CreateTracker() end
    if combat and not frame:IsShown() then return end -- se abre al acabar el combate
    local run = ns.RunActive()
    local d = run and ns.DungeonByKey[run.key] or ns.CurrentDungeon()
    BuildFaces(d)
    frame.title:SetText(ns.DungeonName(d))
    ShowStat(frame.time, not ns.db.trackerHideTime, L.RUN_TIME, ns.FormatRunTime(run and ns.RunDuration(run) or 0))
    ShowStat(frame.xp, not ns.db.trackerHideXP and not ns.RunIsMaxLevel(), L.RUN_XP, tostring(run and run.xp or 0))
    ShowStat(frame.gold, not ns.db.trackerHideGold, L.RUN_GOLD, ns.FormatRunMoney(run and run.money or 0))
    local showBosses = not ns.db.trackerHideBosses
    for _, face in ipairs(faces) do
        local boss = face.boss
        if boss and not InCombatLockdown() then face:SetShown(showBosses) end
        if boss then
            local killed = ns.IsBossKilled(face.dungeon, boss) or (run ~= nil and run.bosses[boss.name] ~= nil)
            local alive = boss.kind == "rare" and not killed and ns.RunRareAlive(boss.name)
            face.portrait:SetDesaturated(killed)
            face.cross:SetShown(killed)
            face:SetAlpha((boss.kind == "rare" and not killed and not ns.RunRareFound(boss.name)) and 0.4 or 1)
            alive = alive and ns.db.rareGlow
            face.glow:SetShown(alive and true or false)
            if alive and not face.pulse:IsPlaying() then face.pulse:Play()
            elseif not alive and face.pulse:IsPlaying() then face.pulse:Stop() end
        end
    end
    if combat then return end
    local rows = showBosses and (frame.rows or 0) or 0
    frame:SetHeight(rows > 0 and 62 + rows * (FACE + GAP) + 4 or 62)
    frame:Show()
end

-- Opciones y "En pantalla" del historial
function ns.ShowRunTracker()
    dismissed, forced = false, true
    ns.RefreshRunTracker()
end

-- Las caras que no se pudieron poner en combate
local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function() ns.RefreshRunTracker() end)
