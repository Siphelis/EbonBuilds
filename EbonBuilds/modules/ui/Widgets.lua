local _, ns = ...

local Widgets = {}
ns.Widgets = Widgets

local CLASS_TEXTURE = ns.Const.CLASS_TEXTURE
local UNKNOWN_ICON  = "Interface\\Icons\\INV_Misc_QuestionMark"

function Widgets.CreateIconButton(parent, size)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(size)
    btn:SetHeight(size)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn._icon = icon
    return btn
end

function Widgets.SetClassIcon(tex, classToken)
    local coords = classToken and CLASS_ICON_TCOORDS[classToken]
    if coords then
        tex:SetTexture(CLASS_TEXTURE)
        tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        tex:SetTexture(UNKNOWN_ICON)
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

local INPUT_BACKDROP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

function Widgets.InputBackdrop(frame)
    frame:SetBackdrop(INPUT_BACKDROP)
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

function Widgets.WireScroll(frame, child, bar, step, onScroll)
    bar:SetScript("OnValueChanged", function(_, value)
        child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, value)
        if onScroll then onScroll(value) end
    end)
    local function Wheel(_, delta)
        local v = bar:GetValue()
        local mn, mx = bar:GetMinMaxValues()
        bar:SetValue(math.max(mn, math.min(mx, v - delta * step)))
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", Wheel)
    return Wheel
end

function Widgets.Attach(frame, container)
    frame:SetParent(container)
    frame:ClearAllPoints()
    frame:SetAllPoints(container)
end

function Widgets.ScrollRange(scrollFrame, scrollBar, contentHeight)
    if not scrollFrame or not scrollBar then return end
    local range = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, range)
    if scrollBar:GetValue() > range then scrollBar:SetValue(range) end
end

function Widgets.FormatScore(v)
    v = v or 0
    if v > -10 and v < 10 then return string.format("%.2f", v) end
    return string.format("%.0f", v)
end
