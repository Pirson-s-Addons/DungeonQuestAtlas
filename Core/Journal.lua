local _, ns = ...

-- ==========================================
-- DIARIO DE MAZMORRAS DEL JUEGO Y ARTE DE CADA MAZMORRA
-- ==========================================
-- Del Diario de mazmorras de Forever salen, en el idioma del cliente, la
-- historia de cada mazmorra y el nombre, la imagen y la historia de cada jefe
-- (casados con Data/Bosses.lua por su displayID, que no cambia con el idioma).
-- Las nuevas de Forever van en otro nivel (tier) del Diario: se recorren todos
-- y cada mazmorra se busca por su mapID o por su nombre.
--
-- El arte no se empaqueta: se prueban por orden texturas del propio cliente y
-- se usa la primera que existe (SetTexture da false si no esta; Forever no
-- trae todo el arte de Retail). Si ninguna, el fondo generico del Diario.

local unpack = unpack or table.unpack
local EJ = "Interface\\EncounterJournal\\"
local DEFAULT_BG = EJ .. "UI-EJ-BACKGROUND-Default"

-- Nombres de fichero de cada mazmorra. ej: arte del Diario (UI-EJ-*-<ej>);
-- lfg: icono redondo del buscador de grupo; load: pantalla de carga.
local FILES = {
    RFC = { ej = "RagefireChasm", lfg = "RagefireChasm", load = "RagefireChasm" },
    DM = { ej = "Deadmines", lfg = "Deadmines", load = "Deadmines" },
    WC = { ej = "WailingCaverns", lfg = "WailingCaverns", load = "WailingCaverns" },
    SFK = { ej = "ShadowfangKeep", lfg = "ShadowfangKeep", load = "ShadowfangKeep" },
    BFD = { ej = "BlackfathomDeeps", lfg = "BlackfathomDeeps", load = "BlackfathomDeeps" },
    STOCKS = { ej = "TheStockade", lfg = "StormwindStockades", load = "StormwindStockade" },
    GNOMER = { ej = "Gnomeregan", lfg = "Gnomeregan", load = "Gnomeregan" },
    RFK = { ej = "RazorfenKraul", lfg = "RazorfenKraul", load = "RazorfenKraul" },
    RFD = { ej = "RazorfenDowns", lfg = "RazorfenDowns", load = "RazorfenDowns" },
    ULDA = { ej = "Uldaman", lfg = "Uldaman", load = "Uldaman" },
    ZF = { ej = "ZulFarrak", load = "ZulFarrak" },
    MARA = { ej = "Maraudon", lfg = "Maraudon", load = "Maraudon" },
    ST = { ej = "SunkenTemple", lfg = "SunkenTemple", load = "SunkenTemple" },
    BRD = { ej = "BlackrockDepths", lfg = "BlackrockDepths", load = "BlackrockDepths" },
    LBRS = { ej = "BlackrockSpire", lfg = "BlackrockSpire", load = "BlackrockSpire" },
    UBRS = { ej = "UpperBlackrockSpire", lfg = "UpperBlackrockSpire", load = "UpperBlackrockSpire" },
    SCHOLO = { ej = "Scholomance", lfg = "Scholomance", load = "Scholomance" },
    LORDAERON = { lfg = "RuinsOfLordaeron", load = "RuinsOfLordaeronBattlegrounds" },
}
for _, key in ipairs({ "SM_GY", "SM_LIB", "SM_ARM", "SM_CATH" }) do
    FILES[key] = { ej = "ScarletMonastery", lfg = "ScarletMonastery", load = "ScarletMonastery2" }
end
for _, key in ipairs({ "DM_E", "DM_W", "DM_N" }) do
    FILES[key] = { ej = "DireMaul", lfg = "DireMaul", load = "DireMaul" }
end
for _, key in ipairs({ "STRAT_LIVE", "STRAT_UD" }) do
    FILES[key] = { ej = "Stratholme", lfg = "Stratholme", load = "Strathome" } -- "Strathome": asi se llama
end

-- Recortes de cada fuente (izquierda, derecha, arriba, abajo)
local CROP = {
    -- Estandarte de la lista: una franja
    banner = { button = { 0, 0.68359375, 0.22, 0.52 }, load = { 0, 1, 0.38, 0.6 }, bg = { 0, 0.77, 0.3, 0.45 } },
    -- Ilustracion de la pestana Mazmorra
    lore = { lore = { 0, 0.7617187, 0, 0.5 }, load = { 0, 1, 0.1, 0.72 }, bg = { 0, 0.77, 0.1, 0.55 } },
    -- Fondo del jefe elegido
    bg = { bg = { 0, 0.77, 0.25, 0.55 }, load = { 0, 1, 0.3, 0.62 } },
}

local journal = {}      -- [clave de mazmorra] = { name, description, button, lore, bg, bosses }
local index             -- [mapID o nombre] = journalInstanceID

local function Valid(texture)
    return texture ~= nil and texture ~= 0 and texture ~= ""
end

-- Todas las mazmorras del Diario, de todos los niveles, por mapID y por
-- nombre. Cambia el nivel elegido del Diario, asi que se deja como estaba.
local function BuildIndex()
    index = {}
    if not (EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex) then return end
    local current = EJ_GetCurrentTier and EJ_GetCurrentTier()
    for tier = 1, EJ_GetNumTiers() do
        EJ_SelectTier(tier)
        for i = 1, 200 do
            local id, name, _, _, _, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(i, false)
            if not id then break end
            if mapID then index[mapID] = index[mapID] or id end
            if name then index[name] = index[name] or id end
        end
    end
    if current then EJ_SelectTier(current) end
end

local function Load(d)
    local info = { bosses = {} }
    if not index then
        local ok = pcall(BuildIndex)
        if not ok then index = {} end
    end
    local id = (d.instanceID and index[d.instanceID]) or index[ns.DungeonName(d)] or index[d.name]
    if not id and d.instanceID and C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap then
        id = C_EncounterJournal.GetInstanceForGameMap(d.instanceID)
    end
    if not (id and EJ_GetInstanceInfo) then return info end
    local name, description, bg, button, lore = EJ_GetInstanceInfo(id)
    info.name, info.description = name, description ~= "" and description or nil
    info.bg = Valid(bg) and bg or nil
    info.button = Valid(button) and button or nil
    info.lore = Valid(lore) and lore or nil
    if EJ_SelectInstance then EJ_SelectInstance(id) end
    -- displayID -> jefe del Diario (nombre traducido, imagen, historia)
    for i = 1, 40 do
        local bossName, bossDesc, encounterID = EJ_GetEncounterInfoByIndex(i, id)
        if not encounterID then break end
        for c = 1, 8 do
            local _, creature, _, display, icon = EJ_GetCreatureInfo(c, encounterID)
            if not creature then break end
            if display then
                info.bosses[display] = { name = creature, icon = Valid(icon) and icon or nil,
                    description = bossDesc ~= "" and bossDesc or nil, encounter = bossName }
            end
        end
    end
    return info
end

function ns.Journal(d)
    if not journal[d.key] then
        local ok, info = pcall(Load, d)
        journal[d.key] = ok and info or { bosses = {} }
    end
    return journal[d.key]
end

-- Lo que el Diario sabe de un jefe de Data/Bosses.lua (o nil)
function ns.JournalBoss(d, boss)
    return boss.display and ns.Journal(d).bosses[boss.display] or nil
end

-- Candidatas de una imagen: { textura, recorte }, en orden
local function Candidates(d, kind)
    local j, f, crop = ns.Journal(d), FILES[d.key] or {}, CROP[kind]
    local list = {}
    local function Add(texture, coords) -- coords nil: la imagen entera
        if texture then list[#list + 1] = { texture, coords } end
    end
    local load = f.load and ("Interface\\Glues\\LoadingScreens\\LoadScreen" .. f.load)
    if kind == "banner" then
        Add(j.button, crop.button)
        Add(f.ej and (EJ .. "UI-EJ-DUNGEONBUTTON-" .. f.ej), crop.button)
        Add(load, crop.load)
        Add(DEFAULT_BG, crop.bg)
    elseif kind == "icon" then
        -- Icono redondo de la cabecera: imagenes enteras (lleva mascara redonda,
        -- y una textura con mascara no admite recorte)
        Add(f.lfg and ("Interface\\LFGFrame\\LFGIcon-" .. f.lfg))
        Add(ns.LOGO)
    elseif kind == "lore" then
        Add(j.lore, crop.lore)
        Add(f.ej and (EJ .. "UI-EJ-LOREBG-" .. f.ej), crop.lore)
        Add(load, crop.load)
        Add(DEFAULT_BG, crop.bg)
    else
        Add(j.bg, crop.bg)
        Add(f.ej and (EJ .. "UI-EJ-BACKGROUND-" .. f.ej), crop.bg)
        Add(load, crop.load)
        Add(DEFAULT_BG, crop.bg)
    end
    return list
end

-- Pone en la textura el arte de la mazmorra (kind: "banner", "icon", "lore",
-- "bg"): la primera candidata que el cliente tiene. La que vale se recuerda.
local chosen = {}
function ns.SetDungeonArt(texture, d, kind)
    local key = d.key .. kind
    local list = Candidates(d, kind)
    local pick = chosen[key]
    if pick then
        texture:SetTexture(list[pick][1])
        if list[pick][2] then texture:SetTexCoord(unpack(list[pick][2])) end
        return
    end
    for i, c in ipairs(list) do
        -- SetTexture devuelve false si el fichero no existe (nil: API sin ese dato)
        if texture:SetTexture(c[1]) ~= false or i == #list then
            if c[2] then texture:SetTexCoord(unpack(c[2])) end
            chosen[key] = i
            return
        end
    end
end
