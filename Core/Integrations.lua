local _, ns = ...
local L = ns.L

-- ==========================================
-- INTEGRACIONES OPCIONALES (OptionalDeps)
-- ==========================================
-- Todo con pcall: si el otro addon no esta, cambia su API o falla, aqui no pasa
-- nada. Ninguna de estas APIs es publica ni documentada: se leen en tiempo de
-- ejecucion, sin copiar nada de sus bases de datos.

local function IsLoaded(name)
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name) or false
end

-- AtlasLoot ----------------------------------------------------------------

function ns.AtlasLootAvailable()
    return IsLoaded("AtlasLoot") and type(AtlasLoot) == "table"
end

-- ponytail: abre AtlasLoot, pero no en la mazmorra: no tiene API publica para
-- elegir instancia. Cuando AtlasLoot for Forever la tenga, se selecciona aqui.
function ns.OpenAtlasLoot(d)
    if not ns.AtlasLootAvailable() then return false end
    local gui = AtlasLoot.GUI
    if gui and gui.Toggle and pcall(gui.Toggle, gui) then return true end
    local slash = SlashCmdList and SlashCmdList.ATLASLOOT
    return slash and pcall(slash, "") or false
end

-- Buscar grupo (la ventana del juego) ------------------------------------
-- La ventana se abre pulsando su boton del micromenu (UI/OverviewPanel.lua):
-- llamar a su codigo desde un addon la contamina y deja de mostrar los grupos.
-- Aqui solo se piden al servidor los grupos de la mazmorra, con la misma llamada
-- que usa la ventana; los resultados llegan por evento a su propio codigo.

function ns.GroupFinderShown()
    return LFGParentFrame and LFGParentFrame:IsShown() or false
end

-- La pestana de buscar grupos (la lupa), a la vista: solo ahi se ven los resultados
function ns.GroupBrowserShown()
    return LFGBrowseFrame and LFGBrowseFrame:IsVisible() or false
end

-- Texto de un desplegable de la ventana: solo su FontString (no su codigo, que la
-- contaminaria); su valor sigue siendo el suyo
local function SetDropdownLabel(dropdown, text)
    if not (dropdown and text) then return end
    local fs = dropdown.Text
    if not (fs and fs.SetText) and dropdown.GetRegions then
        for _, region in ipairs({ dropdown:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "FontString" then fs = region break end
        end
    end
    if fs and fs.SetText then fs:SetText(text) end
end

-- ponytail: las actividades se casan por mapID (el instanceID), asi que las alas
-- (Monasterio, La Masacre, Stratholme) buscan todas las suyas a la vez
function ns.SearchGroups(d)
    local list = C_LFGList
    if not (d and d.instanceID and list and list.Search and list.GetAvailableActivities) then return false end
    local ids, category, name = {}, nil, nil
    local ok = pcall(function()
        for _, id in ipairs(list.GetAvailableActivities() or {}) do
            local info = list.GetActivityInfoTable(id)
            if info and ns.PlainText(info.mapID) == d.instanceID then
                ids[#ids + 1] = id
                category = category or info.categoryID
                name = name or info.fullName
            end
        end
    end)
    if not ok or #ids == 0 then return false end
    if not pcall(list.Search, category, 0, 0, nil, false, nil, ids) then return false end
    -- Los desplegables dicen lo que se ha buscado, como si se hubiera elegido en ellos
    pcall(function()
        local info = list.GetLfgCategoryInfo and list.GetLfgCategoryInfo(category)
        SetDropdownLabel(LFGBrowseFrame.CategoryDropdown, info and info.name)
        SetDropdownLabel(LFGBrowseFrame.ActivityDropdown, #ids == 1 and name or ns.DungeonName(d))
    end)
    return true
end

-- Aviso junto a la lupa de la ventana (la pestana de buscar grupos) hasta que se elige
-- o se cierra la ventana: un addon no puede pulsarla (es un Frame). Como lo hace el
-- juego: el brillo de las pestanas laterales (atlas common-sidetab-selected, el TabGlow
-- de LargeSideTabButtonTemplate, que sube y baja en 0,9 s) en un marco propio encima de
-- la lupa, y al lado un tooltip del juego con el texto, quieto para que se lea.
local hint, glow

local function CreateHint()
    local ok, box = pcall(CreateFrame, "Frame", nil, UIParent, "TooltipBackdropTemplate")
    hint = ok and box or ns.CreateDarkBox(UIParent, 10)
    hint:Hide()
    hint:SetHeight(28)
    hint.text = hint:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint.text:SetPoint("CENTER")
    local appear = hint:CreateAnimationGroup()
    local fadeIn = appear:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.25)
    hint:SetScript("OnShow", function() appear:Play() end)
    hint:SetScript("OnUpdate", function(self)
        if not ns.GroupFinderShown() or ns.GroupBrowserShown() then self:Hide() end
    end)

    glow = CreateFrame("Frame", nil, hint)
    glow.texture = glow:CreateTexture(nil, "OVERLAY")
    glow.texture:SetAllPoints()
    -- Mezcla normal, no ADD: sumado al fondo azul de la lupa apenas se veia (visto en video);
    -- asi es el marco dorado de la pestana elegida, apareciendo y desapareciendo
    if not (glow.texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("common-sidetab-selected")) then
        glow.texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    else
        glow.texture:SetAtlas("common-sidetab-selected")
    end
    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")
    local up = pulse:CreateAnimation("Alpha")
    up:SetFromAlpha(0)
    up:SetToAlpha(1)
    up:SetDuration(0.9)
    up:SetOrder(1)
    local down = pulse:CreateAnimation("Alpha")
    down:SetFromAlpha(1)
    down:SetToAlpha(0)
    down:SetDuration(0.9)
    down:SetOrder(2)
    glow:SetScript("OnShow", function() pulse:Play() end)
    glow:SetScript("OnHide", function() pulse:Stop() end)
end

function ns.ShowGroupBrowserHint()
    local tab = LFGParentFrame and LFGParentFrame.BrowsingTab
    if not tab then return end
    if not hint then CreateHint() end
    -- El nombre de la pestana, el del juego ("Buscador de grupo"); en minuscula detras de
    -- "Cambia a" en los idiomas que no ponen mayuscula a los nombres comunes
    local name = tab.tooltipText or LFG_LIST_TAB_2 or "Group Browser"
    if (GetLocale() or ""):find("^[ei][st]") or (GetLocale() or ""):find("^pt") then name = name:gsub("^%u", string.lower) end
    hint.text:SetText(L.FIND_GROUP_HINT:format(name))
    hint:SetWidth(hint.text:GetStringWidth() + 24)
    hint:ClearAllPoints()
    hint:SetPoint("LEFT", tab, "RIGHT", 6, 0)
    -- El brillo, del tamano y en el sitio del marco de la pestana (su fondo)
    local frameArt = tab.Background or tab
    glow:ClearAllPoints()
    glow:SetAllPoints(frameArt)
    -- Hijos de la ventana de buscar grupo: van en su capa (DQA los tapa si se pone encima)
    -- y se esconden con ella. Encima de la pestana de la lupa.
    hint:SetParent(LFGParentFrame)
    hint:SetFrameStrata(LFGParentFrame:GetFrameStrata())
    hint:SetFrameLevel(tab:GetFrameLevel() + 10)
    glow:SetFrameLevel(tab:GetFrameLevel() + 5)
    glow:Show()
    hint:Show()
end

-- Questie ------------------------------------------------------------------
-- Respaldo para las misiones sin datos propios: startedBy / finishedBy -> primer
-- PNJ -> su primera aparicion. Questie guarda la zona como areaID y ZoneDB la
-- pasa a uiMapID. Coordenadas ya en 0-100.

local cache = {}
local FIELD = { starts = "startedBy", ends = "finishedBy" }

local function QuestieLookup(questID, which)
    local db = QuestieLoader:ImportModule("QuestieDB")
    local zones = QuestieLoader:ImportModule("ZoneDB")
    local by = db.QueryQuestSingle(questID, FIELD[which])
    local npcID = by and by[1] and by[1][1]
    if not npcID then return nil end
    for areaID, spawns in pairs(db.QueryNPCSingle(npcID, "spawns") or {}) do
        local spawn = spawns[1]
        local mapID = zones:GetUiMapIdByAreaId(areaID)
        if spawn and mapID then
            return { npcID = npcID, mapID = mapID, x = spawn[1], y = spawn[2], name = db.QueryNPCSingle(npcID, "name") }
        end
    end
end

function ns.QuestiePlace(questID, which)
    local key = which .. questID
    if cache[key] ~= nil then return cache[key] or nil end
    if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
    local ok, place = pcall(QuestieLookup, questID, which)
    if not ok then ns.Debug("Questie: %s", tostring(place)) end
    cache[key] = ok and place or false
    return cache[key] or nil
end
