local _, ns = ...

-- ==========================================
-- TEMA: la Guia de aventuras de Retail
-- ==========================================
-- Como el Diario de mazmorras del juego: la hoja de texturas del Diario
-- (Interface\EncounterJournal, con las coordenadas de Blizzard_EncounterJournal,
-- rama forever de wow-ui-source), sus fuentes y sus plantillas. Las piezas que
-- tienen arte propio en Art/UI (encargo en _project/docs/DungeonQuestAtlas/
-- arte-retail.md) lo usan si el fichero esta; si no, la del juego (ns.SetSkin).

local unpack = unpack or table.unpack
local SHEET = "Interface\\EncounterJournal\\UI-EncounterJournalTextures"
-- nombre = { izquierda, derecha, arriba, abajo }
local REGION = {
    BossButtonUp = { 0.00195313, 0.63671875, 0.21386719, 0.26757813 },
    BossButtonDown = { 0.00195313, 0.63671875, 0.10253906, 0.15625000 },
    BossButtonHighlight = { 0.00195313, 0.63671875, 0.15820313, 0.21191406 },
    LootFrame = { 0.00195313, 0.62890625, 0.61816406, 0.66210938 },
    DungeonNameBg = { 0.34570313, 0.84570313, 0.42871094, 0.49121094 },
    InstanceButton = { 0.00195313, 0.34179688, 0.42871094, 0.52246094 },
    InstanceButtonPushed = { 0.00195313, 0.34179688, 0.33300781, 0.42675781 },
    DungeonButtonHighlight = { 0.34570313, 0.68554688, 0.33300781, 0.42675781 },
    BossModelButton = { 0.50585938, 0.63085938, 0.02246094, 0.08203125 },
    BossNameShadow = { 0.00195313, 0.77343750, 0.26953125, 0.33105469 },
    LeftPageHeader = { 0, 0.755859375, 0.9599609375, 1 },
}

function ns.SetEJTexture(texture, name)
    texture:SetTexture(SHEET)
    texture:SetTexCoord(unpack(REGION[name]))
end

-- Arte propio (Art/UI). Mientras no este, las piezas del juego.
ns.ART = "Interface\\AddOns\\DungeonQuestAtlas\\Art\\UI\\"
local SKIN = {
    -- Fondo de la portada (la cuadricula de mazmorras)
    home = { atlas = "UI-EJ-Classic", color = { 0.05, 0.04, 0.08 } },
    -- Libro de la pagina de una mazmorra: lista a la izquierda, detalle a la derecha
    book = { file = "Interface\\EncounterJournal\\UI-EJ-JournalBG", coords = { 0, 0.766601562, 0, 0.830078125 } },
}

-- Piezas de Art/UI que lleva el addon ("home", "card_THANES"...). Se apuntan
-- aqui al anadirlas: no consta que Forever devuelva false en SetTexture con un
-- fichero del addon que falta (con las tarjetas, no: salian en negro).
ns.ART_FILES = {}

-- Pone en la textura la pieza "name": la de Art/UI si la hay; si no, la del juego
function ns.SetSkin(texture, name)
    if ns.ART_FILES[name] then
        texture:SetTexture(ns.ART .. name)
        texture:SetTexCoord(0, 1, 0, 1)
        return
    end
    local s = SKIN[name]
    if s.atlas and texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(s.atlas) then
        texture:SetAtlas(s.atlas)
    elseif s.file then
        texture:SetTexture(s.file)
        texture:SetTexCoord(unpack(s.coords or { 0, 1, 0, 1 }))
    else
        texture:SetColorTexture(unpack(s.color))
    end
end

-- Ancho de un marco, o fallback si aun no lo tiene (recien creado, sin anclar)
function ns.Width(frame, fallback)
    local w = frame:GetWidth()
    return type(w) == "number" and w > 0 and w or fallback
end

-- Medidas del libro (las del Diario: 785x425) y de sus paginas
ns.BOOK = { width = 785, height = 425, spine = 392 }

-- Colores del Diario: texto sobre papel, botones de jefe y titulos claros
ns.INK = { 0.16, 0.09, 0.01 }          -- tinta casi negra: el papel del Diario es claro
ns.INK_LIGHT = { 0.33, 0.21, 0.08 }    -- notas: mas suave, pero legible sobre el papel
ns.INK_HEADER = { 0.42, 0.08, 0.02 }   -- cabeceras de seccion: granate oscuro
ns.TEXT_ON_DARK = { 0.86, 0.82, 0.74 } -- texto secundario sobre fondos oscuros
-- Regla de contraste: sobre el papel solo tinta oscura (INK, INK_HEADER, enlaces
-- granates). Lo que lleva color de estado o de dificultad (dorado, verde,
-- amarillo...) va siempre sobre fondo oscuro: placa, franja o fila.
ns.PARCHMENT_GOLD = { 0.827, 0.659, 0.463 } -- texto de los botones de jefe
ns.TITLE_LIGHT = { 0.902, 0.788, 0.671 }    -- titulo de la mazmorra
ns.PARCHMENT_SUB = { 0.78, 0.7, 0.6 }       -- segunda linea de los botones de jefe

-- Texto sobre papel: fuente del juego con la tinta del Diario
function ns.PaperText(parent, font, color)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "QuestFont")
    fs:SetTextColor(unpack(color or ns.INK))
    fs:SetShadowOffset(0, 0)
    fs:SetJustifyH("LEFT")
    return fs
end

-- Titulos sobre papel: la fuente normal del juego (la de su idioma: tiene los
-- glifos de chino, coreano y ruso) mas grande y gruesa. La de titulos de mision
-- (QuestTitleFont) es de trazo fino y en Forever casi no se ve sobre el papel.
function ns.SetPaperTitleFont(fs, size)
    local font = GameFontNormal and GameFontNormal:GetFont()
    if font then fs:SetFont(font, size, "") end
end

-- Titulo de seccion sobre papel con una raya fina debajo
function ns.CreatePaperHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)
    frame.text = ns.PaperText(frame, "GameFontNormal", ns.INK_HEADER)
    ns.SetPaperTitleFont(frame.text, 15)
    frame.text:SetPoint("BOTTOMLEFT", 0, 5)
    frame.text:SetText(text)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(ns.INK_HEADER[1], ns.INK_HEADER[2], ns.INK_HEADER[3], 0.45)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    return frame
end

-- Boton del Diario (el de los jefes): normal / seleccionado / resaltado.
-- El original mide 325x55; nuestras filas pueden ser mas anchas. Estirado
-- entero, el hueco redondo de la izquierda se deforma, asi que va en dos
-- trozos: la tapa con el hueco a su tamano y el resto estirado.
local BUTTON_W = 325
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

-- Texto de una fila sobre el boton del Diario: dorado con sombra
function ns.RowText(fs)
    fs:SetTextColor(unpack(ns.PARCHMENT_GOLD))
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    return fs
end

-- Icono a la izquierda de un boton rojo (UIPanelButtonTemplate), con el texto
-- corrido a su derecha; gris cuando el boton esta apagado. Llamar tras SetText.
function ns.SetButtonIcon(button, icon)
    local size = button:GetHeight() - 8
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetSize(size, size)
    tex:SetPoint("LEFT", 6, 0)
    tex:SetTexture(icon)
    if icon:find("Icons") then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end -- sin el borde
    local text = button:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("CENTER", size / 2 + 2, 0)
    button:HookScript("OnEnable", function() tex:SetDesaturated(false) end)
    button:HookScript("OnDisable", function() tex:SetDesaturated(true) end)
    button.icon = tex
end

-- Pone una textura en el centro del hueco redondo del boton
function ns.PlaceInHole(texture, button, size)
    texture:SetSize(size or ns.JOURNAL_HOLE_SIZE, size or ns.JOURNAL_HOLE_SIZE)
    texture:SetPoint("CENTER", button, "LEFT", ns.JOURNAL_HOLE_X, 0)
end

-- Caja oscura con borde fino (tarjetas de recompensa, placas): la del tooltip
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
function ns.CreateDarkBox(parent, edge)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = BORDER, edgeSize = edge or 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    box:SetBackdropColor(0.04, 0.03, 0.02, 0.85)
    box:SetBackdropBorderColor(0.55, 0.45, 0.3)
    return box
end

-- Cambiar el tamano de una ventana manteniendo el clic derecho y arrastrando
-- (como MoveAny): a la derecha o arriba crece, a la izquierda o abajo mengua.
-- El centro no se mueve; va de 5 en 5 % y, mientras se arrastra, una placa
-- pequena arriba a la izquierda dice el tamano ("125%"). handles: los marcos donde se puede pulsar
-- (los que reciben el raton); onDone(escala) al soltar, para guardarla.
ns.SCALE_MIN, ns.SCALE_MAX = 0.5, 2

-- Placa del porcentaje: una para todas las ventanas, encima de todo y sin
-- escalar con la ventana (siempre del mismo tamano)
local percent
local function PercentPlaque()
    if percent then return percent end
    percent = ns.CreateDarkBox(UIParent)
    percent:SetParent(UIParent)
    percent:SetSize(84, 28)
    percent:SetFrameStrata("TOOLTIP")
    percent.text = percent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    percent.text:SetPoint("CENTER", 0, 1)
    percent:Hide()
    return percent
end

function ns.EnableRightDragScale(target, handles, onDone)
    local driver = CreateFrame("Frame")
    local x0, y0, s0, cx, cy
    local function Show(scale)
        local p = PercentPlaque()
        p.text:SetText(("%d%%"):format(math.floor(scale * 100 + 0.5)))
        p:ClearAllPoints()
        p:SetPoint("TOPLEFT", target, "TOPLEFT", 66, 2) -- junto al retrato, sobre el borde
        p:Show()
    end
    local function Stop()
        driver:SetScript("OnUpdate", nil)
        onDone(target:GetScale())
        -- La placa se queda un momento para leer el tamano final
        if C_Timer then C_Timer.After(0.8, function() if not driver:GetScript("OnUpdate") then PercentPlaque():Hide() end end) end
    end
    for _, handle in ipairs(handles) do
        handle:HookScript("OnMouseDown", function(_, button)
            if button ~= "RightButton" then return end
            x0, y0 = GetCursorPosition()
            s0 = target:GetScale()
            local es = target:GetEffectiveScale()
            cx, cy = target:GetCenter()
            cx, cy = cx * es, cy * es -- en pixeles de pantalla
            Show(s0)
            driver:SetScript("OnUpdate", function()
                if not IsMouseButtonDown("RightButton") then return Stop() end
                local x, y = GetCursorPosition()
                local s = s0 * (1 + ((x - x0) + (y - y0)) / 600)
                s = math.floor(s * 20 + 0.5) / 20 -- de 5 en 5 %
                s = math.max(ns.SCALE_MIN, math.min(ns.SCALE_MAX, s))
                target:SetScale(s)
                local e = target:GetEffectiveScale()
                target:ClearAllPoints()
                target:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / e, cy / e)
                Show(s)
            end)
        end)
    end
end

-- Titulos con la fuente de los titulos de la Guia (Morpheus) en los idiomas que
-- la tienen entera; en los demas (cirilico, asiaticos, letras como la l o la r
-- con trazo) se queda la fuente que traia.
local MORPHEUS_LANGS = { enUS = true, esES = true, deDE = true, frFR = true, itIT = true, ptBR = true,
    svSE = true, noNO = true }
function ns.SetTitleFont(fs, size)
    if MORPHEUS_LANGS[ns.UILANG or ""] then fs:SetFont("Fonts\\MORPHEUS.TTF", size, "") end
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
    AVAILABLE = { paper = "|cff6e3500", light = "|cffffd100" },
    IN_LOG = { paper = "|cff3a2a12", light = "|cffe0d0b0" },
    READY = { paper = "|cff6e3500", light = "|cffffd100" },
    COMPLETED = { paper = "|cff0d5208", light = "|cff40c040" },
    BLOCKED = { paper = "|cff801408", light = "|cffff4040" },
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
        b.border = CreateFrame("Frame", nil, b, "BackdropTemplate")
        b.border:SetPoint("TOPLEFT", -3, 3)
        b.border:SetPoint("BOTTOMRIGHT", 3, -3)
        b.border:SetBackdrop({ edgeFile = BORDER, edgeSize = 12 })
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
