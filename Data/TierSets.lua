local _, ns = ...

-- ==========================================
-- CONJUNTOS DE TIER (pagina "Conjuntos de tier" de la portada, UI/TierSets.lua)
-- ==========================================
-- Por clase, las ocho piezas en este orden: cabeza, hombros, pecho, munecas,
-- manos, cintura, piernas, pies. Tier 0 (Dungeon Set 1) cae de jefes de
-- mazmorra: su jefe sale del botin de Data/Bosses.lua. Tier 0.5 (Dungeon Set 2)
-- es la recompensa de los cuatro cambios de la cadena de Tier 0.5 (misiones
-- 8905-9022, una por clase y paso; los nombres son los mismos para todas).
-- name: el nombre ingles del conjunto, hasta que el juego de el suyo.

ns.TierSets = {
    {
        key = "T0",
        WARRIOR = { 16731, 16733, 16730, 16735, 16737, 16736, 16732, 16734, name = "Battlegear of Valor" },
        PALADIN = { 16727, 16729, 16726, 16722, 16724, 16723, 16728, 16725, name = "Lightforge Armor" },
        HUNTER = { 16677, 16679, 16674, 16681, 16676, 16680, 16678, 16675, name = "Beaststalker Armor" },
        ROGUE = { 16707, 16708, 16721, 16710, 16712, 16713, 16709, 16711, name = "Shadowcraft Armor" },
        PRIEST = { 16693, 16695, 16690, 16697, 16692, 16696, 16694, 16691, name = "Vestments of the Devout" },
        SHAMAN = { 16667, 16669, 16666, 16671, 16672, 16673, 16668, 16670, name = "The Elements" },
        MAGE = { 16686, 16689, 16688, 16683, 16684, 16685, 16687, 16682, name = "Magister's Regalia" },
        WARLOCK = { 16698, 16701, 16700, 16703, 16705, 16702, 16699, 16704, name = "Dreadmist Raiment" },
        DRUID = { 16720, 16718, 16706, 16714, 16717, 16716, 16719, 16715, name = "Wildheart Raiment" },
    },
    {
        key = "T05",
        WARRIOR = { 21999, 22001, 21997, 21996, 21998, 21994, 22000, 21995, name = "Battlegear of Heroism" },
        PALADIN = { 22091, 22093, 22089, 22088, 22090, 22086, 22092, 22087, name = "Soulforge Armor" },
        HUNTER = { 22013, 22016, 22060, 22011, 22015, 22010, 22017, 22061, name = "Beastmaster Armor" },
        ROGUE = { 22005, 22008, 22009, 22004, 22006, 22002, 22007, 22003, name = "Darkmantle Armor" },
        PRIEST = { 22080, 22082, 22083, 22079, 22081, 22078, 22085, 22084, name = "Vestments of the Virtuous" },
        SHAMAN = { 22097, 22101, 22102, 22095, 22099, 22098, 22100, 22096, name = "The Five Thunders" },
        MAGE = { 22065, 22068, 22069, 22063, 22066, 22062, 22067, 22064, name = "Sorcerer's Regalia" },
        WARLOCK = { 22074, 22073, 22075, 22071, 22077, 22070, 22072, 22076, name = "Deathmist Raiment" },
        DRUID = { 22109, 22112, 22113, 22108, 22110, 22106, 22111, 22107, name = "Feralheart Raiment" },
        -- Que cambio de la cadena da cada pieza (indice en quests), en el orden de las piezas
        pieceQuest = { 4, 3, 4, 1, 2, 2, 3, 3 },
        -- An Earnest Proposition, Just Compensation, Anthion's Parting Words, Saving the Best for Last
        quests = { 8909, 8934, 8955, 9003 },
        questNames = { "An Earnest Proposition", "Just Compensation", "Anthion's Parting Words", "Saving the Best for Last" },
    },
}

-- Nivel al que sale solo el icono de la portada (los conjuntos son de nivel 50 y pico)
ns.TIER_ICON_LEVEL = 50
