local _, ns = ...

-- Pulls y ruta de los planos de Data/Maps.lua (aparte: gen.py reescribe ese fichero).
-- [planta] = { { x, y, bichos, paso }, ... } (0-1 sobre la planta, la planta en el
-- orden de Data/Maps.lua). Cada pull es un grupo de bichos normales que se atacan
-- juntos: apariciones de AzerothCore agrupadas por cercania y pasadas a la planta
-- como las de los jefes.
-- paso: su numero en la ruta (el orden recomendado), a mano; nil = fuera de la ruta
-- (se puede saltar). bosses = { [indice del jefe en Data/Bosses.lua] = paso }: los
-- jefes en la ruta. Dos pasos seguidos en la misma planta se unen con una linea.
-- Ejemplo: RFC = { { { 0.58, 0.20, 3, 1 }, { 0.55, 0.30, 2 } }, bosses = { [1] = 2 } }

ns.Pulls = {
}
