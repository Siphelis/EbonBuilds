EbonBuilds.PublicBuildsView = {}

local L = EbonBuilds.L

local PAGE_SIZE  = 8
local CARD_MARGIN = 4
local CARD_HEIGHT = 74
local LOCKED_ICON_SIZE = 22

local CLASS_COLORS = EbonBuilds.Const.CLASS_RGB

local viewFrame
local cardPool   = {}
local pageLabel, prevBtn, nextBtn
local scrollFrame, scrollChild, scrollBar
local noBuildsLabel
local state = { builds = {}, page = 1, totalPages = 1 }

local CLASS_DISPLAY = setmetatable({}, { __index = function(_, token) return EbonBuilds.ClassName(token) end })

local CLASS_TOKENS = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local classDropdown, specDropdown, refreshBtn
local filterClass, filterSpec

local function FetchPublicBuilds()
    return EbonBuilds.Build.ListPublic()
end

local RefreshView, GetFilteredBuilds, UpdateReloadButton
local reloadTimer

local function InitSpecDropdown()
    UIDropDownMenu_Initialize(specDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = L.ALL_SPECS
        info.value = nil
        info.func = function()
            UIDropDownMenu_SetSelectedValue(specDropdown, nil)
            filterSpec = nil
            UIDropDownMenu_SetText(specDropdown, L.ALL_SPECS)
            RefreshView()
        end
        info.checked = (filterSpec == nil)
        UIDropDownMenu_AddButton(info)
        if filterClass then
            local specs = EbonBuilds.SpecData and EbonBuilds.SpecData[filterClass] or {}
            for i, entry in ipairs(specs) do
                info.text = entry.name
                info.value = i
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(specDropdown, i)
                    filterSpec = i
                    UIDropDownMenu_SetText(specDropdown, entry.name)
                    RefreshView()
                end
                info.checked = (i == filterSpec)
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    if filterSpec then
        local specs = EbonBuilds.SpecData and EbonBuilds.SpecData[filterClass] or {}
        local entry = specs[filterSpec]
        if entry then
            UIDropDownMenu_SetText(specDropdown, entry.name)
            UIDropDownMenu_SetSelectedValue(specDropdown, filterSpec)
        else
            UIDropDownMenu_SetText(specDropdown, L.ALL_SPECS)
            UIDropDownMenu_SetSelectedValue(specDropdown, nil)
            filterSpec = nil
        end
    else
        UIDropDownMenu_SetText(specDropdown, L.ALL_SPECS)
        UIDropDownMenu_SetSelectedValue(specDropdown, nil)
    end
end

local function InitClassDropdown()
    UIDropDownMenu_Initialize(classDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = L.ALL_CLASSES
        info.value = nil
        info.func = function()
            UIDropDownMenu_SetSelectedValue(classDropdown, nil)
            filterClass = nil
            filterSpec = nil
            UIDropDownMenu_SetText(classDropdown, L.ALL_CLASSES)
            InitSpecDropdown()
            RefreshView()
        end
        info.checked = (filterClass == nil)
        UIDropDownMenu_AddButton(info)
        for _, token in ipairs(CLASS_TOKENS) do
            info.text = CLASS_DISPLAY[token]
            info.value = token
            info.func = function()
                UIDropDownMenu_SetSelectedValue(classDropdown, token)
                filterClass = token
                filterSpec = nil
                UIDropDownMenu_SetText(classDropdown, CLASS_DISPLAY[token])
                InitSpecDropdown()
                RefreshView()
            end
            info.checked = (token == filterClass)
            UIDropDownMenu_AddButton(info)
        end
    end)
    if filterClass then
        UIDropDownMenu_SetSelectedValue(classDropdown, filterClass)
        UIDropDownMenu_SetText(classDropdown, CLASS_DISPLAY[filterClass])
    else
        UIDropDownMenu_SetSelectedValue(classDropdown, nil)
        UIDropDownMenu_SetText(classDropdown, L.ALL_CLASSES)
    end
end

local SetClassIcon     = EbonBuilds.Widgets.SetClassIcon
local CreateIconButton = EbonBuilds.Widgets.CreateIconButton

local function CreateCard(parent)
    local card = CreateFrame("Button", nil, parent)
    card:SetHeight(CARD_HEIGHT)
    card:RegisterForClicks("LeftButtonUp")

    card:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",     card, "TOPLEFT",     4, -4)
    bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4,  4)
    bg:SetTexture(0, 0, 0, 0.20)
    card._bg = bg

    local stripe = card:CreateTexture(nil, "BACKGROUND")
    stripe:SetPoint("TOPLEFT",    card, "TOPLEFT",    4, -4)
    stripe:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 4,  4)
    stripe:SetWidth(4)
    card._stripe = stripe

    local classIcon = card:CreateTexture(nil, "ARTWORK")
    classIcon:SetWidth(28)
    classIcon:SetHeight(28)
    classIcon:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -10)
    classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card._classIcon = classIcon

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", 8, -4)
    title:SetPoint("RIGHT",   card,      "RIGHT",   -90, 0)
    title:SetJustifyH("LEFT")
    card._titleLabel = title

    local meta = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    meta:SetPoint("RIGHT",   card,  "RIGHT",     -90, 0)
    meta:SetJustifyH("LEFT")
    card._metaLabel = meta

    local specIcon = card:CreateTexture(nil, "ARTWORK")
    specIcon:SetWidth(14)
    specIcon:SetHeight(14)
    specIcon:SetPoint("TOPLEFT", classIcon, "BOTTOMLEFT", 0, -2)
    specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card._specIcon = specIcon

    card._lockedBtns = {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = CreateIconButton(card, LOCKED_ICON_SIZE)
        btn:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", (i - 1) * (LOCKED_ICON_SIZE + 4), -4)
        btn:Hide()
        btn:SetScript("OnEnter", function(self)
            if not self._spellId then return end
            local spellName = GetSpellInfo(self._spellId)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            if spellName then GameTooltip:AddLine(spellName, 1, 0.82, 0) end
            if utils and utils.GetSpellDescription then
                local desc = utils.GetSpellDescription(self._spellId, 500, 1)
                if desc and desc ~= "" then GameTooltip:AddLine(desc, 1, 1, 1, true) end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        card._lockedBtns[i] = btn
    end

    local importBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    importBtn:SetWidth(70)
    importBtn:SetHeight(22)
    importBtn:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    importBtn:SetText(L.IMPORT)
    card._importBtn = importBtn

    return card
end

local importedIndex = {}

local function IndexImportedCopies()
    for k in pairs(importedIndex) do importedIndex[k] = nil end
    for _, b in pairs(EbonBuildsDB.builds) do
        if b.importedFrom then importedIndex[b.importedFrom] = b end
    end
end

local function FindImportedCopy(publicBuildId)
    return importedIndex[publicBuildId]
end

local function ImportBuild(build)
    local settings = EbonBuilds.Build.CloneSettings(build.settings or EbonBuilds.Build.DefaultSettings())
    local data = {
        title    = string.format(L.IMPORTED_SUFFIX, build.title or L.UNTITLED),
        class    = build.class,
        spec     = build.spec or 1,
        comments = build.comments or "",
        lockedEchoes = EbonBuilds.Build.CopyLocked(build.lockedEchoes),
        settings = settings,
        isPublic = false,
    }
    local newBuild = EbonBuilds.Build.Create(data)
    newBuild.importedFrom = build.id
    newBuild._importedAt = build.lastModified
    if build.echoWeights and next(build.echoWeights) then
        newBuild.echoWeights = {}
        for name, weight in pairs(build.echoWeights) do
            newBuild.echoWeights[name] = weight
        end
    end
    EbonBuilds.Build.EnsureSettings(newBuild)
    EbonBuilds.Build.NormalizeWeights(newBuild.echoWeights)
    EbonBuilds.Build.Stamp(newBuild)
    if EbonBuildsDB.remoteBuilds then
        EbonBuildsDB.remoteBuilds[build.id] = nil
        if EbonBuilds.Matrix and EbonBuilds.Matrix.InvalidateBanVotes then
            EbonBuilds.Matrix.InvalidateBanVotes()
        end
    end
    EbonBuilds.Build.SetActive(newBuild.id)
    if EbonBuilds.BuildList and EbonBuilds.BuildList.Refresh then
        EbonBuilds.BuildList.Refresh()
    end
    EbonBuilds.ViewRouter.Show("buildOverview", { build = newBuild })
end

local function UpdateLocalBuild(localBuild, publicBuild)
    EbonBuilds.Build.UpdateFromPublic(localBuild, publicBuild)
    EbonBuilds.Build.SetActive(localBuild.id)
    if EbonBuilds.BuildList and EbonBuilds.BuildList.Refresh then
        EbonBuilds.BuildList.Refresh()
    end
    EbonBuilds.ViewRouter.Show("buildOverview", { build = localBuild })
end

local function PopulateCard(card, build)
    local cc = CLASS_COLORS[build.class] or { 0.5, 0.5, 0.5 }

    card:SetBackdropBorderColor(cc[1], cc[2], cc[3], 0.8)
    card._stripe:SetTexture(cc[1], cc[2], cc[3], 0.8)
    card._bg:SetTexture(cc[1], cc[2], cc[3], 0.06)

    SetClassIcon(card._classIcon, build.class)

    card._titleLabel:SetText(build.title or L.UNTITLED)
    card._titleLabel:SetTextColor(cc[1], cc[2], cc[3], 1)

    local specName = ""
    local specs = EbonBuilds.SpecData and EbonBuilds.SpecData[build.class]
    local specEntry = specs and specs[build.spec or 1]
    if specEntry then
        specName = specEntry.name
        card._specIcon:SetTexture(specEntry.icon)
        card._specIcon:Show()
    else
        card._specIcon:Hide()
    end

    local author = build.author or L.UNKNOWN
    local modified = build.lastModified or ""
    card._metaLabel:SetText(string.format(L.BUILD_META, author, specName, modified))

    local lockeds = build.lockedEchoes
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = card._lockedBtns[i]
        local spellId = lockeds and lockeds[i]
        if spellId then
            btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
            btn._spellId = spellId
            btn:Show()
        else
            btn:Hide()
        end
    end

    local localCopy = FindImportedCopy(build.id)
    if localCopy and build.lastModified ~= localCopy._importedAt then
        card._importBtn:SetText(L.UPDATE)
        card._importBtn:Enable()
        card._importBtn:SetScript("OnClick", function()
            UpdateLocalBuild(localCopy, build)
        end)
    else
        card._importBtn:SetText(L.IMPORT)
        card._importBtn:Enable()
        card._importBtn:SetScript("OnClick", function()
            ImportBuild(build)
        end)
    end
end

local function RefreshPaginationControls()
    if state.page > 1 then prevBtn:Enable() else prevBtn:Disable() end
    if state.page < state.totalPages then nextBtn:Enable() else nextBtn:Disable() end
    pageLabel:SetText(string.format(L.PAGE, state.page, state.totalPages))
end

local function Render()
    local all = state.builds or {}
    if #all == 0 then
        for _, card in ipairs(cardPool) do card:Hide() end
        scrollChild:SetHeight(1)
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        pageLabel:SetText(string.format(L.PAGE, 1, 1))
        prevBtn:Disable()
        nextBtn:Disable()
        if noBuildsLabel then noBuildsLabel:Show() end
        return
    end
    if noBuildsLabel then noBuildsLabel:Hide() end

    local startIdx = (state.page - 1) * PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + PAGE_SIZE - 1, #all)

    local totalHeight = 0
    for i = startIdx, endIdx do
        local poolIdx = i - startIdx + 1
        if not cardPool[poolIdx] then
            cardPool[poolIdx] = CreateCard(scrollChild)
        end
        local card = cardPool[poolIdx]
        PopulateCard(card, all[i])
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -totalHeight)
        card:SetPoint("RIGHT",   scrollChild, "RIGHT",   0, 0)
        card:Show()
        totalHeight = totalHeight + CARD_HEIGHT + CARD_MARGIN
    end
    for i = endIdx - startIdx + 2, #cardPool do
        cardPool[i]:Hide()
    end
    scrollChild:SetHeight(math.max(1, totalHeight))

    local visibleHeight = scrollFrame:GetHeight()
    local maxOffset = math.max(0, totalHeight - visibleHeight)
    scrollBar:SetMinMaxValues(0, maxOffset)
    if scrollBar:GetValue() > maxOffset then scrollBar:SetValue(maxOffset) end

    RefreshPaginationControls()
end

GetFilteredBuilds = function()
    IndexImportedCopies()
    local all = FetchPublicBuilds()
    local filtered = {}
    for _, build in ipairs(all) do
        if filterClass and build.class ~= filterClass then
        elseif filterSpec and build.spec ~= filterSpec then
        else
            local ownBuild = EbonBuildsDB.builds[build.id]
            if ownBuild then
            else
                local localCopy = FindImportedCopy(build.id)
                if localCopy and build.lastModified == localCopy._importedAt then
                else
                    filtered[#filtered + 1] = build
                end
            end
        end
    end
    return filtered
end

RefreshView = function()
    state.builds     = GetFilteredBuilds()
    state.page       = 1
    state.totalPages = math.max(1, math.ceil(#state.builds / PAGE_SIZE))
    scrollBar:SetValue(0)
    Render()
end

UpdateReloadButton = function()
    if not (viewFrame and viewFrame:IsVisible()) then return end
    local remaining = EbonBuilds.Sync.GetCooldownRemaining()
    if remaining > 0 then
        refreshBtn:SetText(string.format(L.WAIT_SECONDS, remaining))
        refreshBtn:Disable()
        EbonBuilds.Timer.Arm(reloadTimer, 1, UpdateReloadButton)
    else
        refreshBtn:SetText(L.RELOAD)
        refreshBtn:Enable()
    end
end

local function WireScrollBar()
    EbonBuilds.Widgets.WireScroll(scrollFrame, scrollChild, scrollBar, 40)
end

local function BuildViewFrame(parent)
    local f = CreateFrame("Frame", nil, parent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.PUBLIC_BUILDS)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    sub:SetText(L.PUBLIC_BUILDS_SUB)

    noBuildsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    noBuildsLabel:SetPoint("CENTER", f, "CENTER", 0, 0)
    noBuildsLabel:SetText(L.PUBLIC_BUILDS_NONE)
    noBuildsLabel:Hide()

    local bottomBar = CreateFrame("Frame", nil, f)
    bottomBar:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  10, 10)
    bottomBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    bottomBar:SetHeight(24)

    prevBtn = CreateFrame("Button", nil, bottomBar, "UIPanelButtonTemplate")
    prevBtn:SetWidth(80)
    prevBtn:SetHeight(22)
    prevBtn:SetPoint("LEFT", bottomBar, "LEFT", 0, 0)
    prevBtn:SetText(L.PREVIOUS)
    prevBtn:SetScript("OnClick", function()
        if state.page > 1 then
            state.page = state.page - 1
            scrollBar:SetValue(0)
            Render()
        end
    end)

    nextBtn = CreateFrame("Button", nil, bottomBar, "UIPanelButtonTemplate")
    nextBtn:SetWidth(80)
    nextBtn:SetHeight(22)
    nextBtn:SetPoint("RIGHT", bottomBar, "RIGHT", 0, 0)
    nextBtn:SetText(L.NEXT)
    nextBtn:SetScript("OnClick", function()
        if state.page < state.totalPages then
            state.page = state.page + 1
            scrollBar:SetValue(0)
            Render()
        end
    end)

    pageLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageLabel:SetPoint("CENTER", bottomBar, "CENTER", 0, 0)
    pageLabel:SetText(string.format(L.PAGE, 1, 1))

    local filterBar = CreateFrame("Frame", nil, f)
    filterBar:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -8)
    filterBar:SetPoint("RIGHT",   f,   "RIGHT",     -10, 0)
    filterBar:SetHeight(24)

    classDropdown = CreateFrame("Frame", "EbonBuildsPubClassDrop", filterBar, "UIDropDownMenuTemplate")
    classDropdown:SetPoint("LEFT", filterBar, "LEFT", 0, 0)
    UIDropDownMenu_SetWidth(classDropdown, 130)

    specDropdown = CreateFrame("Frame", "EbonBuildsPubSpecDrop", filterBar, "UIDropDownMenuTemplate")
    specDropdown:SetPoint("LEFT", classDropdown, "RIGHT", 4, 0)
    UIDropDownMenu_SetWidth(specDropdown, 130)

    filterClass = EbonBuilds.Build.PlayerClassToken()
    filterSpec = nil
    InitClassDropdown()
    InitSpecDropdown()

    refreshBtn = CreateFrame("Button", nil, filterBar, "UIPanelButtonTemplate")
    refreshBtn:SetWidth(60)
    refreshBtn:SetHeight(22)
    refreshBtn:SetPoint("LEFT", specDropdown, "RIGHT", 4, 0)
    refreshBtn:SetText(L.RELOAD)
    refreshBtn:SetScript("OnClick", function()
        EbonBuilds.Sync.RequestSync()
        UpdateReloadButton()
    end)
    reloadTimer = EbonBuilds.Timer.New("Public builds cooldown")

    scrollFrame = CreateFrame("ScrollFrame", nil, f)
    scrollFrame:SetPoint("TOPLEFT",     filterBar, "BOTTOMLEFT",  0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", bottomBar, "TOPRIGHT",    0,  8)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(1)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnSizeChanged", function()
        local w = scrollFrame:GetWidth()
        if w and w > 0 then
            scrollChild:SetWidth(w)
            Render()
        end
    end)

    scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",    scrollFrame, "TOPRIGHT",    -2, -4)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -2,  4)
    scrollBar:SetValueStep(20)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)

    WireScrollBar()
    return f
end

function EbonBuilds.PublicBuildsView.Mount(container)
    viewFrame = viewFrame or BuildViewFrame(container)
    EbonBuilds.Widgets.Attach(viewFrame, container)

    local w = viewFrame:GetWidth()
    if w and w > 0 then scrollChild:SetWidth(w - 24) end

    state.builds     = GetFilteredBuilds()
    state.page       = 1
    state.totalPages = math.max(1, math.ceil(#state.builds / PAGE_SIZE))
    scrollBar:SetValue(0)
    Render()
    viewFrame:Show()
    UpdateReloadButton()
end

function EbonBuilds.PublicBuildsView.Unmount()
    if viewFrame then viewFrame:Hide() end
    if reloadTimer then EbonBuilds.Timer.Cancel(reloadTimer) end
end

local COALESCE_DELAY = 0.5
local coalesceTimer

local function RefreshNow()
    if not (viewFrame and viewFrame:IsVisible()) then return end
    RefreshView()
end

function EbonBuilds.PublicBuildsView.RefreshIfMounted()
    if not (viewFrame and viewFrame:IsVisible()) then return end
    coalesceTimer = coalesceTimer or EbonBuilds.Timer.New("Public builds refresh")
    EbonBuilds.Timer.Arm(coalesceTimer, COALESCE_DELAY, RefreshNow)
end
