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

-- Boton del Diario (el de los jefes): normal / seleccionado / resaltado.
-- El original mide 325x55; nuestras filas son mas anchas. Estirado entero, el
-- hueco redondo de la izquierda se deforma y se mueve, asi que va en dos
-- trozos: la tapa con el hueco a su tamano y el resto estirado.
local BUTTON_W, SHEET_W = 325, 512
local CAP = 72 -- ancho de la tapa con el hueco (px del boton original)
-- Centro del hueco desde el borde izquierdo y tamano de lo que va dentro
ns.JOURNAL_HOLE_X, ns.JOURNAL_HOLE_SIZE = 37, 46

local function SetButtonPiece(texture, name, cap)
    local l, r, t, b = unpack(REGION[name])
    local split = l + (r - l) * CAP / BUTTON_W
    texture:SetTexture(SHEET)
    if cap then texture:SetTexCoord(l, split, t, b) else texture:SetTexCoord(split, r, t, b) end
end

local function ButtonPieces(button, layer)
    local cap = button:CreateTexture(nil, layer)
    cap:SetPoint("TOPLEFT")
    cap:SetPoint("BOTTOMLEFT")
    cap:SetWidth(CAP)
    local body = button:CreateTexture(nil, layer)
    body:SetPoint("TOPLEFT", cap, "TOPRIGHT")
    body:SetPoint("BOTTOMRIGHT")
    return cap, body
end

function ns.SetupJournalButton(button)
    button.cap, button.body = ButtonPieces(button, "BACKGROUND")
    ns.SetJournalButtonSelected(button, false)
    local hlCap, hlBody = ButtonPieces(button, "HIGHLIGHT")
    SetButtonPiece(hlCap, "BossButtonHighlight", true)
    SetButtonPiece(hlBody, "BossButtonHighlight", false)
    hlCap:SetBlendMode("ADD")
    hlBody:SetBlendMode("ADD")
end

function ns.SetJournalButtonSelected(button, on)
    local name = on and "BossButtonDown" or "BossButtonUp"
    SetButtonPiece(button.cap, name, true)
    SetButtonPiece(button.body, name, false)
end

-- Pone una textura en el centro del hueco redondo del boton
function ns.PlaceInHole(texture, button, size)
    texture:SetSize(size or ns.JOURNAL_HOLE_SIZE, size or ns.JOURNAL_HOLE_SIZE)
    texture:SetPoint("CENTER", button, "LEFT", ns.JOURNAL_HOLE_X, 0)
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

-- ------------------------------------------
-- Iconos de estado de mision: los del propio juego
-- ------------------------------------------
-- Los mismos que pone el cliente en los PNJ, el registro y el rastreador
-- (QuestUtil.GetQuestIconOffer/Active y POIButton, rama forever):
-- ! amarilla para coger, bocadillo "..." en curso, ? amarilla para entregar,
-- la marca del rastreador si esta hecha y el candado si aun no se puede.
ns.STATUS_ICON = {
    AVAILABLE = { file = "Interface\\GossipFrame\\AvailableQuestIcon" },
    IN_LOG = { atlas = "SideInProgressquesticon" },
    READY = { file = "Interface\\GossipFrame\\ActiveQuestIcon" },
    COMPLETED = { atlas = "ui-questtracker-tracker-check" },
    BLOCKED = { atlas = "QuestSharing-QuestLog-Padlock" },
}
-- Color del estado, legible sobre papel y sobre los botones oscuros
ns.STATUS_COLOR = {
    AVAILABLE = { paper = "|cff6b4a00", light = "|cffffd100" },
    IN_LOG = { paper = "|cff5a4a33", light = "|cffe0d0b0" },
    READY = { paper = "|cff7a4d00", light = "|cffffd100" },
    COMPLETED = { paper = "|cff1a6b12", light = "|cff40c040" },
    BLOCKED = { paper = "|cff8c1a0d", light = "|cffff4040" },
}

function ns.SetStatusIcon(texture, status)
    local icon = ns.STATUS_ICON[status]
    if icon.atlas then
        texture:SetAtlas(icon.atlas)
    else
        texture:SetTexture(icon.file)
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

-- Para meterlo en un texto: "|A:atlas:14:14|a" o "|Tfichero:14|t"
function ns.StatusMarkup(status, size)
    local icon = ns.STATUS_ICON[status]
    size = size or 14
    if icon.atlas then return ("|A:%s:%d:%d|a"):format(icon.atlas, size, size) end
    return ("|T%s:%d|t"):format(icon.file, size)
end

-- Emblemas de faccion del juego: el pequeno del registro de misiones y el
-- redondo del boton de crear comunidad
ns.FACTION_ATLAS = { Alliance = "questlog-questtypeicon-alliance", Horde = "questlog-questtypeicon-horde" }
ns.FACTION_CREST = { Alliance = "communities-create-button-wow-alliance", Horde = "communities-create-button-wow-horde" }

function ns.FactionMarkup(faction, size)
    local atlas = ns.FACTION_ATLAS[faction]
    return atlas and ("|A:%s:%d:%d|a"):format(atlas, size or 16, size or 16) or ""
end

-- ------------------------------------------
-- Botones de icono que se eligen de uno en uno (como un interruptor)
-- ------------------------------------------
-- options = { { value, tooltip, crests = { atlas, ... } }, ... }. El elegido,
-- a todo color con el brillo de boton marcado; los demas, apagados.
-- Devuelve el grupo con :SetValue(v) (sin llamar a onChange).
function ns.CreateIconToggleGroup(parent, size, options, onChange)
    local group = CreateFrame("Frame", nil, parent)
    group:SetSize(#options * (size + 4) - 4, size)
    group.buttons = {}
    for i, o in ipairs(options) do
        local b = CreateFrame("Button", nil, group)
        b:SetSize(size, size)
        b:SetPoint("LEFT", (i - 1) * (size + 4), 0)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetColorTexture(0, 0, 0, 0.55)
        -- El mismo marco que las filas de mazmorra
        b.border = CreateFrame("Frame", nil, b, "BackdropTemplate")
        b.border:SetPoint("TOPLEFT", -3, 3)
        b.border:SetPoint("BOTTOMRIGHT", 3, -3)
        b.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        b.icons = {}
        local n = #o.crests
        for j, atlas in ipairs(o.crests) do
            local icon = b:CreateTexture(nil, "ARTWORK")
            local s = n > 1 and size * 0.62 or size - 4
            icon:SetSize(s, s)
            -- Dos emblemas: en diagonal, uno delante del otro
            if n > 1 then
                icon:SetPoint(j == 1 and "TOPLEFT" or "BOTTOMRIGHT", j == 1 and 2 or -2, j == 1 and -2 or 2)
            else
                icon:SetPoint("CENTER")
            end
            icon:SetAtlas(atlas)
            b.icons[j] = icon
        end
        b.glow = b:CreateTexture(nil, "OVERLAY", nil, 2)
        b.glow:SetAllPoints()
        b.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        b.glow:SetBlendMode("ADD")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        b:SetScript("OnClick", function()
            group:SetValue(o.value)
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            onChange(o.value)
        end)
        ns.AddTooltip(b, o.tooltip)
        b.value = o.value
        group.buttons[i] = b
    end
    function group:SetValue(value)
        for _, b in ipairs(self.buttons) do
            local on = b.value == value
            b.glow:SetShown(on)
            b.border:SetBackdropBorderColor(on and 1 or 0.55, on and 0.82 or 0.5, on and 0 or 0.45)
            for _, icon in ipairs(b.icons) do
                icon:SetDesaturated(not on)
                icon:SetAlpha(on and 1 or 0.6)
            end
        end
    end
    return group
end

-- ------------------------------------------
-- Pasar pagina
-- ------------------------------------------
-- El juego no dobla texturas en 3D, pero se imita bien: una hoja de
-- pergamino (la misma del libro) se pliega hacia el lomo encogiendose en
-- horizontal y, al otro lado, se despliega y se desvanece. Una sombra en
-- degradado hacia el lomo le da la curva. Lo nuevo ya esta pintado debajo,
-- asi que la hoja lo va destapando. Con el sonido de pasar pagina del juego.

local TURN_TIME = 0.16 -- cada mitad del giro

-- Pixel del libro -> coordenada de su textura
local function U(x) return ns.BOOK.coords[1] + (ns.BOOK.coords[2] - ns.BOOK.coords[1]) * x / ns.BOOK.width end
local function V(y) return ns.BOOK.coords[3] + (ns.BOOK.coords[4] - ns.BOOK.coords[3]) * y / ns.BOOK.height end

-- Hoja: textura del libro recortada a una pagina, con su sombra
local function Leaf(overlay, book, left, right, top, bottom)
    local leaf = CreateFrame("Frame", nil, overlay)
    leaf:SetPoint("TOPLEFT", book, "TOPLEFT", left, -top)
    leaf:SetPoint("BOTTOMRIGHT", book, "TOPLEFT", right, -bottom)
    local paper = leaf:CreateTexture(nil, "ARTWORK")
    paper:SetAllPoints()
    paper:SetTexture(ns.BOOK.file)
    paper:SetTexCoord(U(left), U(right), V(top), V(bottom))
    leaf.shade = leaf:CreateTexture(nil, "OVERLAY")
    leaf.shade:SetAllPoints()
    leaf.shade:SetColorTexture(1, 1, 1, 1)
    leaf:Hide()
    return leaf
end

-- La sombra se oscurece hacia el lomo (side = "LEFT" o "RIGHT" del lomo)
local function Shade(leaf, spineSide)
    if not (CreateColor and leaf.shade.SetGradient) then
        leaf.shade:SetColorTexture(0, 0, 0, 0.25)
        return
    end
    local dark, clear = CreateColor(0, 0, 0, 0.55), CreateColor(0, 0, 0, 0.05)
    if spineSide == "LEFT" then
        leaf.shade:SetGradient("HORIZONTAL", dark, clear)
    else
        leaf.shade:SetGradient("HORIZONTAL", clear, dark)
    end
end

-- Animacion de una hoja: escala horizontal anclada al lomo
local function Fold(leaf, spinePoint, from, to, smoothing, fade)
    local group = leaf:CreateAnimationGroup()
    local scale = group:CreateAnimation("Scale")
    scale:SetOrigin(spinePoint, 0, 0)
    scale:SetScaleFrom(from, 1)
    scale:SetScaleTo(to, 1)
    scale:SetDuration(TURN_TIME)
    scale:SetSmoothing(smoothing)
    if fade then
        local alpha = group:CreateAnimation("Alpha")
        alpha:SetFromAlpha(1)
        alpha:SetToAlpha(0)
        alpha:SetStartDelay(TURN_TIME * 0.4)
        alpha:SetDuration(TURN_TIME * 0.6)
    end
    group:SetScript("OnFinished", function() leaf:Hide() end)
    return group
end

-- book: el marco del libro; spine: x del lomo; page = { top, bottom, left, right }
-- con los margenes del pergamino. Devuelve turner:Turn(forward).
function ns.CreatePageTurner(book, spine, page)
    local overlay = CreateFrame("Frame", nil, book)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(book:GetFrameLevel() + 40)
    local leftLeaf = Leaf(overlay, book, page.left, spine, page.top, page.bottom)
    local rightLeaf = Leaf(overlay, book, spine, page.right, page.top, page.bottom)
    Shade(leftLeaf, "RIGHT")
    Shade(rightLeaf, "LEFT")
    -- Hacia delante: la derecha se pliega al lomo y cae desplegandose a la izquierda
    local anims = {
        [true] = { first = rightLeaf, firstAnim = Fold(rightLeaf, "LEFT", 1, 0.02, "IN"),
            second = leftLeaf, secondAnim = Fold(leftLeaf, "RIGHT", 0.02, 1, "OUT", true) },
        [false] = { first = leftLeaf, firstAnim = Fold(leftLeaf, "RIGHT", 1, 0.02, "IN"),
            second = rightLeaf, secondAnim = Fold(rightLeaf, "LEFT", 0.02, 1, "OUT", true) },
    }
    for _, a in pairs(anims) do
        a.firstAnim:SetScript("OnFinished", function()
            a.first:Hide()
            a.second:Show()
            a.secondAnim:Play()
        end)
    end

    local turner = {}
    function turner:Turn(forward)
        forward = forward ~= false
        for _, a in pairs(anims) do
            a.firstAnim:Stop()
            a.secondAnim:Stop()
            a.first:Hide()
            a.second:Hide()
        end
        local a = anims[forward]
        a.first:Show()
        a.firstAnim:Play()
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
    end
    return turner
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
