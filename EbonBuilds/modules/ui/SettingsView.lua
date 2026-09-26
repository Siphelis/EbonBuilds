EbonBuilds.SettingsView = {}

local L = EbonBuilds.L

local QUALITY_HEX = EbonBuilds.Const.QUALITY_HEX

local FAMILY_ORDER = {
    "Tank", "Survivability", "Healer", "Caster", "Melee", "Ranged", "No family",
}

local WEIGHT_THRESHOLDS = {
    { key = "autoBanishPct",    label = L.T_BANISH_PCT,
      flavor = L.T_BANISH_PCT_HINT,
      min = 0, max = 100, step = 1 },
    { key = "autoRerollPct",    label = L.T_REROLL_PCT,
      flavor = L.T_REROLL_PCT_HINT,
      min = 0, max = 300, step = 1 },
    { key = "rerollGuardPct",   label = L.T_GUARD_PCT,
      flavor = L.T_GUARD_PCT_HINT,
      min = 0, max = 100, step = 1 },
    { key = "autoFreezePct",    label = L.T_FREEZE_PCT,
      flavor = L.T_FREEZE_PCT_HINT,
      min = 0, max = 100, step = 1 },
}

local MATRIX_THRESHOLDS = {
    { key = "matrixBanishBelow", label = L.T_BANISH, absolute = true,
      flavor = L.T_BANISH_HINT,
      min = -5, max = 0, step = 0.1 },
    { key = "matrixRerollBelow", label = L.T_REROLL, absolute = true,
      flavor = L.T_REROLL_HINT,
      min = -5, max = 3, step = 0.1 },
    { key = "matrixRerollGuard", label = L.T_GUARD, absolute = true,
      flavor = L.T_GUARD_HINT,
      min = -5, max = 3, step = 0.1 },
    { key = "matrixFreezeAbove", label = L.T_FREEZE, absolute = true,
      flavor = L.T_FREEZE_HINT,
      min = -5, max = 3, step = 0.1 },
    { key = "matrixWeightFactor", label = L.T_WEIGHT, absolute = true,
      flavor = L.T_WEIGHT_HINT,
      min = 0, max = 3, step = 0.1 },
}

local MATRIX_BLURB = L.MATRIX_BLURB
local WEIGHTS_BLURB = L.WEIGHTS_BLURB

local viewFrame
local scrollFrame, scrollChild, scrollBar
local thresholdSliders = {}
local peakLabel, peakNote
local weightsGroup, matrixGroup
local scoreSourceButton, scoreSourceBlurb
local whitelistToggles = {}
local whitelistWarningLabel

local echoBanItems = {}
local echoBanFrame
local echoBanScroll, echoBanScrollChild, echoBanScrollBar
local echoBanAllButton

local CONTENT_HEIGHT = 1030

local function IsMatrixMode()
    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    return settings.scoreSource ~= "weights"
end

local cachedPeak = 0

local function RecomputePeak()
    if not peakLabel then return 0 end

    if IsMatrixMode() then
        cachedPeak = 0
        peakLabel:SetText(L.SCALE_MATRIX)
        if peakNote then
            peakNote:SetText(L.SCALE_MATRIX_NOTE)
        end
        return 0
    end

    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    local class    = EbonBuilds.BuildForm.GetEditingClass()
    local name, score = EbonBuilds.Scoring.ComputePeak(class, settings, EbonBuilds.Build.GetActiveWeights())
    cachedPeak = score or 0
    if name then
        peakLabel:SetText(string.format(L.PEAK, name, score))
    else
        peakLabel:SetText(L.PEAK_EMPTY)
    end
    if peakNote then
        peakNote:SetText(L.PEAK_NOTE)
    end
    return cachedPeak
end

local function RefreshWhitelistToggles()
    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    settings.banishFamilyWhitelist = settings.banishFamilyWhitelist or {}
    local allSelected = true
    for _, fam in ipairs(FAMILY_ORDER) do
        local row = whitelistToggles[fam]
        if row and row.checkTex then
            local selected = settings.banishFamilyWhitelist[fam] or false
            if selected then row.checkTex:Show() else row.checkTex:Hide() end
            if not selected then allSelected = false end
        end
    end
    if whitelistWarningLabel then
        if allSelected then
            whitelistWarningLabel:Show()
        else
            whitelistWarningLabel:Hide()
        end
    end
end

local function CommitWhitelistToggle(family)
    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    settings.banishFamilyWhitelist = settings.banishFamilyWhitelist or {}
    if settings.banishFamilyWhitelist[family] then
        settings.banishFamilyWhitelist[family] = nil
    else
        settings.banishFamilyWhitelist[family] = true
    end
    RefreshWhitelistToggles()
end

local WHITELIST_ROW1 = { "Tank", "Survivability", "Healer", "Caster" }
local WHITELIST_ROW2 = { "Melee", "Ranged", "No family" }

local function BuildBanishWhitelistSection(parent, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(L.BANISH_PROTECTION)

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    hint:SetText(L.BANISH_PROTECTION_HINT)

    local function CreateWhitelistRow(parent, fam, px, py)
        local row = CreateFrame("Button", nil, parent)
        row:SetWidth(18)
        row:SetHeight(18)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", px, py)
        row.family = fam

        local cb = row:CreateTexture(nil, "ARTWORK")
        cb:SetWidth(14)
        cb:SetHeight(14)
        cb:SetPoint("LEFT", row, "LEFT", 2, 0)
        cb:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        cb:Hide()
        row.checkTex = cb

        local bg = row:CreateTexture(nil, "BORDER")
        bg:SetWidth(14)
        bg:SetHeight(14)
        bg:SetPoint("LEFT", row, "LEFT", 1, 0)
        bg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
        bg:SetAlpha(0.8)

        row:SetScript("OnClick", function(self) CommitWhitelistToggle(self.family) end)
        whitelistToggles[fam] = row

        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetText(L.FAMILY[fam] or fam)
        lbl:SetPoint("LEFT", row, "RIGHT", 4, 0)
        lbl:SetJustifyH("LEFT")
    end

    for i, fam in ipairs(WHITELIST_ROW1) do
        CreateWhitelistRow(parent, fam, x + (i - 1) * 110, y - 32)
    end

    for i, fam in ipairs(WHITELIST_ROW2) do
        CreateWhitelistRow(parent, fam, x + (i - 1) * 110, y - 58)
    end

    whitelistWarningLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whitelistWarningLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 86)
    whitelistWarningLabel:SetWidth(400)
    whitelistWarningLabel:SetJustifyH("LEFT")
    whitelistWarningLabel:SetText(L.ALL_PROTECTED)
    whitelistWarningLabel:Hide()

    local banNote = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    banNote:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 115)
    banNote:SetWidth(490)
    banNote:SetJustifyH("LEFT")
    banNote:SetText(L.BAN_NOTE)
end

local QUALITY_BORDER_COLORS = EbonBuilds.Const.QUALITY_RGB

local ICON_SIZE  = 28
local ICON_GAP   = 4
local ICON_STEP  = ICON_SIZE + ICON_GAP
local BAN_LIST_W = 500
local BAN_LIST_PADDING = 4

local function RefreshBanList()
    if not echoBanFrame then return end
    for _, item in ipairs(echoBanItems) do
        item:Hide()
    end

    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    local banList = settings.echoBanList or {}
    local cols = math.floor((BAN_LIST_W - BAN_LIST_PADDING) / ICON_STEP)
    local idx = 0

    local banned = {}
    for spellId in pairs(banList) do banned[#banned + 1] = spellId end
    table.sort(banned)

    local perkDb = EbonAPI.Ebonhold.PerkDatabase() or {}
    for _, spellId in ipairs(banned) do
        local quality = 0
        local data = perkDb[spellId]
        if data then quality = data.quality or 0 end
        local borderColor = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]

        idx = idx + 1
        if not echoBanItems[idx] then
            local btn = CreateFrame("Button", nil, echoBanScrollChild)
            btn:SetSize(ICON_SIZE, ICON_SIZE)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT",     btn, "TOPLEFT",     2, -2)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2,  2)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn._icon = icon

            local border = btn:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -1,  1)
            border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  1, -1)
            btn._border = border

            btn:RegisterForClicks("LeftButtonUp")
            btn:SetScript("OnEnter", function(self)
                if not self.spellId then return end
                local spellName = GetSpellInfo(self.spellId)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                if spellName then
                    local q = self._quality or 0
                    local c = QUALITY_HEX[q] or "ffffff"
                    GameTooltip:AddLine(string.format("|cff%s%s|r", c, spellName), 1, 1, 1)
                end
                if utils and utils.GetSpellDescription then
                    local desc = utils.GetSpellDescription(self.spellId, 500, 1)
                    if desc and desc ~= "" then
                        GameTooltip:AddLine(desc, 1, 1, 1, true)
                    end
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            btn:SetScript("OnClick", function(self)
                local s = EbonBuilds.BuildForm.GetEditingSettings()
                local id = self._spellId
                if id then s.echoBanList[id] = nil end
                RefreshBanList()
            end)
            echoBanItems[idx] = btn
        end

        local btn = echoBanItems[idx]
        btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
        btn.spellId = spellId
        btn._spellId = spellId
        btn._quality = quality
        btn._border:SetTexture(borderColor[1], borderColor[2], borderColor[3])
        btn._border:Show()
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        btn:SetPoint("TOPLEFT", echoBanScrollChild, "TOPLEFT", BAN_LIST_PADDING + col * ICON_STEP, -BAN_LIST_PADDING - row * ICON_STEP)
        btn:Show()
    end

    local rows = math.ceil(idx / math.max(cols, 1))
    local contentHeight = math.max(rows * ICON_STEP, echoBanFrame:GetHeight())
    echoBanScrollChild:SetHeight(contentHeight)
    local range = math.max(0, contentHeight - echoBanFrame:GetHeight())
    echoBanScrollBar:SetMinMaxValues(0, range)
    if range > 0 then
        echoBanScroll:EnableMouseWheel(true)
    else
        echoBanScroll:EnableMouseWheel(false)
    end

    if idx == 0 then
        echoBanFrame._emptyLabel:Show()
    else
        echoBanFrame._emptyLabel:Hide()
    end
end

local function AddEchoToBan(name, spellId)
    local settings = EbonBuilds.BuildForm.GetEditingSettings()
    settings.echoBanList = settings.echoBanList or {}
    settings.echoBanList[spellId] = name
    RefreshBanList()
end

local function BuildEchoBanSection(parent, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(L.ECHO_BAN)

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    hint:SetText(L.ECHO_BAN_HINT)

    local addBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    addBtn:SetWidth(90)
    addBtn:SetHeight(20)
    addBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 30)
    addBtn:SetText(L.ADD_ECHO)
    addBtn:SetScript("OnClick", function()
        local allList = EbonBuilds.Catalog.AllQualities()
        local settings = EbonBuilds.BuildForm.GetEditingSettings()
        local banList = settings.echoBanList or {}
        local filtered = {}
        for _, entry in ipairs(allList) do
            if not banList[entry.spellId] and not EbonBuilds.BuildForm.IsLocked(entry.spellId) then
                filtered[#filtered + 1] = entry
            end
        end
        EbonBuilds.EchoPicker.Show(function(spellId, quality, name)
            AddEchoToBan(name, spellId)
        end, filtered)
    end)

    local listFrame = CreateFrame("Frame", nil, parent)
    listFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 56)
    listFrame:SetWidth(BAN_LIST_W)
    listFrame:SetHeight(120)

    echoBanScroll = CreateFrame("ScrollFrame", nil, listFrame)
    echoBanScroll:SetPoint("TOPLEFT",     listFrame, "TOPLEFT",     0, 0)
    echoBanScroll:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", 0, 0)

    echoBanScrollChild = CreateFrame("Frame", nil, echoBanScroll)
    echoBanScrollChild:SetWidth(BAN_LIST_W)
    echoBanScrollChild:SetHeight(120)
    echoBanScroll:SetScrollChild(echoBanScrollChild)

    echoBanScrollBar = CreateFrame("Slider", nil, listFrame, "UIPanelScrollBarTemplate")
    echoBanScrollBar:SetPoint("TOPLEFT",     listFrame, "TOPRIGHT",     0, -2)
    echoBanScrollBar:SetPoint("BOTTOMLEFT",  listFrame, "BOTTOMRIGHT",  0,  2)
    echoBanScrollBar:SetValueStep(ICON_STEP)
    echoBanScrollBar:SetValue(0)
    EbonBuilds.Widgets.WireScroll(echoBanScroll, echoBanScrollChild, echoBanScrollBar, ICON_STEP)
    echoBanScroll:EnableMouseWheel(false)

    local empty = listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 10, -4)
    empty:SetText(L.NO_BANNED)
    listFrame._emptyLabel = empty

    echoBanFrame = listFrame

    local allLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    allLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 190)
    allLabel:SetWidth(300)
    allLabel:SetJustifyH("LEFT")
    allLabel:SetText(L.ALL_BANNED_LABEL)

    echoBanAllButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    echoBanAllButton:SetWidth(110)
    echoBanAllButton:SetHeight(20)
    echoBanAllButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 310, y - 185)
    echoBanAllButton:SetText(L.HIGHEST_SCORE)
    echoBanAllButton._value = "highestScore"
    echoBanAllButton:SetScript("OnClick", function(self)
        if self._value == "highestScore" then
            self._value = "random"
            self:SetText(L.RANDOM)
        else
            self._value = "highestScore"
            self:SetText(L.HIGHEST_SCORE)
        end
        local s = EbonBuilds.BuildForm.GetEditingSettings()
        s.echoBanAllMode = self._value
    end)
end

local function BuildPeakRow(parent, x, y)
    peakLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    peakLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    peakLabel:SetText(L.PEAK_NONE)

    peakNote = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    peakNote:SetPoint("TOPLEFT", peakLabel, "BOTTOMLEFT", 0, -2)
    peakNote:SetWidth(480)
    peakNote:SetJustifyH("LEFT")
    peakNote:SetJustifyV("TOP")
end

local ApplyScoreSource

local function BuildScoreSourceSection(parent, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(L.SCORE_SOURCE)

    scoreSourceButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    scoreSourceButton:SetWidth(150)
    scoreSourceButton:SetHeight(22)
    scoreSourceButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 110, y - 4)
    scoreSourceButton:SetText(L.COMMUNITY_MATRIX)
    scoreSourceButton:SetScript("OnClick", function()
        local settings = EbonBuilds.BuildForm.GetEditingSettings()
        settings.scoreSource = (settings.scoreSource == "weights") and "matrix" or "weights"
        ApplyScoreSource()
    end)

    scoreSourceBlurb = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    scoreSourceBlurb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 30)
    scoreSourceBlurb:SetWidth(490)
    scoreSourceBlurb:SetJustifyH("LEFT")
    scoreSourceBlurb:SetJustifyV("TOP")
end

local SLIDER_W  = 400
local SLIDER_DY = 85

local function QuantiseThreshold(entry, value)
    if entry.absolute then return math.floor(value * 10 + 0.5) / 10 end
    return math.floor(value + 0.5)
end

local function FormatThreshold(entry, v)
    if entry.absolute then return string.format("%+.2f", v) end
    return v .. "%"
end

local function RefreshAbsLabel(slider, entry, v)
    if not slider._absLabel then return end
    if cachedPeak > 0 then
        slider._absLabel:SetText("= " .. math.floor(cachedPeak * v / 100))
    else
        slider._absLabel:SetText("")
    end
end

local function CreateThresholdSlider(parent, x, y, entry)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(entry.label)

    local flavorY = y - 20
    if entry.flavor then
        local flavor = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        flavor:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
        flavor:SetWidth(SLIDER_W)
        flavor:SetJustifyH("LEFT")
        flavor:SetText(entry.flavor)
        flavorY = y - 58
    end

    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, flavorY)
    slider:SetWidth(SLIDER_W)
    slider:SetHeight(24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(entry.min, entry.max)
    slider:SetValueStep(entry.step)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(0.25, 0.25, 0.25, 0.8)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetPoint("CENTER", slider, "CENTER", 0, 0)
    track:SetHeight(6)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetWidth(16)
    thumb:SetHeight(24)
    slider:SetThumbTexture(thumb)

    local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valText:SetWidth(40)
    valText:SetJustifyH("LEFT")
    slider._valText = valText

    local absLabel = nil
    if not entry.absolute then
        absLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        absLabel:SetPoint("LEFT", valText, "RIGHT", 2, 0)
        absLabel:SetWidth(60)
        absLabel:SetJustifyH("LEFT")
    end
    slider._absLabel = absLabel

    slider:SetScript("OnValueChanged", function(self, value)
        local v = QuantiseThreshold(entry, value)
        valText:SetText(FormatThreshold(entry, v))
        local settings = EbonBuilds.BuildForm.GetEditingSettings()
        settings[entry.key] = v
        RefreshAbsLabel(self, entry, v)
    end)

    return slider
end

local function BuildSliderGroup(parent, x, y, list, width, height)
    local group = CreateFrame("Frame", nil, parent)
    group:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    group:SetWidth(width)
    group:SetHeight(height)
    for i, entry in ipairs(list) do
        thresholdSliders[entry.key] = CreateThresholdSlider(group, 0, -(i - 1) * SLIDER_DY, entry)
    end
    return group
end

local function BuildThresholdsSection(parent, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(L.THRESHOLDS)

    local groupY  = y - 24
    local groupH  = math.max(#WEIGHT_THRESHOLDS, #MATRIX_THRESHOLDS) * SLIDER_DY
    weightsGroup = BuildSliderGroup(parent, x + 10, groupY, WEIGHT_THRESHOLDS, SLIDER_W + 110, groupH)
    matrixGroup  = BuildSliderGroup(parent, x + 10, groupY, MATRIX_THRESHOLDS, SLIDER_W + 110, groupH)
end

ApplyScoreSource = function()
    local matrixMode = IsMatrixMode()
    if scoreSourceButton then
        scoreSourceButton:SetText(matrixMode and L.COMMUNITY_MATRIX or L.MANUAL_WEIGHTS)
    end
    if scoreSourceBlurb then
        scoreSourceBlurb:SetText(matrixMode and MATRIX_BLURB or WEIGHTS_BLURB)
    end
    if matrixGroup then
        if matrixMode then matrixGroup:Show() else matrixGroup:Hide() end
    end
    if weightsGroup then
        if matrixMode then weightsGroup:Hide() else weightsGroup:Show() end
    end
    RecomputePeak()
    for _, entry in ipairs(WEIGHT_THRESHOLDS) do
        local slider = thresholdSliders[entry.key]
        if slider then
            local settings = EbonBuilds.BuildForm.GetEditingSettings()
            RefreshAbsLabel(slider, entry, settings[entry.key] or 0)
        end
    end
end

local ALL_THRESHOLDS = {}
for _, list in ipairs({ WEIGHT_THRESHOLDS, MATRIX_THRESHOLDS }) do
    for _, entry in ipairs(list) do ALL_THRESHOLDS[#ALL_THRESHOLDS + 1] = entry end
end

local function RefreshInputs()
    local settings = EbonBuilds.BuildForm.GetEditingSettings()

    for _, entry in ipairs(ALL_THRESHOLDS) do
        local slider = thresholdSliders[entry.key]
        if slider then
            local val = settings[entry.key]
            if val == nil then val = entry.absolute and entry.min or 0 end
            slider:SetValue(val)
            slider._valText:SetText(FormatThreshold(entry, QuantiseThreshold(entry, val)))
        end
    end

    RefreshWhitelistToggles()
    RefreshBanList()
    if echoBanAllButton then
        local mode = settings.echoBanAllMode or "highestScore"
        echoBanAllButton._value = mode
        echoBanAllButton:SetText(mode == "random" and L.RANDOM or L.HIGHEST_SCORE)
    end

    ApplyScoreSource()
end

local function BuildViewFrame(parent)
    local f = CreateFrame("Frame", nil, parent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.AUTOMATION_HEADER)

    scrollFrame = CreateFrame("ScrollFrame", nil, f)
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -28)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -22, 10)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(520)
    scrollChild:SetHeight(CONTENT_HEIGHT)
    scrollFrame:SetScrollChild(scrollChild)

    scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",     scrollFrame, "TOPRIGHT",     -2, -4)
    scrollBar:SetPoint("BOTTOMLEFT",  scrollFrame, "BOTTOMRIGHT",  -2,  4)
    scrollBar:SetValueStep(20)
    scrollBar:SetValue(0)

    EbonBuilds.Widgets.WireScroll(scrollFrame, scrollChild, scrollBar, 20)

    scrollFrame:SetScript("OnSizeChanged", function()
        EbonBuilds.Widgets.ScrollRange(scrollFrame, scrollBar, CONTENT_HEIGHT)
    end)

    BuildBanishWhitelistSection (scrollChild, 10,  -5)
    BuildEchoBanSection         (scrollChild, 10, -150)
    BuildScoreSourceSection     (scrollChild, 10, -390)
    BuildPeakRow                (scrollChild, 10, -466)
    BuildThresholdsSection      (scrollChild, 10, -524)

    return f
end

function EbonBuilds.SettingsView.Mount(container)
    viewFrame = viewFrame or BuildViewFrame(container)
    EbonBuilds.Widgets.Attach(viewFrame, container)
    RefreshInputs()
    viewFrame:Show()
    EbonBuilds.Widgets.ScrollRange(scrollFrame, scrollBar, CONTENT_HEIGHT)
    scrollBar:SetValue(0)
end

function EbonBuilds.SettingsView.Unmount()
    if not viewFrame then return end
    viewFrame:Hide()
end
