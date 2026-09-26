local _, ns = ...

-- Mazmorras de WoW Forever, independientes del idioma.
-- name: nombre en ingles, solo de respaldo. El nombre que se ve lo da el juego
-- en el idioma del cliente con GetRealZoneText(instanceID).
-- instanceID: ID de instancia (el 8.o valor de GetInstanceInfo() dentro). Las
-- nuevas, de wowforevertalents.com; sin el aun: Alcaz, Blackmaw, Krol'dok,
-- Ciudad Sumergida y Terraza del Modelador.
-- part: las que comparten instancia (Cumbre de Roca Negra, y las alas del
-- Monasterio Escarlata, La Masacre y Stratholme); se le anade "(<parte>)".
-- minLevel / maxLevel: de foreverchanges.pro.
-- entrance: { mapID = uiMapID, x = 0-100, y = 0-100 }. Todas en nil: la entrada
-- la da el propio mapa del juego (C_EncounterJournal.GetDungeonEntrancesForMap,
-- ver Core/Waypoints.lua). Solo si el juego no la tuviera: /dqa entrance <clave>.
-- quests: IDs de mision (ver Data/Quests.lua), primero las del cliente de
-- Forever (foreverchanges) y luego las que solo estaban en AtlasQuest.

ns.Dungeons = {
    { key = "ALCAZ", name = "Alcaz Prison", instanceID = nil, minLevel = 48, maxLevel = 53, isForever = true, faction = "Both",
        quests = {} },
    { key = "BFD", name = "Blackfathom Deeps", instanceID = 48, minLevel = 24, maxLevel = 32, isForever = false, faction = "Both",
        quests = { 971, 6564, 6563, 6565, 1275, 1200, 6561, 1199, 6921, 1198, 1740 } },
    { key = "BLACKMAW", name = "Blackmaw Hold", instanceID = nil, minLevel = 55, maxLevel = 60, isForever = true, faction = "Both",
        quests = {} },
    { key = "BRD", name = "Blackrock Depths", instanceID = 230, minLevel = 52, maxLevel = 60, isForever = false, faction = "Both",
        quests = { 4083, 3802, 4081, 4136, 4242, 7201, 3907, 4263, 4003, 4004, 4082, 4201, 4126, 4134, 4123, 4286, 4264, 4282, 4322, 4362, 4363, 4024, 4132, 4121, 4063, 9015, 7604, 3906, 3981, 4241, 4262, 4341, 7848 } },
    { key = "DALARAN", name = "City of Dalaran", instanceID = 2959, minLevel = 28, maxLevel = 33, isForever = true, faction = "Both",
        quests = {} },
    { key = "DM_E", name = "Dire Maul (East)", instanceID = 429, minLevel = 54, maxLevel = 60, isForever = false, faction = "Both", part = "EAST",
        quests = { 7488, 7489, 7441, 7499, 7505, 7498, 7502, 7504, 7500, 7506, 7503, 7501, 7462, 7877, 1318, 5528, 8948, 8949, 8950, 8967, 8990, 7463, 7507, 7508, 1193, 5526, 7481, 7482, 7483, 7484, 7485, 7581, 7631, 7703 } },
    { key = "DM_N", name = "Dire Maul (North)", instanceID = 429, minLevel = 56, maxLevel = 60, isForever = false, faction = "Both", part = "NORTH",
        quests = { 7499, 7505, 7498, 7502, 7504, 7500, 7506, 7503, 7501, 5518, 7462, 7877, 1318, 5525, 5528, 8948, 8949, 8950, 8967, 8990, 7507, 7508 } },
    { key = "DM_W", name = "Dire Maul (West)", instanceID = 429, minLevel = 56, maxLevel = 60, isForever = false, faction = "Both", part = "WEST",
        quests = { 7499, 7505, 7498, 7502, 7504, 7500, 7506, 7503, 7501, 7461, 7462, 7877, 1318, 5528, 8948, 8949, 8950, 8967, 8990, 7507, 7508 } },
    { key = "EXCAVATION", name = "Excavation Site", instanceID = 2998, minLevel = 24, maxLevel = 29, isForever = true, faction = "Both",
        quests = {} },
    { key = "GNOMER", name = "Gnomeregan", instanceID = 90, minLevel = 29, maxLevel = 38, isForever = false, faction = "Both",
        quests = { 2922, 2926, 2928, 2962, 2843, 2904, 2924, 2930, 2951, 2952, 2841, 2929, 2945, 2947, 2949 } },
    { key = "THANES", name = "Hall of Thanes", instanceID = 3065, minLevel = 13, maxLevel = 18, isForever = true, faction = "Both",
        quests = { 96393, 96394, 96395, 96403, 98423 } },
    { key = "KROLDOK", name = "Krol'dok Stronghold", instanceID = nil, minLevel = 40, maxLevel = 45, isForever = true, faction = "Both",
        quests = {} },
    { key = "LBRS", name = "Lower Blackrock Spire", instanceID = 229, minLevel = 55, maxLevel = 60, isForever = false, faction = "Both", part = "LOWER",
        quests = { 4788, 4982, 5001, 4983, 4862, 4729, 5002, 4701, 4724, 5047, 5089, 5081, 4866, 6569, 5127, 4867, 4903, 4765, 4764, 4735, 4734, 4742, 4743, 5160, 8995, 8966, 8989, 4981, 5103, 5306 } },
    { key = "MARA", name = "Maraudon", instanceID = 349, minLevel = 46, maxLevel = 55, isForever = false, faction = "Both",
        quests = { 7068, 7070, 7067, 7028, 7029, 7041, 7044, 7046, 7064, 7065, 7066 } },
    { key = "RFC", name = "Ragefire Chasm", instanceID = 389, minLevel = 13, maxLevel = 18, isForever = false, faction = "Horde",
        quests = { 5723, 5728, 5724, 5761, 5725, 5722 } },
    { key = "RFD", name = "Razorfen Downs", instanceID = 129, minLevel = 37, maxLevel = 46, isForever = false, faction = "Both",
        quests = { 6626, 6521, 6522, 3525, 3523, 3341, 3636 } },
    { key = "RFK", name = "Razorfen Kraul", instanceID = 47, minLevel = 29, maxLevel = 38, isForever = false, faction = "Both",
        quests = { 1221, 1144, 1142, 1102, 1101, 1109, 1701, 1838 } },
    { key = "LORDAERON", name = "Ruins of Lordaeron", instanceID = 2999, minLevel = 15, maxLevel = 20, isForever = true, faction = "Both",
        quests = { 92422, 92421, 92401, 95216, 97288, 95204, 95250, 95195, 92415, 95189 } },
    { key = "SM_ARM", name = "Scarlet Monastery (Armory)", instanceID = 189, minLevel = 36, maxLevel = 44, isForever = false, faction = "Both", part = "ARMORY",
        quests = { 1051, 1160, 1049, 1050, 1113, 1048, 1053, 1951 } },
    { key = "SM_CATH", name = "Scarlet Monastery (Cathedral)", instanceID = 189, minLevel = 38, maxLevel = 46, isForever = false, faction = "Both", part = "CATHEDRAL",
        quests = { 1051, 1160, 1049, 1050, 1113, 1048, 1053 } },
    { key = "SM_GY", name = "Scarlet Monastery (Graveyard)", instanceID = 189, minLevel = 30, maxLevel = 38, isForever = false, faction = "Both", part = "GRAVEYARD",
        quests = { 1051, 1160, 1049, 1050, 1113 } },
    { key = "SM_LIB", name = "Scarlet Monastery (Library)", instanceID = 189, minLevel = 33, maxLevel = 41, isForever = false, faction = "Both", part = "LIBRARY",
        quests = { 1051, 1160, 1049, 1050, 1113, 1048, 1053 } },
    { key = "SCHOLO", name = "Scholomance", instanceID = 289, minLevel = 58, maxLevel = 60, isForever = false, faction = "Both",
        quests = { 5341, 5343, 5529, 5382, 5384, 5515, 5531, 4771, 5466, 8969, 8992, 5582, 7629, 7647, 8258 } },
    { key = "SFK", name = "Shadowfang Keep", instanceID = 33, minLevel = 22, maxLevel = 30, isForever = false, faction = "Both",
        quests = { 1013, 1098, 1014, 1654, 1740 } },
    { key = "SHAPERS", name = "Shaper's Terrace", instanceID = nil, minLevel = 58, maxLevel = 60, isForever = true, faction = "Both",
        quests = {} },
    { key = "STRAT_LIVE", name = "Stratholme (Main Gate)", instanceID = 329, minLevel = 58, maxLevel = 60, isForever = false, faction = "Both", part = "MAIN_GATE",
        quests = { 5848, 5125, 5243, 5213, 5251, 5214, 5282, 5262, 5463, 8945, 8968, 8991, 5305, 5307, 7622, 9257 } },
    { key = "STRAT_UD", name = "Stratholme (Service Gate)", instanceID = 329, minLevel = 58, maxLevel = 60, isForever = false, faction = "Both", part = "SERVICE_GATE",
        quests = { 5848, 5263, 5125, 5243, 5213, 5212, 5214, 5282, 6163, 5463, 8945, 8968, 8991 } },
    { key = "ST", name = "Sunken Temple", instanceID = 109, minLevel = 50, maxLevel = 60, isForever = false, faction = "Both",
        quests = { 1445, 1446, 3528, 1475, 3446, 3447, 4146, 3373, 3380, 3445, 4143, 8232, 8236, 8253, 8257, 8413, 8418, 8422, 8425, 9053 } },
    { key = "DM", name = "The Deadmines", instanceID = 36, minLevel = 17, maxLevel = 26, isForever = false, faction = "Both",
        quests = { 214, 168, 166, 167, 2040, 373, 1654 } },
    { key = "DROWNED", name = "The Drowned City", instanceID = nil, minLevel = 35, maxLevel = 40, isForever = true, faction = "Both",
        quests = {} },
    { key = "STOCKS", name = "The Stockade", instanceID = 34, minLevel = 24, maxLevel = 32, isForever = false, faction = "Alliance",
        quests = { 391, 386, 377, 387, 388, 378 } },
    { key = "ULDA", name = "Uldaman", instanceID = 70, minLevel = 41, maxLevel = 51, isForever = false, faction = "Both",
        quests = { 2418, 704, 709, 1360, 2342, 722, 2240, 1139, 17, 2202, 2199, 2283, 2198, 2338, 2340, 2339, 2204, 2361, 2201, 2341, 2279, 2280, 721, 1192, 1956, 2200, 2278, 2284, 2318, 2398 } },
    { key = "UBRS", name = "Upper Blackrock Spire", instanceID = 229, minLevel = 59, maxLevel = 60, isForever = false, faction = "Both", part = "UPPER",
        quests = { 4788, 6502, 4982, 5001, 4983, 4862, 4729, 5002, 6602, 5047, 4974, 5102, 4866, 5127, 4765, 4764, 4735, 4734, 4743, 4768, 5160, 8995, 8966, 8989, 6569, 6821, 7761, 8994 } },
    { key = "WC", name = "Wailing Caverns", instanceID = 43, minLevel = 17, maxLevel = 24, isForever = false, faction = "Both",
        quests = { 914, 1486, 1491, 962, 959, 1487, 6981 } },
    { key = "ZF", name = "Zul'Farrak", instanceID = 209, minLevel = 44, maxLevel = 54, isForever = false, faction = "Both",
        quests = { 2865, 3042, 2846, 2768, 2991, 3527, 2770, 2936 } },
}
