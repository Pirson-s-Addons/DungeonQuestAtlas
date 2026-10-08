local _, ns = ...

-- Marcas de los planos de Data/Maps.lua (aparte: gen.py reescribe ese fichero).
-- [planta] = { { tipo, x, y, planta a la que lleva }, ... } (0-1 sobre la planta, la
-- planta en el orden de Data/Maps.lua). Tipos:
--   "entrance": la entrada de la mazmorra;
--   "up" / "down": escalera o rampa que sube o baja a otra planta;
--   "floor": paso a otra planta sin saber si sube o baja.
-- Sitios de ForeverDungeonJournal (Core/Journal.lua, 08-10-2026; solo los datos,
-- comprobados sobre cada plano). Sube o baja solo donde FDJ lo dice (Colmillo
-- Oscuro, el salto de Gnomeregan) o se ve (Dalaran: la ciudad sobre las cloacas).
-- Excavacion: el remolino del mapa del autor (el de FDJ es otro dibujo).
-- Pasos entre plantas de Colmillo Oscuro, Scholomance, Profundidades y Cumbre de Roca Negra,
-- La Masacre, Maraudon y Uldaman (08-10-2026): calculados con datos del cliente. Un grupo del
-- modelo (WMOGroupID) que UiMapAssignment pinta en dos plantas es la escalera o rampa que
-- las une; su caja, pasada al mundo con la colocacion del modelo, da el sitio en cada planta,
-- y la altura media de cada planta dice si sube o baja. Sin grupo compartido, el sitio donde
-- un grupo de cada planta se tocan. Modelos de Retail via el descubrimiento de DungeonLens
-- (github.com/denisanzora/DungeonLens, MIT); el sitio es el centro del grupo (aproximado
-- dentro de la sala). Gnomeregan, Las Minas y Brazanegra: los de FDJ, comprobados igual.
-- FDJ solo marca un sentido. Las vueltas (planta de destino -> la de antes) salen de
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
        [7] = { { "down", 0.453, 0.873, 6 } },
    },
    BFD = {
        { { "entrance", 0.455, 0.085 }, { "floor", 0.615, 0.700, 2 } },
        { { "floor", 0.470, 0.700, 3 }, { "floor", 0.389, 0.276, 1 } },
        { { "floor", 0.407, 0.330, 2 } },
    },
    STOCKS = { { { "entrance", 0.500, 0.815 } } },
    GNOMER = {
        { { "entrance", 0.642, 0.278 }, { "down", 0.545, 0.409, 2 }, { "floor", 0.487, 0.877, 2 } },
        { { "floor", 0.245, 0.500, 3 }, { "floor", 0.747, 0.838, 1 } },
        { { "floor", 0.370, 0.720, 4 }, { "floor", 0.274, 0.150, 2 } },
        { { "floor", 0.601, 0.772, 3 } },
    },
    RFK = { { { "entrance", 0.714, 0.840 } } },
    SM_GY = { { { "entrance", 0.841, 0.831 } } },
    THANES = { { { "entrance", 0.510, 0.944 } } },
    LORDAERON = { { { "entrance", 0.612, 0.214 } } },
    EXCAVATION = { { { "entrance", 0.077, 0.610 } } },
    DALARAN = {
        { { "entrance", 0.190, 0.838 }, { "up", 0.642, 0.593, 2 } },
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
}
