local _, ns = ...

-- ==========================================
-- MEJORAS DE EQUIPO (para las tiradas de botin)
-- ==========================================
-- Dice si un objeto mejora a cada jugador del grupo, cuanto (%) y que estadisticas cambia.
-- Como Pawn: puntuacion = suma de estadistica x peso, comparada con lo que lleva en ese hueco
-- (anillos, abalorios y armas de una mano: contra el peor de los dos). Los pesos son propios,
-- por clase y especializacion (SPECS). Las estadisticas, de C_Item.GetItemStats.
-- El equipo de los demas, de dos fuentes, guardado por GUID:
--   * Mensajes de addon (DQAGEAR): cada copia de DQA cuenta su equipo y su especializacion.
--     Exacto, pero solo de quien lleva el addon. Manda: pisa lo inspeccionado.
--   * Inspeccion (NotifyInspect -> INSPECT_READY): de uno en uno, fuera de combate, a menos
--     de ~28 m. Se repasa el grupo al entrar en una mazmorra o al cambiar el grupo.

local PREFIX = "DQAGEAR"
local FRESH = 15 * 60     -- segundos que vale un equipo inspeccionado
local INSPECT_WAIT = 4    -- segundos de espera a INSPECT_READY antes de pasar al siguiente
local MIN_GAIN = 1        -- % minimo para llamarlo mejora (redondeos y empates fuera)

-- Clave de C_Item.GetItemStats (sin ITEM_MOD_ ni _SHORT) -> estadistica de los pesos
local STAT = {
    STRENGTH = "str", AGILITY = "agi", STAMINA = "sta", INTELLECT = "int", SPIRIT = "spi",
    ATTACK_POWER = "ap", RANGED_ATTACK_POWER = "rap", FERAL_ATTACK_POWER = "fap",
    SPELL_POWER = "sp", SPELL_DAMAGE_DONE = "sp", SPELL_HEALING_DONE = "heal",
    CRIT_RATING = "crit", CRIT_MELEE_RATING = "crit", CRIT_RANGED_RATING = "crit", CRIT_SPELL_RATING = "scrit",
    HIT_RATING = "hit", HIT_MELEE_RATING = "hit", HIT_RANGED_RATING = "hit", HIT_SPELL_RATING = "shit",
    DEFENSE_SKILL_RATING = "def", DODGE_RATING = "dodge", PARRY_RATING = "parry",
    BLOCK_RATING = "block", BLOCK_VALUE = "blockv",
    MANA_REGENERATION = "mp5", POWER_REGEN0 = "mp5", HEALTH_REGEN = "hp5", HEALTH_REGENERATION = "hp5",
    DAMAGE_PER_SECOND = "dps", RESISTANCE0_NAME = "armor",
}

-- Pesos por clase y especializacion de Forever (9 clases, 3 arboles cada una, en el orden de
-- warcraftforever.games/es/classes), con la estadistica principal a 1. Critico, golpe, esquivar y
-- parar salen en % en Forever: su peso es el de 1 %. Las armas pesan por su DPS (los ferales no:
-- pegan con la forma). Las conversiones de talentos de Forever van dentro del peso:
--   Paladin Reprension "Campeon de la Luz": hasta 33 % del intelecto a daño con hechizos y sanacion
--   Chaman Mejora "Maña mental": 33 % del intelecto a poder de ataque; "Presura mental": 15 % a hechizos
--   Cazador Punteria "Afinar la punteria": 20 % del intelecto a poder de ataque
--   Brujo "Armadura vil": 50 % del espiritu a daño con hechizos; Demonologia "Abrazo demoniaco": +15 % aguante
--   Druida Recuperacion "Espiritu vivo": +5 % espiritu
-- weaponCrit: % de critico con un tipo de arma (subclase de la clase 2), de talentos:
--   Guerrero Armas "Maestro de armas": +1 % con hacha o arma de asta; Picaro Combate "Cortar y
--   rebanar": +1 % con daga o puño
-- shortcut: el cazador puntua igual el DPS de un arma cuerpo a cuerpo que el de una a distancia
-- shortcut: Brujo Demonologia "Conocimiento demoniaco" (33 % de algo -la web dice "nivel"- a hechizos) no
-- cuenta hasta saber de que estadistica sale
local function W(name, role, t) t.name, t.role = name, role; return t end
local SPECS = {
    WARRIOR = { default = 1,
        W("Arms", "DAMAGER", { str = 1, agi = 0.7, ap = 0.5, crit = 14, hit = 16, sta = 0.35, dps = 6, armor = 0.005,
            weaponCrit = { [0] = 1, [1] = 1, [6] = 1 } }),
        W("Fury", "DAMAGER", { str = 1, agi = 0.7, ap = 0.5, crit = 14, hit = 17, sta = 0.35, dps = 5, armor = 0.005 }),
        W("Protection", "TANK", { sta = 1, def = 1.3, dodge = 12, parry = 11, block = 5, blockv = 0.4, str = 0.5,
            agi = 0.6, hit = 7, armor = 0.03, hp5 = 1, dps = 2 }) },
    PALADIN = { default = 3,
        W("Holy", "HEALER", { heal = 1, sp = 0.9, int = 0.8, mp5 = 1.2, scrit = 7, spi = 0.1, sta = 0.3, armor = 0.002 }),
        -- Sello de furia y Escudo Sagrado: el daño Sagrado da amenaza y absorcion
        W("Protection", "TANK", { sta = 1, def = 1.2, sp = 0.6, int = 0.3, dodge = 12, parry = 11, block = 5,
            blockv = 0.4, str = 0.4, agi = 0.5, hit = 6, mp5 = 0.5, armor = 0.03, dps = 2 }),
        -- Fuerza para el ataque; daño Sagrado (sellos, Golpe Sagrado, Martillo del honrado) con hechizos;
        -- intelecto = 33 % x 0,5 de hechizos + mana
        W("Retribution", "DAMAGER", { str = 1, sp = 0.5, int = 0.37, agi = 0.5, ap = 0.5, crit = 14, hit = 15,
            scrit = 3, mp5 = 0.6, spi = 0.1, sta = 0.35, dps = 6, armor = 0.005 }) },
    HUNTER = { default = 1,
        W("Beast Mastery", "DAMAGER", { agi = 1, rap = 0.5, ap = 0.1, int = 0.35, crit = 13, hit = 14, sta = 0.35,
            mp5 = 0.8, dps = 4, armor = 0.005 }),
        -- intelecto = 20 % x 0,55 de poder de ataque + mana
        W("Marksmanship", "DAMAGER", { agi = 1, rap = 0.55, ap = 0.11, int = 0.46, crit = 13, hit = 15, sta = 0.35,
            mp5 = 0.9, dps = 4.5, armor = 0.005 }),
        -- Supervivencia pega tambien cuerpo a cuerpo (Mordedura de mangosta, Patada de zancudo)
        W("Survival", "DAMAGER", { agi = 1.1, rap = 0.45, ap = 0.35, str = 0.15, int = 0.35, crit = 14, hit = 14,
            sta = 0.4, mp5 = 0.8, dps = 4, armor = 0.005 }) },
    ROGUE = { default = 2,
        W("Assassination", "DAMAGER", { agi = 1, str = 0.55, ap = 0.5, crit = 15, hit = 16, sta = 0.3, dps = 5, armor = 0.005 }),
        W("Combat", "DAMAGER", { agi = 1, str = 0.55, ap = 0.5, crit = 14, hit = 17, sta = 0.3, dps = 6, armor = 0.005,
            weaponCrit = { [13] = 1, [15] = 1 } }),
        W("Subtlety", "DAMAGER", { agi = 1, str = 0.55, ap = 0.5, crit = 14, hit = 15, sta = 0.3, dps = 5, armor = 0.005 }) },
    PRIEST = { default = 3,
        W("Discipline", "HEALER", { heal = 1, sp = 0.9, int = 0.7, spi = 0.6, mp5 = 1.2, scrit = 6, sta = 0.3, armor = 0.002 }),
        W("Holy", "HEALER", { heal = 1, sp = 0.9, int = 0.6, spi = 0.7, mp5 = 1.2, scrit = 6, sta = 0.3, armor = 0.002 }),
        W("Shadow", "DAMAGER", { sp = 1, int = 0.35, spi = 0.4, shit = 12, scrit = 6, sta = 0.35, mp5 = 0.6, armor = 0.002 }) },
    SHAMAN = { default = 2,
        W("Elemental", "DAMAGER", { sp = 1, int = 0.4, scrit = 10, shit = 12, mp5 = 0.7, spi = 0.1, sta = 0.3, armor = 0.002 }),
        -- intelecto = 33 % x 0,5 de poder de ataque + 15 % x 0,3 de hechizos + mana
        W("Enhancement", "DAMAGER", { str = 1, agi = 0.7, ap = 0.5, int = 0.31, sp = 0.3, crit = 13, hit = 14,
            mp5 = 0.4, sta = 0.35, dps = 6, armor = 0.005 }),
        W("Restoration", "HEALER", { heal = 1, sp = 0.9, int = 0.6, mp5 = 1.4, spi = 0.2, scrit = 6, sta = 0.3, armor = 0.002 }) },
    MAGE = { default = 3,
        W("Arcane", "DAMAGER", { sp = 1, int = 0.5, spi = 0.25, scrit = 9, shit = 12, mp5 = 0.7, sta = 0.3, armor = 0.002 }),
        W("Fire", "DAMAGER", { sp = 1, int = 0.4, spi = 0.15, scrit = 11, shit = 12, mp5 = 0.5, sta = 0.3, armor = 0.002 }),
        W("Frost", "DAMAGER", { sp = 1, int = 0.4, spi = 0.2, scrit = 9, shit = 12, mp5 = 0.6, sta = 0.3, armor = 0.002 }) },
    WARLOCK = { default = 1,
        -- Aguante = mana (Transfusion de vida); espiritu = 50 % a hechizos (Armadura vil) + Transfusion
        W("Affliction", "DAMAGER", { sp = 1, sta = 0.5, int = 0.35, spi = 0.6, shit = 12, scrit = 6, mp5 = 0.4, armor = 0.002 }),
        W("Demonology", "DAMAGER", { sp = 1, sta = 0.69, int = 0.35, spi = 0.6, shit = 12, scrit = 8, mp5 = 0.4, armor = 0.002 }),
        W("Destruction", "DAMAGER", { sp = 1, sta = 0.45, int = 0.35, spi = 0.55, shit = 12, scrit = 10, mp5 = 0.4, armor = 0.002 }) },
    DRUID = { default = 2,
        W("Balance", "DAMAGER", { sp = 1, int = 0.45, spi = 0.3, scrit = 10, shit = 12, mp5 = 0.6, sta = 0.3, armor = 0.002 }),
        -- Combate feral: gato (daño) u oso (tanque) segun su rol
        W("Feral", "DAMAGER", { str = 1, agi = 0.9, fap = 0.5, ap = 0.5, crit = 14, hit = 15, sta = 0.35, armor = 0.005,
            tank = W("Feral", "TANK", { sta = 1, armor = 0.04, agi = 0.7, def = 1.2, dodge = 12, str = 0.4, fap = 0.2, hit = 6 }) }),
        W("Restoration", "HEALER", { heal = 1, sp = 0.9, int = 0.6, spi = 0.63, mp5 = 1.2, scrit = 6, sta = 0.3, armor = 0.002 }) },
}
ns.UPGRADE_SPECS = SPECS

-- Raza (UnitRace, en ingles): multiplicadores de una estadistica y % de critico con un tipo de arma
-- (warcraftforever.games/es/races). Humano: +5 % espiritu, +2 % critico con espadas. Enano: +1 %
-- con mazas. Orco: +1 % con hachas. Gnomo: +5 % de mana maximo. Tauren: +5 % de salud.
local RACES = {
    Human = { spi = 1.05, weaponCrit = { [7] = 2, [8] = 2 } },
    Dwarf = { weaponCrit = { [4] = 1, [5] = 1 } },
    Orc = { weaponCrit = { [0] = 1, [1] = 1 } },
    Gnome = { int = 1.05, mp5 = 1.05 },
    Tauren = { sta = 1.05 },
}

local function Pick(class, role, spec)
    local specs = SPECS[class] or SPECS.WARRIOR
    local w = spec and specs[spec]
    if w then return (role == "TANK" and w.tank) or w end
    local default = specs[specs.default]
    if role and role ~= default.role then
        for _, s in ipairs(specs) do
            if s.role == role then return s end
            if s.tank and role == "TANK" then return s.tank end
        end
    end
    return default
end

-- Pesos de un jugador: su especializacion si se sabe (y su rol, para el druida feral); si no, la
-- primera de su clase con su rol ("TANK", "HEALER", "DAMAGER") y, sin rol, la de daño mas comun
-- subiendo de nivel. Con la raza, la copia con sus bonus.
local profiles = {}
function ns.UpgradeProfile(class, role, spec, race)
    local base = Pick(class, role, spec)
    local bonus = race and RACES[race]
    if not bonus then return base end
    local key = base.name .. base.role .. tostring(class) .. race
    if profiles[key] then return profiles[key] end
    local w = {}
    for k, v in pairs(base) do w[k] = v end
    for k, v in pairs(bonus) do
        if type(v) == "number" and type(w[k]) == "number" then w[k] = w[k] * v end
    end
    if bonus.weaponCrit then
        w.weaponCrit = {}
        for sub, pct in pairs(base.weaponCrit or {}) do w.weaponCrit[sub] = pct end
        for sub, pct in pairs(bonus.weaponCrit) do w.weaponCrit[sub] = (w.weaponCrit[sub] or 0) + pct end
    end
    profiles[key] = w
    return w
end

-- ------------------------------------------
-- Objetos
-- ------------------------------------------

local function ItemInfo(item)
    local get = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if not get then return end
    local ok, name, link, quality, ilvl, minLevel, _, _, _, equipLoc, _, _, classID, subclassID = pcall(get, item)
    if ok and name then return link, equipLoc, minLevel, classID, subclassID, quality end
end

local statCache = {}
-- { [clave del juego] = valor } de un enlace; vacio si aun no esta en la cache del cliente
function ns.ItemStatsOf(link)
    if not link then return {} end
    local cached = statCache[link]
    if cached then return cached end
    local get = (C_Item and C_Item.GetItemStats) or _G.GetItemStats
    local ok, stats = pcall(get or error, link)
    if not (ok and type(stats) == "table") then return {} end
    statCache[link] = stats
    return stats
end

local function Weight(key, weights)
    local id = STAT[(key:gsub("^ITEM_MOD_", ""):gsub("_SHORT$", ""))]
    return id and weights[id] or 0
end

-- profile: la tabla de pesos de ns.UpgradeProfile
function ns.ItemScore(link, profile)
    local weights, score = profile, 0
    for key, value in pairs(ns.ItemStatsOf(link)) do
        if type(value) == "number" then score = score + value * Weight(key, weights) end
    end
    -- Critico de raza o talento con ese tipo de arma (vale para golpes y hechizos: el mayor peso)
    if weights.weaponCrit then
        local _, _, _, classID, subclassID = ItemInfo(link)
        local pct = classID == 2 and weights.weaponCrit[subclassID]
        if pct then score = score + pct * math.max(weights.crit or 0, weights.scrit or 0) end
    end
    return score
end

-- Hueco del objeto -> huecos del personaje (dos: anillos, abalorios, armas de una mano)
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
ns.UPGRADE_SLOTS = SLOTS
local OFFHAND = { INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true }
local DUAL_WIELD = { WARRIOR = true, ROGUE = true, HUNTER = true, SHAMAN = true }

-- Armadura que puede llevar cada clase (1 tela, 2 cuero, 3 malla, 4 placas): { antes de 40, desde 40 }
local ARMOR = { MAGE = { 1, 1 }, PRIEST = { 1, 1 }, WARLOCK = { 1, 1 }, ROGUE = { 2, 2 }, DRUID = { 2, 2 },
    HUNTER = { 2, 3 }, SHAMAN = { 2, 3 }, WARRIOR = { 3, 4 }, PALADIN = { 3, 4 } }
local SHIELD = { WARRIOR = true, PALADIN = true, SHAMAN = true }
-- Armas (subclase de la clase 2) que aprende cada clase. 14 (miscelanea) vale para todas.
local function Set(...) local t = { [14] = true } for _, v in ipairs({ ... }) do t[v] = true end return t end
local WEAPONS = {
    WARRIOR = Set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18),
    PALADIN = Set(0, 1, 4, 5, 6, 7, 8),
    HUNTER = Set(0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18),
    ROGUE = Set(2, 3, 4, 7, 13, 15, 16, 18),
    SHAMAN = Set(0, 1, 4, 5, 10, 13, 15),
    DRUID = Set(4, 5, 6, 10, 13, 15), -- en Forever los druidas usan armas de asta
    PRIEST = Set(4, 10, 15, 19),
    MAGE = Set(7, 10, 15, 19),
    WARLOCK = Set(7, 10, 15, 19),
}
-- shortcut: no mira "Clases:" ni "Unico" del tooltip; si molesta, leer C_TooltipInfo.GetHyperlink

-- Puede llevarlo esa clase a ese nivel? false + motivo ("class" o el nivel que pide)
function ns.CanEquip(class, level, equipLoc, minLevel, classID, subclassID)
    if minLevel and level and minLevel > level then return false, minLevel end
    if classID == 4 and equipLoc ~= "INVTYPE_CLOAK" then
        if subclassID == 6 then return SHIELD[class] == true, "class" end
        local armor = ARMOR[class]
        if armor and subclassID and subclassID >= 1 and subclassID <= 4 then
            return subclassID <= ((level or 60) >= 40 and armor[2] or armor[1]), "class"
        end
    elseif classID == 2 then
        local list = WEAPONS[class]
        return list == nil or list[subclassID] == true, "class"
    end
    return true
end

-- Diferencia de estadisticas (nuevo - viejo) con el peso de cada una, de mas a menos importante
local function StatDelta(newLink, oldLinks, weights)
    local sum = {}
    for key, value in pairs(ns.ItemStatsOf(newLink)) do sum[key] = (sum[key] or 0) + value end
    for _, link in ipairs(oldLinks) do
        for key, value in pairs(ns.ItemStatsOf(link)) do sum[key] = (sum[key] or 0) - value end
    end
    local list = {}
    for key, value in pairs(sum) do
        local w = Weight(key, weights)
        if value ~= 0 and w > 0 then list[#list + 1] = { key = key, value = value, weight = math.abs(value * w) } end
    end
    table.sort(list, function(a, b) return a.weight > b.weight end)
    return list
end

-- Lo que el objeto le hace a alguien. who = { class, level, profile (pesos), gear = { [hueco] = enlace } }
-- Devuelve { pct, gain, empty, stats, against } o { blocked = "class"|nivel } o nil (no se sabe o no
-- se equipa: bolsas, camisas...)
function ns.EvaluateItem(link, who)
    local itemLink, equipLoc, minLevel, classID, subclassID = ItemInfo(link)
    local slots = equipLoc and SLOTS[equipLoc]
    if not (itemLink and slots) then return end
    local ok, why = ns.CanEquip(who.class, who.level, equipLoc, minLevel, classID, subclassID)
    if not ok then return { blocked = why } end
    if equipLoc == "INVTYPE_WEAPON" and not DUAL_WIELD[who.class] then slots = { 16 } end
    local gear, profile = who.gear, who.profile
    local main = gear[16] and select(2, ItemInfo(gear[16]))
    local twoHanded = main == "INVTYPE_2HWEAPON"
    local against
    if equipLoc == "INVTYPE_2HWEAPON" then
        against = { gear[16], gear[17] } -- un arma de dos manos quita tambien la mano izquierda
    elseif twoHanded and (OFFHAND[equipLoc] or equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND") then
        return { pct = 0, gain = 0, stats = {}, against = {} } -- como Pawn: con dos manos, una mano no cuenta
    else
        -- El peor de sus huecos (o uno vacio)
        local worst, worstScore
        for _, slot in ipairs(slots) do
            local score = gear[slot] and ns.ItemScore(gear[slot], profile) or 0
            if not worstScore or score < worstScore then worst, worstScore = slot, score end
        end
        against = { gear[worst] }
    end
    local old = 0
    for _, l in ipairs(against) do old = old + ns.ItemScore(l, profile) end
    local new = ns.ItemScore(itemLink, profile)
    local empty = #against == 0
    local pct = empty and (new > 0 and 100 or 0) or (old > 0 and (new - old) / old * 100 or (new > 0 and 100 or 0))
    return { pct = pct, gain = new - old, empty = empty, stats = StatDelta(itemLink, against, profile),
        against = against }
end

function ns.IsUpgrade(result) return result ~= nil and result.pct ~= nil and result.pct >= MIN_GAIN end

-- ------------------------------------------
-- Equipo del grupo
-- ------------------------------------------

local cache = {} -- [GUID] = { name, class, level, spec, role, gear, src = "dqa"|"inspect", at }
ns.groupGear = cache

local function Now() return GetTime() end
local function Plain(v) return ns.PlainText(v) end

-- "item:12345:0:0:0:0:0:1196:0:..." -> "12345:0:0:0:0:0:1196:0" (id, encantamiento, gemas, sufijo)
local function ItemString(link)
    local s = type(link) == "string" and link:match("item:([%-%d:]+)")
    if not s then return end
    local parts, n = {}, 0
    for field in (s .. ":"):gmatch("([^:]*):") do
        n = n + 1
        if n > 8 then break end
        parts[n] = field
    end
    return (table.concat(parts, ":"):gsub(":+$", ""))
end
ns.UpgradeItemString = ItemString

local function GroupUnits()
    local units = {}
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do units[#units + 1] = "raid" .. i end
    else
        for i = 1, 4 do units[#units + 1] = "party" .. i end
    end
    local list = {}
    for _, unit in ipairs(units) do
        if Plain(UnitExists(unit)) and not Plain(UnitIsUnit(unit, "player")) then list[#list + 1] = unit end
    end
    return list
end
ns.UpgradeGroupUnits = GroupUnits

local function SpecIndexOf(classID, specID)
    if not (specID and specID > 0 and classID and GetSpecializationInfoForClassID) then return end
    for i = 1, 4 do
        local ok, id = pcall(GetSpecializationInfoForClassID, classID, i)
        if ok and id == specID then return i end
    end
end

local function RoleOf(classID, spec, unit)
    if spec and GetSpecializationInfoForClassID then
        local ok, _, _, _, _, role = pcall(GetSpecializationInfoForClassID, classID, spec)
        if ok and type(role) == "string" then return role end
    end
    local role = unit and UnitGroupRolesAssigned and Plain(UnitGroupRolesAssigned(unit))
    return (role == "TANK" or role == "HEALER" or role == "DAMAGER") and role or nil
end

-- Tu equipo, al momento
local function SelfInfo()
    local _, class, classID = UnitClass("player")
    local spec = GetSpecialization and GetSpecialization() or nil
    local gear = {}
    for slot = 1, 19 do gear[slot] = Plain(GetInventoryItemLink("player", slot)) end
    return { name = ns.UnitFullName("player"), class = class, level = UnitLevel("player"), spec = spec,
        role = RoleOf(classID, spec, "player"), race = select(2, UnitRace("player")), gear = gear }
end

-- Lo que se sabe de una unidad del grupo (o nil)
local function UnitInfo(unit)
    local guid = Plain(UnitGUID(unit))
    local entry = guid and cache[guid]
    if not entry then return end
    local _, class, classID = UnitClass(unit)
    entry.class = Plain(class) or entry.class
    entry.level = Plain(UnitLevel(unit)) or entry.level
    entry.name = ns.UnitFullName(unit) or entry.name
    entry.role = entry.role or RoleOf(classID, entry.spec, unit)
    entry.race = Plain(select(2, UnitRace(unit))) or entry.race
    return entry
end

local function Profiled(info)
    info.profile = ns.UpgradeProfile(info.class, info.role, info.spec, info.race)
    return info
end

function ns.MyUpgradeInfo() return Profiled(SelfInfo()) end

-- Lo que un objeto hace a ti y a cada uno del grupo: { me = resultado, members = { { name, class,
-- result, src } }, unknown = { nombres sin datos } }
function ns.UpgradeAdvice(link)
    local advice = { members = {}, unknown = {} }
    advice.me = ns.EvaluateItem(link, ns.MyUpgradeInfo())
    for _, unit in ipairs(GroupUnits()) do
        local info = UnitInfo(unit)
        if info then
            local result = ns.EvaluateItem(link, Profiled(info))
            advice.members[#advice.members + 1] = { name = info.name, class = info.class, result = result, src = info.src }
        else
            local _, class = UnitClass(unit)
            advice.unknown[#advice.unknown + 1] = { name = ns.UnitFullName(unit) or "?", class = Plain(class) }
        end
    end
    table.sort(advice.members, function(a, b)
        return (a.result and a.result.pct or -1e9) > (b.result and b.result.pct or -1e9)
    end)
    return advice
end

-- ------------------------------------------
-- Inspeccion
-- ------------------------------------------

local pending, pendingAt -- GUID pedido a NotifyInspect y cuando

local function InCombat() return Plain(UnitAffectingCombat("player")) == true or (InCombatLockdown and InCombatLockdown()) end

local function NeedsInspect(unit)
    local guid = Plain(UnitGUID(unit))
    local entry = guid and cache[guid]
    return guid and not (entry and (entry.src == "dqa" or Now() - entry.at < FRESH)), guid
end

local function InspectNext()
    if not (ns.db and ns.db.rollAdvisor) or InCombat() then return end
    if pending and Now() - pendingAt < INSPECT_WAIT then return end
    pending = nil
    if InspectFrame and InspectFrame:IsShown() then return end -- el jugador esta inspeccionando a alguien
    for _, unit in ipairs(GroupUnits()) do
        local need, guid = NeedsInspect(unit)
        if need and Plain(UnitIsConnected(unit)) and Plain(CanInspect(unit)) and Plain(CheckInteractDistance(unit, 1)) then
            pending, pendingAt = guid, Now()
            pcall(NotifyInspect, unit)
            return
        end
    end
end

local function UnitByGUID(guid)
    for _, unit in ipairs(GroupUnits()) do
        if Plain(UnitGUID(unit)) == guid then return unit end
    end
end

local function OnInspectReady(guid)
    if not (guid and guid == pending) then return end
    pending = nil
    local unit = UnitByGUID(guid)
    if not unit then return end
    local entry = cache[guid]
    if entry and entry.src == "dqa" then return end
    local gear, missing = {}, false
    for slot = 1, 19 do
        local link = Plain(GetInventoryItemLink(unit, slot))
        local id = not link and Plain(GetInventoryItemID(unit, slot))
        if id then link, missing = "item:" .. id, true end -- aun sin cache: basta el objeto base
        gear[slot] = link
    end
    local _, class, classID = UnitClass(unit)
    local specID = GetInspectSpecialization and Plain(GetInspectSpecialization(unit))
    local spec = SpecIndexOf(classID, specID)
    cache[guid] = { name = ns.UnitFullName(unit), class = Plain(class), level = Plain(UnitLevel(unit)), spec = spec,
        role = RoleOf(classID, spec, unit), gear = gear, src = "inspect", at = missing and Now() - FRESH + 30 or Now() }
    if not (InspectFrame and InspectFrame:IsShown()) and ClearInspectPlayer then pcall(ClearInspectPlayer) end
    ns.Debug("mejoras: inspeccionado %s", tostring(cache[guid].name))
end

-- ------------------------------------------
-- Mensajes de addon
-- ------------------------------------------
-- "H|especializacion|rol|nivel" y luego trozos "S|hueco=objeto;hueco=objeto" (< 255 bytes cada uno)

local lastSent, sendQueued = 0, false

local function Channel()
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

local function SendGear()
    sendQueued = false
    local channel = Channel()
    if not (channel and ns.db and ns.db.rollAdvisor and C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    lastSent = Now()
    local me = SelfInfo()
    local function Send(text) pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel) end
    Send(("H|%s|%s|%s"):format(me.spec or "", me.role or "", me.level or ""))
    local chunk = "S|"
    for slot = 1, 19 do
        local s = ItemString(me.gear[slot])
        local piece = s and (slot .. "=" .. s .. ";")
        if piece then
            if #chunk + #piece > 240 then
                Send(chunk)
                chunk = "S|"
            end
            chunk = chunk .. piece
        end
    end
    if chunk ~= "S|" then Send(chunk) end
end

-- Agrupa los avisos (al entrar llegan varios eventos seguidos) y no manda mas de uno cada 10 s
local function QueueSend()
    if sendQueued or not C_Timer then return end
    sendQueued = true
    C_Timer.After(math.max(2, 10 - (Now() - lastSent)), SendGear)
end

local function SenderUnit(sender)
    local short = sender and sender:match("^[^%-]+")
    for _, unit in ipairs(GroupUnits()) do
        local name, realm = UnitName(unit)
        name, realm = Plain(name), Plain(realm)
        if name and (name == sender or name == short or (realm and name .. "-" .. realm == sender)) then return unit end
    end
end

-- Lo que llega de otro DQA (tambien para los tests)
function ns.UpgradeMessage(message, sender)
    local unit = SenderUnit(sender)
    local guid = unit and Plain(UnitGUID(unit))
    if not guid then return end
    local _, class = UnitClass(unit)
    local entry = cache[guid]
    if not (entry and entry.src == "dqa") then
        entry = { gear = {}, src = "dqa" }
        cache[guid] = entry
    end
    entry.name, entry.class, entry.at = ns.UnitFullName(unit), Plain(class), Now()
    local kind, rest = message:match("^(%a)|(.*)$")
    if kind == "H" then
        local spec, role, level = rest:match("^(%d*)|(%u*)|(%d*)")
        entry.spec, entry.role, entry.level = tonumber(spec), role ~= "" and role or nil, tonumber(level)
        entry.gear = {} -- llega el equipo entero detras
    elseif kind == "S" then
        for slot, item in rest:gmatch("(%d+)=([%-%d:]+);") do entry.gear[tonumber(slot)] = "item:" .. item end
    end
end

-- ------------------------------------------
-- Eventos
-- ------------------------------------------

local function Rescan()
    if not (ns.db and ns.db.rollAdvisor) then return end
    -- Los que ya no estan en el grupo salen de la cache
    local present = {}
    for _, unit in ipairs(GroupUnits()) do
        local guid = Plain(UnitGUID(unit))
        if guid then present[guid] = true end
    end
    for guid in pairs(cache) do if not present[guid] then cache[guid] = nil end end
    if next(present) then QueueSend() end
end

local frame = CreateFrame("Frame")
local EVENTS = {
    PLAYER_LOGIN = function()
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
    end,
    PLAYER_ENTERING_WORLD = Rescan, -- al entrar en la mazmorra: el grupo entero de nuevo
    GROUP_ROSTER_UPDATE = Rescan,
    PLAYER_EQUIPMENT_CHANGED = function() if Channel() then QueueSend() end end,
    PLAYER_SPECIALIZATION_CHANGED = function(unit) if unit == "player" and Channel() then QueueSend() end end,
    INSPECT_READY = function(guid) OnInspectReady(Plain(guid)) end,
    CHAT_MSG_ADDON = function(prefix, message, _, sender)
        prefix, message, sender = Plain(prefix), Plain(message), Plain(sender)
        if prefix == PREFIX and type(message) == "string" and type(sender) == "string" then ns.UpgradeMessage(message, sender) end
    end,
}
frame:SetScript("OnEvent", function(_, event, ...) EVENTS[event](...) end)
for event in pairs(EVENTS) do pcall(frame.RegisterEvent, frame, event) end
if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(2, InspectNext) end
