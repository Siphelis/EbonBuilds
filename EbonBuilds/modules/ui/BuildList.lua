EbonBuilds.BuildList = {}

local L = EbonBuilds.L

local ROW_SINGLE   = 56
local ROW_DOUBLE   = 74
local CARD_MARGIN  = 3
local CLASS_COLORS  = EbonBuilds.Const.CLASS_RGB

local container
local rowPool     = {}
local scrollFrame
local scrollChild
local newBuildBtn
local savedBuildsBtn
local importBtn
local publicBuildsBtn
local titleMeasureFont

local SetClassIcon     = EbonBuilds.Widgets.SetClassIcon
local CreateIconButton = EbonBuilds.Widgets.CreateIconButton

local TITLE_MAX_W = 136

local function NeedsTwoLines(text)
    if not text or text == "" then return false end
    titleMeasureFont:SetText(text)
    local w = titleMeasureFont:GetStringWidth() or 0
    return w > TITLE_MAX_W
end

local function Navigate(self)
    local build = self._row._build
    if not build then return end
    EbonBuilds.Build.SetActive(build.id)
    EbonBuilds.ViewRouter.Show("buildOverview", { build = build })
end

local function HideTooltip() GameTooltip:Hide() end

local function ShowClassTooltip(self)
    local build = self._row._build
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(EbonBuilds.ClassName(build and build.class), 1, 1, 1)
    GameTooltip:Show()
end

local function ShowSpecTooltip(self)
    if not self._specName then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self._specName, 1, 1, 1)
    GameTooltip:Show()
end

local function ShowEchoTooltip(self)
    local spellName = self._spellId and GetSpellInfo(self._spellId)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if spellName then
        GameTooltip:AddLine(spellName, 1, 0.82, 0)
    end
    GameTooltip:Show()
end

local function Wire(btn, row, onEnter)
    btn._row = row
    btn:SetScript("OnClick", Navigate)
    if onEnter then
        btn:SetScript("OnEnter", onEnter)
        btn:SetScript("OnLeave", HideTooltip)
    end
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("LEFT",  parent, "LEFT",  0, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    row:SetHeight(ROW_SINGLE)

    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetPoint("TOPLEFT",      row, "TOPLEFT",      2, -2)
    stripe:SetPoint("BOTTOMLEFT",   row, "BOTTOMLEFT",   2,  2)
    stripe:SetWidth(4)
    row._stripe = stripe

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",      row, "TOPLEFT",      6, -2)
    bg:SetPoint("BOTTOMRIGHT",  row, "BOTTOMRIGHT", -2,  2)
    row._bg = bg

    local selected = row:CreateTexture(nil, "BACKGROUND")
    selected:SetAllPoints(row)
    selected:SetTexture(0.2, 0.5, 0.9, 0.18)
    selected:Hide()
    row._selected = selected

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT",      row, "TOPLEFT",      6, -2)
    hl:SetPoint("BOTTOMRIGHT",  row, "BOTTOMRIGHT", -2,  2)
    hl:SetTexture(1, 1, 1, 0.08)
    hl:Hide()
    row:SetScript("OnEnter", function() hl:Show() end)
    row:SetScript("OnLeave", function() hl:Hide() end)

    local classBtn = CreateIconButton(row, 22)
    classBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)
    row._classBtn = classBtn

    local titleLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOPLEFT",  classBtn, "TOPRIGHT",  6, -2)
    titleLabel:SetPoint("RIGHT",    row,      "RIGHT",    -8, 0)
    titleLabel:SetJustifyH("LEFT")
    titleLabel:SetHeight(0)
    row._titleLabel = titleLabel

    local specBtn = CreateIconButton(row, 14)
    specBtn:SetPoint("TOPLEFT", classBtn, "BOTTOMLEFT", 0, -2)
    row._specBtn = specBtn

    row._lockedBtns = {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = CreateIconButton(row, 22)
        btn:Hide()
        Wire(btn, row, ShowEchoTooltip)
        row._lockedBtns[i] = btn
    end

    Wire(row, row)
    Wire(classBtn, row, ShowClassTooltip)
    Wire(specBtn, row, ShowSpecTooltip)
    return row
end

local LOCKED_X_START = 32
local LOCKED_STEP    = 28

local function PopulateRow(row, build, activeId, yOffset)
    local isActive = (build.id == activeId)
    local classToken = build.class
    local cc = CLASS_COLORS[classToken] or { 0.5, 0.5, 0.5 }

    local twoLines = NeedsTwoLines(build.title)
    local rowHeight = twoLines and ROW_DOUBLE or ROW_SINGLE
    row:SetHeight(rowHeight)

    row:ClearAllPoints()
    row:SetPoint("LEFT",  scrollChild, "LEFT",  0, 0)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row:SetPoint("TOP",   scrollChild, "TOP",   0, -yOffset)

    if isActive then
        row._stripe:SetWidth(6)
        row._stripe:SetTexture(cc[1], cc[2], cc[3], 1.0)
        row._bg:SetTexture(cc[1], cc[2], cc[3], 0.12)
        row._selected:Show()
    else
        row._stripe:SetWidth(4)
        row._stripe:SetTexture(cc[1], cc[2], cc[3], 0.6)
        row._bg:SetTexture(cc[1], cc[2], cc[3], 0.06)
        row._selected:Hide()
    end

    row._build = build

    SetClassIcon(row._classBtn._icon, classToken)

    local title = build.title or L.UNTITLED
    row._titleLabel:SetText(title)
    row._titleLabel:SetTextColor(cc[1], cc[2], cc[3], 1)
    if twoLines then
        row._titleLabel:SetWidth(TITLE_MAX_W)
        row._titleLabel:SetHeight(28)
    else
        row._titleLabel:SetWidth(0)
        row._titleLabel:SetHeight(0)
    end

    local specs = EbonBuilds.SpecData and EbonBuilds.SpecData[classToken]
    local specEntry = specs and specs[build.spec or 1]
    if specEntry then
        row._specBtn._icon:SetTexture(specEntry.icon)
        row._specBtn._specName = specEntry.name
        row._specBtn:Show()
    else
        row._specBtn:Hide()
    end

    local lockeds = build.lockedEchoes
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = row._lockedBtns[i]
        local spellId = lockeds and lockeds[i]
        btn:ClearAllPoints()
        btn:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", LOCKED_X_START + (i - 1) * LOCKED_STEP, 4)
        if spellId then
            btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
            btn._spellId = spellId
            btn:Show()
        else
            btn:Hide()
        end
    end

    row:Show()
    return rowHeight
end

local function Render()
    local builds   = EbonBuilds.Build.List()
    local activeId = EbonBuildsCharDB.activeBuildId
    local yOffset = 0
    for i = 1, #builds do
        if not rowPool[i] then rowPool[i] = CreateRow(scrollChild) end
        local rowHeight = PopulateRow(rowPool[i], builds[i], activeId, yOffset)
        yOffset = yOffset + rowHeight + CARD_MARGIN
    end
    for i = #builds + 1, #rowPool do rowPool[i]:Hide() end

    scrollChild:SetHeight(math.max(1, yOffset))
end

EbonBuilds.BuildList.Refresh = Render

local function CreateSavedBuildsButton(parent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    btn:SetText(L.SAVED_BUILDS)
    btn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("savedBuilds")
    end)
    return btn
end

local function CreatePublicBuildsButton(parent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    btn:SetText(L.PUBLIC_BUILDS)
    btn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("publicBuilds")
    end)
    return btn
end

local function CreateImportButton(parent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    btn:SetText(L.IMPORT_BUILD)
    btn:SetScript("OnClick", function()
        EbonBuilds.ExportImport.ShowImportDialog()
    end)
    return btn
end

local function CreateNewBuildButton(parent, topAnchor)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  topAnchor, "BOTTOMLEFT",  0, -2)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    btn:SetText(L.NEW_BUILD_BUTTON)
    btn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("buildWizard")
    end)
    return btn
end

local function CreateScrollArea(parent, topAnchor)
    local sf = CreateFrame("ScrollFrame", "EbonBuildsBuildListSF", parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     topAnchor, "BOTTOMLEFT",  0, -4)
    sf:SetPoint("BOTTOMRIGHT", parent,    "BOTTOMRIGHT", -22, 0)

    local child = CreateFrame("Frame", nil, sf)
    child:SetWidth(1)
    child:SetHeight(1)
    sf:SetScrollChild(child)
    return sf, child
end

function EbonBuilds.BuildList.Init(parent)
    container       = parent
    savedBuildsBtn  = CreateSavedBuildsButton(parent)
    publicBuildsBtn = CreatePublicBuildsButton(parent)
    importBtn       = CreateImportButton(parent)
    newBuildBtn     = CreateNewBuildButton(parent, importBtn)
    scrollFrame, scrollChild = CreateScrollArea(parent, newBuildBtn)

    publicBuildsBtn:SetPoint("TOPLEFT",  savedBuildsBtn, "BOTTOMLEFT", 0, -2)
    publicBuildsBtn:SetPoint("TOPRIGHT", parent,         "TOPRIGHT",   0,  0)

    importBtn:SetPoint("TOPLEFT",  publicBuildsBtn, "BOTTOMLEFT",  0, -2)
    importBtn:SetPoint("TOPRIGHT", parent,          "TOPRIGHT",    0,  0)

    titleMeasureFont = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleMeasureFont:Hide()

    scrollChild:SetWidth(parent:GetWidth() - 22)
    parent:SetScript("OnSizeChanged", function()
        scrollChild:SetWidth(parent:GetWidth() - 22)
        Render()
    end)

    Render()

    if EbonBuilds.Build and EbonBuilds.Build.OnActiveChanged then
        EbonBuilds.Build.OnActiveChanged(Render)
    end
end
