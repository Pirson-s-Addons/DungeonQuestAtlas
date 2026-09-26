local _, ns = ...

-- ==========================================
-- TEMA: el Diario de mazmorras del juego
-- ==========================================
-- Todo el arte es del propio cliente (nada se empaqueta): la hoja de texturas
-- del Diario (Interface\EncounterJournal), con las mismas coordenadas que usa
-- Blizzard_EncounterJournal (rama forever de wow-ui-source), y sus fuentes.

local unpack = unpack or table.unpack
local SHEET = "Interface\\EncounterJournal\\UI-EncounterJournalTextures"
-- nombre = { izquierda, derecha, arriba, abajo }
local REGION = {
    BossButtonUp = { 0.00195313, 0.63671875, 0.21386719, 0.26757813 },
    BossButtonDown = { 0.00195313, 0.63671875, 0.10253906, 0.15625000 },
    BossButtonHighlight = { 0.00195313, 0.63671875, 0.15820313, 0.21191406 },
    LootFrame = { 0.00195313, 0.62890625, 0.61816406, 0.66210938 },
    DungeonNameBg = { 0.34570313, 0.84570313, 0.42871094, 0.49121094 },
    DungeonButtonHighlight = { 0.34570313, 0.68554688, 0.33300781, 0.42675781 },
    TabUnselected = { 0.25585938, 0.37890625, 0.90332031, 0.95898438 },
    TabSelected = { 0.12890625, 0.25195313, 0.90332031, 0.95898438 },
    TabHighlight = { 0.00195313, 0.12500000, 0.90332031, 0.95898438 },
    TabLootIcon = { 0.73046875, 0.82421875, 0.61816406, 0.66015625 },
    TabLootIconSelected = { 0.63281250, 0.72656250, 0.61816406, 0.66015625 },
    TabModelIcon = { 0.90234375, 1, 0.662109375, 0.705078125 },
    TabModelIconSelected = { 0.8046875, 0.900390625, 0.662109375, 0.705078125 },
    BossModelButton = { 0.50585938, 0.63085938, 0.02246094, 0.08203125 },
    BossNameShadow = { 0.00195313, 0.77343750, 0.26953125, 0.33105469 },
    LeftPageHeader = { 0, 0.755859375, 0.9599609375, 1 },
}

function ns.SetEJTexture(texture, name)
    texture:SetTexture(SHEET)
    texture:SetTexCoord(unpack(REGION[name]))
end

ns.BOOK = { file = "Interface\\EncounterJournal\\UI-EJ-JournalBG", width = 785, height = 425,
    coords = { 0, 0.766601562, 0, 0.830078125 } }

-- Colores del Diario: texto sobre papel, botones de jefe y titulos claros
ns.INK = { 0.25, 0.15, 0.02 }          -- GameFontBlack del Diario
ns.INK_LIGHT = { 0.45, 0.32, 0.18 }
ns.PARCHMENT_GOLD = { 0.827, 0.659, 0.463 } -- texto de los botones de jefe
ns.TITLE_LIGHT = { 0.902, 0.788, 0.671 }    -- titulo de la mazmorra

-- Texto sobre papel: fuente del juego con la tinta del Diario
function ns.PaperText(parent, font, color)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "QuestFont")
    fs:SetTextColor(unpack(color or ns.INK))
    fs:SetShadowOffset(0, 0)
    fs:SetJustifyH("LEFT")
    return fs
end

-- Titulo de seccion sobre papel con una raya fina debajo
function ns.CreatePaperHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(22)
    frame.text = ns.PaperText(frame, "QuestTitleFont")
    frame.text:SetPoint("BOTTOMLEFT", 0, 5)
    frame.text:SetText(text)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(ns.INK[1], ns.INK[2], ns.INK[3], 0.3)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    return frame
end

-- Boton del Diario (el de los jefes): normal / seleccionado / resaltado
function ns.SetupJournalButton(button)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    ns.SetEJTexture(button.bg, "BossButtonUp")
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    ns.SetEJTexture(hl, "BossButtonHighlight")
    hl:SetBlendMode("ADD")
end

function ns.SetJournalButtonSelected(button, on)
    ns.SetEJTexture(button.bg, on and "BossButtonDown" or "BossButtonUp")
end

-- Pestana lateral del libro (EncounterTabTemplate): icon = region de la hoja
-- o una textura cualquiera. Devuelve el boton; SetSelected(true/false).
function ns.CreateSideTab(parent, tooltip, icon, iconSelected, onClick)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(63, 57)
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    ns.SetEJTexture(tab.bg, "TabUnselected")
    local hl = tab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    ns.SetEJTexture(hl, "TabHighlight")
    hl:SetBlendMode("ADD")
    tab.icon = tab:CreateTexture(nil, "OVERLAY")
    tab.icon:SetSize(REGION[icon] and 48 or 26, REGION[icon] and 43 or 26)
    tab.icon:SetPoint("RIGHT", REGION[icon] and -6 or -16, 0)
    function tab:SetSelected(on)
        ns.SetEJTexture(self.bg, on and "TabSelected" or "TabUnselected")
        local name = on and iconSelected or icon
        if REGION[name] then ns.SetEJTexture(self.icon, name) else self.icon:SetTexture(name) end
        self.icon:SetDesaturated(not on and not REGION[name])
    end
    tab:SetScript("OnClick", onClick)
    ns.AddTooltip(tab, tooltip)
    tab:SetSelected(false)
    return tab
end

-- ScrollFrame con la barra fina del Diario (MinimalScrollBar) pegada a su
-- borde derecho; quien lo crea lo ancla dejando ~18 px a la derecha.
function ns.CreateScrollFrame(parent)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        local scroll = CreateFrame("ScrollFrame", nil, parent)
        local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
        bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
        bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, bar)
        return scroll
    end
    return CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
end
