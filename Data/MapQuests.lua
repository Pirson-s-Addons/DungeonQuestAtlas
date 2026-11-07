local _, ns = ...

-- Sitios de las misiones dentro de las mazmorras, sobre los planos de Data/Maps.lua:
-- [planta] = { { x, y, nombre, { questID, acciones..., item = itemID }, ... } } (x, y de 0 a 1; la
-- planta en el orden de Data/Maps.lua). Acciones: "start", "end", "loot", "use", "explore".
-- Lo pinta UI/DungeonMap.lua: ! donde empieza, ? donde se entrega y una gema donde hay que hacer algo.
-- Posiciones: la aparicion en la base de datos de Classic (CMaNGOS) pasada a la planta con
-- UiMapAssignment. Los que caen sobre la cara de un jefe, un poco al lado.

ns.MapQuests = {
    ULDA = {
        [1] = {
            { 0.207, 0.341, "Tablet of Will", { 1139, "loot", item = 5824 } },
            { 0.207, 0.341, "Shadowforge Cache", { 2201, "loot", item = 7669 }, { 2339, "loot", item = 7669 } },
            { 0.533, 0.638, "Remains of a Paladin", { 2200, "end" }, { 2201, "start" }, { 2284, "end" }, { 2318, "start" } },
            { 0.316, 0.719, "", { 2240, "explore" } },
            { 0.638, 0.948, "Baelog", { 2398, "end" }, { 2240, "start" } },
            { 0.638, 0.948, "Conspicuous Urn", { 2201, "loot", item = 7671 }, { 2339, "loot", item = 7671 } },
        },
        [2] = {
            { 0.501, 0.331, "The Discs of Norgannon", { 2278, "start", "end" }, { 2279, "start" }, { 2280, "start" } },
        },
    },
    DM_N = {
        [1] = {
            { 0.217, 0.526, "Ogre Tannin Basket", { 5518, "loot", item = 18240 } },
            { 0.321, 0.599, "Knot Thimblejack", { 5525, "start", "end" }, { 5518, "start", "end" } },
        },
    },
    BRD = {
        [1] = {
            { 0.509, 0.844, "Commander Gor'shak", { 3982, "start", "end" }, { 3981, "end" }, { 4001, "start" } },
            { 0.509, 0.844, "Kharan Mighthammer", { 4341, "end" }, { 4342, "start", "end" }, { 4361, "start" } },
            { 0.532, 0.928, "Marshal Windsor", { 4322, "start" }, { 4241, "end" }, { 4242, "start" }, { 4264, "end" }, { 4282, "start", "end" } },
        },
        [2] = {
            { 0.551, 0.331, "Spectral Chalice", { 4083, "start", "end" } },
            { 0.693, 0.37, "Core Fragment", { 7848, "loot", item = 18412 } },
            { 0.514, 0.591, "Mistress Nagmara", { 4201, "start", "end" } },
            { 0.514, 0.591, "Lokhtos Darkbargainer", { 7604, "end" } },
            { 0.514, 0.591, "Private Rocknot", { 4295, "start", "end" } },
            { 0.632, 0.732, "Heart of the Mountain", { 4123, "loot", item = 11309 } },
            { 0.632, 0.732, "Dark Coffer", { 4083, "loot", item = 7910 } },
            { 0.615, 0.95, "Monument of Franclorn Forgewright", { 3802, "end" } },
        },
    },
    SM_GY = {
        [1] = {
            { 0.719, 0.514, "Vorrel Sengutz", { 1051, "start" } },
        },
    },
    STRAT_UD = {
        [1] = {
            { 0.695, 0.146, "Scourge Data", { 5213, "loot", item = 13176 } },
            { 0.414, 0.258, "Menethil's Gift", { 5463, "end" } },
            { 0.803, 0.463, "Scourge Data", { 5213, "loot", item = 13176 } },
            { 0.53, 0.52, "Scourge Data", { 5213, "loot", item = 13176 } },
            { 0.678, 0.729, "Aurius", { 5122, "start", "end" }, { 5125, "start", "end" } },
        },
    },
    GNOMER = {
        [1] = {
            { 0.427, 0.66, "The Sparklematic 5200", { 2951, "start", "end" }, { 2945, "end" }, { 2947, "start" }, { 2949, "start" } },
        },
        [4] = {
            { 0.354, 0.177, "Thermaplugg's Safe", { 2841, "loot", item = 9153 } },
        },
    },
    RFD = {
        [1] = {
            { 0.775, 0.152, "Belnistrasz", { 3525, "start", "end" }, { 3523, "start", "end" } },
            { 0.469, 0.223, "Belnistrasz's Brazier", { 3525, "end" } },
        },
    },
    STRAT_LIVE = {
        [1] = {
            { 0.31, 0.408, "Malor's Strongbox", { 5122, "loot", item = 12845 } },
            { 0.307, 0.818, "Scarlet Archive", { 5251, "use" } },
            { 0.307, 0.818, "Unfinished Painting", { 5848, "loot", item = 14679 } },
        },
    },
    LORDAERON = {
        [1] = {
            { 0.612, 0.272, "Captain Truman", { 95250, "start", "end" } },
        },
    },
    RFK = {
        [1] = {
            { 0.364, 0.324, "Willix the Importer", { 1144, "start", "end" } },
            { 0.364, 0.324, "Heralath Fallowbrook", { 1142, "start" } },
        },
    },
    BFD = {
        [1] = {
            { 0.329, 0.412, "Pitted Iron Chest", { 971, "loot", item = 5359 } },
            { 0.208, 0.753, "Argent Guard Thaelrid", { 1198, "end" }, { 1200, "start" }, { 6561, "start" } },
        },
        [2] = {
            { 0.406, 0.804, "Fathom Stone", { 6921, "loot", item = 16762 } },
        },
    },
    RFC = {
        [1] = {
            { 0.618, 0.387, "Maur Grimtotem", { 5724, "start" }, { 5722, "end" } },
        },
    },
    SFK = {
        [1] = {
            { 0.336, 0.55, "Jordan's Hammer", { 1654, "loot", item = 6895 } },
            { 0.558, 0.622, "Deathstalker Vincent", { 1098, "end" } },
        },
        [7] = {
            { 0.472, 0.793, "The Book of Ur", { 1013, "loot", item = 6283 } },
        },
    },
    SM_LIB = {
        [1] = {
            { 0.593, 0.122, "Mythology of the Titans", { 1050, "loot", item = 5536 } },
            { 0.822, 0.14, "Compendium of the Fallen", { 1049, "loot", item = 5535 } },
            { 0.454, 0.322, "Beginnings of the Undead Threat", { 1160, "loot", item = 5861 } },
        },
    },
    ST = {
        [1] = {
            { 0.501, 0.358, "Altar of Hakkar", { 3446, "end" } },
            { 0.501, 0.477, "Idol of Hakkar", { 3447, "end" } },
            { 0.719, 0.803, "Essence Font", { 3373, "end" } },
        },
    },
    DM_W = {
        [1] = {
            { 0.484, 0.538, "Shen'dralar Ancient", { 7461, "start", "end" } },
        },
        [3] = {
            { 0.747, 0.113, "Lorekeeper Javon", { 7506, "end" }, { 7504, "end" }, { 7505, "end" } },
            { 0.802, 0.114, "Lorekeeper Mykos", { 7503, "end" }, { 7501, "end" }, { 7502, "end" } },
            { 0.737, 0.171, "Lorekeeper Lydros", { 7463, "start", "end" }, { 7507, "end" }, { 7483, "start", "end" }, { 7484, "start", "end" }, { 7485, "start", "end" } },
            { 0.845, 0.23, "Lorekeeper Kildrath", { 7500, "end" }, { 7498, "end" }, { 7499, "end" } },
            { 0.573, 0.276, "The Prince's Chest", { 7703, "loot", item = 18336 } },
        },
    },
}
