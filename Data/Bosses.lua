local _, ns = ...

-- Jefes y botin de cada mazmorra (clave de Data/Dungeons.lua), en orden de combate.
-- De foreverchanges.pro/dungeons, que lo lee del cliente de WoW Forever 1.60.1
-- (build 70009); quien suelta que y la probabilidad son las de Classic.
-- name: en ingles, de respaldo. npcID (Wowhead Forever, por nombre y nivel):
-- con el, el tooltip del juego da el nombre en el idioma del cliente.
-- kind: nil (jefe), "rare" (raro), "object" (cofre u objeto), "trash" (bichos normales),
-- "recipes" (recetas y patrones nuevos de Forever, la ultima; from = jefes que la sueltan,
-- por su posicion en la lista, de mas a menos probable). Las recetas, en el botin de
-- cada jefe con su probabilidad: Wowhead Forever (veces que cayo / veces saqueado).
-- display: CreatureDisplayID para el retrato. level: nivel del jefe.
-- optional = true: solo sale tras una mision; no cuenta para dar la partida por terminada (Core/RunLog.lua).
-- En loot, quest = true: objeto de mision que suelta ese jefe (su hoja de mision lleva hasta aqui).
-- members: grupo de varios (los seis trolls del altar del Templo Sumergido, FDJ 2.0.6): cada uno se
-- tacha al morir y el grupo, con todos. npcID de Wowhead Forever.
-- En los bichos (kind "trash"): mobs = "A / B", los que lo sueltan; all = true, cualquiera (FDJ 2.0.6;
-- nombres en ingles, de respaldo). Salen en el tooltip del objeto.
-- oneOf: solo sale uno del grupo por partida (los retadores del Anillo de la Ley): con uno basta.
-- pair: el otro jefe del mismo encuentro (Gyth y Rend): el final del encuentro tacha a los dos.
-- faction: solo la puede atacar esa faccion (los enanos perdidos de Uldaman son amistosos para la Alianza).
-- loot = { { itemID, probabilidad en % (si se conoce) }, ... }
-- Los objetos nuevos de Forever en mazmorras clasicas (sin probabilidad) y los seis cascos de
-- cuero compartidos por varios jefes: foreverchanges.pro, revisado el 17-10-2026.
-- Nombre, icono y calidad de cada objeto los da el cliente en su idioma.

ns.Bosses = {
    -- Abierta desde el 07-11-2026: jefes en el orden del juego, npcID y retratos de Wowhead Forever; botin visto hasta ahora.
    -- probable = true: de la misma tanda del cliente (276732-276746 y el conjunto Defias Enforcer), sin ver caer aun.
    ALCAZ = {
        { name = "Overseer Wrex", npcID = 255391, level = 50, loot = { { 276733 }, { 276734 }, { 276732 } } },
        { name = "The Questioner", npcID = 256236, display = 140092, level = 51, loot = { { 276742 }, { 276743 }, { 276741 }, { 274029, quest = true } } },
        { name = "Tidemistress Ca'zass", npcID = 255997, display = 4973, level = 50, loot = { { 276735 }, { 276736 }, { 276737, probable = true }, { 273883, quest = true } } },
        { name = "Katerina the Cleaner", npcID = 257016, display = 2317, level = 52, loot = { { 276739 }, { 276738 }, { 276740 } } },
        { name = "Blazeroar", npcID = 255702, display = 6374, level = 53, loot = { { 276890, quest = true }, { 276744 }, { 276745 }, { 276746 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 287021 }, { 287019 }, { 287020 }, { 287018 }, { 287017 }, { 287022 }, { 287023 }, { 287024 }, { 287025, mobs = "Strashaz Enchantress" } } },
    },
    -- Abierta desde el 07-11-2026: jefes en el orden del juego. Botin de sus jefes visto sin ID publico aun: no se pone
    -- hasta tenerlo; el de los bichos, Satyr's Touch (Wowhead Forever).
    BLACKMAW = {
        { name = "Impaan the Imprisoner", npcID = 247206, display = 130432, level = 57, loot = { { 280056 }, { 280058 }, { 280057 } } },
        { name = "Bonesnout the Unbroken", npcID = 247198, display = 130427, level = 58, loot = { { 280060 }, { 280059 }, { 280061 }, { 249696, quest = true } } },
        { name = "Moontouched Wanderer", npcID = 269104, display = 12235, level = 55, kind = "rare", loot = { { 280080 }, { 280079 } } },
        { name = "Gortek the Apprentice", npcID = 269111, display = 145808, level = 55, kind = "rare", loot = { { 280077 }, { 280078 } } },
        { name = "Tunnelweb Matriarch", npcID = 250034, level = 55, kind = "rare", loot = { { 280085 }, { 280086 } } },
        { name = "Withermaw", npcID = 247195, display = 140708, level = 58, loot = { { 280064 }, { 280062 }, { 280063 }, { 249697, quest = true } } },
        { name = "Elder Shaman Bloodmane", npcID = 247209, display = 130440, level = 59, loot = { { 280068 }, { 280069 }, { 280070 }, { 276893, quest = true }, { 286415, quest = true } } },
        { name = "Blackmaw Behemoth", npcID = 247207, display = 130436, level = 59, loot = { { 280065 }, { 280066 }, { 280067 } } },
        { name = "Unbound Spirit", npcID = 247231, display = 131644, level = 59, loot = { { 280071 }, { 280073 }, { 280072 } } },
        { name = "Varrox Bleakhoof", npcID = 247234, display = 130447, level = 60, loot = { { 280074 }, { 280075 }, { 280076 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 287036, mobs = "Legashi Ritualist" }, { 287032 }, { 287034 }, { 287028 }, { 251453, mobs = "Legashi Summoner" }, { 287029, mobs = "Blackmaw Berserker / Blackmaw Thrall" }, { 287030, mobs = "Legashi Subjugator" }, { 287033, mobs = "Blackmaw Devotee / Blackmaw Berserker / Legashi Slayer" }, { 252893 }, { 287031 }, { 287035 } } },
        -- Raro de Forever en la entrada de la cueva, dentro de la mazmorra.
        { name = "Sabella No-Eyes", npcID = 269151, kind = "rare", loot = { { 280083 }, { 280084 } } },
        { name = "Mopes", npcID = 247412, display = 130499, kind = "rare", loot = { { 280082 }, { 280081 } } }, -- FDJ 2.1.6 (Wowhead Forever)
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 252893, from = { 11 } }, { 251453, from = { 11 } } } },
    },
    -- Lo visto caer hasta ahora (07-11-2026). probable = true: objetos de la misma tanda del
    -- cliente que nadie ha visto caer aun, a cada jefe por orden de ID y nivel (sin confirmar).
    DROWNED = {
        { name = "Zul'Alai", npcID = 258905, display = 144475, level = 37, loot = { { 274600 }, { 274599 }, { 274598 } } },
        { name = "Var'Taka", npcID = 258924, display = 144487, level = 38, loot = { { 274602 }, { 274601 }, { 274613 } } },
        { name = "Captain Dreadrise", npcID = 260042, display = 142144, level = 38, loot = { { 274604 }, { 274605 }, { 274603 } } },
        { name = "Deathless Marrow", npcID = 269586, display = 142245, level = 39, loot = { { 274606 }, { 274614 }, { 274607, probable = true } } },
        { name = "Primeval Elemental", npcID = 273738, display = 129945, level = 38, loot = { { 274612 }, { 274611 }, { 274615 } } },
        { name = "Gill", npcID = 264177, display = 144023, kind = "rare", level = 38, loot = { { 286646 }, { 286649 } } },
        { name = "Umbra", npcID = 264172, kind = "rare", level = 38, loot = { { 286662 }, { 286658, probable = true } } },
        { name = "\"Pyromancer\" Braxton", npcID = 260468, display = 142457, kind = "rare", level = 38, loot = { { 286650 }, { 286651 } } },
        { name = "Min'loth the Serpent", npcID = 260274, display = 142322, level = 40, loot = { { 274610 }, { 274608 }, { 274609 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 287002, mobs = "Risen Sentry" }, { 286997 }, { 287005, mobs = "Risen Sentry / Champion of the Deep / Brinescale Sorceress / Makrura Snapper" }, { 286998 }, { 286999 }, { 287000 }, { 287001 }, { 287003 }, { 287004 }, { 287006 } } },
    },
    -- Lo visto caer hasta ahora (08-11-2026). El resto del conjunto Krol'dok Warplate (el peto lo suelta Nar'gurk):
    -- sin saber quien lo suelta.
    KROLDOK = {
        { name = "Slavecrusher Grox", npcID = 258966, display = 141217, level = 42, loot = { { 274996 }, { 274997 }, { 274995 }, { 273101 } } },
        { name = "Twilight Commander Zarmok", npcID = 258972, display = 141219, level = 43, loot = { { 275000 }, { 274998 }, { 274999 } } },
        { name = "War Handler Ashka", npcID = 259281, display = 141443, level = 43, loot = { { 275001 }, { 275002 }, { 275003 } } },
        { name = "Nar'gurk", npcID = 258964, display = 141215, level = 44, loot = { { 275005 }, { 275004 }, { 275006 }, { 267104, quest = true } } },
        { name = "Bossman Toof", npcID = 264773, display = 14424, level = 42, loot = { { 286430 }, { 286429 }, { 286428 } } },
        { name = "Overlord Mugg", npcID = 258968, display = 141218, level = 45, loot = { { 275009 }, { 275007 }, { 275010 }, { 275008, probable = true }, { 267086, quest = true } } },
        { name = "Kroog", npcID = 262716, kind = "rare", level = 41, loot = { { 279863 }, { 279857 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 287014, probable = true }, { 287012, probable = true }, { 287013, probable = true }, { 287008 }, { 287010 }, { 287007, mobs = "Twilight Grunt / Twilight Lieutenant / Redridge Prisoner" }, { 287009 }, { 287011 }, { 287015 }, { 287016 } } },
    },
    -- Abierta (09-11-2026). Orden sin confirmar, salvo Nanaya al final. Sin dato de la sala de cada jefe.
    SHAPERS = {
        { name = "Titanosaur", npcID = 253201, display = 142989, level = 61, loot = { { 280009 }, { 280011 }, { 280010 } } },
        { name = "Venomridge", npcID = 261813, display = 144511, level = 61, loot = { { 280015 }, { 280017 }, { 280016 } } },
        { name = "Thunderhoof", npcID = 261812, display = 144514, level = 61, loot = { { 280018 }, { 280020 }, { 280019 } } },
        { name = "Direhorn Matriarch", npcID = 262127, display = 144515, level = 61, loot = { { 280045 }, { 280022 }, { 280021 } } },
        { name = "Cinder", npcID = 261974, level = 61, loot = { { 280029 }, { 280028 } } },
        { name = "Bolt", npcID = 262081, display = 143063, level = 62, loot = { { 280031 }, { 280032 } } },
        { name = "Snowtalon", npcID = 262297, level = 62, loot = { { 280026 } } },
        { name = "Vitrix", npcID = 272561, display = 147098, level = 62, loot = { { 280031 }, { 280027 }, { 280028 }, { 280026 }, { 280029 } } }, -- FDJ 2.1.0: lista entera de Wowhead
        { name = "Izha'Rel and Tor'Rel", npcID = 253218, display = 143040, level = 61, loot = { { 280014 }, { 280013 }, { 280012 } } },
        { name = "Nanaya", npcID = 261809, display = 143832, level = 62, loot = { { 280023 }, { 280025 }, { 280024 }, { 273128 }, { 273116, 3.3 } } },
        { name = "King Op", npcID = 261993, display = 143129, kind = "rare", loot = { { 280027 }, { 280026 } } }, -- FDJ 2.1.6 (Wowhead Forever)
        { name = "Trash mobs", kind = "trash", loot = { { 287037 }, { 287044, mobs = "Stegodon Young" }, { 287045, mobs = "Ravasaur Juvenile" }, { 287038 }, { 287039 }, { 287040 }, { 287041 }, { 287042 }, { 287043 }, { 287046 }, { 252938, mobs = "Azurepetal Trapper / Emerald Flayer" } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 273116, 3.3, from = { 10 } }, { 273128, from = { 10 } } } },
    },
    BFD = {
        { name = "Ghamoo-ra", npcID = 4887, display = 5027, level = 25, loot = { { 6907, 37.3 }, { 6908, 56.4 }, { 273839 }, { 251380, 0.03 }, { 251381, 0.02 }, { 251382, 0.08 }, { 252798, 0.05 }, { 252800, 0.03 }, { 252801, 0.08 }, { 252803, 0.02 }, { 253938, 0.03 }, { 253940, 0.05 }, { 253942, 0.03 }, { 253944, 0.02 }, { 253946, 0.03 }, { 251384 }, { 251383 }, { 251345 }, { 251346 }, { 251347 }, { 251348 }, { 251349 }, { 252792 }, { 252793 }, { 252794 }, { 252795 }, { 252796 }, { 252797 }, { 253948 } } },
        { name = "Lady Sarevess", npcID = 4831, display = 4979, level = 25, loot = { { 888, 36.9 }, { 3078, 19.6 }, { 11121, 38.8 }, { 251380, 0.02 }, { 251381, 0.02 }, { 251382, 0.08 }, { 251383, 0.04 }, { 252798, 0.06 }, { 252799, 0.04 }, { 252800, 0.02 }, { 252803, 0.02 }, { 253940, 0.04 }, { 253942, 0.06 }, { 253944, 0.06 }, { 253946, 0.02 }, { 253948, 0.04 }, { 252802 }, { 251384 }, { 253938 }, { 251345 }, { 251346 }, { 251347 }, { 251348 }, { 251349 }, { 252792 }, { 252793 }, { 252794 }, { 252795 }, { 252796 }, { 252797 } } },
        { name = "Gelihast", npcID = 6243, display = 1773, level = 26, loot = { { 6906, 44.3 }, { 6905, 47.4 }, { 1470, 10.7 }, { 251375, 0.05 }, { 251377, 0.02 }, { 252820, 0.04 }, { 252821, 0.02 }, { 252823, 0.02 }, { 252824, 0.02 }, { 252825, 0.05 }, { 253976, 0.05 }, { 253978, 0.02 }, { 253980, 0.07 }, { 253982, 0.04 }, { 273840 }, { 273141 }, { 252512 }, { 252515 }, { 252456 }, { 252513 }, { 252514 }, { 252455 }, { 251376 }, { 251378 }, { 251379 }, { 252822 }, { 253986 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253984 } } },
        { name = "Lorgus Jett", npcID = 12902, display = 12822, level = 26, loot = { { 273843 }, { 273842 }, { 251376, 0.07 }, { 252820, 0.07 }, { 252822, 0.07 }, { 252823, 0.15 }, { 253976, 0.07 }, { 253978, 0.15 }, { 253980, 0.07 }, { 253982, 0.15 }, { 253984, 0.15 }, { 273841 }, { 252455 }, { 252513 }, { 252512 }, { 252456 }, { 251377 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253986 } } },
        { name = "Baron Aquanis", npcID = 12876, display = 110, level = 28, loot = { { 16782, 92.8 }, { 252821, 0.04 }, { 252822, 0.04 }, { 252825, 0.04 }, { 253978, 0.04 }, { 253980, 0.04 }, { 252456 } } },
        { name = "Twilight Lord Kelris", npcID = 4832, display = 4939, level = 27, loot = { { 1155, 49.6 }, { 6903, 33.5 }, { 273846 }, { 251376, 0.01 }, { 251378, 0.04 }, { 251379, 0.01 }, { 252820, 0.03 }, { 252821, 0.01 }, { 252822, 0.03 }, { 252823, 0.01 }, { 252824, 0.04 }, { 252825, 0.04 }, { 253976, 0.01 }, { 253980, 0.01 }, { 253982, 0.01 }, { 253984, 0.04 }, { 253986, 0.01 }, { 252456 }, { 252513 }, { 252455 }, { 252515 }, { 252512 }, { 251377 }, { 251375 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253978 } } },
        { name = "Old Serra'kis", npcID = 4830, display = 1816, level = 26, loot = { { 6901, 39.3 }, { 6904, 21.2 }, { 6902, 33.6 }, { 251375, 0.05 }, { 251376, 0.03 }, { 251377, 0.03 }, { 251378, 0.03 }, { 251379, 0.05 }, { 252820, 0.05 }, { 252822, 0.03 }, { 252825, 0.03 }, { 253978, 0.08 }, { 253982, 0.03 }, { 252455 }, { 252456 }, { 253986 }, { 252823 }, { 252821 }, { 252824 }, { 253976 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253980 }, { 253984 } } },
        { name = "Aku'mai", npcID = 4829, display = 2837, level = 28, loot = { { 6911, 38.6 }, { 6910, 35.8 }, { 6909, 20.2 }, { 251375, 0.02 }, { 251376, 0.07 }, { 251377, 0.14 }, { 251378, 0.12 }, { 251379, 0.05 }, { 252820, 0.05 }, { 252821, 0.05 }, { 252823, 0.02 }, { 252824, 0.07 }, { 253980, 0.02 }, { 253984, 0.09 }, { 253986, 0.02 }, { 252455 }, { 252512 }, { 252515 }, { 252456 }, { 252514 }, { 252822 }, { 253982 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 1486 }, { 3416 }, { 1491 }, { 3414 }, { 1454 }, { 1481 }, { 2567, 0.1 }, { 3413 }, { 3417 }, { 3415 }, { 2271, 0.1 }, { 2034, 1.8 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 252823, 0.15, from = { 4, 8, 3, 6, 7 } }, { 253978, 0.15, from = { 4, 7, 5, 3, 6, 8 } }, { 253982, 0.15, from = { 4, 3, 7, 6, 8 } }, { 253984, 0.15, from = { 4, 8, 6, 3, 7 } }, { 251377, 0.14, from = { 8, 7, 3, 4, 6 } }, { 251378, 0.12, from = { 8, 6, 7, 3 } }, { 251382, 0.08, from = { 2, 1 } }, { 252801, 0.08, from = { 1 } }, { 252820, 0.07, from = { 4, 8, 7, 3, 6 } }, { 252824, 0.07, from = { 8, 6, 3, 7 } }, { 253976, 0.07, from = { 4, 3, 6, 7, 8 } }, { 253980, 0.07, from = { 4, 3, 5, 8, 6, 7 } }, { 251376, 0.07, from = { 8, 4, 7, 6, 3 } }, { 252822, 0.07, from = { 4, 5, 7, 6, 3, 8 } }, { 252798, 0.06, from = { 2, 1 } }, { 253942, 0.06, from = { 2, 1 } }, { 253944, 0.06, from = { 2, 1 } }, { 253940, 0.05, from = { 1, 2 } }, { 251375, 0.05, from = { 7, 3, 8, 6 } }, { 252821, 0.05, from = { 8, 5, 3, 6, 7 } }, { 252825, 0.05, from = { 3, 6, 5, 7 } }, { 251379, 0.05, from = { 8, 7, 6, 3 } }, { 251383, 0.04, from = { 2, 1 } }, { 252799, 0.04, from = { 2 } }, { 253948, 0.04, from = { 2, 1 } }, { 251380, 0.03, from = { 1, 2 } }, { 252800, 0.03, from = { 1, 2 } }, { 253938, 0.03, from = { 1, 2 } }, { 253946, 0.03, from = { 1, 2 } }, { 251381, 0.02, from = { 2, 1 } }, { 252803, 0.02, from = { 2, 1 } }, { 253986, 0.02, from = { 8, 6, 3, 4, 7 } }, { 251384, from = { 1, 2 } }, { 251345, from = { 1, 2 } }, { 251346, from = { 1, 2 } }, { 251347, from = { 1, 2 } }, { 251348, from = { 1, 2 } }, { 251349, from = { 1, 2 } }, { 252792, from = { 1, 2 } }, { 252793, from = { 1, 2 } }, { 252794, from = { 1, 2 } }, { 252795, from = { 1, 2 } }, { 252796, from = { 1, 2 } }, { 252797, from = { 1, 2 } }, { 252802, from = { 2 } }, { 251350, from = { 3, 4, 7, 6, 8 } }, { 251351, from = { 3, 4, 7, 6, 8 } }, { 251352, from = { 3, 4, 7, 6, 8 } }, { 251353, from = { 3, 4, 7, 6, 8 } }, { 251354, from = { 3, 4, 7, 6, 8 } }, { 252814, from = { 3, 4, 7, 6, 8 } }, { 252815, from = { 3, 4, 7, 6, 8 } }, { 252816, from = { 3, 4, 7, 6, 8 } }, { 252817, from = { 3, 4, 7, 6, 8 } }, { 252818, from = { 3, 4, 7, 6, 8 } }, { 252819, from = { 3, 4, 7, 6, 8 } } } },
    },
    BRD = {
        { name = "Lord Roccor", npcID = 9025, display = 5781, level = 51, loot = { { 22234, 23.4 }, { 11632, 24.4 }, { 11631, 24.1 }, { 22397, 19.9 }, { 11630, 18.4 }, { 11813, 18.3 } } },
        { name = "High Interrogator Gerstahn", npcID = 9018, display = 8761, level = 52, loot = { { 11626, 9.2 }, { 11624, 28.4 }, { 22240, 11.9 }, { 11625, 13.6 }, { 11140, 53 } } },
        { name = "Houndmaster Grebmar", npcID = 9319, display = 9212, level = 52, loot = { { 11623, 19.1 }, { 11627, 42.9 }, { 11628, 9.5 }, { 11629, 9.1 } } },
        { name = "Ring of Law: Gorosh the Dervish", npcID = 9027, oneOf = "RING_OF_LAW", display = 8760, level = 56, loot = { { 11726, 13.9 }, { 22271, 18.9 }, { 22257, 15.6 }, { 22266, 13 } } },
        { name = "Ring of Law: Grizzle", npcID = 9028, oneOf = "RING_OF_LAW", display = 7873, level = 54, loot = { { 11722, 22.9 }, { 11703, 31.4 }, { 22270, 12.6 }, { 11702, 30.9 }, { 11610, 93.1 }, { 277117 } } },
        { name = "Ring of Law: Eviscerator", npcID = 9029, oneOf = "RING_OF_LAW", display = 523, level = 54, loot = { { 11685, 32 }, { 11679, 34.9 }, { 11686, 17.6 }, { 11730, 12.4 } } },
        { name = "Ring of Law: Ok'thor the Breaker", npcID = 9030, oneOf = "RING_OF_LAW", display = 11538, level = 53, loot = { { 11665, 27.6 }, { 11662, 29.8 }, { 11728, 17.1 }, { 11824, 21.5 } } },
        { name = "Ring of Law: Anub'shiah", npcID = 9031, oneOf = "RING_OF_LAW", display = 3004, level = 54, loot = { { 11678, 22.1 }, { 11677, 31.9 }, { 11675, 35.4 }, { 11731, 7.9 } } },
        { name = "Ring of Law: Hedrum the Creeper", npcID = 9032, oneOf = "RING_OF_LAW", display = 8271, level = 53, loot = { { 11633, 32.9 }, { 11634, 29.5 }, { 11635, 21.8 }, { 11729, 9.6 } } },
        { name = "Pyromancer Loregrain", npcID = 9024, kind = "rare", display = 8762, level = 52, loot = { { 11747, 24.2 }, { 11749, 23.7 }, { 11748, 28.4 }, { 11750, 20 }, { 11207, 43.7 } } },
        { name = "Dark Coffer", display = 8592, level = 55, loot = { { 11197, 83.5 }, { 22256 }, { 22205 }, { 22255 }, { 22254 }, { 11923 }, { 11945 }, { 11946 }, { 11752 }, { 11751 }, { 11753 } } },
        { name = "Warder Stilgiss", npcID = 9041, display = 9089, level = 56, loot = { { 11782, 26.6 }, { 22241, 17.1 }, { 11783, 27.5 }, { 11784, 21.8 } } },
        { name = "Verek", npcID = 9042, display = 9019, level = 55, loot = { { 11755, 8.1 }, { 22242, 7.7 } } },
        { name = "Watchman Doomgrip", npcID = 9476, display = 8655, level = 55, loot = { { 22205 }, { 22255 }, { 22256 }, { 22254 } } },
        { name = "Fineous Darkvire", npcID = 9056, display = 8704, level = 54, loot = { { 11839, 17.1 }, { 22223, 12.7 }, { 11842, 25.9 }, { 11841, 23.4 }, { 11840, 2.8 } } },
        { name = "Lord Incendius", npcID = 9017, display = 1204, level = 55, loot = { { 11766, 12.4 }, { 11764, 12.8 }, { 11765, 12.2 }, { 11767, 12.6 }, { 19268, 0.6 }, { 11768, 47 } } },
        { name = "Bael'Gar", npcID = 9016, display = 12162, level = 54, loot = { { 11807, 18.8 }, { 11802, 36.1 }, { 11805, 4.8 }, { 11803, 33.8 } } },
        { name = "General Angerforge", npcID = 9033, display = 8756, level = 57, loot = { { 11820, 28.8 }, { 11821, 11.3 }, { 11810, 5.6 }, { 11817, 8.3 }, { 11816, 29.1 }, { 11841, 24 } } },
        { name = "Golem Lord Argelmach", npcID = 8983, display = 8759, level = 57, loot = { { 11823, 37.2 }, { 11822, 36.8 }, { 11669, 9.5 }, { 11819, 8.9 }, { 273113 } } },
        { name = "Guzzler", display = 8658, level = 55, loot = { { 11735, 7.6 }, { 18043, 20.4 }, { 22275, 23 }, { 18044, 23.9 }, { 18592 }, { 11612, 12.4 }, { 2662, 8.5 }, { 2663, 9 }, { 11742, 13.8 }, { 12793, 29.5 }, { 12791, 10.2 }, { 18653, 16.9 }, { 13483 }, { 15759 }, { 11325, 1.6 }, { 11602, 0.2 } } },
        { name = "Phalanx", npcID = 9502, display = 8177, level = 55, loot = { { 22212, 25.1 }, { 11745, 30.7 }, { 11744, 24.9 }, { 11743, 8.4 }, { 276879 } } },
        { name = "Ambassador Flamelash", npcID = 9156, display = 8329, level = 57, loot = { { 11808, 0.3 }, { 11812, 39.6 }, { 11814, 38.4 }, { 11832, 8.7 }, { 11809, 9.6 }, { 23320 }, { 273122, 0.9 } } },
        { name = "Panzor the Invincible", npcID = 8923, kind = "rare", display = 8270, level = 57, loot = { { 22245, 21.8 }, { 11787, 21.8 }, { 11785, 21.8 }, { 11786, 31 } } },
        { name = "Chest of The Seven", display = 8690, level = 55, loot = { { 11925, 25 }, { 11926, 26.7 }, { 11929, 50 }, { 11927, 46.7 }, { 11920, 25 }, { 11923, 36.2 }, { 11922, 25 }, { 11921, 25 } } },
        { name = "Magmus", npcID = 9938, display = 12162, level = 57, loot = { { 11746, 19.8 }, { 11935, 18.1 }, { 22395, 12.3 }, { 22400, 12.3 }, { 22208, 23.5 }, { 277129, quest = true } } },
        { name = "Princess Moira Bronzebeard", npcID = 8929, display = 8705, level = 58, loot = { { 12557, 22.9 }, { 12554, 23 }, { 12556, 21.6 }, { 12553, 22.8 } } },
        { name = "Emperor Dagran Thaurissan", npcID = 9019, display = 8807, level = 59, loot = { { 11684, 0.6 }, { 11933, 13.8 }, { 11930, 20 }, { 11924, 21.3 }, { 22204, 14.8 }, { 22207, 17.4 }, { 11934, 17 }, { 11815, 15.6 }, { 11928, 19.4 }, { 11931, 21.5 }, { 11932, 16 }, { 12033, 3.2 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 12549 }, { 12552 }, { 12551 }, { 12542 }, { 12546 }, { 12550 }, { 12547 }, { 12555 }, { 12527 }, { 12531, 0.1 }, { 12535 }, { 12528 }, { 12532 }, { 15781 }, { 15770 }, { 11611 }, { 11614 }, { 11615 }, { 16048 }, { 16053 }, { 16049 }, { 18654 }, { 18661 }, { 11746, 11.9 }, { 11920, 28.3 }, { 11921, 26.1 }, { 11922, 21.7 }, { 22305, 100 } } },
        { name = "Plans", kind = "object", loot = { { 11614 }, { 11615 } } },
        -- Se invoca con el Estandarte de provocacion en el Anillo de la Ley (mision 9015).
        { name = "Theldren", npcID = 16059, level = 60, kind = "rare", loot = { { 22047, quest = true }, { 22330 }, { 22317 }, { 22318 } } },
        -- Tabernero del Grim Guzzler: solo pelea si se le provoca; no cuenta para terminar la partida.
        { name = "Plugger Spazzring", npcID = 9499, level = 54, optional = true, loot = { { 276877 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 11813, from = { 1 } }, { 11610, from = { 5 } }, { 11207, from = { 10 } }, { 11611, from = { 28 } }, { 11614, from = { 28 } }, { 11615, from = { 28 } }, { 16049, from = { 28 } }, { 16048, from = { 28 } }, { 18654, from = { 28 } }, { 16053, from = { 28 } }, { 18661, from = { 28 } }, { 273122, 0.9, from = { 22 } } } },
    },
    DM_E = {
        { name = "Pusillin", npcID = 14354, display = 7552, level = 57, loot = { { 18267, 83 }, { 18249, 100 }, { 18316 }, { 18320 } } },
        { name = "Zevrim Thornhoof", npcID = 11490, display = 11335, level = 57, loot = { { 18319, 10.1 }, { 18313, 19.1 }, { 18323, 19.1 }, { 18308, 24.5 }, { 18306, 24.8 } } },
        { name = "Hydrospawn", npcID = 13280, display = 5489, level = 57, loot = { { 18317, 18.9 }, { 18322, 19.6 }, { 18324, 9.7 }, { 19268, 1.2 }, { 18305, 24.2 }, { 18307, 23.6 }, { 7091 } } },
        { name = "Lethtendris", npcID = 14327, display = 14378, level = 57, loot = { { 18325, 28.6 }, { 18311, 9.4 }, { 18301, 27.9 }, { 18302, 28.7 } } },
        { name = "Alzzin the Wildshaper", npcID = 11492, display = 14416, level = 58, loot = { { 18328, 19 }, { 18312, 18.7 }, { 18309, 18.7 }, { 18326, 18.7 }, { 18327, 18.7 }, { 18318, 18.5 }, { 18321, 18.9 }, { 18310, 19 }, { 18314, 19 }, { 18315, 19 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 18289, 1.7 }, { 18296, 0.6 }, { 18298, 0.7 }, { 18295, 1.3 }, { 18333 }, { 18334 }, { 18332 }, { 18255 }, { 18297 }, { 18337, 0.8 }, { 18338, 0.9 }, { 18339, 1 }, { 18340, 1.2 }, { 18343, 1.1 }, { 18344, 0.9 }, { 18354, 24.3 }, { 18450, 9.9 }, { 18451, 9.1 }, { 18458, 9 }, { 18459, 9.6 }, { 18460, 9.4 }, { 18462, 9.2 }, { 18463, 9.1 }, { 18464, 9.4 }, { 18493, 6 }, { 18494, 6.8 }, { 18496, 6.5 }, { 18497, 5.9 }, { 18498, 6.8 } } },
        -- 0.5: se invoca con el Brasero en la sala de Alzzin (trozos del amuleto de Valthalak).
        { name = "Isalien", npcID = 16097, kind = "rare", level = 60, summon = { text = "SUMMON_BRAZIER" }, loot = { { 22314 }, { 22472 }, { 22315 }, { 22304 }, { 22401 }, { 22345 }, { 21984, quest = true }, { 22046, quest = true } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 18267, from = { 1 } }, { 7091, from = { 3 } } } },
    },
    DM_N = {
        { name = "Guard Mol'dar", npcID = 14326, display = 11561, level = 59, loot = { { 18494, 6.7 }, { 18493, 6.5 }, { 18496, 6.4 }, { 18497, 5.5 }, { 18498, 6.2 }, { 18450, 8.1 }, { 18458, 7.9 }, { 18459, 8.2 }, { 18451, 7.7 }, { 18462, 7.8 }, { 18463, 7.7 }, { 18464, 8.2 }, { 18460, 7.9 }, { 18250, 14.1 }, { 18268, 48.2 } } },
        { name = "Stomper Kreeg", npcID = 14322, display = 11545, level = 59, loot = { { 18425, 57.1 }, { 18269 }, { 18284 }, { 18287 }, { 18288 }, { 9260 } } },
        { name = "Guard Fengus", npcID = 14321, display = 11561, level = 59, loot = { { 18450, 12.7 }, { 18458, 10.3 }, { 18459, 12.7 }, { 18451, 11.8 }, { 18462, 12.9 }, { 18463, 10.5 }, { 18464, 13 }, { 18460, 12.5 }, { 18250, 13.4 }, { 18266, 1.1 } } },
        { name = "Guard Slip'kik", npcID = 14323, display = 11561, level = 59, loot = { { 18494, 7 }, { 18493, 5.5 }, { 18496, 6.7 }, { 18497, 5.8 }, { 18498, 7.3 }, { 18450, 8.6 }, { 18458, 8.3 }, { 18459, 7.7 }, { 18451, 8.1 }, { 18462, 7.5 }, { 18463, 8.6 }, { 18464, 7.7 }, { 18460, 7.8 }, { 18250, 13.6 } } },
        { name = "Knot Thimblejack's Cache", kind = "object", level = 50, loot = { { 18414, 1.7 }, { 18517, 1.6 }, { 18518, 1.3 }, { 18519, 2.1 }, { 18415, 12.1 }, { 18416, 12.3 }, { 18417, 12.5 }, { 18418, 11.3 }, { 18514, 10.8 }, { 18515, 12.8 }, { 18516, 12.5 }, { 18258 }, { 18240, 34.3 } } },
        { name = "Captain Kromcrush", npcID = 14325, display = 11564, level = 61, loot = { { 18503, 23.1 }, { 18505, 21.4 }, { 18507, 23.5 }, { 18502, 21.7 } } },
        { name = "Cho'Rush the Observer", npcID = 14324, display = 11537, level = 60, loot = { { 18490, 7.9 }, { 18483, 7.9 }, { 18485, 7.9 }, { 18484, 8.2 } } },
        { name = "King Gordok", npcID = 11501, display = 11583, level = 62, loot = { { 18526, 23.6 }, { 18525, 24.1 }, { 18527, 24.1 }, { 18524, 24.4 }, { 18521, 24.9 }, { 18522, 23.8 }, { 18523, 24.1 }, { 18520, 23.7 }, { 19258, 2.5 }, { 18780, 9 } } },
        { name = "Tribute", kind = "object", level = 60, loot = { { 18538, 0.4 }, { 18528, 17.9 }, { 18495, 9.2 }, { 18532, 12.1 }, { 18530, 12.9 }, { 18533, 9.6 }, { 18529, 19 }, { 18500, 22.5 }, { 18537, 9.2 }, { 18499, 12.4 }, { 18531, 12.2 }, { 18534, 11.4 }, { 18479, 14.3 }, { 18480, 14.2 }, { 18478, 14.8 }, { 18475, 15.9 }, { 18477, 15 }, { 18476, 14.7 }, { 18482, 13.8 }, { 18481, 13.8 }, { 18655, 4.5 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 18250 }, { 18333 }, { 18334 }, { 18332 }, { 18640 }, { 18289, 1.7 }, { 18295, 1.3 }, { 18296, 0.6 }, { 18298, 0.7 }, { 18337, 0.8 }, { 18338, 0.9 }, { 18339, 1 }, { 18340, 1.2 }, { 18343, 1.1 }, { 18344, 0.9 }, { 18354, 24.3 }, { 18450, 9.9 }, { 18451, 9.1 }, { 18458, 9 }, { 18459, 9.6 }, { 18460, 9.4 }, { 18462, 9.2 }, { 18463, 9.1 }, { 18464, 9.4 }, { 18493, 6 }, { 18494, 6.8 }, { 18496, 6.5 }, { 18497, 5.9 }, { 18498, 6.8 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 18655, from = { 9 } }, { 18414, from = { 5 } }, { 18517, from = { 5 } }, { 18518, from = { 5 } }, { 18519, from = { 5 } }, { 18415, from = { 5 } }, { 18416, from = { 5 } }, { 18417, from = { 5 } }, { 18418, from = { 5 } }, { 18514, from = { 5 } }, { 18515, from = { 5 } }, { 18516, from = { 5 } } } },
    },
    DM_W = {
        { name = "Tendris Warpwood", npcID = 11489, display = 14383, level = 60, loot = { { 18393, 24 }, { 18390, 24.9 }, { 18352, 23.8 }, { 18353, 24 }, { 273120 } } },
        { name = "Illyanna Ravenoak", npcID = 11488, display = 11270, level = 60, loot = { { 18383, 23.9 }, { 18386, 22 }, { 18349, 24.2 }, { 18347, 24.3 } } },
        { name = "Magister Kalendris", npcID = 11487, display = 14384, level = 60, loot = { { 18374, 19.9 }, { 18397, 19.4 }, { 18371, 8.7 }, { 18350, 25.2 }, { 18351, 23.4 }, { 22309, 0.4 } } },
        { name = "Tsu'zee", npcID = 11467, kind = "rare", display = 11250, level = 59, loot = { { 18387, 30.4 }, { 18346, 29.1 }, { 18345, 32.7 } } },
        { name = "Immol'thar", npcID = 11496, display = 14173, level = 61, loot = { { 18381, 23.3 }, { 18384, 19.8 }, { 18389, 19.6 }, { 18385, 21.1 }, { 18394, 19.2 }, { 18377, 25.7 }, { 18391, 24 }, { 18379, 24.5 }, { 18370, 8.7 }, { 18372, 9.5 } } },
        { name = "Prince Tortheldrin", npcID = 11486, display = 11256, level = { 60, 61 }, loot = { { 18382, 23.6 }, { 18373, 9.5 }, { 18375, 17.2 }, { 18378, 21.3 }, { 18380, 23.2 }, { 18395, 23.9 }, { 18388, 10.4 }, { 18396, 20.4 }, { 18376, 18.1 }, { 18392, 18.9 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 18340, 1.2 }, { 18344, 0.9 }, { 18338, 0.9 }, { 18333 }, { 18334 }, { 18332 }, { 18289, 1.7 }, { 18295, 1.3 }, { 18296, 0.6 }, { 18298, 0.7 }, { 18337, 0.8 }, { 18339, 1 }, { 18343, 1.1 }, { 18354, 24.3 }, { 18450, 9.9 }, { 18451, 9.1 }, { 18458, 9 }, { 18459, 9.6 }, { 18460, 9.4 }, { 18462, 9.2 }, { 18463, 9.1 }, { 18464, 9.4 }, { 18493, 6 }, { 18494, 6.8 }, { 18496, 6.5 }, { 18497, 5.9 }, { 18498, 6.8 } } },
        { name = "Shen'dralar Provisioner", kind = "object", display = 14412, level = 52, loot = { { 18487 } } },
        { name = "Lord Hel'nurath", npcID = 14506, kind = "object", display = 14556, level = 62, loot = { { 18757, 22.2 }, { 18754, 23.6 }, { 18755, 25.7 }, { 18756, 24.9 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 22309, from = { 3 } }, { 273120, from = { 1 } } } },
    },
    -- Ciudad de Dalaran (09-10-2026, ya abierta): orden de la guia de Wowhead (Mana Devourer,
    -- que no sale en ella, antes de Fel Ancient: este se abre al matar a los de alrededor).
    -- Display y nivel de foreverchanges.pro (Lyn sin nivel). Botin con los itemID de Wowhead
    -- Forever; aun sin probabilidad.
    DALARAN = {
        { name = "Atrexis the Grave Knight", npcID = 247126, display = 145787, level = 29, loot = { { 273032 }, { 273036 }, { 273033 } } },
        { name = "Arcane Anomaly", npcID = 245999, display = 129891, level = 30, loot = { { 273034 }, { 273031 }, { 273035 } } },
        { name = "Arcanic Enigma", npcID = 246016, display = 129900, level = 30, loot = { { 273045 }, { 273044 }, { 273043 } } },
        { name = "Unstable Sentinel", npcID = 246017, display = 129954, level = 31, loot = { { 273046 }, { 273047 }, { 273048 }, { 273099 } } },
        { name = "Mana Devourer", npcID = 246008, display = 129895, level = 31, loot = { { 273041 }, { 273040 }, { 273042 } } },
        { name = "Fel Ancient", npcID = 246003, display = 129894, level = 32, loot = { { 273037 }, { 273039 }, { 273038 } } },
        { name = "Lyn the Ignored", npcID = 247032, kind = "rare", display = 130235, summon = { items = { 276561, 275989 }, text = "SUMMON_TOME" }, loot = { { 273055 }, { 273054 }, { 273053 } } },
        { name = "Shade of the Archmage", npcID = 246020, display = 130061, level = 33, loot = { { 273103 }, { 273052 }, { 273049 }, { 273051 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 286987, mobs = "Dark Caster / Kirin Tor Necromancer" }, { 286988, mobs = "Fallen Mage / Dark Caster" }, { 286989, mobs = "Kirin Tor Necromancer / Fallen Mage" }, { 286991, mobs = "Saturated Remnant / Fallen Mage / Seeking Remnant" }, { 286992, mobs = "Fragmented Sentry" }, { 286994, mobs = "Mana Stalker / Dark Caster / Arcane Echo" }, { 286995, mobs = "Fragmented Sentry" }, { 286990, mobs = "Dark Caster / Saturated Remnant / Mindless Horror" }, { 286993, mobs = "Phantasm / Arcane Elemental / Seeking Remnant" }, { 286996, mobs = "Mana Echo / Dark Caster / Kirin Tor Necromancer" } } },
    },
    EXCAVATION = {
        { name = "Saltspine", npcID = 260322, display = 144209, level = 28, loot = { { 273024 }, { 273022 }, { 273023 } } },
        { name = "Shadetooth", npcID = 260325, display = 144210, level = 29, loot = { { 273025 }, { 273027 }, { 273026 }, { 273106 } } },
        { name = "Relic Guardian", npcID = 260326, display = 144224, level = 31, loot = { { 273028 }, { 273029 }, { 273030 }, { 270866 }, { 273097 }, { 270865 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 287068, mobs = "Highland Snapper / Highland Spider / Thicket Lurker" }, { 286983, mobs = "Highland Lurker / Thicket Hunter / Highland Spider" }, { 286982, mobs = "Highland Lurker / Marsh Crocolisk / Highland Spider" }, { 286984, mobs = "Marsh Skulker / Marsh Crocolisk / Thicket Hunter" }, { 286985, mobs = "Thicket Matriarch / Highland Lurker / Thicket Hunter" }, { 286986, mobs = "Highland Spider / Thicket Lurker / Young Riptooth" } } },
    },
    GNOMER = {
        { name = "Techbot", npcID = 6231, display = 7288, level = 26, loot = { { 9444, 47.6 } } },
        { name = "Grubbis", npcID = 7361, display = 6533, level = 32, loot = { { 9445, 8.8 }, { 274043 }, { 274042 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Viscous Fallout", npcID = 7079, display = 5497, level = 30, loot = { { 9454, 60.8 }, { 9453, 17.5 }, { 9452, 18.8 }, { 7091 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Electrocutioner 6000", npcID = 6235, display = 6915, level = 32, loot = { { 9447, 31.1 }, { 9446, 16.2 }, { 9448, 41.2 }, { 6893, 79.4 }, { 252822 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Crowd Pummeler 9-60", npcID = 6229, display = 6774, level = 32, loot = { { 9449, 32.6 }, { 9450, 65.3 }, { 274068 }, { 274049 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Dark Iron Ambassador", npcID = 6228, kind = "rare", display = 6669, level = 33, loot = { { 9455, 42.9 }, { 9456, 32.5 }, { 9457, 20.9 }, { 253978, 0.33 }, { 252820 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 252814 }, { 252816 }, { 253976 }, { 253980 }, { 253984 } } },
        { name = "Mekgineer Thermaplugg", npcID = 7800, display = 6980, level = 34, loot = { { 9492, 9.5 }, { 9461, 32.3 }, { 9458, 31.8 }, { 9459, 18.3 }, { 4415, 0.5 }, { 4413, 0.4 }, { 4411, 0.5 }, { 7742, 0.3 }, { 11828 }, { 4408 }, { 4409 }, { 4410 }, { 4412 }, { 4414 }, { 4416 }, { 4417 }, { 6672 }, { 6716 }, { 7192 }, { 7560 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 9508 }, { 9491 }, { 9509 }, { 9510 }, { 9487 }, { 9485 }, { 9488 }, { 9486 }, { 9490 }, { 9489, 0.1 }, { 11827 }, { 9327 }, { 7191 }, { 9308 }, { 9326 }, { 9279 }, { 9280 }, { 9282 }, { 9281 }, { 9316 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 253978, 0.33, from = { 6, 2, 3, 4, 5, 7 } }, { 252822, from = { 4 } }, { 252820, from = { 6 } }, { 251350, from = { 2, 3, 4, 5, 7, 6 } }, { 251351, from = { 2, 3, 4, 5, 7, 6 } }, { 251352, from = { 2, 3, 4, 5, 7, 6 } }, { 251353, from = { 2, 3, 4, 5, 7, 6 } }, { 251354, from = { 2, 3, 4, 5, 7 } }, { 252814, from = { 2, 3, 4, 5, 7, 6 } }, { 252815, from = { 2, 3, 4, 5, 7 } }, { 252816, from = { 2, 3, 4, 5, 7, 6 } }, { 252817, from = { 2, 3, 4, 5, 7 } }, { 252818, from = { 2, 3, 4, 5, 7 } }, { 252819, from = { 2, 3, 4, 5, 7 } }, { 253976, from = { 2, 3, 4, 5, 7, 6 } }, { 253980, from = { 2, 3, 4, 5, 7, 6 } }, { 253982, from = { 2, 3, 4, 5, 7 } }, { 253984, from = { 2, 3, 4, 5, 7, 6 } }, { 253986, from = { 2, 3, 4, 5, 7 } }, { 7091, from = { 3 } }, { 4408, from = { 7 } }, { 4409, from = { 7 } }, { 4410, from = { 7 } }, { 4412, from = { 7 } }, { 4414, from = { 7 } }, { 4416, from = { 7 } }, { 4417, from = { 7 } }, { 6672, from = { 7 } }, { 6716, from = { 7 } }, { 7192, from = { 7 } }, { 7560, from = { 7 } }, { 274049, from = { 5 } }, { 4411, from = { 7 } }, { 4413, from = { 7 } }, { 4415, from = { 7 } }, { 7742, from = { 7 } } } },
    },
    -- Niveles de Salas de los Thanes (08-10-2026); Wowhead Forever aun no los tiene
    THANES = {
        { name = "Faldrim Anvilmar", npcID = 261306, display = 142826, level = 16, loot = { { 270227 }, { 271096 }, { 271097 } } },
        { name = "Magmatus", npcID = 261316, display = 1070, level = 16, loot = { { 270230 }, { 270231 }, { 271095 } } },
        { name = "Plunder", npcID = 261311, display = 142840, level = 16, loot = { { 270228 }, { 270229 }, { 271098 } } },
        { name = "Durgen Dirgehammer", npcID = 261319, display = 142837, level = 16, loot = { { 270256 }, { 270260 }, { 270261 }, { 274286 } } },
    },
    LBRS = {
        { name = "Burning Felguard", npcID = 10263, kind = "rare", summon = { text = "SUMMON_FELGUARD" }, display = 5047, level = { 56, 57 }, loot = { { 13181, 31.2 }, { 13182, 32 } } },
        { name = "Spirestone Butcher", npcID = 9219, kind = "rare", display = 11574, level = 57, loot = { { 12608, 59.3 }, { 13286, 37.2 } } },
        { name = "Highlord Omokk", npcID = 9196, display = 11565, level = 59, loot = { { 16670, 13 }, { 13166, 14 }, { 13168, 10.8 }, { 13170, 12.5 }, { 13169, 14 }, { 13167, 14.6 }, { 12336, 27.5 }, { 12534, 89.8 } } },
        { name = "Spirestone Battle Lord", npcID = 9218, kind = "rare", display = 11576, level = 58, loot = { { 13284, 56.4 }, { 13285, 38.4 } } },
        { name = "Spirestone Lord Magus", npcID = 9217, kind = "rare", display = 11578, level = 58, loot = { { 13282, 24.7 }, { 13283, 48 }, { 13261, 20.7 } } },
        { name = "Shadow Hunter Vosh'gajin", npcID = 9236, display = 9732, level = 58, loot = { { 16712, 17.5 }, { 13257, 6.9 }, { 12626, 18.5 }, { 13255, 36 }, { 12653, 7 }, { 12651, 7 }, { 12654, 27.6 } } },
        { name = "War Master Voone", npcID = 9237, display = 9733, level = 59, loot = { { 16676, 19.4 }, { 13177, 18.2 }, { 13179, 18.3 }, { 22231, 15.5 }, { 13173, 91.4 }, { 12582, 14.3 }, { 12335, 35 }, { 13175, 0.9 } } },
        { name = "Bannok Grimaxe", npcID = 9596, kind = "rare", display = 9668, level = 59, loot = { { 12637, 32.6 }, { 12634, 30.2 }, { 12621, 30.3 }, { 12838, 7.8 } } },
        { name = "Mother Smolderweb", npcID = 10596, display = 9929, level = 59, loot = { { 16715, 15.2 }, { 13244, 26.8 }, { 13213, 11.7 }, { 13183, 1.4 }, { 249521 } } },
        { name = "Crystal Fang", npcID = 10376, kind = "rare", display = 9755, level = 60, loot = { { 13185, 34.9 }, { 13184, 31.7 }, { 13218, 15.1 } } },
        { name = "Urok Doomhowl", npcID = 10584, display = 11583, level = 60, loot = { { 13053 }, { 13258, 21.7 }, { 22232, 17.4 }, { 13259, 17.4 }, { 13178, 16.5 }, { 18784, 13 } } },
        { name = "Quartermaster Zigris", npcID = 9736, display = 9738, level = 59, loot = { { 13247, 26 }, { 13253, 14 }, { 13252, 18.5 }, { 12835, 13.6 }, { 273115 } } },
        { name = "Halycon", npcID = 10220, display = 9567, level = 59, loot = { { 13212, 28.5 }, { 22313, 16.8 }, { 13211, 28.2 }, { 13210, 16.8 } } },
        { name = "Gizrul the Slavener", npcID = 10268, display = 9564, level = 60, loot = { { 16718, 18.2 }, { 13208, 24.4 }, { 13206, 25.8 }, { 13205, 25 } } },
        { name = "Ghok Bashguud", npcID = 9718, kind = "rare", display = 11809, level = 59, loot = { { 13203, 39.1 }, { 13198, 22.5 }, { 13204, 34 } } },
        { name = "Overlord Wyrmthalak", npcID = 9568, display = 8711, level = 60, loot = { { 13143, 1 }, { 16679, 16.1 }, { 13162, 16.6 }, { 13164, 2.2 }, { 22321, 11 }, { 13163, 15.1 }, { 13148, 3.4 }, { 13161, 17.8 }, { 12337, 40.5 }, { 12780, 26.9 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 14513 }, { 16696, 2.9 }, { 16685 }, { 16683, 3.1 }, { 16703, 3 }, { 16713, 2.7 }, { 16716 }, { 16680, 3 }, { 16673, 2.8 }, { 16736 }, { 16735, 2.8 }, { 15749 }, { 15775 }, { 13494 }, { 16250 }, { 16244 }, { 9214 }, { 12219 }, { 12586 }, { 13260 }, { 251451 } } },
        -- 0.5: se invoca con el Brasero de las misiones del conjunto de mazmorra 2 (trozos del amuleto de Valthalak).
        { name = "Mor Grayhoof", npcID = 16080, kind = "rare", level = 60, summon = { text = "SUMMON_BRAZIER" }, loot = { { 22306 }, { 22319 }, { 22322 }, { 22325 }, { 22398 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 249521, from = { 9 } }, { 12838, from = { 8 } }, { 12835, from = { 12 } }, { 14513, from = { 17 } }, { 251451, from = { 17 } }, { 15775, from = { 17 } }, { 16250, from = { 17 } }, { 16244, from = { 17 } } } },
    },
    MARA = {
        { name = "Veng", display = 9418, level = 47, loot = { { 17765, 92.3 } } },
        { name = "Noxxion", npcID = 13282, display = 11172, level = 48, loot = { { 17746, 36.2 }, { 17744, 35.9 }, { 17745, 17.5 }, { 254100 }, { 254096 }, { 252918 }, { 251405 } } },
        { name = "Razorlash", npcID = 12258, display = 12389, level = 48, loot = { { 17749, 24.7 }, { 17748, 24 }, { 17750, 24.2 }, { 17751, 23.8 }, { 252869 }, { 254100 }, { 254096 }, { 252871 }, { 251407 } } },
        { name = "Maraudos", display = 9441, level = 46, loot = { { 17764, 90.3 } } },
        { name = "Lord Vyletongue", npcID = 12236, display = 12334, level = 47, loot = { { 17755, 27 }, { 17754, 29.3 }, { 17752, 28.4 }, { 275864 } } },
        { name = "Meshlok the Harvester", npcID = 12237, kind = "rare", display = 9014, level = 48, loot = { { 17767, 29.9 }, { 17741, 31.2 }, { 17742, 31.5 }, { 251407 } } },
        { name = "Celebras the Cursed", npcID = 12225, display = 12350, level = 49, loot = { { 17740, 29.8 }, { 17739, 32.3 }, { 17738, 32.5 }, { 251405 }, { 254098 }, { 252920 }, { 252868 } } },
        { name = "Landslide", npcID = 12203, display = 12293, level = 50, loot = { { 17734, 22.4 }, { 17736, 23.8 }, { 17737, 24.5 }, { 17943, 26 }, { 252868 }, { 252918 }, { 254098 }, { 252867 }, { 254106 }, { 252920 }, { 252919 }, { 251404 } } },
        { name = "Tinkerer Gizlock", npcID = 13601, display = 7125, level = 50, loot = { { 17718, 32.8 }, { 17717, 32.8 }, { 17719, 33.1 }, { 254098 }, { 252867 }, { 254106 }, { 252920 }, { 252868 }, { 251404 } } },
        { name = "Rotgrip", npcID = 13596, display = 13589, level = 50, loot = { { 17732, 35.9 }, { 17728, 35.1 }, { 17730, 23.7 }, { 252918 }, { 254102 }, { 254100 }, { 252919 } } },
        { name = "Princess Theradras", npcID = 12201, display = 12292, level = 51, loot = { { 17780, 0.3 }, { 17715, 19.4 }, { 17707, 19.6 }, { 17714, 24.3 }, { 17711, 19.5 }, { 17713, 24.6 }, { 17710, 19.4 }, { 17766, 19.6 }, { 254100 }, { 252868 }, { 252869 }, { 251407 }, { 251403 } } },
        { name = "The Nameless Prophet", kind = "object", display = 9426, level = 41, loot = { { 17757, 48.8 } } },
        { name = "Kolk", kind = "object", display = 4860, level = 43, loot = { { 17761, 85.9 } } },
        { name = "Gelk", kind = "object", display = 9427, level = 42, loot = { { 17762, 94 } } },
        { name = "Magra", kind = "object", display = 9433, level = 43, loot = { { 17763, 91.9 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 254100, from = { 2, 3, 10, 11 } }, { 254096, from = { 2, 3 } }, { 252918, from = { 2, 8, 10 } }, { 251405, from = { 2, 7 } }, { 252869, from = { 3, 11 } }, { 252871, from = { 3 } }, { 251407, from = { 3, 6, 11 } }, { 254098, from = { 7, 8, 9 } }, { 252920, from = { 7, 8, 9 } }, { 252868, from = { 7, 8, 9, 11 } }, { 252867, from = { 8, 9 } }, { 254106, from = { 8, 9 } }, { 252919, from = { 8, 10 } }, { 251404, from = { 8, 9 } }, { 254102, from = { 10 } }, { 251403, from = { 11 } } } },
    },
    RFC = {
        { name = "Oggleflint", npcID = 11517, display = 11611, level = 16, loot = { { 272999 }, { 272996 }, { 272998 }, { 251341, 0.02 }, { 251362, 0.05 }, { 251363, 0.02 }, { 251364, 0.05 }, { 252778, 0.05 }, { 252780, 0.02 }, { 252781, 0.02 }, { 252782, 0.05 }, { 253906, 0.02 } } },
        { name = "Taragaman the Hungerer", npcID = 11520, display = 7970, level = 16, loot = { { 14149, 34.8 }, { 14148, 32.9 }, { 14145, 17.6 }, { 251361, 0.01 }, { 251362, 0.01 }, { 251363, 0.02 }, { 251364, 0.01 }, { 252778, 0.01 }, { 252780, 0.01 }, { 252782, 0.02 }, { 253904, 0.01 }, { 253910, 0.01 } } },
        { name = "Jergosh the Invoker", npcID = 11518, display = 11429, level = 16, loot = { { 14150, 36.4 }, { 14147, 37.3 }, { 14151, 17.7 }, { 251341, 0.01 }, { 251360, 0.01 }, { 251363, 0.01 }, { 252778, 0.01 }, { 253906, 0.01 }, { 253912, 0.01 } } },
        { name = "Bazzalan", npcID = 11519, display = 2007, level = 16, loot = { { 273003 }, { 273005 }, { 273007 }, { 251362, 0.02 }, { 251363, 0.04 }, { 252778, 0.02 }, { 252780, 0.06 }, { 252781, 0.02 }, { 252782, 0.04 }, { 253904, 0.02 }, { 253908, 0.04 }, { 253910, 0.04 }, { 253912, 0.02 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 252780, 0.06, from = { 4, 1, 2 } }, { 251362, 0.05, from = { 1, 4, 2 } }, { 251364, 0.05, from = { 1, 2 } }, { 252778, 0.05, from = { 1, 4, 3, 2 } }, { 252782, 0.05, from = { 1, 4, 2 } }, { 251363, 0.04, from = { 4, 2, 1, 3 } }, { 253910, 0.04, from = { 4, 2 } }, { 253908, 0.04, from = { 4 } }, { 251341, 0.02, from = { 1, 3 } }, { 252781, 0.02, from = { 4, 1 } }, { 253906, 0.02, from = { 1, 3 } }, { 253904, 0.02, from = { 4, 2 } }, { 253912, 0.02, from = { 4, 3 } }, { 251361, 0.01, from = { 2 } }, { 251360, 0.01, from = { 3 } } } },
    },
    RFD = {
        { name = "Tuten'kash", npcID = 7355, display = 7845, level = 40, loot = { { 10776, 34.1 }, { 10775, 32.4 }, { 10777, 30.3 }, { 251398 }, { 254042 }, { 254040 }, { 251402 }, { 254038 }, { 254046 }, { 252844 }, { 252846 }, { 251401 }, { 252896 }, { 252847 }, { 252843 }, { 254048 }, { 252845 }, { 251399 }, { 251400 } } },
        { name = "Mordresh Fire Eye", npcID = 7357, display = 8055, level = 39, loot = { { 10769, 33.3 }, { 10771, 31.9 }, { 10770, 33 }, { 254044 }, { 254042 }, { 252843 }, { 251402 }, { 254040 }, { 252847 }, { 254048 }, { 252898 }, { 252896 }, { 254046 }, { 252897 }, { 252845 }, { 251398 }, { 251401 }, { 251399 }, { 254038 }, { 252846 }, { 251400 } } },
        { name = "Glutton", npcID = 8567, display = 7864, level = 40, loot = { { 10774, 47.7 }, { 10772, 50.3 }, { 274385 }, { 251402 }, { 252846 }, { 254038 }, { 252843 }, { 252897 }, { 252896 }, { 252845 }, { 254044 }, { 252847 }, { 254048 }, { 252844 }, { 254042 }, { 254046 }, { 252899 }, { 251398 }, { 251401 }, { 251400 } } },
        { name = "Ragglesnout", npcID = 7354, kind = "rare", display = 11382, level = 40, loot = { { 10768, 38.9 }, { 10767, 39.2 }, { 10758, 20.1 }, { 251399 }, { 252897 }, { 254038 }, { 252899 }, { 252843 }, { 252898 }, { 252845 } } },
        { name = "Amnennar the Coldbringer", npcID = 7358, display = 7971, level = 41, loot = { { 10763, 36.9 }, { 10762, 38.7 }, { 10764, 28.6 }, { 10761, 18.6 }, { 10765, 27.3 }, { 274381 }, { 276916, quest = true }, { 252899 }, { 252896 }, { 251402 }, { 254044 }, { 254042 }, { 252847 }, { 252843 }, { 252845 }, { 251401 }, { 251400 }, { 254040 }, { 252898 }, { 252846 }, { 252897 }, { 251398 } } },
        { name = "Plaguemaw the Rotting", npcID = 7356, display = 6124, level = 40, optional = true, loot = { { 10766, 32.7 }, { 10760, 62.8 }, { 274380 }, { 254042 }, { 254038 }, { 252845 }, { 254044 }, { 254040 }, { 251398 }, { 251401 }, { 252844 }, { 252897 }, { 252896 }, { 252847 }, { 252899 }, { 252843 }, { 252898 }, { 252846 }, { 251399 }, { 251400 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 10574 }, { 10581 }, { 10583, 0.1 }, { 10584 }, { 10578 }, { 10582 }, { 10572 }, { 10567 }, { 10571 }, { 10570 }, { 10573 } } },
        { name = "Henry Stern", kind = "object", display = 8029, level = 36, loot = { { 3826 }, { 10841 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251398, from = { 1, 6, 2, 3, 5 } }, { 254042, from = { 1, 6, 2, 3, 5 } }, { 254040, from = { 1, 6, 2, 5 } }, { 251402, from = { 1, 2, 3, 5 } }, { 254038, from = { 1, 6, 2, 3, 4 } }, { 254046, from = { 1, 2, 3 } }, { 252844, from = { 1, 6, 3 } }, { 252846, from = { 1, 6, 2, 3, 5 } }, { 251401, from = { 1, 6, 2, 3, 5 } }, { 252896, from = { 1, 6, 2, 3, 5 } }, { 252847, from = { 1, 6, 2, 3, 5 } }, { 252843, from = { 1, 6, 2, 3, 4, 5 } }, { 254048, from = { 1, 2, 3 } }, { 252845, from = { 1, 6, 2, 3, 4, 5 } }, { 251399, from = { 1, 6, 2, 4 } }, { 251400, from = { 1, 6, 2, 3, 5 } }, { 254044, from = { 6, 2, 3, 5 } }, { 252897, from = { 6, 2, 3, 4, 5 } }, { 252899, from = { 6, 3, 4, 5 } }, { 252898, from = { 6, 2, 4, 5 } } } },
    },
    RFK = {
        { name = "Aggem Thorncurse", npcID = 4424, display = 6097, level = 30, loot = { { 6681, 47.9 }, { 252820, 0.07 }, { 252821, 0.07 }, { 252822, 0.07 }, { 252823, 0.04 }, { 253982, 0.04 }, { 253984, 0.04 }, { 274158 }, { 274159 }, { 252512 }, { 252455 }, { 252456 }, { 252515 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253986 } } },
        { name = "Death Speaker Jargba", npcID = 4428, display = 4644, level = 30, loot = { { 2816, 10 }, { 6685, 43.6 }, { 6682, 42.8 }, { 251375, 0.02 }, { 251376, 0.02 }, { 251377, 0.02 }, { 251379, 0.02 }, { 252822, 0.02 }, { 252824, 0.02 }, { 253982, 0.02 }, { 253984, 0.04 }, { 253986, 0.02 }, { 252512 }, { 252515 }, { 252820 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 } } },
        { name = "Roogug", npcID = 6168, display = 6110, level = 28, loot = { { 274155 }, { 274152 }, { 252820, 0.08 }, { 252821, 0.08 }, { 274149 }, { 252512 }, { 6841, quest = true }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Overlord Ramtusk", npcID = 4420, display = 4652, level = 32, loot = { { 6687, 33.8 }, { 6686, 62.4 }, { 251376, 0.02 }, { 251377, 0.02 }, { 251378, 0.02 }, { 251379, 0.04 }, { 252821, 0.06 }, { 252822, 0.02 }, { 252824, 0.02 }, { 253976, 0.02 }, { 253980, 0.02 }, { 253986, 0.02 }, { 274161 }, { 252512 }, { 252513 }, { 252515 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253978 }, { 253982 }, { 253984 } } },
        { name = "Razorfen Spearhide", npcID = 4438, display = 6078, level = { 29, 30 }, loot = { { 6679, 59.6 } } },
        { name = "Agathelos the Raging", npcID = 4422, display = 2450, level = 33, loot = { { 6691, 33.5 }, { 6690, 61.9 }, { 251375, 0.04 }, { 251376, 0.02 }, { 251378, 0.06 }, { 251379, 0.1 }, { 252820, 0.02 }, { 252821, 0.04 }, { 252824, 0.1 }, { 253986, 0.02 }, { 274160 }, { 252455 }, { 252512 }, { 252513 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 } } },
        { name = "Blind Hunter", npcID = 4425, kind = "rare", display = 4735, level = 32, loot = { { 6695, 27.1 }, { 6697, 32.7 }, { 6696, 33.3 }, { 252821, 0.11 }, { 253976, 0.11 }, { 253984, 0.11 }, { 253986, 0.23 }, { 251351 }, { 251352 }, { 251353 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253978 }, { 253980 }, { 253982 } } },
        { name = "Charlga Razorflank", npcID = 4421, display = 4642, level = 33, loot = { { 6693, 35.6 }, { 6694, 33.4 }, { 6692, 17.8 }, { 17008, 45.2 }, { 274463, quest = true }, { 251376, 0.03 }, { 251378, 0.02 }, { 253976, 0.05 }, { 253978, 0.02 }, { 252515 }, { 252455 }, { 252456 }, { 252512 }, { 273103 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Earthcaller Halmgar", npcID = 4842, kind = "rare", display = 6102, level = 32, loot = { { 6689, 48.8 }, { 6688, 45.2 }, { 252455 }, { 252514 }, { 251351 }, { 251352 }, { 251353 }, { 252815 }, { 252818 }, { 252819 }, { 253976 }, { 253980 }, { 253984 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 2264 }, { 1488 }, { 4438 }, { 1978, 0.1 }, { 2039, 0.1 }, { 1727, 0.1 }, { 776 }, { 1976, 0.1 }, { 1975, 0.1 }, { 2549, 0.1 }, { 6681, 53.3 }, { 6679, 60.8 }, { 3569, 2.9 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 253986, 0.23, from = { 7, 6, 4, 2, 3, 1, 8 } }, { 252821, 0.11, from = { 7, 3, 1, 4, 6 } }, { 253984, 0.11, from = { 7, 2, 1, 3, 4, 6, 8, 9 } }, { 253976, 0.11, from = { 7, 8, 4, 3, 1, 2, 6, 9 } }, { 251379, 0.1, from = { 6, 4, 2 } }, { 252824, 0.1, from = { 6, 4, 2 } }, { 252820, 0.08, from = { 3, 1, 6, 2 } }, { 252822, 0.07, from = { 1, 4, 2 } }, { 251378, 0.06, from = { 6, 8, 4 } }, { 252823, 0.04, from = { 1 } }, { 253982, 0.04, from = { 1, 2, 3, 4, 6, 8, 7 } }, { 251375, 0.04, from = { 6, 2 } }, { 251376, 0.03, from = { 8, 6, 4, 2 } }, { 251377, 0.02, from = { 4, 2 } }, { 253980, 0.02, from = { 4, 3, 1, 2, 6, 8, 7, 9 } }, { 253978, 0.02, from = { 8, 3, 1, 2, 4, 6, 7 } }, { 251350, from = { 3, 1, 2, 4, 6, 8 } }, { 251351, from = { 3, 1, 2, 4, 6, 8, 7, 9 } }, { 251352, from = { 3, 1, 2, 4, 6, 8, 7, 9 } }, { 251353, from = { 3, 1, 2, 4, 6, 8, 7, 9 } }, { 251354, from = { 3, 1, 2, 4, 6, 8 } }, { 252814, from = { 3, 1, 2, 4, 6, 8, 7 } }, { 252815, from = { 3, 1, 2, 4, 6, 8, 7, 9 } }, { 252816, from = { 3, 1, 2, 4, 6, 8, 7 } }, { 252817, from = { 3, 1, 2, 4, 6, 8, 7 } }, { 252818, from = { 3, 1, 2, 4, 6, 8, 7, 9 } }, { 252819, from = { 3, 1, 2, 4, 6, 8, 7, 9 } } } },
    },
    LORDAERON = {
        { name = "The Baron", npcID = 250660, display = 144188, level = 17, loot = { { 271204 }, { 271205 }, { 271206 } } },
        { name = "Witherfang", npcID = 250483, display = 144189, level = 17, loot = { { 271201 }, { 271202 }, { 271203 } } },
        { name = "The Abandoned", npcID = 250631, display = 138667, level = 18, loot = { { 271207 }, { 271208 }, { 271216 } } },
        { name = "Bjork", npcID = 256097, display = 144170, level = 19, loot = { { 271209 }, { 271210 }, { 271217 } } },
        { name = "Rath'mael", npcID = 250657, display = 144175, level = 20, loot = { { 271213 }, { 271214 }, { 271215 }, { 273085 }, { 273103 } } },
        { name = "Viktor the Vile", npcID = 256035, display = 139455, level = 19, loot = { { 271211 }, { 271212 }, { 271218 } } },
        { name = "Lordaeron Captain", npcID = 255699, kind = "rare", faction = "Horde", display = 139050, level = 19, loot = { { 6641 }, { 6642 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 286981, mobs = "Skeleton / Skeletal Soldier / Skeletal Mage / Fallen Necromancer" }, { 286977, mobs = "Ghoul / Ragged Ghoul / Plague Ghoul" }, { 286980, all = true }, { 286979, all = true }, { 286978, all = true } } },
    },
    SM_ARM = {
        { name = "Herod", npcID = 3975, display = 2041, level = 40, loot = { { 7719, 32.8 }, { 7718, 33.7 }, { 10330, 13.9 }, { 7717, 14 }, { 274295 }, { 251398 }, { 251399 }, { 251400 }, { 251401 }, { 251402 }, { 252843 }, { 252844 }, { 252845 }, { 252846 }, { 252847 }, { 252896 }, { 252897 }, { 252898 }, { 252899 }, { 254038 }, { 254040 }, { 254042 }, { 254044 }, { 254046 }, { 254048 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 5819 }, { 7755 }, { 7727 }, { 7728 }, { 7759 }, { 7754 }, { 10332 }, { 1992 }, { 2262 }, { 7787 }, { 7729 }, { 7761 }, { 7752 }, { 8226 }, { 7786 }, { 5756 }, { 7736 }, { 8225 }, { 7753 }, { 7730 }, { 7757 }, { 10333, 2.3 }, { 10329, 2.3, mobs = "Scarlet Defender / Scarlet Myrmidon" }, { 23192 }, { 7758 }, { 7760 }, { 10328, 0.3 }, { 10330, 13.9 }, { 10331, 2.1 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251398, from = { 1 } }, { 251399, from = { 1 } }, { 251400, from = { 1 } }, { 251401, from = { 1 } }, { 251402, from = { 1 } }, { 252843, from = { 1 } }, { 252844, from = { 1 } }, { 252845, from = { 1 } }, { 252846, from = { 1 } }, { 252847, from = { 1 } }, { 252896, from = { 1 } }, { 252897, from = { 1 } }, { 252898, from = { 1 } }, { 252899, from = { 1 } }, { 254038, from = { 1 } }, { 254040, from = { 1 } }, { 254042, from = { 1 } }, { 254044, from = { 1 } }, { 254046, from = { 1 } }, { 254048, from = { 1 } } } },
    },
    SM_CATH = {
        { name = "High Inquisitor Fairbanks", npcID = 4542, display = 2605, level = 40, loot = { { 19507, 34 }, { 19508, 32.3 }, { 19509, 31.7 }, { 251398 }, { 251399 }, { 251400 }, { 251401 }, { 251402 }, { 252843 }, { 252844 }, { 252845 }, { 252846 }, { 252847 }, { 252896 }, { 252897 }, { 252898 }, { 252899 }, { 254038 }, { 254040 }, { 254042 }, { 254046 }, { 254048 } } },
        { name = "Scarlet Commander Mograine", npcID = 3976, display = 2042, level = 42, loot = { { 7724, 20.1 }, { 10330, 14.6 }, { 7726, 42.8 }, { 7723, 19.1 }, { 251398 }, { 251399 }, { 251400 }, { 251401 }, { 251402 }, { 252843 }, { 252844 }, { 252845 }, { 252846 }, { 252847 }, { 252896 }, { 252897 }, { 252898 }, { 252899 }, { 254038 }, { 254040 }, { 254042 }, { 254044 }, { 254046 }, { 254048 } } },
        { name = "High Inquisitor Whitemane", npcID = 3977, display = 2043, level = 42, loot = { { 7720, 37.6 }, { 7722, 37.1 }, { 7721, 18.7 }, { 251398 }, { 251399 }, { 251400 }, { 251401 }, { 251402 }, { 252843 }, { 252844 }, { 252845 }, { 252846 }, { 252847 }, { 252896 }, { 252898 }, { 252899 }, { 254040 }, { 254042 }, { 254044 }, { 254046 }, { 254048 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 5819 }, { 7755 }, { 7727 }, { 7728 }, { 7759 }, { 7760 }, { 7754 }, { 10332 }, { 1992 }, { 2262 }, { 7787 }, { 7729 }, { 7761 }, { 7752 }, { 8226 }, { 7786 }, { 5756 }, { 7736 }, { 8225 }, { 7753 }, { 7730 }, { 7758 }, { 7757 }, { 10328, 0.3, mobs = "Scarlet Champion" }, { 10331, 2.1, mobs = "Scarlet Centurion" }, { 10329, 2.3 }, { 10330, 13.9 }, { 10333, 2.3 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251398, from = { 1, 2, 3 } }, { 251399, from = { 1, 2, 3 } }, { 251400, from = { 1, 2, 3 } }, { 251401, from = { 1, 2, 3 } }, { 251402, from = { 1, 2, 3 } }, { 252843, from = { 1, 2, 3 } }, { 252844, from = { 1, 2, 3 } }, { 252845, from = { 1, 2, 3 } }, { 252846, from = { 1, 2, 3 } }, { 252847, from = { 1, 2, 3 } }, { 252896, from = { 1, 2, 3 } }, { 252897, from = { 1, 2 } }, { 252898, from = { 1, 2, 3 } }, { 252899, from = { 1, 2, 3 } }, { 254038, from = { 1, 2 } }, { 254040, from = { 1, 2, 3 } }, { 254042, from = { 1, 2, 3 } }, { 254046, from = { 1, 2, 3 } }, { 254048, from = { 1, 2, 3 } }, { 254044, from = { 2, 3 } } } },
    },
    SM_GY = {
        { name = "Interrogator Vishas", npcID = 3983, display = 2044, level = 32, loot = { { 7682, 6.1 }, { 7683, 52.4 }, { 251378, 0.01 }, { 252821, 0.01 }, { 252822, 0.01 }, { 252823, 0.01 }, { 252824, 0.01 }, { 252825, 0.01 }, { 253978, 0.01 }, { 253982, 0.01 }, { 253984, 0.01 }, { 253986, 0.01 }, { 274290 }, { 252455 }, { 252513 }, { 252456 }, { 252514 }, { 252820 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253980 } } },
        { name = "Azshir the Sleepless", npcID = 6490, kind = "rare", display = 5534, level = 33, loot = { { 7709, 30.6 }, { 7708, 32.2 }, { 7731, 33.9 }, { 253976, 0.04 }, { 253986, 0.04 }, { 252512 }, { 252456 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252819 }, { 253980 }, { 253982 }, { 253984 } } },
        { name = "Fallen Champion", npcID = 6488, kind = "rare", display = 5230, level = 33, loot = { { 7691, 39 }, { 7690, 38.9 }, { 7689, 17.7 }, { 251375, 0.04 }, { 252820, 0.04 }, { 252456 }, { 252513 }, { 251350 }, { 251352 }, { 251353 }, { 251354 }, { 252818 }, { 252819 }, { 253976 }, { 253982 }, { 253986 } } },
        { name = "Ironspine", npcID = 6489, kind = "rare", display = 5231, level = 33, loot = { { 7688, 32.9 }, { 7687, 21.2 }, { 7686, 42 }, { 252820, 0.04 }, { 253976, 0.04 }, { 252512 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 253978 }, { 253980 }, { 253984 }, { 253986 } } },
        { name = "Bloodmage Thalnos", npcID = 4543, display = 11396, level = 34, loot = { { 7685, 50 }, { 7684, 47.8 }, { 251377, 0.01 }, { 252822, 0.01 }, { 253978, 0.02 }, { 253980, 0.01 }, { 253982, 0.01 }, { 253984, 0.01 }, { 253986, 0.01 }, { 252455 }, { 274291 }, { 252513 }, { 252514 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 5819 }, { 7727 }, { 7728 }, { 7754 }, { 10332 }, { 2262 }, { 7787 }, { 7729 }, { 7761 }, { 7752 }, { 8226 }, { 7786 }, { 7753 }, { 7730 }, { 1992 }, { 5756 }, { 7736 }, { 7755 }, { 7757 }, { 7758 }, { 7759 }, { 7760 }, { 8225 }, { 10328, 0.3 }, { 10329, 2.3 }, { 10330, 13.9 }, { 10331, 2.1 }, { 10333, 2.3 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 253986, 0.04, from = { 2, 5, 1, 3, 4 } }, { 253976, 0.04, from = { 4, 2, 1, 3, 5 } }, { 251375, 0.04, from = { 3 } }, { 252820, 0.04, from = { 4, 3, 1 } }, { 253978, 0.02, from = { 5, 1, 4 } }, { 251378, 0.01, from = { 1 } }, { 252821, 0.01, from = { 1 } }, { 252822, 0.01, from = { 5, 1 } }, { 252823, 0.01, from = { 1 } }, { 252824, 0.01, from = { 1 } }, { 252825, 0.01, from = { 1 } }, { 253982, 0.01, from = { 5, 1, 2, 3 } }, { 253984, 0.01, from = { 5, 1, 2, 4 } }, { 251377, 0.01, from = { 5 } }, { 253980, 0.01, from = { 5, 1, 2, 4 } }, { 251350, from = { 1, 2, 3, 4, 5 } }, { 251351, from = { 1, 2, 4, 5 } }, { 251352, from = { 1, 2, 3, 4, 5 } }, { 251353, from = { 1, 2, 3, 4, 5 } }, { 251354, from = { 1, 2, 3, 4, 5 } }, { 252814, from = { 1, 2, 4, 5 } }, { 252815, from = { 1, 2, 4, 5 } }, { 252816, from = { 1, 2, 4, 5 } }, { 252817, from = { 1, 2, 4, 5 } }, { 252818, from = { 1, 3, 4, 5 } }, { 252819, from = { 1, 2, 3, 5 } } } },
    },
    SM_LIB = {
        { name = "Houndmaster Loksey", npcID = 3974, display = 2040, level = 34, loot = { { 7710, 13.9 }, { 7756, 56.3 }, { 3456, 25.2 }, { 251378, 0.01 }, { 274292 }, { 252512 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 }, { 273109 } } },
        { name = "Arcanist Doan", npcID = 6487, display = 5266, level = 37, loot = { { 7714, 47.2 }, { 7713, 46.6 }, { 7712, 47.5 }, { 7711, 45.9 }, { 274293 }, { 274294 }, { 251398 }, { 251399 }, { 251400 }, { 251401 }, { 251402 }, { 252843 }, { 252844 }, { 252845 }, { 252846 }, { 252847 }, { 252896 }, { 252897 }, { 252898 }, { 252899 }, { 254038 }, { 254040 }, { 254042 }, { 254044 }, { 254046 }, { 254048 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 5819 }, { 7755 }, { 7727 }, { 7728 }, { 7759 }, { 7760 }, { 7754 }, { 10332 }, { 1992 }, { 2262 }, { 7787 }, { 7729 }, { 7761 }, { 7752 }, { 8226 }, { 7786 }, { 5756 }, { 7736 }, { 8225 }, { 7753 }, { 7730 }, { 7758 }, { 7757 }, { 10328, 0.3 }, { 10329, 2.3 }, { 10330, 13.9 }, { 10331, 2.1 }, { 10333, 2.3 } } },
        { name = "Doan's Strongbox", kind = "object", loot = { { 7146 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251378, 0.01, from = { 1 } }, { 251350, from = { 1 } }, { 251351, from = { 1 } }, { 251352, from = { 1 } }, { 251353, from = { 1 } }, { 251354, from = { 1 } }, { 252814, from = { 1 } }, { 252815, from = { 1 } }, { 252816, from = { 1 } }, { 252817, from = { 1 } }, { 252818, from = { 1 } }, { 252819, from = { 1 } }, { 253976, from = { 1 } }, { 253978, from = { 1 } }, { 253980, from = { 1 } }, { 253982, from = { 1 } }, { 253984, from = { 1 } }, { 253986, from = { 1 } }, { 251398, from = { 2 } }, { 251399, from = { 2 } }, { 251400, from = { 2 } }, { 251401, from = { 2 } }, { 251402, from = { 2 } }, { 252843, from = { 2 } }, { 252844, from = { 2 } }, { 252845, from = { 2 } }, { 252846, from = { 2 } }, { 252847, from = { 2 } }, { 252896, from = { 2 } }, { 252897, from = { 2 } }, { 252898, from = { 2 } }, { 252899, from = { 2 } }, { 254038, from = { 2 } }, { 254040, from = { 2 } }, { 254042, from = { 2 } }, { 254044, from = { 2 } }, { 254046, from = { 2 } }, { 254048, from = { 2 } } } },
    },
    SCHOLO = {
        { name = "Blood Steward of Kirtonos", npcID = 14861, display = 10925, level = 61, loot = { { 13523, 58.7 } } },
        { name = "Kirtonos the Herald", npcID = 10506, display = 7534, level = 60, loot = { { 16734, 18.8 }, { 13960, 19.2 }, { 13955, 18.1 }, { 13969, 18.7 }, { 13957, 18.7 }, { 13956, 18 }, { 13967, 18.4 }, { 14024, 18.4 }, { 13983, 14.2 } } },
        { name = "Jandice Barov", npcID = 10503, display = 11073, level = 61, loot = { { 16701, 16.5 }, { 14548, 10.5 }, { 18689, 9.4 }, { 14543, 2.5 }, { 14545, 15.8 }, { 18690, 10.7 }, { 14541, 8.9 }, { 22394, 8 }, { 13523, 19.9 } } },
        { name = "Rattlegore", npcID = 11622, display = 12073, level = 61, loot = { { 16711, 18.5 }, { 14539, 12.4 }, { 14538, 11.8 }, { 18686, 11.7 }, { 14537, 12.2 }, { 14528, 12.1 }, { 14531, 12.5 }, { 18782, 8.4 }, { 13873, 100 } } },
        { name = "Death Knight Darkreaver", npcID = 14516, display = 14591, level = 62, loot = { { 18760, 25.9 }, { 18761, 22.6 }, { 18758, 25 }, { 18759, 21.8 }, { 18749, quest = true }, { 18880, quest = true } } },
        { name = "Marduk Blackpool", npcID = 10433, display = 10248, level = 58, loot = { { 18692, 7 }, { 14576, 6.5 }, { 276069 }, { 276071 } } },
        { name = "Vectus", npcID = 10432, display = 2606, level = 60, loot = { { 18691, 6.8 }, { 14577, 7.5 }, { 273121, 5.9 }, { 276073 }, { 276072 } } },
        { name = "Ras Frostwhisper", npcID = 10508, display = 7919, level = 62, loot = { { 13314, 0.4 }, { 16689, 18.8 }, { 14503, 14.2 }, { 14340, 14.7 }, { 18693, 15.2 }, { 14525, 14.7 }, { 14502, 15.6 }, { 14522, 14.9 }, { 18694, 15.4 }, { 18695, 15.4 }, { 18696, 15.4 }, { 13952, 14.9 }, { 14487, 15.9 }, { 13521, 4.5 }, { 273112 } } },
        { name = "Instructor Malicia", npcID = 10505, display = 11069, level = 60, loot = { { 16710, 4.5 }, { 18681, 1.5 }, { 14633, 4.6 }, { 14626, 1.4 }, { 14637, 1.5 }, { 14611, 1.4 }, { 14624, 1.4 }, { 14629, 4.6 }, { 14640, 4.6 }, { 14615, 4.5 }, { 14622, 4.1 }, { 14636, 4.4 }, { 14614, 4.5 }, { 14620, 4.6 }, { 14632, 4.5 }, { 14638, 4.6 }, { 18682, 1.5 }, { 14612, 4.5 }, { 14623, 4.8 }, { 14631, 4.4 }, { 14641, 4.6 }, { 14616, 4.3 }, { 14621, 4.7 }, { 18684, 1.5 }, { 23201, 0.3 }, { 23200, 0.1 }, { 18680, 1.4 }, { 18683, 1.6 } } },
        { name = "Doctor Theolen Krastinov", npcID = 11261, display = 10901, level = 60, loot = { { 16684, 5.2 }, { 14617, 1.4 }, { 18681, 1.6 }, { 14633, 4.5 }, { 14626, 1.7 }, { 14637, 1.4 }, { 14611, 1.2 }, { 14624, 1.5 }, { 14629, 4.9 }, { 14640, 4.1 }, { 14615, 4.2 }, { 14622, 4.3 }, { 14636, 4.7 }, { 14614, 4.4 }, { 14620, 4.2 }, { 14632, 4.5 }, { 14638, 4.7 }, { 18682, 1.5 }, { 14612, 4.2 }, { 14623, 4 }, { 14631, 4.5 }, { 14641, 4.3 }, { 14616, 4.3 }, { 14621, 4.1 }, { 18684, 1.4 }, { 23201, 0.9 }, { 23200, 0.5 }, { 18680, 1.5 }, { 18683, 1.4 }, { 273118, 3.8 } } },
        { name = "Lorekeeper Polkelt", npcID = 10901, display = 11492, level = 60, loot = { { 16705, 5.2 }, { 18681, 1.5 }, { 14633, 4.5 }, { 14626, 1.5 }, { 14637, 1.4 }, { 14611, 1.3 }, { 14624, 1.5 }, { 14629, 4.4 }, { 14640, 4.5 }, { 14615, 4.7 }, { 14622, 4.2 }, { 14636, 4.6 }, { 14614, 4.4 }, { 14620, 4.4 }, { 14632, 4.6 }, { 14638, 4.4 }, { 18682, 1.4 }, { 14612, 4.7 }, { 14623, 4.2 }, { 14631, 4.7 }, { 14641, 4.4 }, { 14616, 4.5 }, { 14621, 4.2 }, { 18684, 1.4 }, { 23201, 0.1 }, { 23200, 0.1 }, { 18680, 1.5 }, { 18683, 1.3 } } },
        { name = "The Ravenian", npcID = 10507, display = 10433, level = 60, loot = { { 16716, 4.6 }, { 18681, 1.4 }, { 14633, 4.5 }, { 14626, 1.3 }, { 14637, 1.3 }, { 14611, 1.5 }, { 14624, 1.4 }, { 14629, 4.4 }, { 14640, 4.7 }, { 14615, 4.6 }, { 14622, 4.6 }, { 14636, 4.6 }, { 14614, 4.6 }, { 14620, 4.5 }, { 14632, 4.3 }, { 14638, 4.7 }, { 18682, 1.4 }, { 14612, 4.3 }, { 14623, 4.3 }, { 14631, 4.6 }, { 14641, 4.5 }, { 14616, 4.7 }, { 14621, 4.2 }, { 18684, 1.6 }, { 23201, 0.3 }, { 23200, 0.1 }, { 18680, 1.4 }, { 18683, 1.4 } } },
        { name = "Lord Alexei Barov", npcID = 10504, display = 11072, level = 60, loot = { { 16722, 4.3 }, { 18681, 9.1 }, { 14633, 0.2 }, { 14626, 9.7 }, { 14637, 9.3 }, { 14611, 8.7 }, { 14624, 9 }, { 14629, 0.3 }, { 14640, 0.2 }, { 14615, 0.1 }, { 14622, 0.2 }, { 14636, 0.3 }, { 14614, 0.1 }, { 14620, 0.2 }, { 14632, 0.3 }, { 14638, 0.3 }, { 18682, 9.2 }, { 14612, 0.1 }, { 14623, 0.2 }, { 14631, 0.3 }, { 14641, 0.4 }, { 14616, 0.1 }, { 14621, 0.1 }, { 18684, 9.3 }, { 23201, 1.1 }, { 23200, 0.7 }, { 18680, 9.4 }, { 18683, 9.7 } } },
        { name = "Lady Illucia Barov", npcID = 10502, display = 11835, level = 60, loot = { { 18681, 1.7 }, { 14633, 4.5 }, { 14626, 1.4 }, { 14637, 1.4 }, { 14611, 1.5 }, { 14624, 1.5 }, { 14629, 4.4 }, { 14640, 4.7 }, { 14615, 5 }, { 14622, 4.6 }, { 14636, 4.8 }, { 14614, 4.6 }, { 14620, 4.9 }, { 14632, 4.7 }, { 14638, 4.8 }, { 18682, 1.6 }, { 14612, 4.8 }, { 14623, 4.4 }, { 14631, 4.7 }, { 14641, 4.4 }, { 14616, 4.5 }, { 14621, 4.7 }, { 18684, 1.5 }, { 23201, 0.4 }, { 23200, 0.2 }, { 18680, 1.6 }, { 18683, 1.5 } } },
        { name = "Darkmaster Gandling", npcID = 1853, display = 11070, level = 61, loot = { { 13937, 1.7 }, { 14514, 8.7 }, { 16693, 10.8 }, { 16686, 13.8 }, { 16698, 11 }, { 16707, 10.4 }, { 16720, 11.2 }, { 16677, 13.2 }, { 16667, 4.3 }, { 16727, 6.6 }, { 16731, 12.3 }, { 13944, 15.2 }, { 13951, 13.1 }, { 13950, 2.1 }, { 13398, 12.8 }, { 22433, 12.5 }, { 13938, 12.9 }, { 13953, 11.2 }, { 13964, 12.6 }, { 19276, 4.3 }, { 13501, 7.5 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 16685, mobs = "Scholomance Adept" }, { 16702, mobs = "Scholomance Necromancer" }, { 16710, mobs = "Scholomance Occultist / Risen Construct" }, { 16714, mobs = "Diseased Ghoul" }, { 16716, mobs = "Spectral Researcher / Spectral Teacher / Scholomance Handler" }, { 16671, mobs = "Splintered Skeleton" }, { 16722, 3.2, mobs = "Risen Warrior / Risen Protector" }, { 12843 }, { 12841 }, { 12840 }, { 20520, mobs = "Scholomance Necromancer / Scholomance Dark Summoner" }, { 12753, mobs = "Risen Construct / Risen Bonewarder" }, { 18698, all = true }, { 18699, all = true }, { 14536, all = true }, { 18700, all = true }, { 18702, all = true }, { 18697, all = true }, { 18701, all = true }, { 16254, mobs = "Spectral Researcher" }, { 16255, mobs = "Scholomance Adept" }, { 15773, mobs = "Spectral Researcher" }, { 15776, mobs = "Scholomance Dark Summoner" }, { 13920 }, { 16684, 4.7 }, { 16705, 4.5 }, { 14611, 2.2 }, { 14612, 3.1 }, { 14614, 3.1 }, { 14615, 3.2 }, { 14616, 3.1 }, { 14620, 3.2 }, { 14621, 3.1 }, { 14622, 3.1 }, { 14623, 3 }, { 14624, 2.3 }, { 14626, 2.5 }, { 14629, 3.3 }, { 14631, 3.4 }, { 14632, 3.3 }, { 14633, 3.3 }, { 14636, 3.4 }, { 14637, 2.4 }, { 14638, 3.4 }, { 14640, 3.3 }, { 14641, 3.3 }, { 18680, 2.5 }, { 18681, 2.5 }, { 18682, 2.4 }, { 18683, 2.5 }, { 18684, 2.4 }, { 23200, 1.2 }, { 23201, 1.6 }, { 252940 } } },
        -- FDJ 2.0.8 (Wowhead Forever, % de sus muertes): se invoca en la sala de Ras con el Brasero de las misiones del Set 2
        { name = "Kormok", npcID = 16118, kind = "rare", summon = { text = "SUMMON_BRAZIER" }, display = 16020, level = 60, loot = { { 22332, 14.6 }, { 22303, 15.6 }, { 22326, 12.2 }, { 21984, 15.1, quest = true }, { 22046, 3.4, quest = true }, { 22331 }, { 22333 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 13521, from = { 8 } }, { 14514, from = { 15 } }, { 13501, from = { 15 } }, { 16254, from = { 16 } }, { 16255, from = { 16 } }, { 15776, from = { 16 } }, { 15773, from = { 16 } }, { 252940, from = { 16 } }, { 273118, 3.8, from = { 10 } }, { 273121, 5.9, from = { 7 } } } },
    },
    SFK = {
        { name = "Rethilgore", npcID = 3914, display = 524, level = 20, loot = { { 5254, 89.5 }, { 273456 }, { 273457 } } },
        { name = "Fel Steed / Shadow Charger", npcID = 3864, display = 1952, level = { 20, 21 }, loot = { { 6341, 6.2 }, { 932, 18.7 }, { 251341, 0.06 }, { 251360, 0.02 }, { 251361, 0.01 }, { 251362, 0.05 }, { 251363, 0.04 }, { 251364, 0.05 }, { 251381, 0.02 }, { 251382, 0.02 }, { 252777, 0.02 }, { 252778, 0.01 }, { 252779, 0.04 }, { 252780, 0.01 }, { 252781, 0.08 }, { 252782, 0.02 }, { 252799, 0.05 }, { 252800, 0.02 }, { 252801, 0.02 }, { 252803, 0.05 }, { 253902, 0.04 }, { 253904, 0.02 }, { 253906, 0.06 }, { 253908, 0.04 }, { 253910, 0.06 }, { 253912, 0.05 }, { 253940, 0.02 }, { 253942, 0.02 }, { 253946, 0.07 }, { 253948, 0.07 } } },
        { name = "Razorclaw the Butcher", npcID = 3886, display = 524, level = 22, loot = { { 1292, 9.8 }, { 6226, 43.5 }, { 6633, 42 }, { 273096 }, { 253938 }, { 253942 }, { 253944 } } },
        { name = "Baron Silverlaine", npcID = 3887, display = 3222, level = 24, loot = { { 6321, 19.5 }, { 6323, 40 }, { 273637 } } },
        { name = "Commander Springvale", npcID = 4278, display = 3223, level = 24, loot = { { 6320, 29.3 }, { 3191, 35 }, { 273643 }, { 273105 } } },
        { name = "Odo the Blindwatcher", npcID = 4279, display = 522, level = 24, loot = { { 6318, 35.1 }, { 6319, 61.1 }, { 273645 } } },
        { name = "Deathsworn Captain", npcID = 3872, kind = "rare", display = 3224, level = 25, loot = { { 6642, 35.3 }, { 6641, 57.7 } } },
        { name = "Arugal's Voidwalker", npcID = 4627, display = 1131, level = { 24, 25 }, loot = { { 5943, 2.5 } } },
        { name = "Fenrus the Devourer", npcID = 4274, display = 2352, level = 25, loot = { { 251380 }, { 6340, 74.2 }, { 3230, 17.2 }, { 273646 } } },
        { name = "Wolf Master Nandos", npcID = 3927, display = 11179, level = 25, loot = { { 3748, 56.7 }, { 6314, 38.6 }, { 273647 } } },
        { name = "Archmage Arugal", npcID = 4275, display = 2353, level = 26, loot = { { 6324, 34.9 }, { 6392, 34 }, { 6220, 17.6 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 2292 }, { 1489 }, { 1974 }, { 2807 }, { 1482 }, { 1935 }, { 1483 }, { 1318 }, { 3194 }, { 2205 }, { 1484 }, { 5943, 2.4 }, { 6341, 7.8 } } },
        { name = "Jordan's Smithing Hammer", kind = "object", loot = { { 6895 } } },
        { name = "The Book of Ur", kind = "object", loot = { { 6283 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 252781, 0.08, from = { 2 } }, { 253946, 0.07, from = { 2 } }, { 253948, 0.07, from = { 2 } }, { 251341, 0.06, from = { 2 } }, { 253906, 0.06, from = { 2 } }, { 253910, 0.06, from = { 2 } }, { 251362, 0.05, from = { 2 } }, { 251364, 0.05, from = { 2 } }, { 252799, 0.05, from = { 2 } }, { 252803, 0.05, from = { 2 } }, { 253912, 0.05, from = { 2 } }, { 251363, 0.04, from = { 2 } }, { 252779, 0.04, from = { 2 } }, { 253902, 0.04, from = { 2 } }, { 253908, 0.04, from = { 2 } }, { 251360, 0.02, from = { 2 } }, { 251381, 0.02, from = { 2 } }, { 251382, 0.02, from = { 2 } }, { 252777, 0.02, from = { 2 } }, { 252782, 0.02, from = { 2 } }, { 252800, 0.02, from = { 2 } }, { 252801, 0.02, from = { 2 } }, { 253904, 0.02, from = { 2 } }, { 253940, 0.02, from = { 2 } }, { 253942, 0.02, from = { 2, 3 } }, { 251361, 0.01, from = { 2 } }, { 252778, 0.01, from = { 2 } }, { 252780, 0.01, from = { 2 } }, { 253938, from = { 3 } }, { 253944, from = { 3 } }, { 251380, from = { 9 } } } },
    },
    STRAT_LIVE = {
        { name = "Skul", npcID = 10393, kind = "rare", display = 2606, level = 58, loot = { { 13395, 29.9 }, { 13394, 29.8 }, { 13396, 30.4 } } },
        { name = "Stratholme Courier", npcID = 11082, display = 10547, level = 57, loot = { { 13303, 39.8 }, { 13305, 39 }, { 13304, 39.5 }, { 13307, 38.3 }, { 13306, 40.1 }, { 13302, 39.4 } } },
        { name = "Hearthsinger Forresten", npcID = 10558, kind = "rare", display = 10482, level = 57, loot = { { 16682, 12.9 }, { 13378, 29 }, { 13384, 17.6 }, { 13383, 19.5 }, { 13379, 15.6 } } },
        { name = "The Unforgiven", npcID = 10516, display = 10771, level = 57, loot = { { 16717, 12.5 }, { 13404, 20.2 }, { 13405, 22.7 }, { 13409, 17.5 }, { 13408, 19.3 } } },
        { name = "Postmaster Malown", npcID = 11143, display = 10669, level = 60, loot = { { 13390, 5 }, { 13388, 5 }, { 13389, 10 }, { 13391, 25 }, { 13392, 15 }, { 13393, 5 } } },
        { name = "Timmy the Cruel", npcID = 10808, display = 571, level = 58, loot = { { 16724, 12.3 }, { 13400, 22.1 }, { 13403, 17.7 }, { 13402, 21.7 }, { 13401, 19.5 } } },
        { name = "Malor the Zealous", npcID = 11032, display = 10458, level = 60, loot = { { 12845, 100 }, { 276398 }, { 276399 }, { 276397 } } },
        { name = "Crimson Hammersmith", npcID = 11120, display = 10637, level = 60, loot = { { 18781, 63.2 } } },
        { name = "Cannon Master Willey", npcID = 10997, display = 10674, level = 60, loot = { { 16708, 14.2 }, { 22407, 18.3 }, { 22403, 22.7 }, { 22405, 16.6 }, { 18721, 17 }, { 13381, 17 }, { 13382, 18 }, { 13380, 22 }, { 13377, 91.1 }, { 22404, 10.8 }, { 22406, 7.1 }, { 12839, 10.9 } } },
        { name = "Archivist Galford", npcID = 10811, display = 10544, level = 60, loot = { { 16692, 18 }, { 13386, 21.5 }, { 13387, 21.2 }, { 18716, 21.3 }, { 13385, 13.7 }, { 12811, 4.3 }, { 22897, 3.3 } } },
        { name = "Balnazzar", npcID = 10813, display = 10545, level = 62, loot = { { 13353, 2.1 }, { 14512, 6.9 }, { 16725, 17.3 }, { 13359, 17.4 }, { 18718, 12.7 }, { 12103, 22.8 }, { 18720, 15 }, { 13358, 17.6 }, { 13369, 13.8 }, { 13360, 17.2 }, { 18717, 21.1 }, { 22334, 1.9 }, { 13348, 17.1 }, { 13520, 4.8 }, { 13250, 11.8 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 16697, 1.2, mobs = "Crimson Conjuror / Crimson Initiate / Crimson Priest" }, { 16685, mobs = "Crimson Conjuror / Crimson Sorcerer / Crimson Battle Mage" }, { 16702, mobs = "Crimson Sorcerer / Crimson Conjuror" }, { 16710, mobs = "Plague Ghoul" }, { 16714, mobs = "Crimson Inquisitor / Shrieking Banshee / Wailing Banshee" }, { 16681, mobs = "Crimson Defender / Ghoul Ravener / Fleshflayer Ghoul" }, { 16671, mobs = "Crimson Monk" }, { 16723, 2.1, mobs = "Crimson Guardsman / Crimson Gallant / Rockwing Gargoyle / Rockwing Screecher" }, { 16736 }, { 12811, mobs = "All Scarlet Crusade mobs" }, { 12735 }, { 12843 }, { 12841 }, { 12840 }, { 18742, all = true }, { 18743, all = true }, { 17061, all = true }, { 18741, all = true }, { 18744, all = true }, { 18745, all = true }, { 18736, all = true }, { 16249, mobs = "Crimson Sorcerer" }, { 16248 }, { 14495 }, { 15777, mobs = "Crimson Battle Mage" }, { 15768 }, { 18658, mobs = "Crimson Inquisitor" }, { 16052, mobs = "Crimson Inquisitor" }, { 16725, 14.2 }, { 12103, 15.6 }, { 13348, 15.6 }, { 13358, 13.6 }, { 13359, 15.5 }, { 13360, 14.6 }, { 13369, 16 }, { 18717, 14.1 }, { 18718, 12 }, { 18720, 11.8 }, { 12827 } } },
        { name = "Plans", kind = "object", loot = { { 12827 }, { 12830 } } },
        -- FDJ 2.0.8 (Wowhead Forever, % de sus muertes): sale al tocar la caja de tabaco (The Great Fras Siabi)
        { name = "Ezra Grimm", npcID = 11058, display = 10475, level = 61, optional = true, loot = { { 276396, 41.2 }, { 276395, 26.5 }, { 276394, 20.6 }, { 13172, 35.3, quest = true }, { 273129, 94.1 }, { 273117, 5.9 } } },
        -- 0.5: se invocan juntos en la sala de Balnazzar con el mismo Brasero.
        { name = "Jarien and Sothos", kind = "rare", level = 60, summon = { text = "SUMMON_BRAZIER" }, members = { { name = "Jarien", npcID = 16101, level = 60 }, { name = "Sothos", npcID = 16102, level = 60 } }, loot = { { 22301 }, { 22327 }, { 22328 }, { 22329 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 12839, from = { 9 } }, { 14512, from = { 11 } }, { 13520, from = { 11 } }, { 16249, from = { 12 } }, { 15777, from = { 12 } }, { 18658, from = { 12 } }, { 16052, from = { 12 } }, { 12827, from = { 12 } } } },
    },
    STRAT_UD = {
        { name = "Magistrate Barthilas", npcID = 10435, display = 10433, level = 58, loot = { { 18727, 15.6 }, { 13376, 15.3 }, { 18726, 15.1 }, { 18722, 15.4 }, { 23198, 1.2 }, { 18725, 15.7 }, { 12382, 100 } } },
        { name = "Stonespine", npcID = 10809, kind = "rare", display = 7856, level = 60, loot = { { 13397, 31.3 }, { 13954, 29.6 }, { 13399, 34 } } },
        { name = "Baroness Anastari", npcID = 10436, display = 10698, level = 59, loot = { { 16704, 17.7 }, { 18728, 17.5 }, { 18730, 18.6 }, { 18729, 17.2 }, { 13534, 17.2 }, { 13538, 10.1 }, { 13535, 10.6 }, { 13537, 10.5 }, { 13539, 10.7 }, { 13514, 8.9 }, { 273124, 7.1 } } },
        { name = "Black Guard Swordsmith", npcID = 11121, display = 775, level = { 61, 62 }, loot = { { 18783, 42.4 } } },
        { name = "Nerub'enkan", npcID = 10437, display = 9793, level = 60, loot = { { 16675, 17.7 }, { 18740, 18.1 }, { 18739, 18 }, { 18738, 18.1 }, { 13529, 18.6 }, { 13533, 10.8 }, { 13532, 10.8 }, { 13531, 11.2 }, { 13530, 11.2 }, { 13508, 9 } } },
        { name = "Maleki the Pallid", npcID = 10438, display = 10546, level = 61, loot = { { 16691, 17.8 }, { 18734, 18.3 }, { 18735, 17.9 }, { 13524, 17.9 }, { 18737, 18.9 }, { 13528, 10.4 }, { 13525, 10.9 }, { 13526, 11.2 }, { 13527, 11.3 }, { 13509, 8.7 }, { 12833, 8 } } },
        { name = "Ramstein the Gorger", npcID = 10439, display = 12818, level = 61, loot = { { 16737, 17.9 }, { 18723, 12 }, { 13374, 12.4 }, { 13373, 12.1 }, { 13515, 12.7 }, { 13375, 12.5 }, { 13372, 12 } } },
        { name = "Baron Rivendare", npcID = 10440, display = 10729, level = 62, loot = { { 13335 }, { 13505, 0.1 }, { 22411, 11.6 }, { 22412, 17.2 }, { 13340, 14.6 }, { 13346, 14.4 }, { 22409, 16.4 }, { 13344, 13.3 }, { 22410, 11.9 }, { 13345, 12.7 }, { 22408, 17.5 }, { 13349, 15.6 }, { 13368, 5.7 }, { 13361, 6.2 }, { 16694, 10.2 }, { 16687, 13.3 }, { 16699, 9.9 }, { 16709, 11.2 }, { 16719, 8 }, { 16678, 11.1 }, { 16668, 4.1 }, { 16728, 6.8 }, { 16732, 8.7 }, { 13251, quest = true } } },
        { name = "Trash mobs", kind = "trash", loot = { { 16697, 1.2, mobs = "Thuzadin Necromancer / Thuzadin Shadowcaster" }, { 16685, mobs = "Thuzadin Shadowcaster / Thuzadin Necromancer" }, { 16702, mobs = "Thuzadin Necromancer / Thuzadin Shadowcaster" }, { 16710, mobs = "Plague Ghoul" }, { 16714, mobs = "Shrieking Banshee / Wailing Banshee" }, { 16681, mobs = "Ghoul Ravener / Fleshflayer Ghoul" }, { 16671, mobs = "Crypt Crawler / Crypt Beast" }, { 16723, 2.1, mobs = "Rockwing Gargoyle / Rockwing Screecher" }, { 16736, mobs = "Patchwork Horror / Venom Belcher / Bile Spewer" }, { 12811 }, { 12735, mobs = "Patchwork Horror / Bile Spewer / Venom Belcher" }, { 12843 }, { 12841 }, { 12840 }, { 18742, all = true }, { 18743, all = true }, { 17061, all = true }, { 18741, all = true }, { 18744, all = true }, { 18745, all = true }, { 18736, all = true }, { 16249 }, { 16248, mobs = "Thuzadin Shadowcaster" }, { 14495, mobs = "Spectral Citizen" }, { 15777 }, { 15768, mobs = "Ghoul Ravener" }, { 18658 }, { 16052 }, { 16725, 14.2 }, { 12103, 15.6 }, { 13348, 15.6 }, { 13358, 13.6 }, { 13359, 15.5 }, { 13360, 14.6 }, { 13369, 16 }, { 18717, 14.1 }, { 18718, 12 }, { 18720, 11.8 }, { 12830 } } },
        { name = "Plans", kind = "object", loot = { { 12827 }, { 12830 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 12833, from = { 6 } }, { 16248, from = { 9 } }, { 14495, from = { 9 } }, { 15768, from = { 9 } }, { 12830, from = { 9 } }, { 273124, 7.1, from = { 3 } } } },
    },
    ST = {
        { name = "Balcony Minibosses", display = 6701, level = 52, members = { { name = "Gasher", npcID = 5713, level = 51 }, { name = "Hukku", npcID = 5715, level = 52 }, { name = "Loro", npcID = 5714, level = 51 }, { name = "Mijan", npcID = 5717, level = 52 }, { name = "Zolo", npcID = 5712, level = 51 }, { name = "Zul'Lor", npcID = 5716, level = 52 } }, loot = { { 10783, 5 }, { 10784, 2.6 }, { 10787, 7 }, { 10788, 10.1 }, { 10785, 5.7 }, { 10786, 8.3 }, { 20606, 20 }, { 20607, 23.9 }, { 20608, 22.4 } } },
        { name = "Atal'alarion", npcID = 8580, display = 7873, level = 50, loot = { { 10800, 38.1 }, { 10798, 36.6 }, { 10799, 18.3 } } },
        { name = "Spawn of Hakkar", npcID = 5708, display = 4065, level = 51, loot = { { 10801, 46.7 }, { 10802, 23.7 } } },
        { name = "Avatar of Hakkar", npcID = 8443, display = 8053, level = { 49, 50 }, loot = { { 12462, 0.1 }, { 10843, 28.5 }, { 10845, 26.5 }, { 10842, 30.3 }, { 10846, 30.2 }, { 10838, 14.3 }, { 10844, 14.1 }, { 252871 }, { 10663, quest = true } } },
        { name = "Jammal'an the Prophet", npcID = 5710, display = 6708, level = 54, loot = { { 10806, 27 }, { 10808, 29.6 }, { 10807, 27.2 }, { 254102 }, { 252919 }, { 252918 }, { 252869 }, { 251405 }, { 273119 } } },
        { name = "Ogom the Wretched", npcID = 5711, display = 6709, level = 53, loot = { { 10805, 29.9 }, { 10803, 30.4 }, { 10804, 30.8 } } },
        { name = "Dreamscythe", npcID = 5721, display = 7553, level = 53, loot = { { 12465, 9.5 }, { 12466, 9.7 }, { 12464, 8.5 }, { 10797, 10.2 }, { 12463, 8.1 }, { 12243, 8.6 }, { 10795, 9.4 }, { 10796, 9.2 } } },
        { name = "Weaver", npcID = 5720, display = 6375, level = 51, loot = { { 12465, 8.6 }, { 12466, 9.2 }, { 12464, 7.5 }, { 10797, 8.6 }, { 12463, 10.6 }, { 12243, 10.1 }, { 10795, 10 }, { 10796, 9.3 } } },
        { name = "Hazzas", npcID = 5722, display = 9584, level = 53, loot = { { 12465, 8.1 }, { 12466, 8.5 }, { 12464, 8.2 }, { 10797, 9.5 }, { 12463, 8.6 }, { 12243, 8.4 }, { 10795, 9.6 }, { 10796, 8.8 } } },
        { name = "Morphaz", npcID = 5719, display = 7975, level = 52, loot = { { 12465, 7.9 }, { 12466, 8.2 }, { 12464, 6.9 }, { 10797, 7.3 }, { 12463, 8.2 }, { 12243, 7.7 }, { 10795, 7.3 }, { 10796, 8.3 }, { 20019, quest = true }, { 20022, quest = true }, { 20025, quest = true }, { 20085, quest = true } } },
        { name = "Shade of Eranikus", npcID = 5709, display = 7806, level = 55, loot = { { 10847, 0.2 }, { 10833, 30.9 }, { 10829, 31.8 }, { 10836, 26.3 }, { 10835, 28.9 }, { 10837, 14.2 }, { 10828, 16.4 }, { 10454, 63.7 }, { 254106 }, { 252919 }, { 251403 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 10630, 0.1, all = true }, { 10632, all = true }, { 10631, all = true }, { 10633, 0.1, all = true }, { 10629, all = true }, { 10634, all = true }, { 10624, all = true }, { 10623, all = true }, { 10625, all = true }, { 10626, 0.1, all = true }, { 10628, all = true }, { 10627, all = true }, { 10782 }, { 10781 }, { 10780 }, { 16216, mobs = "Atal'ai Witch Doctor" }, { 15733, mobs = "Murk Worm" }, { 10783, 4.2 }, { 10784, 2.8 }, { 10785, 5.6 }, { 10786, 8.3 }, { 10787, 7 }, { 10788, 9.7 }, { 10795, 8.9 }, { 10796, 8.8 }, { 10797, 8.9 }, { 10838, 16.5 }, { 10842, 32.8 }, { 10843, 31.9 }, { 10844, 15.9 }, { 10845, 30.8 }, { 10846, 33.2 }, { 12243, 8.6 }, { 12463, 8.9 }, { 12464, 7.9 }, { 12465, 8.7 }, { 12466, 8.8 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 254106, from = { 11 } }, { 252919, from = { 11, 5 } }, { 251403, from = { 11 } }, { 254102, from = { 5 } }, { 252918, from = { 5 } }, { 252869, from = { 5 } }, { 251405, from = { 5 } }, { 15733, from = { 12 } }, { 16216, from = { 12 } }, { 252871, from = { 4 } } } },
    },
    DM = {
        { name = "Rhahk'Zor", npcID = 644, display = 14403, level = 19, loot = { { 872, 3.9 }, { 5187, 72.9 }, { 273289 }, { 251362, 0.02 }, { 251363, 0.02 }, { 251364, 0.03 }, { 252779, 0.01 }, { 252781, 0.02 }, { 252782, 0.01 }, { 253906, 0.03 }, { 253908, 0.01 }, { 253910, 0.01 } } },
        { name = "Miner Johnson", npcID = 3586, kind = "rare", display = 556, level = 19, loot = { { 5443, 40.4 }, { 5444, 55.9 } } },
        { name = "Sneed", npcID = 643, display = 7125, level = 20, loot = { { 5194, 27.6 }, { 5195, 67.3 }, { 273293 }, { 273092 }, { 251341, 0.01 }, { 251360, 0.01 }, { 251363, 0.01 }, { 251364, 0.01 }, { 252780, 0.01 }, { 253902, 0.02 }, { 253904, 0.01 }, { 251361 } } },
        { name = "Sneed's Shredder", npcID = 642, display = 1269, level = 20, loot = { { 1937, 9.5 }, { 2169, 52.2 }, { 285292 } } },
        { name = "Gilnid", npcID = 1763, display = 7124, level = 20, loot = { { 1156, 36.9 }, { 5199, 56.9 }, { 273297 }, { 251363, 0.01 }, { 252777, 0.03 }, { 252778, 0.01 }, { 252779, 0.01 }, { 252780, 0.02 }, { 252782, 0.01 }, { 253904, 0.01 }, { 253906, 0.02 }, { 273086 }, { 251340 }, { 251341 }, { 251342 }, { 251343 }, { 251344 }, { 252771 }, { 252772 }, { 252773 }, { 252774 }, { 252775 }, { 252776 }, { 253908 } } },
        { name = "Mr. Smite", npcID = 646, display = 2026, level = 20, loot = { { 7230, 18.6 }, { 5192, 38.3 }, { 5196, 37.4 }, { 284715 }, { 251361, 0.01 }, { 251362, 0.01 }, { 252777, 0.01 }, { 252778, 0.01 }, { 252779, 0.01 }, { 252780, 0.01 }, { 252781, 0.01 }, { 252782, 0.01 }, { 253906, 0.01 } } },
        { name = "Captain Greenskin", npcID = 647, display = 7113, level = 20, loot = { { 5201, 37.8 }, { 10403, 26.6 }, { 5200, 27.8 }, { 253906, 0.01 }, { 253912, 0.01 } } },
        { name = "Edwin VanCleef", npcID = 639, display = 2029, level = 21, loot = { { 5193, 23.1 }, { 5202, 23.2 }, { 10399, 14.7 }, { 5191, 15.7 }, { 2874, 56.1 }, { 251382, 0.01 }, { 252799, 0.01 }, { 252800, 0.01 }, { 252801, 0.01 }, { 252803, 0.01 }, { 253938, 0.02 }, { 253948, 0.02 }, { 253940 }, { 251345 }, { 251346 }, { 251347 }, { 251348 }, { 251349 }, { 251383 }, { 252792 }, { 252793 }, { 252794 }, { 252795 }, { 252796 }, { 252797 }, { 253942 }, { 253944 }, { 253946 } } },
        { name = "Cookie", npcID = 645, display = 1305, level = 20, loot = { { 5198, 33.4 }, { 5197, 55.3 }, { 8490, 10.2 }, { 273298 }, { 251341, 0.01 }, { 251360, 0.02 }, { 252778, 0.01 }, { 252779, 0.01 }, { 253906, 0.01 }, { 253908, 0.01 }, { 253910, 0.01 }, { 253912, 0.01 }, { 273102 } } },
        { name = "Defias Gunpowder", kind = "object", loot = { { 5397 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 8492 }, { 1934, 5.5, mobs = "Defias Blackguard" }, { 10402, 2.7, mobs = "Defias Strip Miner" }, { 1943, 6.2 }, { 1951, 6, mobs = "Defias Pirate / Defias Squallshaper" }, { 10400, 3.4, mobs = "Defias Overseer / Defias Taskmaster" }, { 10401, 3.1, mobs = "Defias Overseer / Defias Taskmaster" }, { 1929, 5.8, mobs = "Defias Evoker / Defias Wizard" }, { 1930, 2.5 }, { 1936, 5.6, mobs = "Goblin Engineer" }, { 1944, 5.1 }, { 1945, 6.5 }, { 1925, 6.6 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251364, 0.03, from = { 1, 3 } }, { 253906, 0.03, from = { 1, 5, 9, 7, 6 } }, { 252777, 0.03, from = { 5, 6 } }, { 251362, 0.02, from = { 1, 6 } }, { 251363, 0.02, from = { 1, 5, 3 } }, { 252781, 0.02, from = { 1, 6 } }, { 251360, 0.02, from = { 9, 3 } }, { 252780, 0.02, from = { 5, 6, 3 } }, { 253902, 0.02, from = { 3 } }, { 253938, 0.02, from = { 8 } }, { 253948, 0.02, from = { 8 } }, { 252779, 0.01, from = { 9, 6, 5, 1 } }, { 252782, 0.01, from = { 6, 5, 1 } }, { 253908, 0.01, from = { 9, 1, 5 } }, { 253910, 0.01, from = { 9, 1 } }, { 251341, 0.01, from = { 9, 3, 5 } }, { 253904, 0.01, from = { 5, 3 } }, { 252778, 0.01, from = { 9, 6, 5 } }, { 251361, 0.01, from = { 6, 3 } }, { 253912, 0.01, from = { 9, 7 } }, { 251382, 0.01, from = { 8 } }, { 252799, 0.01, from = { 8 } }, { 252800, 0.01, from = { 8 } }, { 252801, 0.01, from = { 8 } }, { 252803, 0.01, from = { 8 } }, { 253940, from = { 8 } }, { 251340, from = { 5 } }, { 251342, from = { 5 } }, { 251343, from = { 5 } }, { 251344, from = { 5 } }, { 252771, from = { 5 } }, { 252772, from = { 5 } }, { 252773, from = { 5 } }, { 252774, from = { 5 } }, { 252775, from = { 5 } }, { 252776, from = { 5 } }, { 251345, from = { 8 } }, { 251346, from = { 8 } }, { 251347, from = { 8 } }, { 251348, from = { 8 } }, { 251349, from = { 8 } }, { 251383, from = { 8 } }, { 252792, from = { 8 } }, { 252793, from = { 8 } }, { 252794, from = { 8 } }, { 252795, from = { 8 } }, { 252796, from = { 8 } }, { 252797, from = { 8 } }, { 253942, from = { 8 } }, { 253944, from = { 8 } }, { 253946, from = { 8 } } } },
    },
    STOCKS = {
        { name = "Kam Deepfury", npcID = 1666, display = 825, level = 27, loot = { { 2280, 0.9 }, { 273808 }, { 252815 }, { 251375, 0.01 }, { 251379, 0.01 }, { 252822, 0.03 }, { 252823, 0.01 }, { 252824, 0.01 }, { 252825, 0.01 }, { 253978, 0.01 }, { 253980, 0.01 }, { 253982, 0.01 }, { 273807 }, { 252515 }, { 252455 }, { 252512 }, { 252513 }, { 252456 }, { 252514 }, { 252820 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253984 }, { 253986 } } },
        { name = "Bruegal Ironknuckle", npcID = 1720, kind = "rare", display = 2142, level = 26, loot = { { 3228, 56.2 }, { 2941, 19 }, { 2942, 17.5 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253984 }, { 253986 } } },
        { name = "Targorr the Dread", npcID = 1696, display = 517, level = 24, loot = { { 273804 }, { 273805 }, { 273806 }, { 273820 }, { 251380, 0.04 }, { 251382, 0.01 }, { 251383, 0.02 }, { 252801, 0.01 }, { 252803, 0.02 }, { 253942, 0.02 }, { 253944, 0.02 }, { 251345 }, { 251346 }, { 251347 }, { 251348 }, { 251349 }, { 252792 }, { 252793 }, { 252794 }, { 252795 }, { 252796 }, { 252797 }, { 253938 }, { 253940 }, { 253946 }, { 253948 } } },
        { name = "Hamhock", npcID = 1717, display = 3250, level = 28, loot = { { 273809 }, { 273810 }, { 273811 }, { 251375, 0.01 }, { 251376, 0.01 }, { 251377, 0.03 }, { 251378, 0.01 }, { 252821, 0.01 }, { 252822, 0.01 }, { 252823, 0.01 }, { 252825, 0.01 }, { 253976, 0.04 }, { 253980, 0.03 }, { 253984, 0.01 }, { 253986, 0.01 }, { 252513 }, { 252455 }, { 252456 }, { 252512 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253978 }, { 253982 } } },
        { name = "Bazil Thredd", npcID = 1716, display = 1621, level = 29, loot = { { 273824 }, { 273825 }, { 273827 }, { 273829 }, { 251378, 0.02 }, { 251379, 0.01 }, { 252820, 0.01 }, { 252821, 0.01 }, { 252822, 0.01 }, { 252824, 0.01 }, { 252825, 0.02 }, { 253976, 0.02 }, { 253984, 0.01 }, { 253986, 0.02 }, { 252455 }, { 252456 }, { 252515 }, { 252512 }, { 252514 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253978 }, { 253980 }, { 253982 } } },
        { name = "Dextren Ward", npcID = 1663, display = 2149, level = 26, loot = { { 273817 }, { 273819 }, { 273820 }, { 252514 }, { 252515 }, { 252512 }, { 252456 }, { 252820 }, { 251375 }, { 251376 }, { 252821 }, { 251350 }, { 251351 }, { 251352 }, { 251353 }, { 251354 }, { 252814 }, { 252815 }, { 252816 }, { 252817 }, { 252818 }, { 252819 }, { 253976 }, { 253978 }, { 253980 }, { 253982 }, { 253984 }, { 253986 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 1076 }, { 274092 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251380, 0.04, from = { 3 } }, { 253976, 0.04, from = { 4, 5, 1, 6, 2 } }, { 252822, 0.03, from = { 1, 5, 4 } }, { 253980, 0.03, from = { 4, 1, 6, 5, 2 } }, { 251377, 0.03, from = { 4 } }, { 252825, 0.02, from = { 5, 4, 1 } }, { 251383, 0.02, from = { 3 } }, { 252803, 0.02, from = { 3 } }, { 253942, 0.02, from = { 3 } }, { 253944, 0.02, from = { 3 } }, { 251378, 0.02, from = { 5, 4 } }, { 253986, 0.02, from = { 5, 4, 1, 6, 2 } }, { 251375, 0.01, from = { 4, 1, 6 } }, { 251379, 0.01, from = { 5, 1 } }, { 252823, 0.01, from = { 4, 1 } }, { 252824, 0.01, from = { 5, 1 } }, { 253978, 0.01, from = { 1, 4, 6, 5, 2 } }, { 253982, 0.01, from = { 1, 4, 6, 5 } }, { 251382, 0.01, from = { 3 } }, { 252801, 0.01, from = { 3 } }, { 251376, 0.01, from = { 4, 6 } }, { 252821, 0.01, from = { 5, 4, 6 } }, { 253984, 0.01, from = { 5, 4, 1, 6, 2 } }, { 252820, 0.01, from = { 5, 1, 6 } }, { 251345, from = { 3 } }, { 251346, from = { 3 } }, { 251347, from = { 3 } }, { 251348, from = { 3 } }, { 251349, from = { 3 } }, { 252792, from = { 3 } }, { 252793, from = { 3 } }, { 252794, from = { 3 } }, { 252795, from = { 3 } }, { 252796, from = { 3 } }, { 252797, from = { 3 } }, { 253938, from = { 3 } }, { 253940, from = { 3 } }, { 253946, from = { 3 } }, { 253948, from = { 3 } }, { 251350, from = { 1, 4, 6, 5, 2 } }, { 251351, from = { 1, 4, 6, 5, 2 } }, { 251352, from = { 1, 4, 6, 5, 2 } }, { 251353, from = { 1, 4, 6, 5, 2 } }, { 251354, from = { 1, 4, 6, 5, 2 } }, { 252814, from = { 1, 4, 6, 5, 2 } }, { 252816, from = { 1, 4, 6, 5, 2 } }, { 252817, from = { 1, 4, 6, 5, 2 } }, { 252818, from = { 1, 4, 6, 5, 2 } }, { 252819, from = { 1, 4, 6, 5, 2 } }, { 252815, from = { 4, 6, 5, 1 } } } },
    },
    ULDA = {
        { faction = "Horde", name = "Eric \"The Swift\"", display = 5708, level = 40, loot = { { 9394, 8.2 }, { 9398, 79.8 }, { 2459, 43 }, { 251400 }, { 252896 } } },
        { faction = "Horde", name = "Baelog", npcID = 6906, display = 5710, level = 41, loot = { { 9401, 9.3 }, { 9399, 87.6 }, { 9400, 39.6 }, { 251400 }, { 252896 } } },
        { faction = "Horde", name = "Olaf", npcID = 6908, display = 5709, level = 40, loot = { { 9404, 13.2 }, { 9403, 77.9 }, { 1177, 85.4 }, { 251400 }, { 252896 } } },
        { name = "Revelosh", npcID = 6910, display = 5945, level = 40, loot = { { 9389, 23.3 }, { 9388, 21 }, { 9390, 21.1 }, { 9387, 22.7 }, { 7741, 40.2 } } },
        { name = "Ironaya", npcID = 7228, display = 6089, level = 40, loot = { { 9409, 37.7 }, { 9407, 37.7 }, { 9408, 20.5 }, { 274484 } } },
        { name = "Obsidian Sentinel", npcID = 7023, display = 5285, level = 42, loot = { { 8053 }, { 274425 }, { 274428 }, { 274430 }, { 274485 }, { 251400 } } },
        { name = "Ancient Stone Keeper", npcID = 7206, display = 10798, level = 44, loot = { { 9410, 47.7 }, { 9411, 47 }, { 274431 } } },
        { name = "Galgann Firehammer", npcID = 7291, display = 6059, level = 45, loot = { { 11310, 19.5 }, { 9412, 17.7 }, { 11311, 38.1 }, { 9419, 19.9 }, { 251402 } } },
        { name = "Grimlok", npcID = 4854, display = 11165, level = 45, loot = { { 9415, 39.7 }, { 9416, 19.4 }, { 9414, 28.8 }, { 7670 } } },
        { name = "Archaedas", npcID = 2748, display = 5988, level = 47, loot = { { 11118, 62.4 }, { 9413, 13.6 }, { 9418, 13.2 }, { 274432 }, { 252868 }, { 254100 }, { 252871 }, { 254096 }, { 254106 }, { 252870 }, { 252919 }, { 251404 }, { 251405 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 9431 }, { 9429 }, { 9420 }, { 9430 }, { 9397 }, { 9406 }, { 9428 }, { 9432 }, { 9396 }, { 9393 }, { 7666 }, { 9381 }, { 9426 }, { 9422 }, { 9465 }, { 9384 }, { 9386 }, { 9427 }, { 9392 }, { 9424 }, { 9383 }, { 9425 }, { 9423 }, { 9391 } } },
        { name = "Baelog's Chest", kind = "object", loot = { { 7740 } } },
        { name = "Conspicuous Urn", kind = "object", loot = { { 7671 } } },
        { name = "Shadowforge Cache", kind = "object", loot = { { 7669 } } },
        { name = "Tablet of Will", kind = "object", loot = { { 5824 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 251400, from = { 1, 2, 3, 6 } }, { 252896, from = { 1, 2, 3 } }, { 251402, from = { 8 } }, { 252868, from = { 10 } }, { 254100, from = { 10 } }, { 252871, from = { 10 } }, { 254096, from = { 10 } }, { 254106, from = { 10 } }, { 252870, from = { 10 } }, { 252919, from = { 10 } }, { 251404, from = { 10 } }, { 251405, from = { 10 } } } },
    },
    UBRS = {
        { name = "Pyroguard Emberseer", npcID = 9816, display = 2172, level = 60, loot = { { 16672, 18.4 }, { 12929, 12.3 }, { 12927, 11.4 }, { 12905, 26.8 }, { 12926, 27.7 }, { 23320, 1.1 }, { 249520 } } },
        { name = "Solakar Flamewreath", npcID = 10264, display = 9581, level = 60, loot = { { 16695, 17.8 }, { 12609, 18 }, { 12603, 18.4 }, { 12589, 19.6 }, { 12606, 17 }, { 18657, 8.1 } } },
        { name = "Jed Runewatcher", npcID = 10509, kind = "rare", display = 9686, level = 59, loot = { { 12604, 32.7 }, { 12930, 30.4 }, { 12605, 33.2 } } },
        { name = "Goraluk Anvilcrack", npcID = 10899, display = 10222, level = 61, loot = { { 13502, 6.2 }, { 13498, 28.6 }, { 18047, 17.2 }, { 18048, 23.8 }, { 12834, 8.9 }, { 12837, 9.2 }, { 18779, 22.7 }, { 12806 }, { 12696 }, { 12728 } } },
        { name = "Gyth", npcID = 10339, pair = "Warchief Rend Blackhand", display = 9806, level = 62, loot = { { 12871, 4.5 }, { 16669, 19.7 }, { 22225, 12.9 }, { 12960, 20 }, { 12953, 18.8 }, { 12952, 21.1 }, { 13522, 3.3 } } },
        { name = "Warchief Rend Blackhand", npcID = 10429, pair = "Gyth", display = 9778, level = 62, loot = { { 12590, 1.9 }, { 16733, 17.8 }, { 12587, 20.6 }, { 12588, 2.2 }, { 12936, 15.9 }, { 18104, 19.4 }, { 12935, 23.7 }, { 18102, 21.8 }, { 22247, 14.5 }, { 18103, 20.7 }, { 12940, 7.9 }, { 12939, 13.1 }, { 12583, 8.8 } } },
        { name = "The Beast", npcID = 10430, display = 10193, level = 62, loot = { { 12731 }, { 16729, 16.9 }, { 12967, 24.5 }, { 12968, 21 }, { 12966, 20.2 }, { 12965, 23.7 }, { 12963, 19 }, { 12964, 28.5 }, { 22311, 15 }, { 12709, 15.4 }, { 12969, 13 }, { 24101, 3.7 }, { 19227, 6.6 } } },
        { name = "General Drakkisath", npcID = 10363, display = 10115, level = 62, loot = { { 12592, 1.1 }, { 22267, 20.8 }, { 13141, 26.2 }, { 22269, 17 }, { 13142, 23.9 }, { 13098, 22.4 }, { 22268, 7.5 }, { 22253, 21 }, { 12602, 22.6 }, { 15730, 5 }, { 13519, 4.6 }, { 16690, 10.4 }, { 16688, 9.7 }, { 16700, 13.1 }, { 16721, 9.2 }, { 16706, 13.1 }, { 16674, 9.7 }, { 16666, 5.6 }, { 16726, 7.4 }, { 16730, 13.6 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 24102 }, { 13260 }, { 16696, 2.9 }, { 16683, 3.1 }, { 16703, 3 }, { 16713, 2.7 }, { 16681 }, { 16680, 3 }, { 16673, 2.8 }, { 16735, 2.8 }, { 16247 } } },
        { name = "Darkstone Tablet", kind = "object", loot = { { 12358 } } },
        { name = "Lord Valthalak", npcID = 16042, kind = "rare", loot = { { 22335 }, { 22336 }, { 22337 }, { 22339 }, { 22340 }, { 22342 }, { 22343 }, { 22302 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 249520, from = { 1 } }, { 18657, from = { 2 } }, { 12834, from = { 4 } }, { 12837, from = { 4 } }, { 12728, from = { 4 } }, { 13522, from = { 5 } }, { 15730, from = { 8 } }, { 13519, from = { 8 } }, { 16247, from = { 9 } } } },
    },
    WC = {
        { name = "Lord Cobrahn", npcID = 3669, display = 4213, level = 20, loot = { { 6460, 18.1 }, { 10410, 17.5 }, { 6465, 54.7 }, { 253908 }, { 252778 }, { 252782 } } },
        { name = "Lady Anacondra", npcID = 3671, display = 4313, level = 20, loot = { { 10412, 9.6 }, { 5404, 43.3 }, { 6446, 4.7 }, { 273088 }, { 273098 } } },
        { name = "Kresh", npcID = 3653, display = 5126, level = 20, loot = { { 13245, 13.5 }, { 6447, 66.7 }, { 273084 } } },
        { name = "Lord Pythas", npcID = 3670, display = 4214, level = 21, loot = { { 6472, 29.6 }, { 6473, 55.2 }, { 273089 }, { 253938 }, { 253940 }, { 253946 } } },
        { name = "Skum", npcID = 3674, display = 4203, level = 21, loot = { { 6449, 45.5 }, { 6448, 46.6 }, { 273137 }, { 253944 } } },
        { name = "Lord Serpentis", npcID = 3673, display = 4215, level = 21, loot = { { 6469, 16.8 }, { 5970, 19.4 }, { 10411, 21.1 }, { 6459, 23.3 }, { 273087 }, { 253942 } } },
        { name = "Verdan the Everliving", npcID = 5775, display = 4256, level = 21, loot = { { 6630, 39.2 }, { 6631, 37.8 }, { 6629, 19.6 }, { 253938 }, { 253948 } } },
        { name = "Mutanus the Devourer", npcID = 3654, display = 4088, level = 22, loot = { { 6461, 29.6 }, { 6627, 22.4 }, { 6463, 30.6 }, { 10441, 67.9 }, { 252798 } } },
        { name = "Deviate Faerie Dragon", npcID = 5912, kind = "rare", display = 1267, level = 20, loot = { { 5243, 41.9 }, { 6632, 44.6 }, { 252781, 0.2 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 10413, 2.4, mobs = "Druid of the Fang" } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 252781, 0.2, from = { 9 } }, { 253908, from = { 1 } }, { 252778, from = { 1 } }, { 253938, from = { 4, 7 } }, { 253944, from = { 5 } }, { 252782, from = { 1 } }, { 253940, from = { 4 } }, { 253946, from = { 4 } }, { 253942, from = { 6 } }, { 253948, from = { 7 } }, { 252798, from = { 8 } } } },
    },
    ZF = {
        { name = "Antu'sul", npcID = 8127, display = 7353, level = 48, loot = { { 9640, 32 }, { 9641, 35 }, { 9639, 17.8 }, { 9379, 1 }, { 251407 }, { 252920 }, { 252869 }, { 252868 }, { 252870 }, { 251403 }, { 251405 } } },
        { name = "Theka the Martyr", npcID = 7272, display = 6696, level = { 45, 46 }, loot = { { 10660, 43.7 }, { 274641 }, { 274639 }, { 274638 }, { 254098 }, { 254096 }, { 252920 }, { 251403 } } },
        { name = "Sandarr Dunereaver", npcID = 10080, kind = "rare", display = 9291, level = 45, loot = { { 9523, 4.9 }, { 274660 }, { 274659 } } },
        { name = "Witch Doctor Zum'rah", npcID = 7271, display = 6434, level = 46, loot = { { 277112, quest = true }, { 18083, 34.9 }, { 18082, 15.1 }, { 274642 }, { 252868 }, { 252918 }, { 252869 }, { 251403 }, { 252871 }, { 254106 }, { 252870 }, { 251404 }, { 251405 } } },
        { name = "Nekrum Gutchewer", npcID = 7796, display = 6690, level = { 45, 46 }, loot = { { 9471, 39.1 }, { 274644 }, { 274645 }, { 274643 }, { 252871 }, { 252868 }, { 251400 } } },
        { name = "Shadowpriest Sezz'ziz", npcID = 7275, display = 6441, level = 47, loot = { { 9470, 23.4 }, { 9473, 21.6 }, { 9474, 21.3 }, { 9475, 21.7 }, { 254102 }, { 251404 }, { 254098 }, { 252919 }, { 252918 }, { 251407 }, { 251403 } } },
        { name = "Dustwraith", npcID = 10081, kind = "rare", display = 9292, level = 45, loot = { { 12471, 21.9 }, { 12469 }, { 251399 } } },
        { name = "Sandfury Executioner", npcID = 7274, display = 6440, level = 46, loot = { { 8444, 77.2 } } },
        { name = "Sergeant Bly", npcID = 7604, display = 6433, level = 45, loot = { { 8548, 66.9 }, { 5616 }, { 274646 }, { 274647 }, { 274648 }, { 252896 }, { 251399 }, { 251400 }, { 251402 } } },
        { name = "Hydromancer Velratha", npcID = 7795, display = 6685, level = 46, loot = { { 9234, 61.5 }, { 10661, 49.4 }, { 274653 }, { 274651 }, { 274652 } } },
        { name = "Gahz'rilla", npcID = 7273, display = 7271, level = 46, summon = { items = { 9241, 9240 }, text = "SUMMON_MALLET" }, loot = { { 9469, 45.2 }, { 9467, 45.5 }, { 274657 }, { 254096 }, { 252871 }, { 254106 }, { 254098 }, { 252867 }, { 252868 }, { 252869 } } },
        { name = "Chief Ukorz Sandscalp", npcID = 7267, display = 6439, level = 48, loot = { { 9479, 9.4 }, { 9476, 33.1 }, { 9478, 23.4 }, { 9477, 24 }, { 11086, 0.9 }, { 274654 }, { 274655 }, { 252919 }, { 254100 }, { 252869 }, { 254102 }, { 254096 }, { 252870 }, { 252918 }, { 251407 }, { 251405 }, { 254098 }, { 252871 }, { 252867 }, { 254106 }, { 251404 } } },
        { name = "Zerillis", npcID = 10082, kind = "rare", display = 9293, level = 45, loot = { { 12470, 18.1 }, { 274658 }, { 251400 } } },
        { name = "Trash mobs", kind = "trash", loot = { { 9512 }, { 9484 }, { 862 }, { 6440 }, { 9483 }, { 2040 }, { 5616 }, { 9511 }, { 9481 }, { 9480 }, { 9482 }, { 9243, 1.4 } } },
        { name = "Recipes & Patterns", kind = "recipes", loot = { { 254098, from = { 2, 6, 11, 12 } }, { 254096, from = { 2, 11, 12 } }, { 252920, from = { 2, 1 } }, { 251403, from = { 2, 1, 4, 6 } }, { 251407, from = { 1, 6, 12 } }, { 252869, from = { 1, 4, 11, 12 } }, { 252868, from = { 1, 4, 5, 11 } }, { 252870, from = { 1, 4, 12 } }, { 251405, from = { 1, 4, 12 } }, { 252918, from = { 4, 6, 12 } }, { 252871, from = { 4, 5, 11, 12 } }, { 254106, from = { 4, 11, 12 } }, { 251404, from = { 4, 6, 12 } }, { 251400, from = { 5, 9, 13 } }, { 254102, from = { 6, 12 } }, { 252919, from = { 6, 12 } }, { 252896, from = { 9 } }, { 251399, from = { 9, 7 } }, { 251402, from = { 9 } }, { 252867, from = { 11, 12 } }, { 254100, from = { 12 } } } },
    },
}

-- ID de encuentro (ENCOUNTER_END) -> jefe (su name de arriba). De la tabla DungeonEncounter del
-- cliente de Forever (wago.tools, build 1.60.1.70959): el mismo numero en todos los idiomas y
-- tambien en las mazmorras nuevas, que no estan en el Diario del juego. Los que el cliente
-- llama distinto, emparejados a mano (Overseer Mugg, Deathless Guardians, Geilhast...). Una lista:
-- encuentro de varios jefes, se tachan todos. Sin emparejar: Ring of Law (sale uno de seis: va
-- por npcID), Mana Wraith (no los tenemos), Hurley, Ribbly, The Vault...
ns.BossEncounters = {
    [227] = "High Interrogator Gerstahn", -- BRD
    [228] = "Lord Roccor", -- BRD
    [229] = "Houndmaster Grebmar", -- BRD
    [231] = "Pyromancer Loregrain", -- BRD
    [232] = "Lord Incendius", -- BRD
    [233] = "Warder Stilgiss", -- BRD
    [234] = "Fineous Darkvire", -- BRD
    [235] = "Bael'Gar", -- BRD
    [236] = "General Angerforge", -- BRD
    [237] = "Golem Lord Argelmach", -- BRD
    [239] = "Phalanx", -- BRD
    [241] = "Plugger Spazzring", -- BRD
    [242] = "Ambassador Flamelash", -- BRD
    [243] = "Chest of The Seven", -- BRD (The Seven: su cofre)
    [244] = "Magmus", -- BRD
    [267] = "Highlord Omokk", -- LBRS
    [268] = "Shadow Hunter Vosh'gajin", -- LBRS
    [269] = "War Master Voone", -- LBRS
    [270] = "Mother Smolderweb", -- LBRS
    [271] = "Urok Doomhowl", -- LBRS
    [272] = "Quartermaster Zigris", -- LBRS
    [273] = "Gizrul the Slavener", -- LBRS
    [274] = "Halycon", -- LBRS
    [275] = "Overlord Wyrmthalak", -- LBRS
    [343] = "Zevrim Thornhoof", -- DM_E
    [344] = "Hydrospawn", -- DM_E
    [345] = "Lethtendris", -- DM_E
    [346] = "Alzzin the Wildshaper", -- DM_E
    [347] = "Illyanna Ravenoak", -- DM_W
    [348] = "Magister Kalendris", -- DM_W
    [349] = "Immol'thar", -- DM_W
    [350] = "Tendris Warpwood", -- DM_W
    [361] = "Prince Tortheldrin", -- DM_W
    [362] = "Guard Mol'dar", -- DM_N
    [363] = "Stomper Kreeg", -- DM_N
    [364] = "Guard Fengus", -- DM_N
    [365] = "Guard Slip'kik", -- DM_N
    [366] = "Captain Kromcrush", -- DM_N
    [367] = "Cho'Rush the Observer", -- DM_N
    [368] = "King Gordok", -- DM_N
    [422] = "Noxxion", -- MARA
    [423] = "Razorlash", -- MARA
    [424] = "Lord Vyletongue", -- MARA
    [425] = "Celebras the Cursed", -- MARA
    [426] = "Landslide", -- MARA
    [427] = "Tinkerer Gizlock", -- MARA
    [428] = "Rotgrip", -- MARA
    [429] = "Princess Theradras", -- MARA
    [444] = "Interrogator Vishas", -- SM_GY
    [446] = "Houndmaster Loksey", -- SM_LIB
    [447] = "Arcanist Doan", -- SM_LIB
    [448] = "Herod", -- SM_ARM
    [449] = "High Inquisitor Fairbanks", -- SM_CATH
    [450] = "High Inquisitor Whitemane", -- SM_CATH
    [472] = "The Unforgiven", -- STRAT_LIVE
    [473] = "Hearthsinger Forresten", -- STRAT_LIVE
    [474] = "Timmy the Cruel", -- STRAT_LIVE
    [475] = "Cannon Master Willey", -- STRAT_LIVE
    [476] = "Malor the Zealous", -- STRAT_LIVE
    [477] = "Archivist Galford", -- STRAT_LIVE
    [478] = "Balnazzar", -- STRAT_LIVE
    [479] = "Baroness Anastari", -- STRAT_UD
    [480] = "Nerub'enkan", -- STRAT_UD
    [481] = "Maleki the Pallid", -- STRAT_UD
    [482] = "Magistrate Barthilas", -- STRAT_UD
    [483] = "Ramstein the Gorger", -- STRAT_UD
    [484] = "Baron Rivendare", -- STRAT_UD
    [486] = "Dreamscythe", -- ST
    [487] = "Weaver", -- ST
    [488] = "Jammal'an the Prophet", -- ST
    [490] = "Morphaz", -- ST
    [491] = "Hazzas", -- ST
    [492] = "Avatar of Hakkar", -- ST
    [493] = "Shade of Eranikus", -- ST
    [547] = "Revelosh", -- ULDA
    [548] = { "Baelog", "Eric \"The Swift\"", "Olaf" }, -- ULDA (The Lost Dwarves)
    [549] = "Ironaya", -- ULDA
    [551] = "Ancient Stone Keeper", -- ULDA
    [552] = "Galgann Firehammer", -- ULDA
    [553] = "Grimlok", -- ULDA
    [554] = "Archaedas", -- ULDA
    [585] = "Lady Anacondra", -- WC
    [586] = "Lord Cobrahn", -- WC
    [587] = "Kresh", -- WC
    [588] = "Lord Pythas", -- WC
    [589] = "Skum", -- WC
    [590] = "Lord Serpentis", -- WC
    [591] = "Verdan the Everliving", -- WC
    [592] = "Mutanus the Devourer", -- WC
    [593] = "Hydromancer Velratha", -- ZF
    [594] = "Gahz'rilla", -- ZF
    [595] = "Antu'sul", -- ZF
    [596] = "Theka the Martyr", -- ZF
    [597] = "Witch Doctor Zum'rah", -- ZF
    [598] = "Nekrum Gutchewer", -- ZF
    [599] = "Shadowpriest Sezz'ziz", -- ZF
    [600] = "Chief Ukorz Sandscalp", -- ZF
    [1887] = "Obsidian Sentinel", -- ULDA
    [2694] = "Baron Aquanis", -- BFD
    [2697] = "Ghamoo-ra", -- BFD
    [2699] = "Lady Sarevess", -- BFD
    [2704] = "Gelihast", -- BFD
    [2710] = "Lorgus Jett", -- BFD
    [2732] = "Oggleflint", -- RFC
    [2733] = "Taragaman the Hungerer", -- RFC
    [2734] = "Jergosh the Invoker", -- RFC
    [2735] = "Bazzalan", -- RFC
    [2741] = "Rhahk'Zor", -- DM
    [2742] = "Sneed", -- DM
    [2743] = "Gilnid", -- DM
    [2744] = "Captain Greenskin", -- DM
    [2745] = "Mr. Smite", -- DM
    [2746] = "Cookie", -- DM
    [2747] = "Edwin VanCleef", -- DM
    [2748] = "Rethilgore", -- SFK
    [2749] = "Razorclaw the Butcher", -- SFK
    [2750] = "Baron Silverlaine", -- SFK
    [2751] = "Commander Springvale", -- SFK
    [2752] = "Odo the Blindwatcher", -- SFK
    [2753] = "Fenrus the Devourer", -- SFK
    [2754] = "Wolf Master Nandos", -- SFK
    [2755] = "Archmage Arugal", -- SFK
    [2756] = "Targorr the Dread", -- STOCKS
    [2757] = "Kam Deepfury", -- STOCKS
    [2758] = "Hamhock", -- STOCKS
    [2759] = "Dextren Ward", -- STOCKS
    [2760] = "Bazil Thredd", -- STOCKS
    [2761] = "Ghamoo-ra", -- BFD
    [2762] = "Lady Sarevess", -- BFD
    [2763] = "Gelihast", -- BFD
    [2764] = "Lorgus Jett", -- BFD
    [2765] = "Old Serra'kis", -- BFD
    [2766] = "Twilight Lord Kelris", -- BFD
    [2767] = "Aku'mai", -- BFD
    [2768] = "Grubbis", -- GNOMER
    [2769] = "Viscous Fallout", -- GNOMER
    [2770] = "Electrocutioner 6000", -- GNOMER
    [2771] = "Crowd Pummeler 9-60", -- GNOMER
    [2772] = "Mekgineer Thermaplugg", -- GNOMER
    [2773] = "Roogug", -- RFK
    [2774] = "Aggem Thorncurse", -- RFK
    [2775] = "Death Speaker Jargba", -- RFK
    [2776] = "Overlord Ramtusk", -- RFK
    [2777] = "Agathelos the Raging", -- RFK
    [2778] = "Charlga Razorflank", -- RFK
    [2779] = "Bloodmage Thalnos", -- SM_GY
    [2780] = "Tuten'kash", -- RFD
    [2781] = "Plaguemaw the Rotting", -- RFD
    [2782] = "Mordresh Fire Eye", -- RFD
    [2783] = "Ragglesnout", -- RFD
    [2784] = "Glutton", -- RFD
    [2785] = "Amnennar the Coldbringer", -- RFD
    [2789] = "Princess Moira Bronzebeard", -- BRD
    [2790] = "Emperor Dagran Thaurissan", -- BRD
    [2792] = "Pusillin", -- DM_E
    [2793] = "Lord Hel'nurath", -- DM_W
    [2794] = "Tsu'zee", -- DM_W
    [2795] = "Black Guard Swordsmith", -- STRAT_UD
    [2796] = "Crimson Hammersmith", -- STRAT_LIVE
    [2797] = "Ezra Grimm", -- STRAT_LIVE
    [2798] = "Postmaster Malown", -- STRAT_LIVE
    [2799] = "Skul", -- STRAT_LIVE
    [2800] = "Stonespine", -- STRAT_UD
    [2801] = "Darkmaster Gandling", -- SCHOLO
    [2802] = "Doctor Theolen Krastinov", -- SCHOLO
    [2803] = "Instructor Malicia", -- SCHOLO
    [2804] = "Jandice Barov", -- SCHOLO
    [2805] = "Kirtonos the Herald", -- SCHOLO
    [2806] = "Lady Illucia Barov", -- SCHOLO
    [2807] = "Lord Alexei Barov", -- SCHOLO
    [2808] = "Lorekeeper Polkelt", -- SCHOLO
    [2809] = "Marduk Blackpool", -- SCHOLO
    [2810] = "Ras Frostwhisper", -- SCHOLO
    [2811] = "Rattlegore", -- SCHOLO
    [2812] = "The Ravenian", -- SCHOLO
    [2813] = "Vectus", -- SCHOLO
    [2814] = "Atal'alarion", -- ST
    [2825] = "Twilight Lord Kelris", -- BFD
    [2891] = "Aku'mai", -- BFD
    [2899] = "Crowd Pummeler 9-60", -- GNOMER
    [2910] = "Aku'mai", -- BFD
    [2911] = "Twilight Lord Kelris", -- BFD
    [2912] = "Old Serra'kis", -- BFD
    [2913] = "Lorgus Jett", -- BFD
    [2914] = "Gelihast", -- BFD
    [2915] = "Lady Sarevess", -- BFD
    [2916] = "Ghamoo-ra", -- BFD
    [2925] = "Grubbis", -- GNOMER
    [2927] = "Electrocutioner 6000", -- GNOMER
    [2928] = "Viscous Fallout", -- GNOMER
    [2940] = "Mekgineer Thermaplugg", -- GNOMER
    [2952] = "Atal'alarion", -- ST
    [2954] = "Balcony Minibosses", -- ST
    [2955] = { "Dreamscythe", "Weaver" }, -- ST
    [2956] = "Avatar of Hakkar", -- ST
    [2957] = { "Jammal'an the Prophet", "Ogom the Wretched" }, -- ST
    [2958] = { "Morphaz", "Hazzas" }, -- ST
    [2959] = "Shade of Eranikus", -- ST
    [3055] = "Kormok", -- SCHOLO
    [3062] = "Pyroguard Emberseer", -- UBRS
    [3063] = "Warchief Rend Blackhand", -- UBRS
    [3068] = "The Beast", -- UBRS
    [3069] = "General Drakkisath", -- UBRS
    [3070] = "Lord Valthalak", -- UBRS
    [3298] = "Arcane Anomaly", -- DALARAN
    [3299] = "Fel Ancient", -- DALARAN
    [3300] = "Mana Devourer", -- DALARAN
    [3301] = "Arcanic Enigma", -- DALARAN (Mana Elemental: el objetivo de su mision lo llama asi)
    [3302] = "Unstable Sentinel", -- DALARAN
    [3303] = "Shade of the Archmage", -- DALARAN
    [3310] = "Lyn the Ignored", -- DALARAN
    [3311] = "Atrexis the Grave Knight", -- DALARAN
    [3315] = "Withermaw", -- BLACKMAW
    [3316] = "Impaan the Imprisoner", -- BLACKMAW
    [3322] = "Bonesnout the Unbroken", -- BLACKMAW
    [3323] = "Blackmaw Behemoth", -- BLACKMAW
    [3327] = "Elder Shaman Bloodmane", -- BLACKMAW
    [3334] = "Varrox Bleakhoof", -- BLACKMAW
    [3336] = "Unbound Spirit", -- BLACKMAW
    [3353] = "Witherfang", -- LORDAERON
    [3354] = "Rath'mael", -- LORDAERON
    [3355] = "The Baron", -- LORDAERON (The Butcher: mismo puesto en el orden del cliente)
    [3357] = "The Abandoned", -- LORDAERON
    [3403] = "Overseer Wrex", -- ALCAZ
    [3408] = "Lordaeron Captain", -- LORDAERON
    [3409] = "Blazeroar", -- ALCAZ
    [3410] = "Tidemistress Ca'zass", -- ALCAZ
    [3411] = "Viktor the Vile", -- LORDAERON
    [3412] = "Bjork", -- LORDAERON
    [3415] = "The Questioner", -- ALCAZ
    [3418] = "Katerina the Cleaner", -- ALCAZ
    [3449] = "Nar'gurk", -- KROLDOK
    [3450] = "Slavecrusher Grox", -- KROLDOK
    [3451] = "Overlord Mugg", -- KROLDOK
    [3452] = "Twilight Commander Zarmok", -- KROLDOK
    [3453] = "War Handler Ashka", -- KROLDOK
    [3474] = "Zul'Alai", -- DROWNED
    [3475] = "Var'Taka", -- DROWNED
    [3476] = "Captain Dreadrise", -- DROWNED
    [3478] = "Deathless Marrow", -- DROWNED
    [3479] = "Min'loth the Serpent", -- DROWNED
    [3480] = "Saltspine", -- EXCAVATION
    [3481] = "Shadetooth", -- EXCAVATION
    [3482] = "Relic Guardian", -- EXCAVATION
    [3493] = "Faldrim Anvilmar", -- THANES
    [3494] = "Plunder", -- THANES
    [3495] = "Magmatus", -- THANES (Infurnus: mismo puesto en el orden del cliente)
    [3496] = "Durgen Dirgehammer", -- THANES
    [3498] = "Titanosaur", -- SHAPERS
    [3499] = "Izha'Rel and Tor'Rel", -- SHAPERS (Ravasaur Hunters: las dos bestias, tras Titanosaur)
    [3500] = "Thunderhoof", -- SHAPERS
    [3501] = "Venomridge", -- SHAPERS
    [3502] = "Nanaya", -- SHAPERS
    [3503] = "Cinder", -- SHAPERS
    [3504] = "King Op", -- SHAPERS
    [3505] = "Bolt", -- SHAPERS
    [3507] = "Direhorn Matriarch", -- SHAPERS
    [3511] = "Primeval Elemental", -- DROWNED
    [3582] = "Atal'alarion", -- ST
    [3583] = "Avatar of Hakkar", -- ST
    [3584] = "Shade of Eranikus", -- ST
    [3585] = "Hazzas", -- ST
    [3586] = "Morphaz", -- ST
    [3587] = "Weaver", -- ST
    [3588] = "Dreamscythe", -- ST
    [3589] = "Jammal'an the Prophet", -- ST
    [3597] = "Snowtalon", -- SHAPERS
    [3600] = "Vitrix", -- SHAPERS
    [3676] = "Miner Johnson", -- DM
}
