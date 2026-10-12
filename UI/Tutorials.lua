local _, ns = ...
local L = ns.L

-- ==========================================
-- SECCION: TUTORIALES (GUIA DEL ADDON)
-- ==========================================
-- Pestana de abajo de la ventana (contrato de seccion: SECTIONS en UI/MainFrame.lua).
-- Como la pestana Tutoriales de la Guia de Retail: franja oscura con el titulo y
-- una hoja de pergamino grande (atlas del Diario "adventureguide-pane-large") con
-- la ilustracion a la izquierda y, a la derecha, titulo, separador, texto en tinta
-- y un boton rojo que lleva a lo que explica. Varias paginas: flechas arriba a la
-- derecha o la rueda del raton; la ultima vista se recuerda (ns.char.tutorialPage).

-- Paginas: clave de los textos (TUT_<key>_TITLE/_TEXT/_BUTTON), arte y accion
local function CurrentDungeon(needMap)
    local d = ns.char.dungeon and ns.DungeonByKey[ns.char.dungeon]
    if d and (not needMap or ns.DungeonMaps(d)) then return d end
    return ns.DungeonByKey.DM
end

local function OpenWorldMap()
    if DungeonQuestAtlasFrame then DungeonQuestAtlasFrame:Hide() end -- si no, tapa el mapa
    local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if id then ns.OpenMapAt(id) elseif ToggleWorldMap then pcall(ToggleWorldMap) end
end

local PAGES = {
    { key = "DUNGEONS", art = "DM", action = function() ns.ShowSection("dungeons") end },
    { key = "MARK", art = "WC", action = OpenWorldMap },
    { key = "MAP", art = "SFK", action = function() ns.ShowDungeonMap(CurrentDungeon(true)) end },
    { key = "BOSSES", art = "BRD", action = function() ns.ShowBoss(CurrentDungeon(), 1) end },
    { key = "WORLDMAP", art = "ST", action = OpenWorldMap },
    { key = "COMMANDS", action = function() ns.OpenOptions() end },
}
ns.TUTORIAL_PAGES = PAGES

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

-- Boton de pagina (los del libro de hechizos, como en Contenido sugerido)
local function PageButton(parent, name)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(28, 28)
    local path = "Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "Page-"
    b:SetNormalTexture(path .. "Up")
    b:SetPushedTexture(path .. "Down")
    b:SetDisabledTexture(path .. "Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return b
end

function ns.CreateTutorialsSection(parent)
    local section = {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    section.frame = frame

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.05, 0.04, 1)
    local band = frame:CreateTexture(nil, "BORDER") -- franja oscura del titulo, como en la Guia
    band:SetPoint("TOPLEFT")
    band:SetPoint("TOPRIGHT")
    band:SetHeight(54)
    band:SetColorTexture(0, 0, 0, 0.45)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    ns.SetTitleFont(title, 24)
    title:SetPoint("LEFT", band, "LEFT", 20, 0)
    title:SetText(L.TAB_TUTORIALS)

    -- Paginas: flechas y "2 / 6" a la derecha de la franja
    local nextButton = PageButton(frame, "Next")
    nextButton:SetPoint("RIGHT", band, "RIGHT", -16, 0)
    local counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    counter:SetPoint("RIGHT", nextButton, "LEFT", -8, 0)
    local prevButton = PageButton(frame, "Prev")
    prevButton:SetPoint("RIGHT", counter, "LEFT", -8, 0)

    -- Hoja de pergamino
    local sheet = CreateFrame("Frame", nil, frame)
    sheet:SetPoint("TOPLEFT", 26, -66)
    sheet:SetPoint("BOTTOMRIGHT", -26, 12)
    local paper = sheet:CreateTexture(nil, "BACKGROUND")
    paper:SetAllPoints()
    if HasAtlas("adventureguide-pane-large") then
        paper:SetAtlas("adventureguide-pane-large")
    else
        paper:SetTexture("Interface\\QuestFrame\\QuestBG")
        paper:SetTexCoord(0, 0.586, 0, 0.65)
    end

    -- Ilustracion a la izquierda, con un marco oscuro fino
    local artBorder = sheet:CreateTexture(nil, "BORDER")
    artBorder:SetSize(310, 207)
    artBorder:SetPoint("LEFT", 28, 0)
    artBorder:SetColorTexture(0.12, 0.07, 0.02, 0.9)
    local art = sheet:CreateTexture(nil, "ARTWORK")
    art:SetPoint("TOPLEFT", artBorder, 3, -3)
    art:SetPoint("BOTTOMRIGHT", artBorder, -3, 3)
    -- Ultima pagina: el logo del addon, cuadrado y centrado
    local logo = sheet:CreateTexture(nil, "ARTWORK")
    logo:SetSize(200, 200)
    logo:SetPoint("CENTER", artBorder)
    logo:SetTexture(ns.LOGO)

    -- Texto a la derecha
    local textLeft = 28 + 310 + 30
    local header = ns.PaperText(sheet, "GameFontNormalHuge", ns.INK_HEADER)
    ns.SetTitleFont(header, 26)
    header:SetPoint("TOPLEFT", textLeft, -28)
    header:SetPoint("RIGHT", -28, 0)
    header:SetMaxLines(2)
    local divider = sheet:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    if HasAtlas("adventureguide-tutorial-divider") then
        divider:SetAtlas("adventureguide-tutorial-divider")
        divider:SetSize(300, 9)
    else
        divider:SetSize(300, 1)
        divider:SetColorTexture(ns.INK_HEADER[1], ns.INK_HEADER[2], ns.INK_HEADER[3], 0.5)
    end
    local text = ns.PaperText(sheet, "GameFontBlackMedium")
    text:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -12)
    text:SetPoint("RIGHT", -28, 0)
    text:SetSpacing(3)

    local ok, button = pcall(CreateFrame, "Button", nil, sheet, "SharedButtonSmallTemplate")
    if not ok or not button then button = CreateFrame("Button", nil, sheet, "UIPanelButtonTemplate") end
    button:SetSize(190, 26)
    button:SetPoint("BOTTOM", sheet, "BOTTOMLEFT", textLeft + (ns.Width(sheet, 733) - textLeft - 28) / 2, 26)

    local function Show(index)
        index = math.max(1, math.min(#PAGES, index or 1))
        ns.char.tutorialPage = index
        local page = PAGES[index]
        local d = page.art and ns.DungeonByKey[page.art]
        art:SetShown(d ~= nil)
        artBorder:SetShown(d ~= nil)
        logo:SetShown(d == nil)
        if d then ns.SetDungeonArt(art, d, "lore") end
        header:SetText(L["TUT_" .. page.key .. "_TITLE"])
        text:SetText(L["TUT_" .. page.key .. "_TEXT"])
        button:SetText(L["TUT_" .. page.key .. "_BUTTON"])
        button:SetScript("OnClick", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            page.action()
        end)
        counter:SetText(index .. " / " .. #PAGES)
        prevButton:SetEnabled(index > 1)
        nextButton:SetEnabled(index < #PAGES)
    end
    local function Turn(step)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
        Show((ns.char.tutorialPage or 1) + step)
    end
    prevButton:SetScript("OnClick", function() Turn(-1) end)
    nextButton:SetScript("OnClick", function() Turn(1) end)
    sheet:EnableMouseWheel(true)
    sheet:SetScript("OnMouseWheel", function(_, delta) Turn(delta > 0 and -1 or 1) end)

    function section:Refresh()
        Show(ns.char.tutorialPage)
    end
    section.Show = function(_, index) Show(index) end
    section.header, section.button, section.counter = header, button, counter -- para los tests
    return section
end
