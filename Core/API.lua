local ADDON_NAME, ns = ...

-- ==========================================
-- API PUBLICA (solo lectura)
-- ==========================================
-- Para otros addons (p. ej. Azeroth AI): mazmorras, sus misiones con el estado
-- del personaje, jefes, bandas y entradas. Devuelve siempre copias y con
-- nombres en el idioma del cliente; las claves de mazmorra ("DM",
-- "SM_LIB"...) son las de Data/Dungeons.lua y no cambian.
--
-- El global DungeonQuestAtlas (el namespace entero) sigue existiendo para
-- /dump, pero no es estable: lo que no este aqui puede cambiar sin aviso.
--
-- version solo sube si cambia el significado de algo ya existente; anadir
-- funciones o campos no la sube.
--
--   local api = DungeonQuestAtlasAPI
--   if api and api.version == 1 then
--       for _, q in ipairs(api.GetDungeonQuests("DM") or {}) do
--           print(q.title, q.status)
--       end
--   end

local function Point(p)
    return p and { mapID = p.mapID, x = p.x, y = p.y } or nil
end

local function DungeonInfo(d)
    return {
        key = d.key, name = ns.DungeonName(d), englishName = d.name,
        minLevel = d.minLevel, maxLevel = d.maxLevel, faction = d.faction,
        isForever = d.isForever or false, entrance = Point(d.entrance),
    }
end

local function QuestLine(id)
    local status, reason = ns.QuestStatus(id)
    return { questID = id, title = ns.QuestTitle(id), status = status, reason = reason }
end

local function RaidByKey(key)
    for _, raid in ipairs(ns.Raids or {}) do
        if raid.key == key then return raid end
    end
end

DungeonQuestAtlasAPI = {
    version = 1,

    -- Estados de mision que devuelve GetDungeonQuests, en el orden de la lista
    STATUS = { "AVAILABLE", "IN_LOG", "READY", "COMPLETED", "BLOCKED" },

    -- { { key, name, englishName, minLevel, maxLevel, faction, isForever, entrance = { mapID, x, y } | nil }, ... }
    GetDungeons = function()
        local out = {}
        for _, d in ipairs(ns.Dungeons) do out[#out + 1] = DungeonInfo(d) end
        return out
    end,

    -- La de GetDungeons para una clave, o nil
    GetDungeon = function(key)
        local d = ns.DungeonByKey and ns.DungeonByKey[key]
        return d and DungeonInfo(d) or nil
    end,

    -- Claves de mazmorra para un atajo o una clave ("sm", "lib", "deadmines"...), o nil
    FindDungeons = function(text)
        local list = ns.DungeonsByAlias(text)
        if not list then return nil end
        local keys = {}
        for i, d in ipairs(list) do keys[i] = d.key end
        return keys
    end,

    -- Misiones de la mazmorra para la faccion del jugador (o la que se pase):
    -- { { questID, title, status, reason }, ... }; reason solo si status == "BLOCKED"
    GetDungeonQuests = function(key, faction)
        local d = ns.DungeonByKey and ns.DungeonByKey[key]
        if not d then return nil end
        local out = {}
        for _, id in ipairs(ns.DungeonQuests(d, faction or UnitFactionGroup("player"), false)) do
            out[#out + 1] = QuestLine(id)
        end
        return out
    end,

    -- Jefes en orden (incluye raros; sin bichos, cofres ni recetas):
    -- { { name, englishName, rare, npcID, level }, ... }
    GetDungeonBosses = function(key)
        local d = ns.DungeonByKey and ns.DungeonByKey[key]
        if not d then return nil end
        local out = {}
        for _, boss in ipairs(ns.Bosses[key] or {}) do
            if boss.kind == nil or boss.kind == "rare" then
                out[#out + 1] = { name = ns.BossName(boss, d), englishName = boss.name,
                    rare = boss.kind == "rare", npcID = boss.npcID, level = boss.level }
            end
        end
        return out
    end,

    -- { { key, name, englishName, entrance }, ... }
    GetRaids = function()
        local out = {}
        for _, raid in ipairs(ns.Raids or {}) do
            out[#out + 1] = { key = raid.key, name = ns.DungeonName(raid), englishName = raid.name,
                entrance = Point(raid.entrance) }
        end
        return out
    end,

    -- Una mision de mazmorra (o de llave de banda) que DQA conoce, o nil:
    -- { questID, title, status, reason, level, minLevel, xp, money, dungeonKey, dungeonName,
    --   rewards = { itemID... }, choice = { itemID... }, need = { { itemID, count }... },
    --   chain = { { questID, title, status }... } (la serie entera, en orden), step = n }
    GetQuest = function(questID)
        local q = ns.Quests and ns.Quests[questID]
        if not q then return nil end
        local info = QuestLine(questID)
        info.level, info.minLevel, info.xp, info.money = q.level, q.minLevel, q.xp, q.money
        local function ids(list)
            local out = {}
            for i, id in ipairs(list or {}) do out[i] = id end
            return out
        end
        info.rewards, info.choice = ids(q.rewards), ids(q.choice)
        info.need = {}
        for i, n in ipairs(q.need or {}) do info.need[i] = { itemID = n[1], count = n[2] } end
        if type(q.chain) == "table" then
            info.chain = {}
            for i, id in ipairs(q.chain) do
                info.chain[i] = QuestLine(id)
                if id == questID then info.step = i end
            end
        end
        for _, d in ipairs(ns.Dungeons) do
            for _, id in ipairs(d.quests or {}) do
                if id == questID then
                    info.dungeonKey, info.dungeonName = d.key, ns.DungeonName(d)
                    return info
                end
            end
        end
        return info
    end,

    -- De donde sale un objeto: { { who, where, chance, dungeonKey } | { quest, questID, where }, ... }
    -- who: jefe (nombre local); where: mazmorra o banda; chance: % o nil; nil si no lo tiene
    GetItemSources = function(itemID)
        local list = ns.ItemSources(itemID)
        if not list then return nil end
        local out = {}
        for _, e in ipairs(list) do
            local where = ns.DungeonName(e.d)
            if e.quest then
                out[#out + 1] = { quest = ns.QuestTitle(e.quest), questID = e.quest, where = where }
            else
                local boss = e.d.size and e.d.bosses[e.boss] or ns.Bosses[e.d.key][e.boss]
                out[#out + 1] = { who = e.d.size and boss.name or ns.BossName(boss, e.d), where = where,
                    chance = e.chance, dungeonKey = not e.d.size and e.d.key or nil }
            end
        end
        return out
    end,

    -- Quien da (which = "starts") o recoge ("ends") una mision: { { name, mapID, x, y }, ... }
    -- (sin mapID: empieza con un objeto del inventario); nil si no se sabe
    GetQuestPlaces = function(questID, which)
        local list = ns.QuestPlaces(questID, which)
        if not list or #list == 0 then return nil end
        local out = {}
        for _, p in ipairs(list) do
            out[#out + 1] = { name = ns.PlaceName(p), mapID = p.mapID, x = p.x, y = p.y }
        end
        return out
    end,

    -- { key, name, entrance, bosses = { nombre, ... }, attunement = { item, steps = { quest... } } | nil }
    GetRaid = function(key, faction)
        local raid = RaidByKey(key)
        if not raid then return nil end
        local info = { key = raid.key, name = ns.DungeonName(raid), entrance = Point(raid.entrance), bosses = {} }
        for _, boss in ipairs(raid.bosses or {}) do info.bosses[#info.bosses + 1] = boss.name end
        local a = raid.attunement
        if a then
            info.attunement = {
                item = a.item, itemName = a.item and C_Item.GetItemNameByID(a.item) or a.itemName, steps = {},
            }
            for _, id in ipairs(ns.RaidAttunement(raid, faction or UnitFactionGroup("player")) or {}) do
                info.attunement.steps[#info.attunement.steps + 1] = QuestLine(id)
            end
        end
        return info
    end,
}
