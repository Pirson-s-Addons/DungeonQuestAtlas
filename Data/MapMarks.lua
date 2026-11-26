local _, ns = ...

-- Marcas de los planos de Data/Maps.lua (aparte: gen.py reescribe ese fichero).
-- [planta] = { { tipo, x, y, planta a la que lleva }, ... } (0-1 sobre la planta, la
-- planta en el orden de Data/Maps.lua). Tipos:
--   "entrance": la entrada de la mazmorra;
--   "up" / "down": escalera o rampa que sube o baja a otra planta;
--   "floor": paso a otra planta sin saber si sube o baja;
--   "item": sitio posible de un objeto { "item", x, y, itemID, clave de L con la pista };
--   "spawn": otro sitio donde puede estar un jefe { "spawn", x, y, indice del jefe, clave de L con %s = su nombre }.
--   "note": como llegar a un jefe { "note", x, y, indice del jefe, clave de L con %s = su nombre }.
--   Horado Rajacieno: liana hasta Roogug (el salto por la pared ya no funciona, FDJ 2.0.5).
--   "statue": estatua { "statue", x, y, orden, clave de L con su lado }. Templo Sumergido: las seis
--   serpientes que traen a Atal'alarion, en el orden de activarlas (AzerothCore, gameobject
--   148830-148835 de la 109, pasadas al plano con UiMapAssignment; el orden de sus ID es el del evento).
-- Sitios comprobados sobre cada plano (08-10-2026). Sube o baja solo donde se sabe
-- (Colmillo Oscuro, el salto de Gnomeregan) o se ve (Dalaran: la ciudad sobre las
-- cloacas). Excavacion: el remolino del mapa del autor.
-- Pasos entre plantas de Colmillo Oscuro, Scholomance, Profundidades y Cumbre de Roca Negra,
-- La Masacre, Maraudon y Uldaman (08-10-2026): calculados con datos del cliente. Un grupo del
-- modelo (WMOGroupID) que UiMapAssignment pinta en dos plantas es la escalera o rampa que
-- las une; su caja, pasada al mundo con la colocacion del modelo, da el sitio en cada planta,
-- y la altura media de cada planta dice si sube o baja. Sin grupo compartido, el sitio donde
-- un grupo de cada planta se tocan. Modelos de Retail; el sitio es el centro del grupo
-- (aproximado dentro de la sala). Gnomeregan, Las Minas y Brazanegra: comprobados igual.
-- Las vueltas (planta de destino -> la de antes) salen de
-- pasar su punto al mundo y del mundo a la otra planta con los rectangulos de
-- UiMapAssignment (_project/tools/dqa_maps/regions.json). Sin vuelta: el salto de
-- la Sala de Engranajes (solo baja) y Colmillo Oscuro (el punto cae fuera de la
-- planta de destino). Las Minas: un poco abajo a la derecha, para no tapar a Gilnid.

ns.MapMarks = {
    RFC = { { { "entrance", 0.610, 0.075 } } },
    WC = { { { "entrance", 0.465, 0.590 } } },
    DM = {
        { { "entrance", 0.295, 0.135 }, { "floor", 0.615, 0.610, 2 } },
        { { "floor", 0.16, 0.84, 1 } },
    },
    -- Plantas en el orden del recorrido (Data/Maps.lua): 3 es la muralla (316 de Blizzard).
    -- Movidas a mano sobre el plano las que caian fuera de la sala, encima de otra o de una cara.
    SFK = {
        [1] = { { "entrance", 0.705, 0.605 }, { "down", 0.132, 0.842, 2 }, { "floor", 0.345, 0.72, 3 } },
        [2] = { { "up", 0.236, 0.856, 1 }, { "up", 0.5, 0.45, 3 } },
        [3] = { { "floor", 0.34, 0.78, 1 }, { "down", 0.25, 0.74, 2 }, { "up", 0.462, 0.197, 4 } },
        [4] = { { "up", 0.506, 0.831, 5 }, { "down", 0.564, 0.401, 3 } },
        [5] = { { "down", 0.506, 0.831, 4 }, { "up", 0.439, 0.729, 6 }, { "up", 0.546, 0.539, 6 } },
        [6] = { { "down", 0.42, 0.76, 5 }, { "down", 0.546, 0.539, 5 }, { "up", 0.5, 0.69, 7 } },
        -- Tomo negro (276561): en la mesa de la sala de Arugal; invoca a Lyn el Ignorado
        -- en Ciudad de Dalaran. Sitio de una captura del autor desde dentro (22-10-2026).
        [7] = { { "down", 0.453, 0.873, 6 }, { "item", 0.600, 0.281, 276561, "MAP_ITEM_TOME" } },
    },
    BFD = {
        { { "entrance", 0.455, 0.085 }, { "floor", 0.615, 0.700, 2 } },
        { { "floor", 0.470, 0.700, 3 }, { "floor", 0.389, 0.276, 1 },
          { "spawn", 0.385, 0.194, 4, "MAP_NOTE_ALT_SPAWN" }, { "spawn", 0.442, 0.231, 4, "MAP_NOTE_ALT_SPAWN" } }, -- Lorgus Jett (FDJ 2.1.0)
        { { "floor", 0.407, 0.330, 2 } },
    },
    STOCKS = { { { "entrance", 0.500, 0.815 }, { "spawn", 0.499, 0.205, 3, "MAP_NOTE_ALT_SPAWN" },
        { "spawn", 0.335, 0.395, 3, "MAP_NOTE_ALT_SPAWN" }, { "spawn", 0.569, 0.544, 3, "MAP_NOTE_ALT_SPAWN" } } },
    GNOMER = {
        { { "entrance", 0.642, 0.278 }, { "down", 0.545, 0.409, 2 }, { "floor", 0.487, 0.877, 2 } },
        { { "floor", 0.245, 0.500, 3 }, { "floor", 0.747, 0.838, 1 } },
        { { "floor", 0.370, 0.720, 4 }, { "floor", 0.274, 0.150, 2 } },
        { { "floor", 0.601, 0.772, 3 } },
    },
    ST = { {
        { "statue", 0.500, 0.562, 1, "MAP_STATUE_S" }, { "statue", 0.501, 0.355, 2, "MAP_STATUE_N" },
        { "statue", 0.441, 0.510, 3, "MAP_STATUE_SW" }, { "statue", 0.560, 0.510, 4, "MAP_STATUE_SE" },
        { "statue", 0.441, 0.407, 5, "MAP_STATUE_NW" }, { "statue", 0.560, 0.406, 6, "MAP_STATUE_NE" },
    } },
    RFK = { {
        { "entrance", 0.714, 0.840 },
        { "note", 0.626, 0.562, 3, "MAP_NOTE_VINE" },
    } },
    SM_GY = { { { "entrance", 0.841, 0.831 } } },
    THANES = { { { "entrance", 0.510, 0.946 } } },
    -- Blason de Lordaeron (inicia 95189/95204): sale en uno de 5 sitios al azar (guia de
    -- Warcraft Tavern, 17-10-2026). Puestos a ojo sobre el plano siguiendo su recorrido.
    LORDAERON = { {
        { "entrance", 0.609, 0.204 },
        { "item", 0.566, 0.586, 275521, "MAP_ITEM_CRYPT" },
        { "item", 0.455, 0.245, 275521, "MAP_ITEM_FLOOR" },
        { "item", 0.349, 0.212, 275521, "MAP_ITEM_WALL" },
        { "item", 0.668, 0.262, 275521, "MAP_ITEM_TOP" },
        { "item", 0.372, 0.419, 275521, "MAP_ITEM_TOP" },
    } },
    EXCAVATION = { { { "entrance", 0.888, 0.258 } } },
    ALCAZ = { { { "entrance", 0.367, 0.171 }, { "down", 0.348, 0.553, 2 } } }, -- la escalera se abre con el llavero de Wrex
    -- Se baja a Atal'Byzal buceando (dos sitios) y se sube por los dos extremos del pasillo
    -- (el del norte, con tiburones).
    DROWNED = {
        { { "entrance", 0.845, 0.522 }, { "down", 0.575, 0.599, 2 }, { "down", 0.590, 0.837, 2 } },
        { { "up", 0.679, 0.111, 1 }, { "up", 0.262, 0.792, 1 } },
    },
    -- Pasos de FDJ 2.1.7 en nuestro plano. De la II se vuelve a la I por otra cueva.
    BLACKMAW = {
        { { "entrance", 0.218, 0.723 }, { "down", 0.687, 0.328, 2 }, { "down", 0.756, 0.512, 3 } },
        { { "up", 0.570, 0.791, 1 } },
        { { "up", 0.320, 0.906, 1 }, { "down", 0.313, 0.298, 4 } },
        { { "up", 0.812, 0.301, 3 }, { "down", 0.638, 0.675, 5 } },
        { { "up", 0.378, 0.765, 4 }, { "down", 0.635, 0.329, 6 } },
    },
    KROLDOK = { { { "entrance", 0.205, 0.806 } } },
    SHAPERS = { { { "entrance", 0.280, 0.678 } } },
    DALARAN = {
        { { "entrance", 0.192, 0.835 }, { "up", 0.641, 0.591, 2 } },
        { { "down", 0.610, 0.560, 1 } },
    },
    -- Calculadas con datos del cliente (ver arriba); las que tapaban una cara u otra marca, apartadas
    -- unos 45 px a mano.
    SCHOLO = {
        [1] = { { "down", 0.407, 0.557, 2 } },
        [2] = { { "up", 0.432, 0.473, 1 }, { "down", 0.329, 0.778, 3 }, { "down", 0.611, 0.614, 3 }, { "down", 0.431, 0.899, 4 } },
        [3] = { { "up", 0.32, 0.75, 2 }, { "up", 0.619, 0.549, 2 }, { "down", 0.685, 0.47, 4 } },
        [4] = { { "up", 0.443, 0.603, 2 }, { "up", 0.673, 0.303, 3 } },
    },
    BRD = {
        [1] = { { "up", 0.427, 0.629, 2 }, { "up", 0.356, 0.523, 2 } },
        [2] = { { "down", 0.41, 0.91, 1 }, { "down", 0.366, 0.77, 1 } },
    },
    LBRS = {
        [1] = { { "up", 0.607, 0.737, 2 }, { "up", 0.595, 0.579, 2 } },
        [2] = { { "down", 0.607, 0.737, 1 }, { "down", 0.595, 0.579, 1 }, { "up", 0.468, 0.539, 3 } },
        [3] = { { "up", 0.344, 0.478, 4 }, { "up", 0.378, 0.625, 5 }, { "down", 0.462, 0.51, 2 } },
        [4] = { { "down", 0.344, 0.478, 3 }, { "up", 0.428, 0.762, 5 } },
        [5] = { { "down", 0.375, 0.6, 3 }, { "down", 0.428, 0.762, 4 }, { "up", 0.43, 0.6, 6 } },
        [6] = { { "down", 0.408, 0.604, 5 } },
    },
    DM_E = {
        [1] = { { "down", 0.162, 0.178, 2 } },
        [2] = { { "up", 0.351, 0.451, 1 } },
    },
    DM_W = {
        [1] = { { "down", 0.256, 0.755, 2 }, { "down", 0.264, 0.427, 3 } },
        [2] = { { "up", 0.417, 0.736, 1 }, { "down", 0.269, 0.657, 3 } },
        [3] = { { "up", 0.752, 0.399, 1 }, { "up", 0.65, 0.577, 2 } },
    },
    MARA = {
        [1] = { { "down", 0.152, 0.646, 2 } },
        [2] = { { "up", 0.293, 0.095, 1 } },
    },
    ULDA = {
        [1] = { { "down", 0.39, 0.083, 2 } },
        [2] = { { "up", 0.505, 0.352, 1 } },
    },
    ONYXIA = { { { "entrance", 0.336, 0.200 } } }, -- el remolino del propio mapa
}
