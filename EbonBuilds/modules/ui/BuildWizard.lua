EbonBuilds.BuildWizard = {}

local L = EbonBuilds.L

local QUALITY_COLOR = EbonBuilds.Const.QUALITY_HEX
local QUALITY_BORDER_COLORS = EbonBuilds.Const.QUALITY_RGB
local QUALITY_LABELS = EbonBuilds.Const.QUALITY_NAME
local FAMILIES = {}
for i, key in ipairs({ "Tank", "Survivability", "Healer", "Caster", "Melee", "Ranged" }) do
    FAMILIES[i] = { key = key, label = L.FAMILY_LONG[key] }
end
local WEIGHT_OPTIONS = {
    { label = L.WEIGHT_WANT, value = 50 },
    { label = L.WEIGHT_GOOD,   value = 40 },
    { label = L.WEIGHT_OK,     value = 30 },
    { label = L.WEIGHT_MEH,   value = 20 },
}

local viewFrame, contentArea
local stepLabel, backBtn, nextBtn
local RenderCurrentStep

local state = {}

local function BuildFilteredEchoList()
    local best = EbonBuilds.Catalog.BestByName()
    local lockedSet = {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        if state.locked[i] then
            local n = GetSpellInfo(state.locked[i])
            if n then lockedSet[n] = true end
        end
    end
    local list = {}
    for name, entry in pairs(best) do
        if not state.echoes[name] and not lockedSet[name] then
            list[#list + 1] = {
                spellId = entry.spellId,
                name    = name,
                quality = entry.quality,
            }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local CreateIconButton = EbonBuilds.Widgets.CreateIconButton

local function HighlightButton(btn, on)
    if not btn._hl then
        local b = btn:CreateTexture(nil, "OVERLAY")
        b:SetAllPoints(btn)
        b:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        b:SetBlendMode("ADD")
        b:Hide()
        btn._hl = b
    end
    if on then btn._hl:Show() else btn._hl:Hide() end
end

local function ClearContent()
    if not contentArea then return end
    for _, child in ipairs({ contentArea:GetChildren() }) do
        child:Hide()
    end
    for _, region in ipairs({ contentArea:GetRegions() }) do
        region:Hide()
    end
end

local widgetCache = {}

local function CachedFontString(key, template, parent)
    local w = widgetCache[key]
    if not w then
        w = (parent or contentArea):CreateFontString(nil, "OVERLAY", template)
        widgetCache[key] = w
    end
    w:ClearAllPoints()
    w:Show()
    return w
end

local function CachedFrame(key, frameType, template, parent)
    local w = widgetCache[key]
    if not w then
        w = CreateFrame(frameType, nil, parent or contentArea, template)
        widgetCache[key] = w
    end
    w:ClearAllPoints()
    w:Show()
    return w
end

local function CachedIconButton(key, size, parent)
    local w = widgetCache[key]
    if not w then
        w = CreateIconButton(parent or contentArea, size)
        widgetCache[key] = w
    end
    w:ClearAllPoints()
    w:SetWidth(size)
    w:SetHeight(size)
    w:Show()
    return w
end

local function HasAdaptivePower()
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local id = state.locked[i]
        if id then
            local name = GetSpellInfo(id)
            if name and name:lower():find("adaptive power") then
                return true
            end
        end
    end
    return false
end

local function TotalSteps()
    return HasAdaptivePower() and 6 or 5
end

local function UpdateNavButtons()
    local total = TotalSteps()
    local realStep = state.step
    if not HasAdaptivePower() and state.step >= 2 then
        realStep = state.step - 1
    end
    stepLabel:SetText(string.format(L.WIZARD_STEP, realStep, total))
    if state.step <= 0 then
        backBtn:Disable()
    else
        backBtn:Enable()
    end
    if state.step >= 6 then
        nextBtn:SetText(L.CREATE_BUILD)
    else
        nextBtn:SetText(L.NEXT)
    end
end

local lockedButtons = {}

local function RenderStep1()
    ClearContent()

    local slots = EbonBuilds.Build.LOCKED_SLOTS

    local title = CachedFontString("s1.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -20)
    title:SetText(string.format(L.WIZARD_S1_TITLE, slots))

    local slotSize = 48
    local spacing  = 10
    local totalW   = slots * slotSize + (slots - 1) * spacing
    local startX   = -math.floor(totalW / 2)

    for i = 1, slots do
        local btn = CachedIconButton("s1.slot" .. i, slotSize)
        btn:SetPoint("TOP", contentArea, "TOP", startX + (i - 1) * (slotSize + spacing), -90)
        btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
        btn.spellId = nil
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        EbonBuilds.EchoTableRows.WireIconTooltip(btn)

        local border = btn._border
        if not border then
            border = btn:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -3,  3)
            border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  3, -3)
            btn._border = border
        end
        border:Hide()

        if state.locked[i] then
            btn.spellId = state.locked[i]
            btn._icon:SetTexture(select(3, GetSpellInfo(state.locked[i])))
            local data = EbonBuilds.Catalog.Entry(state.locked[i])
            local quality = data and data.quality or 0
            local bc = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]
            border:SetTexture(bc[1], bc[2], bc[3])
            border:Show()
        end

        local idx = i
        btn:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                state.locked[idx] = nil
                btn.spellId = nil
                btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
                btn._border:Hide()
                return
            end
            EbonBuilds.EchoPicker.Show(function(spellId, quality, _)
                state.locked[idx] = spellId
                btn.spellId = spellId
                btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
                local bc = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]
                btn._border:SetTexture(bc[1], bc[2], bc[3])
                btn._border:Show()
            end, BuildFilteredEchoList())
        end)
        lockedButtons[i] = btn
    end
end

local noveltySlider, noveltyValueLabel

local function RenderStep2()
    ClearContent()

    local title = CachedFontString("s2.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -30)
    title:SetText(L.WIZARD_S2_TITLE)

    local desc = CachedFontString("s2.desc", "GameFontDisableSmall")
    desc:SetPoint("TOP", contentArea, "TOP", 0, -52)
    desc:SetText(L.WIZARD_S2_DESC)

    local slider = noveltySlider
    if not slider then
        slider = CreateFrame("Slider", "EbonBuildsWizardNoveltySlider", contentArea, "OptionsSliderTemplate")
        slider:SetWidth(300)
        slider:SetHeight(24)
        slider:SetMinMaxValues(0, 100)
        slider:SetValueStep(1)
        local sliderName = slider:GetName()
        if sliderName then
            _G[sliderName .. "Low"]:SetText("0")
            _G[sliderName .. "High"]:SetText("100")
        end
        noveltySlider = slider
    end
    slider:ClearAllPoints()
    slider:SetPoint("TOP", contentArea, "TOP", 0, -110)
    slider:SetValue(state.noveltyValue or 30)
    slider:Show()

    local valLabel = CachedFontString("s2.value", "GameFontHighlightLarge")
    valLabel:SetPoint("TOP", slider, "BOTTOM", 0, -10)
    valLabel:SetText(tostring(state.noveltyValue or 30))
    noveltyValueLabel = valLabel

    local hint = CachedFontString("s2.hint", "GameFontDisableSmall")
    hint:SetPoint("TOP", valLabel, "BOTTOM", 0, -8)
    hint:SetText(L.WIZARD_S2_HINT)

    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v)
        state.noveltyValue = v
        noveltyValueLabel:SetText(tostring(v))
    end)
end

local familyCycleLabels = { [0] = L.WIZARD_FAMILY_NONE, [10] = L.WIZARD_FAMILY_SECONDARY, [20] = L.WIZARD_FAMILY_PRIMARY }
local familyCycleValues = { 0, 10, 20 }

local function FamilyNextValue(current)
    for i, v in ipairs(familyCycleValues) do
        if v == current then
            local nextIdx = i + 1
            if nextIdx > #familyCycleValues then nextIdx = 1 end
            return familyCycleValues[nextIdx]
        end
    end
    return 0
end

local function FamilyPrevValue(current)
    for i, v in ipairs(familyCycleValues) do
        if v == current then
            local prevIdx = i - 1
            if prevIdx < 1 then prevIdx = #familyCycleValues end
            return familyCycleValues[prevIdx]
        end
    end
    return 0
end

local function RenderFamilyRow(rowIndex, familyEntry, anchorY)
    local key = "s3.row" .. rowIndex
    local rowW = 360
    local row = CachedFrame(key, "Frame")
    row:SetPoint("TOP", contentArea, "TOP", 0, anchorY)
    row:SetWidth(rowW)
    row:SetHeight(26)

    local label = CachedFontString(key .. ".label", "GameFontNormal", row)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    label:SetWidth(130)
    label:SetJustifyH("RIGHT")
    label:SetText(familyEntry.label)

    local famKey = familyEntry.key
    local currentVal = state.familyPriorities[famKey] or 0

    local btn = CachedFrame(key .. ".btn", "Button", "UIPanelButtonTemplate", row)
    btn:SetWidth(100)
    btn:SetHeight(22)
    btn:SetPoint("LEFT", label, "RIGHT", 32, 0)
    btn:SetText(familyCycleLabels[currentVal])

    local function RefreshBtn()
        btn:SetText(familyCycleLabels[state.familyPriorities[famKey] or 0])
    end

    local leftArrow = CachedFrame(key .. ".left", "Button", nil, row)
    leftArrow:SetWidth(18)
    leftArrow:SetHeight(18)
    leftArrow:SetPoint("RIGHT", btn, "LEFT", -8, 0)
    leftArrow:SetNormalFontObject("GameFontNormal")
    leftArrow:SetText("<")
    leftArrow:SetScript("OnClick", function()
        state.familyPriorities[famKey] = FamilyPrevValue(state.familyPriorities[famKey] or 0)
        RefreshBtn()
    end)

    local rightArrow = CachedFrame(key .. ".right", "Button", nil, row)
    rightArrow:SetWidth(18)
    rightArrow:SetHeight(18)
    rightArrow:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    rightArrow:SetNormalFontObject("GameFontNormal")
    rightArrow:SetText(">")
    rightArrow:SetScript("OnClick", function()
        state.familyPriorities[famKey] = FamilyNextValue(state.familyPriorities[famKey] or 0)
        RefreshBtn()
    end)

    btn:SetScript("OnClick", function()
        state.familyPriorities[famKey] = FamilyNextValue(state.familyPriorities[famKey] or 0)
        RefreshBtn()
    end)

    return row
end

local function RenderStep3()
    ClearContent()

    local title = CachedFontString("s3.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -20)
    title:SetText(L.WIZARD_S3_TITLE)

    local desc = CachedFontString("s3.desc", "GameFontDisableSmall")
    desc:SetPoint("TOP", contentArea, "TOP", 0, -42)
    desc:SetText(L.WIZARD_DEFAULTS_HINT)

    for i, entry in ipairs(FAMILIES) do
        RenderFamilyRow(i, entry, -72 - (i - 1) * 30)
    end
end

local qualityValues = { 0, 5, 10, 15, 20, 25, 30, 35, 40 }

local function NextQualityValue(current)
    for i, v in ipairs(qualityValues) do
        if v == current then
            local nextIdx = i + 1
            if nextIdx > #qualityValues then nextIdx = 1 end
            return qualityValues[nextIdx]
        end
    end
    return 0
end

local function PrevQualityValue(current)
    for i, v in ipairs(qualityValues) do
        if v == current then
            local prevIdx = i - 1
            if prevIdx < 1 then prevIdx = #qualityValues end
            return qualityValues[prevIdx]
        end
    end
    return 0
end

local function RenderQualityRow(q, anchorY)
    local key = "s4.row" .. q
    local row = CachedFrame(key, "Frame")
    row:SetPoint("TOP", contentArea, "TOP", 0, anchorY)
    row:SetWidth(360)
    row:SetHeight(28)

    local colorHex = QUALITY_COLOR[q] or "ffffff"
    local label = CachedFontString(key .. ".label", "GameFontNormal", row)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetWidth(130)
    label:SetJustifyH("RIGHT")
    label:SetText("|cff" .. colorHex .. QUALITY_LABELS[q] .. "|r")

    local currentVal = state.qualityBonus[q]
    if currentVal == nil then currentVal = q * 10 end
    state.qualityBonus[q] = currentVal

    local btn = CachedFrame(key .. ".btn", "Button", "UIPanelButtonTemplate", row)
    btn:SetWidth(100)
    btn:SetHeight(22)
    btn:SetPoint("LEFT", label, "RIGHT", 32, 0)
    btn:SetText("+" .. tostring(currentVal))

    local function RefreshBtn()
        btn:SetText("+" .. tostring(state.qualityBonus[q]))
    end

    local leftArrow = CachedFrame(key .. ".left", "Button", nil, row)
    leftArrow:SetWidth(18)
    leftArrow:SetHeight(18)
    leftArrow:SetPoint("RIGHT", btn, "LEFT", -8, 0)
    leftArrow:SetNormalFontObject("GameFontNormal")
    leftArrow:SetText("<")
    leftArrow:SetScript("OnClick", function()
        state.qualityBonus[q] = PrevQualityValue(state.qualityBonus[q])
        RefreshBtn()
    end)

    local rightArrow = CachedFrame(key .. ".right", "Button", nil, row)
    rightArrow:SetWidth(18)
    rightArrow:SetHeight(18)
    rightArrow:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    rightArrow:SetNormalFontObject("GameFontNormal")
    rightArrow:SetText(">")
    rightArrow:SetScript("OnClick", function()
        state.qualityBonus[q] = NextQualityValue(state.qualityBonus[q])
        RefreshBtn()
    end)

    btn:SetScript("OnClick", function()
        state.qualityBonus[q] = NextQualityValue(state.qualityBonus[q])
        RefreshBtn()
    end)
end

local function RenderStep4()
    ClearContent()

    local title = CachedFontString("s4.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -20)
    title:SetText(L.WIZARD_S4_TITLE)

    local desc = CachedFontString("s4.desc", "GameFontDisableSmall")
    desc:SetPoint("TOP", contentArea, "TOP", 0, -42)
    desc:SetText(L.WIZARD_DEFAULTS_HINT)

    for i, q in ipairs({ 0, 1, 2, 3, 4 }) do
        RenderQualityRow(q, -72 - (i - 1) * 32)
    end
end

local echoRows = {}
local echoScrollFrame, echoScrollBar, echoScrollChild

local function RenderEchoRow(parent, entry, index, y)
    local key = "s5.row" .. index
    local row = CachedFrame(key, "Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    row:SetPoint("RIGHT",   parent, "RIGHT",   -6, 0)
    row:SetHeight(28)

    local icon = row._icon
    if not icon then
        icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(22)
        icon:SetHeight(22)
        icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = icon
    end
    icon:SetTexture(select(3, GetSpellInfo(entry.spellId)))
    icon:Show()

    local color = QUALITY_COLOR[entry.quality] or "ffffff"
    local nameLabel = CachedFontString(key .. ".name", "GameFontNormalSmall", row)
    nameLabel:SetPoint("LEFT",  icon, "RIGHT", 4, 0)
    nameLabel:SetWidth(140)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetText("|cff" .. color .. entry.name .. "|r")

    local btns = {}
    local currentVal = state.echoes[entry.name] and state.echoes[entry.name].weight or 40
    local btnStartX = 170

    for j, opt in ipairs(WEIGHT_OPTIONS) do
        local btn = CachedFrame(key .. ".w" .. j, "Button", "UIPanelButtonTemplate", row)
        btn:SetWidth(55)
        btn:SetHeight(18)
        btn:SetPoint("LEFT", row, "LEFT", btnStartX + (j - 1) * 60, -2)
        btn:SetText(opt.label)
        btn._val = opt.value

        HighlightButton(btn, opt.value == currentVal)

        btn:SetScript("OnClick", function(self)
            state.echoes[entry.name].weight = self._val
            for _, b in ipairs(btns) do
                HighlightButton(b, b._val == self._val)
            end
        end)
        btns[j] = btn
    end

    local removeBtn = CachedFrame(key .. ".remove", "Button", "UIPanelButtonTemplate", row)
    removeBtn:SetWidth(56)
    removeBtn:SetHeight(18)
    removeBtn:SetPoint("LEFT", row, "LEFT", btnStartX + 4 * 60 + 6, -2)
    removeBtn:SetText(L.REMOVE)
    removeBtn:SetScript("OnClick", function()
        state.echoes[entry.name] = nil
        RenderCurrentStep()
    end)

    table.insert(echoRows, row)
    return row
end

local function RenderStep5()
    ClearContent()
    for _, row in ipairs(echoRows) do row:Hide() end
    echoRows = {}

    local title = CachedFontString("s5.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -20)
    title:SetText(L.WIZARD_S5_TITLE)

    local subtitle = CachedFontString("s5.subtitle", "GameFontDisableSmall")
    subtitle:SetPoint("TOP", contentArea, "TOP", 0, -42)
    subtitle:SetText(L.WIZARD_S5_DESC)

    local addBtn = CachedFrame("s5.add", "Button", "UIPanelButtonTemplate")
    addBtn:SetWidth(120)
    addBtn:SetHeight(20)
    addBtn:SetPoint("TOP", contentArea, "TOP", 0, -64)
    addBtn:SetText(L.ADD_ECHO_BUTTON)
    addBtn:SetScript("OnClick", function()
        EbonBuilds.EchoPicker.Show(function(spellId, quality, name)
            state.echoes[name] = { spellId = spellId, quality = quality, name = name, weight = 40 }
            RenderStep5()
        end, BuildFilteredEchoList())
    end)

    local sf, sb, child = echoScrollFrame, echoScrollBar, echoScrollChild
    if not sf then
        sf = CreateFrame("ScrollFrame", "EbonBuildsWizardEchoScroll", contentArea)
        sf:SetPoint("TOPLEFT",     contentArea, "TOPLEFT",     10, -90)
        sf:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -20,   0)

        sf:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        sf:SetBackdropColor(0, 0, 0, 0.4)
        sf:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        sb = CreateFrame("Slider", "EbonBuildsWizardEchoScrollBar", sf, "UIPanelScrollBarTemplate")
        sb:SetPoint("TOPRIGHT",    sf, "TOPRIGHT",    -4, -20)
        sb:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -4,  20)
        sb:SetOrientation("VERTICAL")
        sb:SetValueStep(30)
        sb:SetScript("OnValueChanged", function(self, value)
            sf:SetVerticalScroll(value)
        end)

        child = CreateFrame("Frame", nil, sf)
        sf:SetScrollChild(child)

        echoScrollFrame, echoScrollBar, echoScrollChild = sf, sb, child
    end
    sf:Show()
    sb:SetMinMaxValues(0, 0)
    sb:SetValue(0)
    sf:SetVerticalScroll(0)

    local sorted = {}
    for _, entry in pairs(state.echoes) do
        sorted[#sorted + 1] = entry
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    if #sorted == 0 then
        local hint = CachedFontString("s5.empty", "GameFontDisableSmall")
        hint:SetPoint("TOP", contentArea, "TOP", 0, -96)
        hint:SetText(L.WIZARD_S5_EMPTY)
    end

    child:SetWidth(contentArea:GetWidth() - 54)
    child:SetHeight(1)

    for i, entry in ipairs(sorted) do
        RenderEchoRow(child, entry, i, -(i - 1) * 30)
    end
    child:SetHeight(math.max(1, #sorted * 30))

    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local childH = child:GetHeight()
        local sfH = self:GetHeight()
        local range = math.max(0, childH - sfH)
        if range <= 0 then return end
        local newPos = self:GetVerticalScroll() - delta * 30
        if newPos < 0 then newPos = 0
        elseif newPos > range then newPos = range end
        self:SetVerticalScroll(newPos)
        sb:SetValue(newPos)
    end)

    local function UpdateRange()
        local childH = child:GetHeight()
        local sfH = sf:GetHeight()
        local range = math.max(0, childH - sfH)
        sb:SetMinMaxValues(0, range)
        if range > 0 then
            sb:Show()
        else
            sb:Hide()
        end
    end
    sf:SetScript("OnSizeChanged", UpdateRange)
    UpdateRange()
end

local function RenderStep6()
    ClearContent()

    local title = CachedFontString("s6.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, -20)
    title:SetText(L.WIZARD_S6_TITLE)

    local desc = CachedFontString("s6.desc", "GameFontDisableSmall")
    desc:SetPoint("TOP", contentArea, "TOP", 0, -44)
    desc:SetText(L.WIZARD_S6_DESC)

    local titleLabel = CachedFontString("s6.titleLabel", "GameFontNormal")
    titleLabel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 40, -80)
    titleLabel:SetText(L.TITLE_LABEL)

    local titleBox = CachedFrame("s6.titleBox", "EditBox")
    titleBox:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 40, -100)
    titleBox:SetPoint("RIGHT", contentArea, "RIGHT", -40, 0)
    titleBox:SetHeight(22)
    titleBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    titleBox:SetTextColor(1, 1, 1, 1)
    titleBox:SetAutoFocus(false)
    titleBox:SetMaxLetters(40)
    titleBox:SetText(state.wizardTitle or "")
    titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    titleBox:SetScript("OnTextChanged", function(self)
        state.wizardTitle = self:GetText()
    end)

    local titleBg = CachedFrame("s6.titleBg", "Frame")
    titleBg:SetPoint("TOPLEFT",     titleBox, "TOPLEFT",     -2,  2)
    titleBg:SetPoint("BOTTOMRIGHT", titleBox, "BOTTOMRIGHT",  2, -2)
    EbonBuilds.Widgets.InputBackdrop(titleBg)
    titleBg:SetFrameLevel(titleBox:GetFrameLevel() - 1)

    local descLabel = CachedFontString("s6.descLabel", "GameFontNormal")
    descLabel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 40, -140)
    descLabel:SetText(L.DESCRIPTION_LABEL)

    local descBox = CachedFrame("s6.descBox", "EditBox")
    descBox:SetMultiLine(true)
    descBox:SetMaxLetters(0)
    descBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    descBox:SetPoint("TOPLEFT",     contentArea, "TOPLEFT",     40, -160)
    descBox:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -40,  16)
    descBox:SetAutoFocus(false)
    descBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    descBox:SetText(state.wizardDescription or "")

    local descBg = CachedFrame("s6.descBg", "Frame")
    descBg:SetPoint("TOPLEFT",     descBox, "TOPLEFT",     -2,  2)
    descBg:SetPoint("BOTTOMRIGHT", descBox, "BOTTOMRIGHT",  2, -2)
    EbonBuilds.Widgets.InputBackdrop(descBg)
    descBg:SetFrameLevel(descBox:GetFrameLevel() - 1)

    local placeHolder = CachedFontString("s6.placeholder", "GameFontDisable", descBox)
    placeHolder:SetPoint("TOPLEFT",     descBox, "TOPLEFT",     2, -2)
    placeHolder:SetPoint("BOTTOMRIGHT", descBox, "BOTTOMRIGHT", -2,  2)
    placeHolder:SetJustifyH("LEFT")
    placeHolder:SetJustifyV("TOP")
    placeHolder:SetTextColor(0.5, 0.5, 0.5, 1)
    placeHolder:SetText(L.WIZARD_S6_HINT)

    descBox:SetScript("OnEditFocusGained", function() placeHolder:Hide() end)
    descBox:SetScript("OnEditFocusLost", function(self)
        if (self:GetText() or "") == "" then placeHolder:Show() end
    end)
    descBox:SetScript("OnTextChanged", function(self)
        if self:HasFocus() then
            placeHolder:Hide()
        else
            if (self:GetText() or "") == "" then placeHolder:Show() else placeHolder:Hide() end
        end
        state.wizardDescription = self:GetText()
    end)

    if (descBox:GetText() or "") == "" then placeHolder:Show() else placeHolder:Hide() end
end

local function CreateBuildFromWizard()
    EbonBuilds.Draft.weights = EbonBuilds.Draft.weights or {}

    for name, entry in pairs(state.echoes) do
        EbonBuilds.Draft.weights[name] = entry.weight
    end

    local settings = EbonBuilds.Build.DefaultSettings()

    for q = 0, 4 do
        settings.qualityBonus[q] = state.qualityBonus[q] or (q * 10)
    end

    for _, entry in ipairs(FAMILIES) do
        local val = state.familyPriorities[entry.key] or 0
        if val > 0 then
            settings.familyBonus[entry.key] = val
        end
    end

    if HasAdaptivePower() then
        settings.noveltyValue = state.noveltyValue or 30
    else
        settings.noveltyValue = 0
    end

    local locked = EbonBuilds.Build.CopyLocked(state.locked)

    local playerClass = EbonBuilds.Build.PlayerClassToken()

    EbonBuilds.Draft.wizardPrefill = {
        title        = state.wizardTitle ~= "" and state.wizardTitle or L.NEW_BUILD_TITLE,
        class        = playerClass,
        spec         = EbonBuilds.Build.PlayerTopTalentTab(),
        comments     = state.wizardDescription or "",
        lockedEchoes = locked,
        settings     = settings,
        isPublic     = false,
    }
    EbonBuilds.Draft.isEditing = true

    EbonBuilds.ViewRouter.Show("buildTabs", { mode = "create", fromWizard = true })
end

local function RenderStep0()
    ClearContent()
    local y = -20

    local title = CachedFontString("s0.title", "GameFontHighlight")
    title:SetPoint("TOP", contentArea, "TOP", 0, y)
    title:SetText(L.WIZARD_S0_TITLE)

    y = y - 20
    local subtitle = CachedFontString("s0.subtitle", "GameFontDisableSmall")
    subtitle:SetPoint("TOP", contentArea, "TOP", 0, y)
    subtitle:SetText(L.WIZARD_S0_DESC)

    local wizardBtn = CachedFrame("s0.wizardBtn", "Button", "UIPanelButtonTemplate")
    wizardBtn:SetWidth(200)
    wizardBtn:SetHeight(40)
    wizardBtn:SetPoint("TOP", contentArea, "TOP", 0, y - 30)
    wizardBtn:SetText(L.WIZARD_MODE)
    wizardBtn:SetScript("OnClick", function()
        state.step = 1
        RenderCurrentStep()
    end)

    local wizardDesc = CachedFontString("s0.wizardDesc", "GameFontDisableSmall")
    wizardDesc:SetPoint("TOP", wizardBtn, "BOTTOM", 0, -2)
    wizardDesc:SetText(L.WIZARD_MODE_DESC)

    local proBtn = CachedFrame("s0.proBtn", "Button", "UIPanelButtonTemplate")
    proBtn:SetWidth(200)
    proBtn:SetHeight(40)
    proBtn:SetPoint("TOP", wizardDesc, "BOTTOM", 0, -18)
    proBtn:SetText(L.PRO_MODE)
    proBtn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("buildTabs", { mode = "create" })
    end)

    local proDesc = CachedFontString("s0.proDesc", "GameFontDisableSmall")
    proDesc:SetPoint("TOP", proBtn, "BOTTOM", 0, -2)
    proDesc:SetText(L.PRO_MODE_DESC)
end

local function GoNext()
    if state.step >= 6 then
        CreateBuildFromWizard()
        return
    end

    if state.step == 1 and not HasAdaptivePower() then
        state.step = 3
    else
        state.step = state.step + 1
    end

    RenderCurrentStep()
end

local function GoBack()
    if state.step <= 1 then
        state.step = 0
        RenderCurrentStep()
        return
    end

    if state.step == 3 and not HasAdaptivePower() then
        state.step = 1
    else
        state.step = state.step - 1
    end

    RenderCurrentStep()
end

RenderCurrentStep = function()
    ClearContent()
    if state.step == 0 then
        stepLabel:SetText("")
        backBtn:Hide()
        nextBtn:Hide()
        RenderStep0()
        return
    end
    backBtn:Show()
    nextBtn:Show()
    UpdateNavButtons()
    if state.step == 1 then
        RenderStep1()
    elseif state.step == 2 then
        RenderStep2()
    elseif state.step == 3 then
        RenderStep3()
    elseif state.step == 4 then
        RenderStep4()
    elseif state.step == 5 then
        RenderStep5()
    elseif state.step == 6 then
        RenderStep6()
    end
end

local view = {}

function view.Show(container, context)
    EbonBuilds.Widgets.Attach(viewFrame, container)

    state.step = 0
    state.locked = { nil, nil, nil, nil, nil }
    state.noveltyValue = 30
    state.qualityBonus = { [0] = 0, [1] = 10, [2] = 20, [3] = 30, [4] = 40 }
    state.familyPriorities = {}
    state.echoes = {}
    state.wizardTitle = ""
    state.wizardDescription = ""

    RenderCurrentStep()
    viewFrame:Show()
end

function view.Hide()
    if viewFrame then viewFrame:Hide() end
end

local function BuildViewFrame()
    local f = CreateFrame("Frame", nil, UIParent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.WIZARD_HEADER)

    stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepLabel:SetPoint("TOP", f, "TOP", 0, -10)

    contentArea = CreateFrame("Frame", nil, f)
    contentArea:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -40)
    contentArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,  50)

    backBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    backBtn:SetWidth(80)
    backBtn:SetHeight(22)
    backBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 20)
    backBtn:SetText(L.BACK)
    backBtn:SetScript("OnClick", GoBack)

    nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    nextBtn:SetWidth(80)
    nextBtn:SetHeight(22)
    nextBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 100, 20)
    nextBtn:SetText(L.NEXT)
    nextBtn:SetScript("OnClick", GoNext)

    f:Hide()
    return f
end

function EbonBuilds.BuildWizard.Init()
    viewFrame = BuildViewFrame()
    EbonBuilds.ViewRouter.Register("buildWizard", view)
end
