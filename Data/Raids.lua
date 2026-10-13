local _, ns = ...

-- ==========================================
-- BANDAS Y CONTENIDO ANUNCIADO DE WOW FOREVER
-- ==========================================
-- Lo que Blizzard ha anunciado (hoja de ruta de 2026-09). Lo usan la pestana
-- Bandas (UI/Raids.lua) y "Proximamente" de Viajes (UI/Journeys.lua).
-- Fechas en "AAAA-MM-DD" si se saben; si no, season = "spring2027" / "summer2027".
--
-- ns.Raids: una entrada por banda con nombre conocido.
--   key, name (ingles), size (jugadores), unlock (fecha) o season,
--   isForever (nueva de Forever), instanceID (si se sabe: nombre del juego con
--   GetRealZoneText), bosses = { { name = "..." }, ... } (de la demo de la
--   BlizzCon si no hay lista oficial), bossCount (anunciado)
--   entrance: { mapID, x, y } del portal, para el mapa del mundo (UI/MapPins.lua)
--   zone: "hyjal" (L.RAID_ZONE_HYJAL) o zoneMapID (nombre del juego, ns.ZoneName)
--   bossSource: "demo" (ventana de Legado de la demo de la BlizzCon) o "beta"
--   (datos de la beta recogidos por warcraft.wiki.gg); los dos pueden cambiar.
--   Jefes: npcID / display si se saben (retrato y modelo); loot = { { itemID }, ... }
--   si se conoce (aun ninguna banda de Forever lo tiene). lootSource = "classic": el de
--   WoW Classic, provisional (sale un aviso encima del botin).
--   attunement: requisito de acceso. item = la llave; Alliance / Horde = misiones
--   en orden (las que no estan en Data/Quests.lua se anaden abajo, sin pisar).
--   names: nombre por idioma mientras el cliente de Forever no traiga la banda
--   (la build 1.60.1.70338 solo tiene Onyxia: Map y AreaTable de wago.tools).
--   Cumbre de Hyjal: el oficial de TBC (AreaTable 3606 de Retail). Barrow Deeps
--   no tiene nombre oficial en ningun idioma: traduccion nuestra, provisional.
--   Los 10 idiomas sin cliente oficial, en ingles (como los muestra el juego).
-- ns.Upcoming: anuncios sin nombre todavia (bandas y mazmorras por temporada).
--
-- Fuentes: blizzardwatch.com (2026-09-13 y 2026-09-14), icy-veins.com (hoja de
-- ruta), warcraft.wiki.gg (Barrow_Deeps_(instance), Hyjal_Summit_(instance)),
-- wowclassicforever.info/raids/barrow-deeps, Wowhead Forever (npc=10184).

ns.Raids = {
    { key = "BARROW", name = "The Barrow Deeps", size = 10, unlock = "2026-12-09", isForever = true, bossCount = 8,
        names = { esES = "Las Profundidades de los Túmulos", deDE = "Die Grabhügeltiefen",
            frFR = "Les Profondeurs des Tumulus", itIT = "Profondità dei Tumuli", ptBR = "Profundezas dos Túmulos",
            ruRU = "Глубины Курганов", koKR = "무덤 심연", zhCN = "古冢深渊", zhTW = "古塚深淵" },
        zone = "hyjal", bossSource = "demo",
        bosses = {
            { name = "Deepscar Matriarch" },
            { name = "Elder Tangleclaw" },
            { name = "Khalith the Dreadspinner" },
            { name = "Well of Sorrow" },
            { name = "Amethrax" },
            { name = "Del'lynar Songwood" },
            { name = "Ravus and Darlissa" },
            { name = "Sonya Darkhallow" },
        } },
    { key = "HYJAL", name = "Hyjal Summit", size = 20, unlock = "2026-12-09", isForever = true, bossCount = 13,
        names = { esES = "La Cima Hyjal", deDE = "Hyjalgipfel", frFR = "Sommet d’Hyjal", itIT = "Sommità di Hyjal",
            ptBR = "Pico Hyjal", ruRU = "Вершина Хиджала", koKR = "하이잘 정상", zhCN = "海加尔峰", zhTW = "海加爾山之巔" },
        zone = "hyjal", bossSource = "beta",
        bosses = {
            { name = "Bandalar" },
            { name = "Time-Lost Battalion" },
            { name = "Old Gloomlurker" },
            { name = "Kathris the Haunted" },
            { name = "Elder Minderel" },
            { name = "Council of Thorns" },
            { name = "The Wild King" },
            { name = "Ancient of Decay" },
            { name = "Sylvesteris Dusksong" },
            { name = "Gharalis the Abyssal" },
            { name = "Anara Chillwind" },
            { name = "Tracker Stillwind" },
            { name = "Nythus the Dreambound" },
        } },
    { key = "ONYXIA", name = "Onyxia's Lair", size = 40, unlock = "2026-12-09", instanceID = 249, bossCount = 1,
        zoneMapID = 1445, -- Marjal Revolcafango
        -- Portal: AreaTrigger 2848 (wago.tools, wow_classic_era) pasado a la zona con UiMapAssignment
        entrance = { mapID = 1445, x = 52.9, y = 78.2 },
        -- Botin de WoW Classic hasta que Forever publique el suyo (lootSource): cMaNGOS classic-db
        -- 1.12.1 (creature_loot_template 10184 y sus reference_loot_template). Cascos de T2: 2 de 9
        -- (8 por faccion) = 23,4 %; epicas: 1 de 4; armas: 8 % cada una. Sin el botin comun de mundo.
        lootSource = "classic",
        bosses = { { name = "Onyxia", npcID = 10184, display = 8570, level = 63, loot = {
            { 16921, 23.4 }, { 16914, 23.4 }, { 16929, 23.4 }, { 16900, 23.4 }, { 16908, 23.4 },
            { 16939, 23.4 }, { 16947, 23.4 }, { 16955, 23.4 }, { 16963, 23.4 },
            { 17078, 25 }, { 18205, 25 }, { 17067, 25 }, { 18813, 25 },
            { 17068, 8 }, { 17075, 8 }, { 17064, 8 },
            { 17966, 100 }, { 18423, 100 }, { 18422, 100 }, { 18705, 40 } } } },
        -- Cadena de Classic (guia de Wowhead Classic); las 30 misiones existen en
        -- Wowhead Forever. Blizzard dijo en una entrevista que las bandas de Forever
        -- no pediran attunement al salir: puede no hacer falta.
        attunement = { item = 16309, itemName = "Drakefire Amulet", warning = "RAID_ATTUNE_WARNING",
            Alliance = { 4182, 4183, 4184, 4185, 4186, 4223, 4224, 4241, 4242, 4264, 4282, 4322, 6402, 6403, 6501, 6502 },
            Horde = { 4903, 4941, 4974, 6566, 6567, 6568, 6569, 6570, 6584, 6582, 6583, 6585, 6601, 6602 } } },
}

ns.Upcoming = {
    { season = "spring2027", raids = { 10, 20 }, dungeons = 2 },
    { season = "summer2027", raids = { "revamp", "new" }, dungeons = 2 },
}

-- Misiones de la cadena de Onyxia y sus PNJ de inicio: Wowhead Forever (12-10-2026,
-- /forever/quest= y g_mapperData); 4903 empieza con Warlord Goretooth (guia de
-- Wowhead Classic). Se anaden sin pisar lo que ya hay en Data/Quests.lua y Data/Places.lua.
local attuneQuests = {
    [4182] = { name = "Dragonkin Menace", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:9562" } },
    [4183] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:9562" } },
    [4184] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:344" } },
    [4185] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:1748" } },
    [4186] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:1748" } },
    [4223] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:344" } },
    [4224] = { name = "The True Masters", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:9560" } },
    [4241] = { name = "Marshal Windsor", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:9560" } },
    [4242] = { name = "Abandoned Hope", level = 54, minLevel = 48, faction = "Alliance", starts = { "npc:9023" } },
    [4264] = { name = "A Crumpled Up Note", level = 58, minLevel = 50, faction = "Alliance" },
    [4282] = { name = "A Shred of Hope", level = 58, minLevel = 50, faction = "Alliance", starts = { "npc:9023" } },
    [4322] = { name = "Jail Break!", level = 58, minLevel = 50, faction = "Alliance", starts = { "npc:9023" } },
    [6402] = { name = "Stormwind Rendezvous", level = 60, minLevel = 50, faction = "Alliance", starts = { "npc:9560" } },
    [6403] = { name = "The Great Masquerade", level = 60, minLevel = 50, faction = "Alliance", starts = { "npc:12580" } },
    [6501] = { name = "The Dragon's Eye", level = 60, minLevel = 50, faction = "Alliance", starts = { "npc:1748" } },
    [6502] = { name = "Drakefire Amulet", level = 60, minLevel = 50, faction = "Alliance", starts = { "npc:10929" } },
    [4903] = { name = "Warlord's Command", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:9077" } },
    [4941] = { name = "Eitrigg's Wisdom", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:9077" } },
    [4974] = { name = "For The Horde!", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:4949" } },
    [6566] = { name = "What the Wind Carries", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:4949" } },
    [6567] = { name = "The Champion of the Horde", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:4949" } },
    [6568] = { name = "The Testament of Rexxar", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10182" } },
    [6569] = { name = "Oculus Illusions", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:11872" } },
    [6570] = { name = "Emberstrife", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:11872" } },
    [6584] = { name = "The Test of Skulls, Chronalis", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10321" } },
    [6582] = { name = "The Test of Skulls, Scryer", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10321" } },
    [6583] = { name = "The Test of Skulls, Somnus", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10321" } },
    [6585] = { name = "The Test of Skulls, Axtroz", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10321" } },
    [6601] = { name = "Ascension...", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10321" } },
    [6602] = { name = "Blood of the Black Dragon Champion", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:10182" } },
    -- Llave de Scholomance (Data/Dungeons.lua): niveles, PNJ y orden de AzerothCore
    -- (quest_template, creature_queststarter/ender, PrevQuestID); nombres de Wowhead Forever
    [5092] = { name = "Clear the Way", level = 52, minLevel = 50, faction = "Alliance", starts = { "npc:10838" }, ends = { "npc:10838" } },
    [5097] = { name = "All Along the Watchtowers", level = 56, minLevel = 50, faction = "Alliance", starts = { "npc:10838" }, ends = { "npc:10838" } },
    [5533] = { name = "Scholomance", level = 55, minLevel = 55, faction = "Alliance", starts = { "npc:10838" }, ends = { "npc:11056" } },
    [5537] = { name = "Skeletal Fragments", level = 57, minLevel = 55, faction = "Alliance", starts = { "npc:11056" }, ends = { "npc:11056" } },
    [5538] = { name = "Mold Rhymes With...", level = 57, minLevel = 55, faction = "Alliance", starts = { "npc:11056" }, ends = { "npc:5411" } },
    [5801] = { name = "Fire Plume Forged", level = 57, minLevel = 55, faction = "Alliance", starts = { "npc:5411" }, ends = { "npc:11056" } },
    [5803] = { name = "Araj's Scarab", level = 60, minLevel = 55, faction = "Alliance", starts = { "npc:11056" }, ends = { "npc:11056" } },
    [5505] = { name = "The Key to Scholomance", level = 60, minLevel = 55, faction = "Alliance", rewards = { 13704 }, starts = { "npc:11056" }, ends = { "npc:11056" } },
    [5096] = { name = "Scarlet Diversions", level = 53, minLevel = 50, faction = "Horde", starts = { "npc:10837" }, ends = { "npc:10837" } },
    [5098] = { name = "All Along the Watchtowers", level = 56, minLevel = 50, faction = "Horde", starts = { "npc:10837" }, ends = { "npc:10837" } },
    [838] = { name = "Scholomance", level = 55, minLevel = 55, faction = "Horde", starts = { "npc:10837" }, ends = { "npc:11057" } },
    [964] = { name = "Skeletal Fragments", level = 57, minLevel = 55, faction = "Horde", starts = { "npc:11057" }, ends = { "npc:11057" } },
    [5514] = { name = "Mold Rhymes With...", level = 57, minLevel = 55, faction = "Horde", starts = { "npc:11057" }, ends = { "npc:5411" } },
    [5802] = { name = "Fire Plume Forged", level = 57, minLevel = 55, faction = "Horde", starts = { "npc:5411" }, ends = { "npc:11057" } },
    [5804] = { name = "Araj's Scarab", level = 60, minLevel = 55, faction = "Horde", starts = { "npc:11057" }, ends = { "npc:11057" } },
    [5511] = { name = "The Key to Scholomance", level = 60, minLevel = 55, faction = "Horde", rewards = { 13704 }, starts = { "npc:11057" }, ends = { "npc:11057" } },
}
local attunePlaces = {
    -- Scholomance: aparicion de AzerothCore (creature.sql) pasada a la zona con UiMapAssignment
    ["npc:10837"] = { npcID = 10837, name = "High Executor Derrington", mapID = 1422, x = 26.5, y = 56.0 },
    ["npc:11056"] = { npcID = 11056, name = "Alchemist Arbington", mapID = 1422, x = 42.7, y = 83.8 },
    ["npc:11057"] = { npcID = 11057, name = "Apothecary Dithers", mapID = 1422, x = 26.7, y = 56.3 },
    ["npc:5411"] = { npcID = 5411, name = "Krinkle Goodsteel", mapID = 1446, x = 51.5, y = 28.8 },
    ["npc:10182"] = { npcID = 10182, name = "Rexxar", mapID = 1443, x = 49.2, y = 50.2 },
    ["npc:10321"] = { npcID = 10321, name = "Emberstrife", mapID = 1445, x = 56.6, y = 87.6 },
    ["npc:10929"] = { npcID = 10929, name = "Haleh", mapID = 1452, x = 54.4, y = 51.2 },
    ["npc:11872"] = { npcID = 11872, name = "Myranda the Hag", mapID = 1422, x = 50.8, y = 77.8 },
    ["npc:12580"] = { npcID = 12580, name = "Reginald Windsor", mapID = 1453, x = 60.2, y = 51.6 },
    ["npc:1748"] = { npcID = 1748, name = "Highlord Bolvar Fordragon", mapID = 1453, x = 77.4, y = 18.8 },
    ["npc:344"] = { npcID = 344, name = "Magistrate Solomon", mapID = 1433, x = 29.8, y = 44.6 },
    ["npc:4949"] = { npcID = 4949, name = "Thrall", mapID = 1454, x = 32, y = 37.8 },
    ["npc:9023"] = { npcID = 9023, name = "Marshal Windsor", inside = true },
    ["npc:9077"] = { npcID = 9077, name = "Warlord Goretooth", mapID = 1418, x = 5.8, y = 47.6 },
    ["npc:9560"] = { npcID = 9560, name = "Marshal Maxwell", mapID = 1428, x = 84.6, y = 68.8 },
    ["npc:9562"] = { npcID = 9562, name = "Helendis Riverhorn", mapID = 1428, x = 85.6, y = 69 },
}
for key, place in pairs(attunePlaces) do
    if not ns.Places[key] then ns.Places[key] = place end
end
for id, q in pairs(attuneQuests) do
    if not ns.Quests[id] then ns.Quests[id] = q end
end
