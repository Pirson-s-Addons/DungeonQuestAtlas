local _, ns = ...

-- Planos de las mazmorras: los mapas de Blizzard de WoW Classic (WotLK 3.4.3,
-- con la distribucion de vanilla). WoW Forever no trae mapas de mazmorra.
-- Cada planta es su uiMapID de Blizzard; su dibujo son 12 piezas de 256x256
-- (4x3) en Art/Maps/<id>_<1-12>.blp, de las que se ven 1002x668.
-- tex: las mismas piezas en el cliente (Interface\WorldMap; %d = 1-12). Forever
-- las trae aunque no tenga los uiMap; ForeverDungeonJournal las usa. Si el
-- cliente no tiene una, se usa la del addon.
-- pins: { indice del jefe en Data/Bosses.lua, x, y } (0-1 sobre la planta).
-- Posiciones: aparicion del jefe en AzerothCore pasada a la planta con
-- UiMapAssignment; la planta y los que no tienen aparicion fija, a mano.

ns.Maps = {
    RFC = {
        { id = 213, tex = "interface\\worldmap\\ragefire\\ragefire1_%d", pins = { { 1, 0.561, 0.38 }, { 2, 0.41, 0.577 }, { 3, 0.33, 0.845 }, { 4, 0.415, 0.862 } } },
    },
    ZF = {
        { id = 219, tex = "interface\\worldmap\\zulfarrak\\zulfarrak%d", pins = { { 1, 0.69, 0.256 }, { 2, 0.553, 0.297 }, { 3, 0.441, 0.548 }, { 4, 0.44, 0.152 }, { 5, 0.235, 0.136 }, { 6, 0.266, 0.183 }, { 7, 0.342, 0.204 }, { 8, 0.235, 0.23 }, { 9, 0.204, 0.183 }, { 10, 0.299, 0.383 }, { 11, 0.328, 0.435 }, { 12, 0.439, 0.352 }, { 13, 0.521, 0.409 } } },
    },
    ST = {
        { id = 220, tex = "interface\\worldmap\\thetempleofatalhakkar\\thetempleofatalhakkar1_%d", pins = { { 1, 0.501, 0.358 }, { 2, 0.498, 0.486 }, { 3, 0.603, 0.595 }, { 4, 0.24, 0.457 }, { 5, 0.761, 0.323 }, { 6, 0.761, 0.413 }, { 7, 0.44, 0.428 }, { 8, 0.453, 0.44 }, { 9, 0.521, 0.89 }, { 10, 0.489, 0.89 }, { 11, 0.688, 0.87 } } },
    },
    BFD = {
        { id = 221, tex = "interface\\worldmap\\blackfathomdeeps\\blackfathomdeeps1_%d", pins = { { 1, 0.329, 0.602 }, { 2, 0.101, 0.36 }, { 3, 0.522, 0.551 } } },
        { id = 222, tex = "interface\\worldmap\\blackfathomdeeps\\blackfathomdeeps2_%d", pins = { { 4, 0.354, 0.483 }, { 5, 0.414, 0.754 }, { 6, 0.519, 0.816 }, { 8, 0.856, 0.867 } } },
        { id = 223, tex = "interface\\worldmap\\blackfathomdeeps\\blackfathomdeeps3_%d", pins = { { 7, 0.606, 0.312 } } },
    },
    STOCKS = {
        { id = 225, tex = "interface\\worldmap\\thestockade\\thestockade1_%d", pins = { { 1, 0.692, 0.309 }, { 2, 0.381, 0.24 }, { 3, 0.499, 0.242 }, { 4, 0.782, 0.456 }, { 5, 0.864, 0.52 } } },
    },
    GNOMER = {
        { id = 226, tex = "interface\\worldmap\\gnomeregan\\gnomeregan1_%d", pins = { { 2, 0.819, 0.651 }, { 3, 0.576, 0.566 } } },
        { id = 227, tex = "interface\\worldmap\\gnomeregan\\gnomeregan2_%d", pins = { { 4, 0.246, 0.684 } } },
        { id = 228, tex = "interface\\worldmap\\gnomeregan\\gnomeregan3_%d", pins = { { 5, 0.438, 0.865 } } },
        { id = 229, tex = "interface\\worldmap\\gnomeregan\\gnomeregan4_%d", pins = { { 6, 0.434, 0.622 }, { 7, 0.313, 0.3 } } },
    },
    ULDA = {
        { id = 230, tex = "interface\\worldmap\\uldaman\\uldaman1_%d", pins = { { 1, 0.589, 0.899 }, { 2, 0.615, 0.966 }, { 3, 0.574, 0.942 }, { 4, 0.541, 0.722 }, { 5, 0.375, 0.738 }, { 6, 0.288, 0.618 }, { 7, 0.474, 0.407 }, { 8, 0.258, 0.315 }, { 9, 0.212, 0.248 }, { 12, 0.563, 0.966 }, { 13, 0.629, 0.932 }, { 14, 0.259, 0.307 }, { 15, 0.258, 0.405 } } },
        { id = 231, tex = "interface\\worldmap\\uldaman\\uldaman2_%d", pins = { { 10, 0.554, 0.506 } } },
    },
    DM_E = {
        { id = 239, tex = "interface\\worldmap\\diremaul\\diremaul5_%d", pins = { { 1, 0.122, 0.31 } } },
        { id = 240, tex = "interface\\worldmap\\diremaul\\diremaul6_%d", pins = { { 2, 0.575, 0.746 }, { 3, 0.565, 0.64 }, { 4, 0.565, 0.73 }, { 5, 0.554, 0.269 } } },
    },
    DM_N = {
        { id = 235, tex = "interface\\worldmap\\diremaul\\diremaul1_%d", pins = { { 1, 0.699, 0.752 }, { 2, 0.62, 0.657 }, { 3, 0.493, 0.816 }, { 4, 0.277, 0.588 }, { 5, 0.285, 0.547 }, { 6, 0.318, 0.497 }, { 7, 0.312, 0.209 }, { 8, 0.338, 0.276 }, { 9, 0.286, 0.277 } } },
    },
    DM_W = {
        { id = 236, tex = "interface\\worldmap\\diremaul\\diremaul2_%d", pins = { { 1, 0.332, 0.53 }, { 2, 0.202, 0.812 } } },
        { id = 237, tex = "interface\\worldmap\\diremaul\\diremaul3_%d", pins = { { 3, 0.294, 0.436 } } },
        { id = 238, tex = "interface\\worldmap\\diremaul\\diremaul4_%d", pins = { { 4, 0.684, 0.243 }, { 5, 0.35, 0.531 }, { 6, 0.599, 0.235 }, { 8, 0.821, 0.259 }, { 9, 0.35, 0.621 } } },
    },
    BRD = {
        { id = 242, tex = "interface\\worldmap\\blackrockdepths\\blackrockdepths1_%d", pins = { { 1, 0.561, 0.609 }, { 2, 0.475, 0.934 }, { 10, 0.545, 0.7 }, { 11, 0.624, 0.363 }, { 12, 0.614, 0.342 }, { 13, 0.614, 0.432 }, { 14, 0.624, 0.453 }, { 15, 0.616, 0.238 }, { 16, 0.561, 0.312 }, { 17, 0.24, 0.516 } } },
        { id = 243, tex = "interface\\worldmap\\blackrockdepths\\blackrockdepths2_%d", pins = { { 3, 0.496, 0.888 }, { 4, 0.502, 0.839 }, { 5, 0.543, 0.874 }, { 6, 0.543, 0.944 }, { 7, 0.502, 0.97 }, { 8, 0.461, 0.944 }, { 9, 0.461, 0.874 }, { 18, 0.366, 0.844 }, { 19, 0.369, 0.65 }, { 20, 0.481, 0.619 }, { 21, 0.529, 0.628 }, { 22, 0.538, 0.488 }, { 23, 0.488, 0.363 }, { 24, 0.568, 0.233 }, { 25, 0.817, 0.119 }, { 26, 0.932, 0.07 }, { 27, 0.932, 0.16 } } },
    },
    LBRS = {
        { id = 250, tex = "interface\\worldmap\\blackrockspire\\blackrockspire1_%d", pins = { { 7, 0.53, 0.544 }, { 8, 0.495, 0.56 } } },
        { id = 251, tex = "interface\\worldmap\\blackrockspire\\blackrockspire2_%d", pins = { { 6, 0.556, 0.72 }, { 9, 0.65, 0.744 } } },
        { id = 252, tex = "interface\\worldmap\\blackrockspire\\blackrockspire3_%d", pins = { { 2, 0.51, 0.577 }, { 3, 0.351, 0.553 }, { 4, 0.482, 0.574 }, { 5, 0.418, 0.567 }, { 10, 0.465, 0.694 } } },
        { id = 253, tex = "interface\\worldmap\\blackrockspire\\blackrockspire4_%d", pins = { { 11, 0.458, 0.539 } } },
        { id = 254, tex = "interface\\worldmap\\blackrockspire\\blackrockspire5_%d", pins = { { 1, 0.378, 0.705 }, { 12, 0.548, 0.837 }, { 13, 0.393, 0.798 }, { 14, 0.393, 0.888 }, { 15, 0.34, 0.667 } } },
        { id = 255, tex = "interface\\worldmap\\blackrockspire\\blackrockspire6_%d", pins = { { 16, 0.56, 0.553 } } },
    },
    UBRS = {
        { id = 255, tex = "interface\\worldmap\\blackrockspire\\blackrockspire6_%d", pins = { { 1, 0.303, 0.271 }, { 2, 0.345, 0.365 }, { 3, 0.398, 0.236 }, { 4, 0.286, 0.269 }, { 5, 0.512, 0.2 }, { 6, 0.512, 0.29 }, { 7, 0.648, 0.305 }, { 8, 0.334, 0.453 }, { 10, 0.328, 0.404 } } },
    },
    WC = {
        { id = 279, tex = "interface\\worldmap\\wailingcaverns\\wailingcaverns1_%d", pins = { { 1, 0.156, 0.585 }, { 2, 0.19, 0.397 }, { 3, 0.258, 0.446 }, { 4, 0.552, 0.469 }, { 6, 0.625, 0.536 }, { 7, 0.619, 0.741 }, { 8, 0.342, 0.158 } } },
    },
    MARA = {
        { id = 280, tex = "interface\\worldmap\\maraudon\\maraudon1_%d", pins = { { 1, 0.586, 0.223 }, { 2, 0.348, 0.107 }, { 3, 0.162, 0.34 }, { 4, 0.52, 0.845 }, { 5, 0.377, 0.694 }, { 6, 0.227, 0.662 } } },
        { id = 281, tex = "interface\\worldmap\\maraudon\\maraudon2_%d", pins = { { 7, 0.245, 0.144 }, { 8, 0.406, 0.482 }, { 9, 0.484, 0.686 }, { 10, 0.333, 0.771 }, { 11, 0.242, 0.784 } } },
    },
    DM = {
        { id = 291, tex = "interface\\worldmap\\thedeadmines\\thedeadmines1_%d", pins = { { 1, 0.377, 0.612 }, { 2, 0.517, 0.504 }, { 3, 0.493, 0.826 }, { 4, 0.493, 0.916 } } },
        { id = 292, tex = "interface\\worldmap\\thedeadmines\\thedeadmines2_%d", pins = { { 5, 0.114, 0.729 }, { 6, 0.561, 0.265 }, { 7, 0.606, 0.375 }, { 8, 0.606, 0.459 }, { 9, 0.674, 0.399 }, { 10, 0.2, 0.516 } } },
    },
    RFD = {
        { id = 300, tex = "interface\\worldmap\\razorfendowns\\razorfendowns1_%d", pins = { { 1, 0.596, 0.275 }, { 2, 0.858, 0.457 }, { 3, 0.385, 0.452 }, { 4, 0.529, 0.672 }, { 5, 0.45, 0.591 }, { 6, 0.349, 0.665 }, { 8, 0.81, 0.168 } } },
    },
    RFK = {
        { id = 301, tex = "interface\\worldmap\\razorfenkraul\\razorfenkraul1_%d", pins = { { 1, 0.808, 0.544 }, { 2, 0.879, 0.414 }, { 3, 0.648, 0.421 }, { 4, 0.569, 0.253 }, { 5, 0.569, 0.343 }, { 6, 0.112, 0.724 }, { 7, 0.11, 0.303 }, { 8, 0.264, 0.324 }, { 9, 0.494, 0.471 } } },
    },
    SM_GY = {
        { id = 302, tex = "interface\\worldmap\\scarletmonastery\\scarletmonastery1_%d", pins = { { 1, 0.715, 0.59 }, { 2, 0.283, 0.434 }, { 3, 0.359, 0.663 }, { 4, 0.517, 0.679 }, { 5, 0.244, 0.508 } } },
    },
    SM_LIB = {
        { id = 303, tex = "interface\\worldmap\\scarletmonastery\\scarletmonastery2_%d", pins = { { 1, 0.308, 0.878 }, { 2, 0.832, 0.745 }, { 4, 0.844, 0.822 } } },
    },
    SM_ARM = {
        { id = 304, tex = "interface\\worldmap\\scarletmonastery\\scarletmonastery3_%d", pins = { { 1, 0.787, 0.108 } } },
    },
    SM_CATH = {
        { id = 305, tex = "interface\\worldmap\\scarletmonastery\\scarletmonastery4_%d", pins = { { 1, 0.554, 0.261 }, { 2, 0.491, 0.272 }, { 3, 0.49, 0.169 } } },
    },
    SCHOLO = {
        { id = 306, tex = "interface\\worldmap\\scholomance\\scholomance1_%d", pins = { { 1, 0.789, 0.716 } } },
        { id = 307, tex = "interface\\worldmap\\scholomance\\scholomance2_%d", pins = { { 2, 0.495, 0.043 }, { 3, 0.54, 0.237 }, { 6, 0.444, 0.638 }, { 7, 0.483, 0.662 } } },
        { id = 308, tex = "interface\\worldmap\\scholomance\\scholomance3_%d", pins = { { 4, 0.304, 0.579 }, { 5, 0.304, 0.669 }, { 9, 0.728, 0.808 }, { 10, 0.956, 0.459 }, { 11, 0.72, 0.12 }, { 15, 0.736, 0.464 } } },
        { id = 309, tex = "interface\\worldmap\\scholomance\\scholomance4_%d", pins = { { 8, 0.406, 0.884 }, { 12, 0.675, 0.521 }, { 13, 0.844, 0.308 }, { 14, 0.67, 0.061 } } },
    },
    -- Colmillo Oscuro: plantas en el orden del recorrido, no en el de Blizzard (316, la
    -- muralla, va tercera: de la cocina se sube a ella y de ella a la torre). A mano: gen.py
    -- las deja en el orden de Blizzard.
    SFK = {
        { id = 310, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep1_%d", pins = { { 1, 0.661, 0.711 }, { 2, 0.34, 0.635 }, { 5, 0.275, 0.586 }, { 6, 0.596, 0.646 }, { 7, 0.657, 0.456 }, { 13, 0.338, 0.568 } } },
        { id = 311, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep2_%d", pins = { { 3, 0.48, 0.29 }, { 4, 0.295, 0.803 } } },
        { id = 316, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep7_%d", pins = {} },
        { id = 312, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep3_%d", pins = { { 14, 0.463, 0.626 } } },
        { id = 313, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep4_%d", pins = { { 9, 0.574, 0.433 } } },
        { id = 314, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep5_%d", pins = {} },
        { id = 315, tex = "interface\\worldmap\\shadowfangkeep\\shadowfangkeep6_%d", pins = { { 10, 0.591, 0.533 }, { 11, 0.639, 0.2 } } },
    },
    STRAT_LIVE = {
        { id = 317, tex = "interface\\worldmap\\stratholme\\stratholme1_%d", pins = { { 1, 0.575, 0.697 }, { 2, 0.54, 0.71 }, { 3, 0.847, 0.454 }, { 4, 0.71, 0.218 }, { 6, 0.394, 0.335 }, { 7, 0.304, 0.4 }, { 8, 0.125, 0.476 }, { 9, 0.036, 0.501 }, { 10, 0.271, 0.751 }, { 11, 0.188, 0.837 } } },
    },
    STRAT_UD = {
        { id = 318, tex = "interface\\worldmap\\stratholme\\stratholme2_%d", pins = { { 1, 0.653, 0.755 }, { 2, 0.62, 0.251 }, { 3, 0.749, 0.469 }, { 4, 0.727, 0.524 }, { 5, 0.564, 0.469 }, { 6, 0.682, 0.199 }, { 7, 0.451, 0.197 }, { 8, 0.372, 0.199 } } },
    },
    -- Mazmorras nuevas de Forever: mapas propios del autor (una planta; jefes
    -- pasados a ojo desde las capturas con su sitio que dio el autor).
    -- id = clave: Art/Maps/<CLAVE>_<1-12>.tga, generadas con
    -- _project/tools/dqa_maps/forever_maps.py.
    EXCAVATION = { { id = "EXCAVATION", pins = { { 1, 0.381, 0.545 }, { 2, 0.664, 0.499 }, { 3, 0.581, 0.301 } } } },
    LORDAERON = { { id = "LORDAERON", pins = { { 1, 0.591, 0.713 }, { 2, 0.693, 0.469 }, { 3, 0.399, 0.515 }, { 4, 0.415, 0.288 }, { 5, 0.451, 0.604 }, { 6, 0.367, 0.626 }, { 7, 0.342, 0.377 } } } },
    THANES = { { id = "THANES", pins = { { 1, 0.479, 0.674 }, { 2, 0.737, 0.469 }, { 3, 0.501, 0.513 }, { 4, 0.501, 0.16 } } } },
    -- Dalaran: planta 1 las cloacas (la entrada), planta 2 la ciudad. Jefes de
    -- ForeverDungeonJournal (los vistos en la demo de la BlizzCon)
    DALARAN = {
        { id = "DALARAN1", pins = { { 1, 0.535, 0.505 } } },
        { id = "DALARAN2", pins = { { 2, 0.545, 0.705 }, { 7, 0.52, 0.24 } } },
    },
}
