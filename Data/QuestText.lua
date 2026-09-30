local _, ns = ...

-- Textos de mision por idioma: ns.QuestText[locale][questID] =
--   { title = "...", desc = "...", obj = "...", giverName = "..." }
-- Vacio a proposito: los textos no se inventan ni se copian de webs. Salen del
-- juego con el recolector (/dqa collect on, abrir la mision, /dqa export) y se
-- pegan aqui. Lo recogido en tu propio cliente se usa al momento, sin pegar nada.
-- Se guardan todos los idiomas: la ventana puede mostrarse en otro que el del
-- juego (ns.SetLanguage) y usa sus textos si estan recogidos.

local QuestText = {
    enUS = {},
    esES = {},
}

local locale = GetLocale()
if locale == "esMX" then locale = "esES" end
ns.QuestTextData = { byLocale = QuestText, active = QuestText[locale] or {}, fallback = QuestText.enUS }
