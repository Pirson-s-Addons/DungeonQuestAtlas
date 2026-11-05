local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- AVISO DE VERSION NUEVA E INFORME DE FALLOS
-- ==========================================
-- Un addon no puede mirar internet: la unica forma de saber que hay una version
-- nueva es que otro jugador la lleve. Cada copia dice su version, sin que se vea,
-- por mensajes de addon a la hermandad y al grupo (como mucho cada THROTTLE s por
-- canal). Si alguien lleva una mas nueva, se avisa una vez por sesion y, mientras
-- se haya oido hace menos de REMEMBER, tambien al entrar en el juego.
-- Dentro de mazmorras Forever puede bloquear los mensajes de addon: todo con pcall.

local PREFIX = "DQAVER"
local THROTTLE = 60
local REMEMBER = 3 * 24 * 60 * 60

ns.ISSUES_URL = "https://github.com/Pirson-s-Addons/DungeonQuestAtlas/issues"

local MY_VERSION = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0"

-- "2.16" > "2.15"; lo que no sea un numero no cuenta
local function Newer(a, b)
    return (tonumber(a) or 0) > (tonumber(b) or 0)
end
ns.IsNewerVersion = Newer

local warned = false
local function Warn(version)
    if warned then return end
    warned = true
    ns.Print(L.NEW_VERSION:format(version, MY_VERSION))
end

local lastSent = {}
local function Send(channel)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    if lastSent[channel] and GetTime() - lastSent[channel] < THROTTLE then return end
    lastSent[channel] = GetTime()
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, MY_VERSION, channel)
end

local function Announce()
    if IsInGuild and IsInGuild() then Send("GUILD") end
    if IsInRaid and IsInRaid() then
        Send("RAID")
    elseif IsInGroup and IsInGroup() then
        Send("PARTY")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, event, prefix, message)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
        end
        -- Lo oido en otra sesion, si aun es reciente y mas nuevo que esta
        local seen = ns.db.newerVersion
        if seen and Newer(seen[1], MY_VERSION) and time() - (seen[2] or 0) < REMEMBER then
            C_Timer.After(8, function() Warn(seen[1]) end)
        end
        C_Timer.After(10, Announce)
    elseif event == "GROUP_ROSTER_UPDATE" then
        Announce()
    elseif event == "CHAT_MSG_ADDON" then
        prefix, message = ns.PlainText(prefix), ns.PlainText(message)
        if prefix ~= PREFIX or type(message) ~= "string" then return end
        if Newer(message, MY_VERSION) then
            local seen = ns.db.newerVersion
            if not (seen and Newer(seen[1], message)) then ns.db.newerVersion = { message, time() } end
            ns.db.newerVersion[2] = time()
            Warn(message)
        end
    end
end)

-- /dqa bug: la direccion para abrir un fallo, con lo que hace falta saber del cliente
function ns.ShowBugReport()
    local version, build = GetBuildInfo()
    local info = ("Dungeon Quest Atlas %s · WoW %s (%s) · %s · %s"):format(MY_VERSION, tostring(version),
        tostring(build), GetLocale(), ns.UILANG or "")
    ns.ShowCopyDialog(L.BUG_REPORT, ns.ISSUES_URL .. "\n\n" .. L.BUG_REPORT_TEXT .. "\n" .. info)
end
