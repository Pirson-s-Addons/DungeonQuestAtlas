local _, ns = ...
local L = ns.L

-- ==========================================
-- AVISO GRANDE AL ENCONTRAR UN RARO
-- ==========================================
-- Idea de los avisos de RareScanner (sin su codigo: All Rights Reserved): al ver vivo un raro
-- de la mazmorra (Core/RunLog.lua, RareFound) sale arriba en el centro una tira pequena con su
-- cara, el dragon plateado, "Raro encontrado" y su nombre; suena el aviso de banda del juego y
-- su icono parpadea si estas en otra ventana. (Mas grande, con nivel, mazmorra y el texto de
-- banda en el centro, ocupaba demasiado.) Opcion rareToast (Opciones > Seguimiento). La tarjeta no es un marco protegido (se
-- tiene que poder ensenar en combate): clic, deja de avisar; seleccionarlo es con su cara en la
-- ventana de la partida.

local SHOW_TIME = 12 -- segundos en pantalla si no se pulsa
local DRAGON = "ui-hud-unitframe-target-portraiton-boss-rare-silver"

local toast
local shownCount = 0 -- cuantas veces ha salido: el temporizador de una vez anterior no la quita

local function CreateToast()
    local f = CreateFrame("Button", "DungeonQuestAtlasRareAlert", UIParent, "BackdropTemplate")
    f:SetSize(230, 40) -- compacta: cara, "Raro encontrado" y el nombre
    f:SetPoint("TOP", UIParent, "TOP", 0, -130)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.94)
    f:SetBackdropBorderColor(0.78, 0.8, 0.86) -- plateado, como el dragon de los raros
    -- Brillo que late detras de la tarjeta
    local glow = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    glow:SetPoint("TOPLEFT", -3, 3)
    glow:SetPoint("BOTTOMRIGHT", 3, -3)
    glow:SetColorTexture(0.75, 0.85, 1, 0.5) -- halo plateado que asoma por el borde
    f.glow = glow
    -- Cara del raro con el dragon plateado alrededor
    f.portrait = f:CreateTexture(nil, "ARTWORK")
    f.portrait:SetSize(28, 28)
    f.portrait:SetPoint("LEFT", 8, 0)
    local mask = f:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(f.portrait)
    f.portrait:AddMaskTexture(mask)
    f.dragon = f:CreateTexture(nil, "OVERLAY")
    f.dragon:SetSize(42, 42)
    f.dragon:SetPoint("CENTER", f.portrait, "CENTER", 5, 2)
    if not pcall(f.dragon.SetAtlas, f.dragon, DRAGON) then f.dragon:Hide() end
    f.dragon:SetTexCoord(1, 0, 0, 1) -- la cabeza a la izquierda, como en la lista de jefes
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", f.portrait, "TOPRIGHT", 14, 1)
    f.title:SetText(L.RARE_ALERT_TITLE)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.name:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -1)
    f.name:SetPoint("RIGHT", -10, 0)
    f.name:SetJustifyH("LEFT")
    f.name:SetWordWrap(false)
    -- Entrada (crece desde un poco mas pequena y aparece) y latido del brillo
    local intro = f:CreateAnimationGroup()
    local fade = intro:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.25)
    local grow = intro:CreateAnimation("Scale")
    grow:SetScaleFrom(0.85, 0.85)
    grow:SetScaleTo(1, 1)
    grow:SetDuration(0.25)
    f.intro = intro
    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local beat = pulse:CreateAnimation("Alpha")
    beat:SetFromAlpha(0.25)
    beat:SetToAlpha(0.9)
    beat:SetDuration(0.7)
    f.pulse = pulse
    local out = f:CreateAnimationGroup()
    local outFade = out:CreateAnimation("Alpha")
    outFade:SetFromAlpha(1)
    outFade:SetToAlpha(0)
    outFade:SetDuration(0.6)
    out:SetScript("OnFinished", function() f:Hide() end)
    f.out = out

    f:RegisterForClicks("AnyUp")
    f:SetScript("OnClick", function(self)
        if self.boss then ns.RunAckRare(self.boss.name) end
        self.pulse:Stop()
        self.out:Play()
    end)
    ns.AddTooltip(f, L.RARE_ALERT_HINT)
    f:SetScript("OnHide", function(self) self.pulse:Stop() end)
    f:Hide()
    toast = f
end

-- Mazmorra del raro (para su nombre traducido y la linea de abajo)
local function DungeonOf(boss)
    for _, d in ipairs(ns.Dungeons) do
        for _, b in ipairs(ns.Bosses[d.key] or {}) do
            if b == boss then return d end
        end
    end
end

function ns.ShowRareAlert(boss)
    if not (ns.db and ns.db.rareToast and boss) then return end
    if not toast then CreateToast() end
    local d = DungeonOf(boss)
    local name = (ns.BossName and ns.BossName(boss, d)) or boss.name
    toast.boss = boss
    toast.name:SetText(name)
    -- Su cara; sin retrato conocido, la calavera de los jefes
    local ok = boss.display and SetPortraitTextureFromCreatureDisplayID
        and pcall(SetPortraitTextureFromCreatureDisplayID, toast.portrait, boss.display)
    if not ok then toast.portrait:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull") end
    toast.out:Stop()
    toast:SetAlpha(1)
    toast:Show()
    toast.intro:Play()
    toast.pulse:Play()
    -- Se va sola a los SHOW_TIME s (salvo que haya salido otro raro entre medias)
    shownCount = shownCount + 1
    local this = shownCount
    C_Timer.After(SHOW_TIME, function()
        if shownCount == this and toast:IsShown() then toast.out:Play() end
    end)
    -- El sonido del aviso de banda y el icono del juego parpadeando
    if ns.db.rareChime then
        if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master") end
        if FlashClientIcon then pcall(FlashClientIcon) end
    end
end

-- /dqa rare: el aviso de prueba, para verlo sin esperar a un raro. El raro de la mazmorra en la
-- que estas o, fuera, el primero de los datos con cara (Embajador Hierro Negro, Gnomeregan).
-- Sale aunque la opcion este apagada; no apunta nada en la partida.
function ns.TestRareAlert()
    local pick
    for _, d in ipairs(ns.DungeonsOf(ns.RunInside and ns.RunInside())) do
        for _, b in ipairs(ns.Bosses[d.key] or {}) do
            if not pick and b.kind == "rare" then pick = b end
        end
    end
    for _, d in ipairs(ns.Dungeons) do
        for _, b in ipairs(ns.Bosses[d.key] or {}) do
            if not pick and b.kind == "rare" and b.display then pick = b end
        end
    end
    if not pick then return end
    local saved = ns.db.rareToast
    ns.db.rareToast = true
    ns.ShowRareAlert(pick)
    ns.db.rareToast = saved
end

-- Deja de avisar (clic en su cara en la ventana de la partida): fuera la tarjeta
function ns.HideRareAlert(name)
    if toast and toast:IsShown() and (not name or (toast.boss and toast.boss.name == name)) then toast.out:Play() end
end
