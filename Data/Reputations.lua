local _, ns = ...

-- ==========================================
-- REPUTACIONES NUEVAS DE WOW FOREVER (Viajes > Renombres)
-- ==========================================
-- Las facciones con envChange "new" de https://www.wowhead.com/forever/factions
-- (2026-10-12), sin las de prueba (Legacy Track, PvP Rank Points...). Solo hechos
-- de sus paginas /forever/faction=<id>:
--   id: factionID del juego (nombre y nivel en el idioma del cliente salen de la API)
--   name: ingles, si la API no da nada
--   side: "Alliance", "Horde" o nil (las dos)
--   zone: zona en ingles (donde estan sus miembros); mapID si es una de vanilla,
--         para el nombre traducido
--   raid / dungeon: clave de ns.Raids / ns.Dungeons a la que se asocia
--   pvp: campo de batalla de las Islas Lanza Negra (Darkspear Islands)
--   rewards: objetos que vende o da por reputacion (recuento de Wowhead)
--   icons: nombres de Interface\Icons, en orden: el primero que tenga el cliente.
--          Wowhead Forever no da icono de faccion; si tiene tabardo, el suyo, y si
--          no, uno del juego que encaje (cada uno con su porque en el comentario).

ns.Reputations = {
    -- Icono: su tabardo (recompensa en Wowhead Forever)
    { id = 2765, name = "Guardians of Hyjal", zone = "Mount Hyjal", raid = "HYJAL", rewards = 2,
        icons = { "inv_misc_tabard_guardiansofhyjal", "spell_nature_tranquility" } },
    -- Icono: furbolgs: el de Fauces de Madera (sin datos en Wowhead)
    { id = 2747, name = "Barkskin Burrow", zone = "Mount Hyjal",
        icons = { "achievement_reputation_timbermaw", "inv_misc_pelt_bear_01" } },
    -- Icono: el del Kirin Tor de Retail
    { id = 2740, name = "Kirin Tor", side = "Alliance", zone = "Alterac Mountains", mapID = 1416, dungeon = "DALARAN",
        rewards = 9,
        icons = { "achievement_reputation_kirintor", "spell_holy_magicalsentry" } },
    -- Icono: magisters arcanos (sin icono propio en Wowhead)
    { id = 2779, name = "High Order", side = "Alliance", zone = "Zephras Isle",
        icons = { "spell_arcane_blink", "spell_holy_magicalsentry" } },
    -- Icono: chamanes del viento (sin icono propio en Wowhead)
    { id = 2778, name = "Windshapers", side = "Horde", zone = "Zephras Isle",
        icons = { "spell_nature_cyclone", "spell_nature_lightningshield" } },
    -- Icono: druidas "Garranoche": forma felina (sin icono propio)
    { id = 2758, name = "Nightclaw Druids", zone = "Zephras Isle", rewards = 50,
        icons = { "ability_druid_catform", "spell_nature_regeneration" } },
    -- Icono: su tabardo de Retail; respaldo, totem de tierra
    { id = 2787, name = "Earthen Ring", side = "Horde", zone = "Mulgore", mapID = 1412, rewards = 8,
        icons = { "inv_misc_tabard_earthenring", "spell_nature_earthbindtotem" } },
    -- Icono: caballeria de Ventormenta (sin icono propio)
    { id = 2826, name = "Brotherhood of the Horse", zone = "Riverglades",
        icons = { "ability_mount_ridinghorse" } },
    -- Icono: "Polvofusil": bomba (sin icono propio)
    { id = 2827, name = "Powderfuse", zone = "Riverglades", rewards = 6,
        icons = { "inv_misc_bomb_04" } },
    -- Icono: ogros ex Martillo Crepuscular (sin icono propio)
    { id = 2782, name = "Bolder'ok Clan", zone = "Riverglades",
        icons = { "achievement_reputation_ogre", "inv_hammer_04" } },
    -- Icono: su tabardo (recompensa en Wowhead Forever)
    { id = 2799, name = "Theramore Expeditionary Force", side = "Alliance", pvp = true, rewards = 52,
        icons = { "inv_tabard_theramorec60", "inv_bannerpvp_02" } },
    -- Icono: su tabardo (recompensa en Wowhead Forever)
    { id = 2798, name = "Darkspear Raiders", side = "Horde", pvp = true, rewards = 52,
        icons = { "inv_tabard_darkspearc60", "inv_bannerpvp_01" } },
    -- Icono: carceleros elfos de la noche: llave (sin icono propio)
    { id = 2819, name = "The Watchers", rewards = 18,
        icons = { "inv_misc_key_03" } },
    -- Icono: exploradores (sin icono propio)
    { id = 2719, name = "Cenarion Scouts",
        icons = { "ability_hunter_eagleeye" } },
}
