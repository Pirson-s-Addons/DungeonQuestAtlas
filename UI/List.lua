local _, ns = ...

-- ==========================================
-- LISTA CON SCROLL
-- ==========================================
-- ScrollBox + DataProvider (API moderna) si existen; si no, FauxScrollFrame.
-- En los dos casos las filas se reutilizan: nunca se crean al refrescar.
-- setup(row): crea las regiones de una fila nueva (una vez por fila).
-- update(row, item): la rellena con un elemento.
-- Devuelve { SetItems = function(self, items) }

local function ModernList(parent, rowHeight, setup, update)
    local box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    box:SetPoint("TOPLEFT")
    box:SetPoint("BOTTOMRIGHT", -18, 0)
    local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(rowHeight)
    view:SetElementInitializer("Button", function(row, item)
        if not row.dqaReady then
            setup(row)
            row.dqaReady = true
        end
        update(row, item)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)

    return {
        SetItems = function(_, items)
            box:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants.RetainScrollPosition)
        end,
    }
end

local function FauxList(parent, rowHeight, setup, update)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    local rows, items = {}, {}

    local function Refresh()
        local visible = math.max(1, math.floor(scroll:GetHeight() / rowHeight))
        for i = #rows + 1, visible do
            local row = CreateFrame("Button", nil, parent)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * rowHeight)
            row:SetPoint("RIGHT", scroll, "RIGHT")
            setup(row)
            rows[i] = row
        end
        FauxScrollFrame_Update(scroll, #items, visible, rowHeight)
        local offset = FauxScrollFrame_GetOffset(scroll)
        for i, row in ipairs(rows) do
            local item = i <= visible and items[i + offset]
            row:SetShown(item ~= nil)
            if item then update(row, item) end
        end
    end
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, Refresh)
    end)
    scroll:SetScript("OnSizeChanged", Refresh)

    return {
        SetItems = function(_, newItems)
            items = newItems
            Refresh()
        end,
    }
end

function ns.CreateScrollList(parent, rowHeight, setup, update)
    if CreateScrollBoxListLinearView and ScrollUtil and CreateDataProvider then
        return ModernList(parent, rowHeight, setup, update)
    end
    return FauxList(parent, rowHeight, setup, update)
end

-- Tooltip de una linea (o varias) para cualquier control
function ns.AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(type(text) == "function" and text() or text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
