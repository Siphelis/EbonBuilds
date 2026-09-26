EbonBuilds.BuildForm = {}

local L = EbonBuilds.L

local classChangeCallbacks = {}

local function NotifyClassChange()
    for i = 1, #classChangeCallbacks do classChangeCallbacks[i]() end
end

function EbonBuilds.BuildForm.OnClassChanged(fn)
    classChangeCallbacks[#classChangeCallbacks + 1] = fn
end

local CLASS_ORDER = {
    "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST",
    "DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID",
}
local CLASS_TEXTURE = EbonBuilds.Const.CLASS_TEXTURE
local QUALITY_COLOR = EbonBuilds.Const.QUALITY_HEX
local QUALITY_BORDER_COLORS = EbonBuilds.Const.QUALITY_RGB

local viewFrame
local state = {
    mode     = "create",
    id       = nil,
    title    = "",
    class    = nil,
    spec     = 1,
    comments = "",
    locked = { nil, nil, nil, nil, nil },
    settings  = nil,
    isPublic  = false,
}
function EbonBuilds.BuildForm.GetEditingClass()
    return state.class
end
function EbonBuilds.BuildForm.GetEditingSettings()
    if not state.settings then
        state.settings = EbonBuilds.Build.DefaultSettings()
    end
    return state.settings
end

function EbonBuilds.BuildForm.GetEditingLockedEchoes()
    if not state.mode then return nil end
    return state.locked
end

function EbonBuilds.BuildForm.IsLocked(spellId)
    if not spellId then return false end
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        if state.locked[i] == spellId then return true end
    end
    return false
end

function EbonBuilds.BuildForm.IsBanned(spellId)
    if not spellId then return false end
    local banList = EbonBuilds.BuildForm.GetEditingSettings().echoBanList
    return (banList and banList[spellId]) and true or false
end

local classButtons = {}
local specButtons  = {}
local slotButtons  = {}
local titleBox, commentsBox, publicToggle

local _linkHookInstalled = false

local function InstallLinkHook()
    if _linkHookInstalled then return end
    _linkHookInstalled = true
    if not ChatEdit_InsertLink then return end
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        if not link then return end
        local focus = GetCurrentKeyBoardFocus()
        if focus and focus == commentsBox then
            commentsBox:Insert(link)
        end
    end)
end

local SetClassIcon     = EbonBuilds.Widgets.SetClassIcon
local CreateIconButton = EbonBuilds.Widgets.CreateIconButton

local function HighlightBorder(btn, on)
    if not btn._border then
        local b = btn:CreateTexture(nil, "OVERLAY")
        b:SetAllPoints(btn)
        b:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        b:SetBlendMode("ADD")
        b:Hide()
        btn._border = b
    end
    if on then btn._border:Show() else btn._border:Hide() end
end

local function RefreshClassSelection()
    for token, btn in pairs(classButtons) do
        HighlightBorder(btn, token == state.class)
    end
end

local function RefreshSpecButtons()
    local specs = state.class and EbonBuilds.SpecData and EbonBuilds.SpecData[state.class]
    for i = 1, 3 do
        local btn = specButtons[i]
        local entry = specs and specs[i]
        local icon  = entry and entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        local name  = entry and entry.name or string.format(L.SPEC_N, i)
        if btn._icon then btn._icon:SetTexture(icon) end
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(name)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        HighlightBorder(btn, i == state.spec)
    end
end

local function BuildClassGrid(parent, xAnchor, yAnchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", xAnchor, yAnchor)
    label:SetText(L.FORM_CLASS)
    for i, token in ipairs(CLASS_ORDER) do
        local btn = CreateIconButton(parent, 28)
        SetClassIcon(btn._icon, token)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xAnchor + 56 + (i - 1) * 30, yAnchor + 6)
        btn:SetScript("OnClick", function()
            if state.class == token then return end
            state.class = token
            if state.spec > 3 then state.spec = 1 end
            RefreshClassSelection()
            RefreshSpecButtons()
            NotifyClassChange()
        end)
        classButtons[token] = btn
    end
end

local function BuildSpecGrid(parent, xAnchor, yAnchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", xAnchor, yAnchor)
    label:SetText(L.FORM_SPEC)
    for i = 1, 3 do
        local btn = CreateIconButton(parent, 36)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xAnchor + 56 + (i - 1) * 40, yAnchor + 6)
        btn:SetScript("OnClick", function()
            state.spec = i
            RefreshSpecButtons()
        end)
        specButtons[i] = btn
    end
end

local function CreateBackdropEditBox(parent, width, height, multi)
    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(width, height)
    EbonBuilds.Widgets.InputBackdrop(c)

    local box = CreateFrame("EditBox", nil, c)
    box:SetPoint("TOPLEFT",     c, "TOPLEFT",     4,  -4)
    box:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -4,  4)
    box:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    box:SetTextColor(1, 1, 1, 1)
    box:SetAutoFocus(false)
    if multi then
        box:SetMultiLine(true)
        box:SetMaxLetters(0)
        box:EnableMouse(true)
    else
        box:SetMaxLetters(40)
    end
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box, c
end

local function BuildTitleField(parent, x, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(L.TITLE_LABEL)
    local box = CreateBackdropEditBox(parent, 300, 22, false)
    box:GetParent():SetPoint("TOPLEFT", parent, "TOPLEFT", x + 56, y + 6)
    titleBox = box
end

local function BuildLockedSlots(parent, x, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(L.LOCKED_ECHOES)
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = CreateIconButton(parent, 36)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 140 + (i - 1) * 44, y + 6)
        btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
        btn.spellId = nil
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        EbonBuilds.EchoTableRows.WireIconTooltip(btn)

        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -2,  2)
        border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  2, -2)
        border:Hide()
        btn._qualityBorder = border

        btn:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                state.locked[i] = nil
                btn.spellId = nil
                btn._quality = nil
                btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
                btn._qualityBorder:Hide()
                return
            end
            local settings = EbonBuilds.BuildForm.GetEditingSettings()
            local banList = settings and settings.echoBanList or {}
            local allList = EbonBuilds.Catalog.AllQualities()
            local filtered = {}
            for _, entry in ipairs(allList) do
                if not banList[entry.spellId] then
                    filtered[#filtered + 1] = entry
                end
            end
            EbonBuilds.EchoPicker.Show(function(spellId, quality, name)
                state.locked[i] = spellId
                btn.spellId = spellId
                btn._quality = quality
                btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
                local bc = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]
                btn._qualityBorder:SetTexture(bc[1], bc[2], bc[3])
                btn._qualityBorder:Show()
            end, filtered)
        end)
        slotButtons[i] = btn
    end
end

local descriptionPlaceholder

local function RefreshDescriptionPlaceholder()
    if not descriptionPlaceholder or not commentsBox then return end
    if commentsBox:HasFocus() then
        descriptionPlaceholder:Hide()
        return
    end
    if (commentsBox:GetText() or "") == "" then
        descriptionPlaceholder:Show()
    else
        descriptionPlaceholder:Hide()
    end
end

local function BuildDescriptionField(parent, x, y, height)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(L.DESCRIPTION_LABEL)

    local insertBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    insertBtn:SetWidth(110)
    insertBtn:SetHeight(20)
    insertBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 90, y + 2)
    insertBtn:SetText(L.INSERT_LINK_BUTTON)
    insertBtn:SetScript("OnClick", function()
        EbonBuilds.EchoPicker.Show(function(spellId, quality, name)
            local color = QUALITY_COLOR[quality] or "ffffff"
            local link  = "|cff" .. color .. "|Hecho:" .. spellId .. "|h[" .. name .. "]|h|r"
            if commentsBox:HasFocus() then
                commentsBox:Insert(link)
            else
                commentsBox:SetText((commentsBox:GetText() or "") .. link)
            end
        end)
    end)
    insertBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L.INSERT_LINK_TITLE, 1, 0.82, 0, 1)
        GameTooltip:AddLine(L.INSERT_LINK_BODY, 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1, 1)
        GameTooltip:AddLine(L.INSERT_LINK_HINT1, 0.6, 0.6, 0.6, 1)
        GameTooltip:AddLine(L.INSERT_LINK_HINT2, 0.6, 0.6, 0.6, 1)
        GameTooltip:Show()
    end)
    insertBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT",     parent, "TOPLEFT",     x,   y - 24)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 50)
    EbonBuilds.Widgets.InputBackdrop(container)

    local scroll = CreateFrame("ScrollFrame", "EbonBuildsBuildFormDescriptionSF", container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     container, "TOPLEFT",      4, -4)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -4,  4)

    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetMaxLetters(0)
    box:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    box:SetWidth(420)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(box)
    commentsBox = box

    local descMeasure = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descMeasure:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    descMeasure:SetWidth(410)
    descMeasure:Hide()

    local hint = box:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("TOPLEFT",  box, "TOPLEFT",   2, -2)
    hint:SetPoint("TOPRIGHT", box, "TOPRIGHT", -2, -2)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetTextColor(0.5, 0.5, 0.5, 1)
    hint:SetText(L.FORM_DESCRIPTION_HINT)
    descriptionPlaceholder = hint

    box:SetScript("OnEditFocusGained", function() descriptionPlaceholder:Hide() end)
    box:SetScript("OnEditFocusLost", function(self)
        if (self:GetText() or "") == "" then descriptionPlaceholder:Show() end
    end)
    box:SetScript("OnTextChanged", function(self)
        if self:HasFocus() then
            descriptionPlaceholder:Hide()
        else
            if (self:GetText() or "") == "" then
                descriptionPlaceholder:Show()
            else
                descriptionPlaceholder:Hide()
            end
        end

        descMeasure:SetText(self:GetText() or "")
        local textHeight = descMeasure:GetStringHeight() or 0
        local contentH = math.max(textHeight + 10, scroll:GetHeight())
        self:SetHeight(contentH)

        local sbar = _G["EbonBuildsBuildFormDescriptionSFScrollBar"]
        if sbar then
            local maxScroll = math.max(0, contentH - scroll:GetHeight())
            sbar:SetMinMaxValues(0, maxScroll)

            local cursorByte = self:GetCursorPosition() or 0
            local textBefore = (self:GetText() or ""):sub(1, cursorByte)
            descMeasure:SetText(textBefore)
            local cursorY = descMeasure:GetStringHeight() or 0

            local scrollTop = sbar:GetValue() or 0
            local visibleH = scroll:GetHeight()
            local cursorScreenY = cursorY - scrollTop

            if cursorScreenY > visibleH - 20 then
                sbar:SetValue(math.min(maxScroll, cursorY - visibleH + 20))
            elseif cursorScreenY < 4 then
                sbar:SetValue(math.max(0, cursorY - 20))
            end
        end
    end)
end

local function CollectFromInputs()
    state.title    = titleBox:GetText() or ""
    state.comments = commentsBox:GetText() or ""
end

local function OnSave()
    CollectFromInputs()
    if strtrim(state.title) == "" then
        EbonBuilds.Log.Warn(L.FORM_NEEDS_TITLE)
        if titleBox then titleBox:SetFocus() end
        return
    end
    local weights = EbonBuilds.Draft.weights
    if state.mode == "create" then
        local b = EbonBuilds.Build.Create({
            title = state.title, class = state.class, spec = state.spec,
            comments = state.comments, lockedEchoes = EbonBuilds.Build.CopyLocked(state.locked),
            settings = state.settings,
            isPublic = state.isPublic,
            echoWeights = weights,
        })
        state.mode = "edit"
        state.id   = b.id
        EbonBuilds.Build.SetActive(b.id)
    else
        EbonBuilds.Build.Save(state.id, {
            title = state.title, class = state.class, spec = state.spec,
            comments = state.comments, lockedEchoes = EbonBuilds.Build.CopyLocked(state.locked),
            settings = state.settings,
            isPublic = state.isPublic,
            echoWeights = weights,
        })
    end
    EbonBuilds.Draft.isEditing = false
    EbonBuilds.Draft.weights = nil
    EbonBuilds.Draft.wizardPrefill = nil
    if EbonBuilds.BuildList and EbonBuilds.BuildList.Refresh then
        EbonBuilds.BuildList.Refresh()
    end
    if EbonBuilds.BuildTabs and EbonBuilds.BuildTabs.OnBuildSaved then
        EbonBuilds.BuildTabs.OnBuildSaved()
    end
    if EbonBuilds.BuildTabs and EbonBuilds.BuildTabs.EnableEchoesTab then
        EbonBuilds.BuildTabs.EnableEchoesTab()
    end
    local active = EbonBuilds.Build.GetActive()
    if active then
        EbonBuilds.ViewRouter.Show("buildOverview", { build = active })
    end
end

local LoadFromBuild, ApplyStateToInputs

local function OnCancel()
    EbonBuilds.Draft.isEditing = false
    EbonBuilds.Draft.weights = nil
    EbonBuilds.Draft.wizardPrefill = nil

    if state.mode == "edit" and state.id then
        local build = EbonBuilds.Build.Get(state.id)
        if build then
            LoadFromBuild(build)
            ApplyStateToInputs()
        end
    end

    local active = EbonBuilds.Build.GetActive()
    if active then
        EbonBuilds.ViewRouter.Show("buildOverview", { build = active })
    else
        EbonBuilds.ViewRouter.Show("welcome")
    end
end

EbonBuilds.BuildForm.Save   = OnSave
EbonBuilds.BuildForm.Cancel = OnCancel

ApplyStateToInputs = function()
    titleBox:SetText(state.title or "")
    commentsBox:SetText(state.comments or "")
    RefreshDescriptionPlaceholder()
    RefreshClassSelection()
    RefreshSpecButtons()
    publicToggle:SetText(state.isPublic and L.PUBLIC or L.MAKE_PUBLIC)
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local id = state.locked[i]
        local btn = slotButtons[i]
        btn.spellId = id
        if id then
            btn._icon:SetTexture(select(3, GetSpellInfo(id)))
            local data = EbonBuilds.Catalog.Entry(id)
            local quality = data and data.quality or 0
            btn._quality = quality
            local bc = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]
            btn._qualityBorder:SetTexture(bc[1], bc[2], bc[3])
            btn._qualityBorder:Show()
        else
            btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
            btn._quality = nil
            btn._qualityBorder:Hide()
        end
    end
end

local function CloneSettings(src)
    local dst = EbonBuilds.Build.DefaultSettings()
    if not src then return dst end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            for k2, v2 in pairs(v) do dst[k][k2] = v2 end
        else
            dst[k] = v
        end
    end
    return dst
end

LoadFromBuild = function(build)
    state.mode     = "edit"
    state.id       = build.id
    state.title    = build.title    or ""
    state.class    = build.class
    state.spec     = build.spec     or 1
    state.comments = build.comments or ""
    state.settings = CloneSettings(build.settings)
    state.isPublic = build.isPublic or false
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do state.locked[i] = build.lockedEchoes and build.lockedEchoes[i] or nil end
    EbonBuilds.Draft.isEditing = true
    EbonBuilds.Draft.weights = {}
    if build.echoWeights then
        for name, weight in pairs(build.echoWeights) do
            EbonBuilds.Draft.weights[name] = weight
        end
    end
end

local function LoadDefaults()
    state.mode     = "create"
    state.id       = nil
    state.title    = ""
    state.class    = EbonBuilds.Build.PlayerClassToken()
    state.spec     = EbonBuilds.Build.PlayerTopTalentTab()
    state.comments = ""
    state.settings = EbonBuilds.Build.DefaultSettings()
    state.isPublic = false
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do state.locked[i] = nil end
    EbonBuilds.Draft.isEditing = true
    EbonBuilds.Draft.weights = {}
    EbonBuilds.Draft.wizardPrefill = nil
end

local function LoadFromWizardPrefill()
    local pre = EbonBuilds.Draft.wizardPrefill
    state.mode     = "create"
    state.id       = nil
    state.title    = pre.title or ""
    state.class    = pre.class or EbonBuilds.Build.PlayerClassToken()
    state.spec     = pre.spec or EbonBuilds.Build.PlayerTopTalentTab()
    state.comments = pre.comments or ""
    state.settings = pre.settings or EbonBuilds.Build.DefaultSettings()
    state.isPublic = pre.isPublic or false
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do state.locked[i] = (pre.lockedEchoes and pre.lockedEchoes[i]) or nil end
    EbonBuilds.Draft.isEditing = true
    EbonBuilds.Draft.weights = EbonBuilds.Draft.weights or {}
end

local function TargetMatchesState(context)
    if context.mode == "edit" and context.build then
        return state.mode == "edit" and state.id == context.build.id
    end
    return false
end

function EbonBuilds.BuildForm.Mount(container, context)
    EbonBuilds.Widgets.Attach(viewFrame, container)

    context = context or {}
    local keepState = TargetMatchesState(context)
    if not keepState then
        if context.mode == "create" and context.fromWizard and EbonBuilds.Draft.wizardPrefill then
            LoadFromWizardPrefill()
        elseif context.mode == "edit" and context.build then
            LoadFromBuild(context.build)
        else
            LoadDefaults()
        end
    end

    ApplyStateToInputs()
    NotifyClassChange()
    viewFrame:Show()
end

function EbonBuilds.BuildForm.Unmount()
    if viewFrame and titleBox and commentsBox then
        state.title    = titleBox:GetText() or state.title
        state.comments = commentsBox:GetText() or state.comments
    end
    if viewFrame then viewFrame:Hide() end
end

local function BuildViewFrame()
    local f = CreateFrame("Frame", nil, UIParent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.FORM_HEADER)

    publicToggle = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    publicToggle:SetSize(120, 22)
    publicToggle:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    publicToggle:SetText(L.MAKE_PUBLIC)
    publicToggle:SetScript("OnClick", function(self)
        state.isPublic = not state.isPublic
        self:SetText(state.isPublic and L.PUBLIC or L.MAKE_PUBLIC)
    end)

    BuildClassGrid(f, 10, -36)
    BuildSpecGrid(f, 10, -76)
    BuildTitleField(f, 10, -124)
    BuildLockedSlots(f, 10, -160)
    BuildDescriptionField(f, 10, -210, 180)
    return f
end

function EbonBuilds.BuildForm.Init()
    viewFrame = BuildViewFrame()
    viewFrame:Hide()
    InstallLinkHook()
end
