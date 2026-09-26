EbonBuilds.BuildOverview = {}

local L = EbonBuilds.L

local CLASS_COLORS = EbonBuilds.Const.CLASS_RGB

local QUALITY_BORDER_COLORS = EbonBuilds.Const.QUALITY_RGB

local QUALITY_LABELS = EbonBuilds.Const.QUALITY_NAME

local viewFrame
local tab1, tab2, tab3, tab4
local contentArea
local state = { build = nil }

StaticPopupDialogs["EBONBUILDS_DELETE_BUILD"] = {
    text = "",
    button1 = L.DELETE,
    button2 = L.CANCEL,
    OnAccept = function()
        local build = state.build
        if not build or not build.id then return end
        local id = build.id
        EbonBuilds.Build.Delete(id)
        if EbonBuilds.BuildList and EbonBuilds.BuildList.Refresh then
            EbonBuilds.BuildList.Refresh()
        end
        local builds = EbonBuilds.Build.List()
        if #builds > 0 then
            EbonBuilds.Build.SetActive(builds[1].id)
            EbonBuilds.ViewRouter.Show("buildOverview", { build = builds[1] })
        else
            EbonBuilds.ViewRouter.Show("welcome")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local SetClassIcon     = EbonBuilds.Widgets.SetClassIcon
local CreateIconButton = EbonBuilds.Widgets.CreateIconButton

local CLASS_MASK = EbonBuilds.Const.CLASS_BITS

local PREFIXES = { "tome of ", "codex of ", "scroll of ", "manual of ", "grimoire of ", "libram of ", "tablet of " }
local QUALITY_SUFFIXES = { " %- common", " %- uncommon", " %- rare", " %- epic", " %- legendary" }

local function NormalizeEchoName(name)
    if not name then return nil end
    local n = strlower(name)
    for _, prefix in ipairs(PREFIXES) do
        if n:sub(1, #prefix) == prefix then
            n = n:sub(#prefix + 1)
            break
        end
    end
    for _, suffix in ipairs(QUALITY_SUFFIXES) do
        if n:sub(-#suffix) == suffix then
            n = n:sub(1, -(#suffix + 1))
            break
        end
    end
    return n
end

local function ComputeMissingEchoes(build)
    if not build or not build.class then return nil end

    local classMask = CLASS_MASK[build.class] or 0
    local playerLevel = UnitLevel("player")

    local ownedLower = {}
    local ownedGroups = {}
    local spellbookIds = {}
    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    for tabIdx = 1, numTabs do
        local tabName, _, offset, numSpells = GetSpellTabInfo(tabIdx)
        if tabName == "Echoes" then
            for slot = offset + 1, offset + numSpells do
                local link = GetSpellLink(slot, "spell")
                local tomeSpellId = link and tonumber(link:match("spell:(%d+)"))
                if tomeSpellId then
                    spellbookIds[tomeSpellId] = true
                end
            end
            break
        end
    end

    local perkDb = EbonAPI.Ebonhold.PerkDatabase() or {}
    for spellId, data in pairs(perkDb) do
        local isOwned = spellbookIds[data.requiredSpell] or spellbookIds[spellId + 100000]
        if isOwned then
            local name = GetSpellInfo(spellId)
            local norm = NormalizeEchoName(name)
            if norm then ownedLower[norm] = true end
            if data.groupId then ownedGroups[data.groupId] = true end
        end
    end

    local perks = EbonAPI.Ebonhold.Perks()
    if perks and perks.GetGrantedPerks then
        local granted = perks.GetGrantedPerks()
        for name in pairs(granted or {}) do
            local norm = NormalizeEchoName(name)
            if norm then ownedLower[norm] = true end
        end
    end

    local lockedLower = {}
    if build.lockedEchoes then
        for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
            local spellId = build.lockedEchoes[i]
            if spellId then
                local name = GetSpellInfo(spellId)
                if name then lockedLower[NormalizeEchoName(name)] = true end
            end
        end
    end

    local byName = {}
    for spellId, data in pairs(perkDb) do
        local spellName = GetSpellInfo(spellId)
        if spellName then
            local key = NormalizeEchoName(spellName)
            local isOwned = ownedLower[key] or (data.groupId and ownedGroups[data.groupId])
            if not isOwned then
                if classMask == 0 or bit.band(data.classMask or 0, classMask) ~= 0 then
                    if not data.minLevel or playerLevel >= data.minLevel then
                        local existing = byName[key]
                        if not existing or (data.quality or 0) > (existing.quality or 0) then
                            byName[key] = { spellId = spellId, data = data, displayName = spellName }
                        end
                    end
                end
            end
        end
    end

    local settings = build.settings or EbonBuilds.Build.DefaultSettings()
    local banList = settings.echoBanList or {}
    local weights = build.echoWeights or {}
    local missing = {}
    local dropSources = EbonAPI.Ebonhold.PerkDropSources()
    local dropByGroup = EbonAPI.Ebonhold.PerkDropSourceByGroup()
    for key, entry in pairs(byName) do
        local source = dropSources and dropSources[entry.spellId]
        if not source and entry.data.groupId and dropByGroup then
            source = dropByGroup[entry.data.groupId]
        end
        local needsTome = entry.data.requiredSpell and entry.data.requiredSpell > 0
        if not banList[entry.spellId] and needsTome then
            local scoringEntry = {
                spellId = entry.spellId,
                name = entry.displayName,
                quality = entry.data.quality or 0,
                families = entry.data.families,
                classMask = entry.data.classMask,
            }
            local weightKey = EbonBuilds.Catalog.WeightKey(entry.spellId)
                              or entry.displayName
            local weight = weights[weightKey] or 0
            local score = EbonBuilds.Scoring.Score(scoringEntry, weight, settings)
            missing[#missing + 1] = {
                spellId = entry.spellId,
                name = entry.displayName,
                quality = entry.data.quality or 0,
                dropSource = source or "Unknown",
                isLocked = lockedLower[key] or false,
                score = score,
            }
        end
    end

    table.sort(missing, function(a, b)
        if a.isLocked ~= b.isLocked then
            return a.isLocked
        end
        if a.score ~= b.score then
            return a.score > b.score
        end
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        return a.name < b.name
    end)
    return missing
end

local function BuildOverviewTab(parent)
    local outer = CreateFrame("Frame", nil, parent)
    outer:SetAllPoints(parent)

    local classIcon = outer:CreateTexture(nil, "ARTWORK")
    classIcon:SetWidth(32)
    classIcon:SetHeight(32)
    classIcon:SetPoint("TOPLEFT", outer, "TOPLEFT", 10, -10)
    outer._classIcon = classIcon

    local nameLabel = outer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", 8, -6)
    nameLabel:SetPoint("RIGHT",   outer,     "RIGHT",     -10, 0)
    nameLabel:SetJustifyH("LEFT")
    outer._nameLabel = nameLabel

    local metaLabel = outer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    metaLabel:SetPoint("TOPLEFT", classIcon, "BOTTOMLEFT", 0, -2)
    metaLabel:SetPoint("RIGHT",  outer,     "RIGHT",      -10, 0)
    metaLabel:SetJustifyH("LEFT")
    outer._metaLabel = metaLabel

    local statusFrame = CreateFrame("Button", nil, outer)
    statusFrame:SetPoint("TOPLEFT",     metaLabel, "BOTTOMLEFT", 0, -12)
    statusFrame:SetPoint("RIGHT",       outer,     "RIGHT",      -10, 0)
    statusFrame:SetHeight(16)
    local statusLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetAllPoints(statusFrame)
    statusLabel:SetJustifyH("LEFT")
    statusFrame:SetScript("OnEnter", function(self)
        local build = state.build
        if not build or not build.isPublic then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L.PUBLIC_BUILD_TITLE, 1, 0.82, 0, 1)
        GameTooltip:AddLine(L.PUBLIC_BUILD_BODY1, 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine(L.PUBLIC_BUILD_BODY2, 0.6, 0.6, 0.6, 1)
        GameTooltip:Show()
    end)
    statusFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    outer._statusLabel = statusLabel

    local lockedHeader = outer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockedHeader:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -14)
    lockedHeader:SetText(L.LOCKED_ECHOES)
    outer._lockedHeader = lockedHeader

    local lockedButtons = {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = CreateIconButton(outer, 36)
        btn:SetPoint("TOPLEFT", lockedHeader, "BOTTOMLEFT", (i - 1) * 42, -6)
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -2,  2)
        border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  2, -2)
        border:Hide()
        btn._border = border
        btn:SetScript("OnEnter", function(self)
            if not self._spellId then return end
            local name = GetSpellInfo(self._spellId)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            if name then GameTooltip:AddLine(name, 1, 0.82, 0) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lockedButtons[i] = btn
    end
    outer._lockedButtons = lockedButtons

    local autoToggle = CreateFrame("Button", nil, outer, "UIPanelButtonTemplate")
    autoToggle:SetWidth(140)
    autoToggle:SetHeight(22)
    autoToggle:SetPoint("TOPLEFT", lockedButtons[1], "BOTTOMLEFT", 0, -22)
    autoToggle:SetText(L.AUTOMATION_ON)
    autoToggle:SetScript("OnClick", function(self)
        local build = state.build
        if not build then return end
        build.automationEnabled = not build.automationEnabled
        self:SetText(build.automationEnabled and L.AUTOMATION_ON or L.AUTOMATION_OFF)
    end)
    outer._autoToggle = autoToggle

    local editBtn = CreateFrame("Button", nil, outer, "UIPanelButtonTemplate")
    editBtn:SetWidth(120)
    editBtn:SetHeight(22)
    editBtn:SetPoint("LEFT", autoToggle, "RIGHT", 8, 0)
    editBtn:SetText(L.EDIT_BUILD)
    editBtn:SetScript("OnClick", function()
        if state.build then
            EbonBuilds.ViewRouter.Show("buildTabs", { mode = "edit", build = state.build })
        end
    end)

    local descHeader = outer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descHeader:SetPoint("TOPLEFT", autoToggle, "BOTTOMLEFT", 0, -14)
    descHeader:SetText(L.DESCRIPTION_LABEL)
    outer._descHeader = descHeader

    local descScroll = CreateFrame("ScrollFrame", nil, outer)
    descScroll:SetPoint("TOPLEFT",     descHeader, "BOTTOMLEFT", 0, -4)
    descScroll:SetPoint("BOTTOMRIGHT", outer,      "BOTTOMRIGHT", -22, 28)

    local descChild = CreateFrame("Frame", nil, descScroll)
    descChild:SetWidth(416)
    descChild:SetHeight(1)
    descScroll:SetScrollChild(descChild)

    local descBar = CreateFrame("Slider", nil, descScroll, "UIPanelScrollBarTemplate")
    descBar:SetPoint("TOPLEFT",    descScroll, "TOPRIGHT",    -2, -4)
    descBar:SetPoint("BOTTOMLEFT", descScroll, "BOTTOMRIGHT", -2,  4)
    descBar:SetValueStep(20)
    local descWheel = EbonBuilds.Widgets.WireScroll(descScroll, descChild, descBar, 20)

    local descSmf = CreateFrame("ScrollingMessageFrame", nil, descChild)
    descSmf:SetPoint("TOPLEFT", descChild, "TOPLEFT", 0, -2)
    descSmf:SetWidth(416)
    descSmf:SetFontObject("GameFontNormalSmall")
    descSmf:SetJustifyH("LEFT")
    descSmf:SetFading(false)
    descSmf:SetInsertMode("TOP")
    descSmf:SetMaxLines(500)
    descSmf:SetHyperlinksEnabled(true)
    descSmf:EnableMouse(true)
    descSmf:EnableMouseWheel(false)
    descSmf:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        if not pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
            GameTooltip:Hide()
            return
        end
        GameTooltip:Show()
    end)
    descSmf:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
    descSmf:SetScript("OnMouseWheel", descWheel)

    local descMeasure = descChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descMeasure:SetWidth(416)
    descMeasure:Hide()


    outer._descSmf = descSmf
    outer._descMeasure = descMeasure
    outer._descScroll = descScroll
    outer._descChild  = descChild
    outer._descBar    = descBar

    local deleteBtn = CreateFrame("Button", nil, outer, "UIPanelButtonTemplate")
    deleteBtn:SetSize(64, 20)
    deleteBtn:SetPoint("BOTTOMLEFT", outer, "BOTTOMLEFT", 10, 4)
    deleteBtn:SetText(L.DELETE)
    deleteBtn:SetScript("OnClick", function()
        local build = state.build
        if not build then return end
        local name = build.title or L.UNTITLED
        StaticPopupDialogs["EBONBUILDS_DELETE_BUILD"].text = string.format(L.DELETE_BUILD_CONFIRM, name)
        StaticPopup_Show("EBONBUILDS_DELETE_BUILD")
    end)
    outer._deleteBtn = deleteBtn

    return outer, descSmf, descMeasure, descScroll, descChild, descBar
end

local STAT_ROWS = {
    { key = "echoesSeen",    label = L.STAT_ECHOES_SEEN },
    { key = "runsCompleted", label = L.STAT_RUNS_COMPLETED },
    { key = "runsReset",     label = L.STAT_RUNS_RESET },
    { key = "picks",         label = L.STAT_PICKS },
    { key = "rerollsUsed",   label = L.STAT_REROLLS },
    { key = "banishesUsed",  label = L.STAT_BANISHES },
    { key = "freezesUsed",   label = L.STAT_FREEZES },
}

local function BuildStatsTab(parent)
    local y = -10

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    header:SetText(L.STATS_TITLE)

    y = y - 30
    local valueLabels = {}
    for i, row in ipairs(STAT_ROWS) do
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
        lbl:SetText(row.label .. ":")
        lbl:SetWidth(160)
        lbl:SetJustifyH("LEFT")

        local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        val:SetText("0")
        val:SetWidth(60)
        val:SetJustifyH("RIGHT")
        valueLabels[row.key] = val

        y = y - 22
    end


    local qy = -10
    local qHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    qHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 270, qy)
    qHeader:SetText(L.STATS_QUALITY)

    qy = qy - 26
    local qualityLabels = {}
    for q = 0, 3 do
        local qlbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        qlbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 274, qy)
        qlbl:SetText(QUALITY_LABELS[q] .. ":")
        qlbl:SetWidth(90)
        qlbl:SetJustifyH("LEFT")

        local qval = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        qval:SetPoint("LEFT", qlbl, "RIGHT", 4, 0)
        qval:SetText("0 (0%)")
        qval:SetWidth(80)
        qval:SetJustifyH("RIGHT")
        qualityLabels[q] = qval

        qy = qy - 18
    end

    return valueLabels, qualityLabels
end

local function BuildMissingTab(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT",     parent, "TOPLEFT",     10, -14)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -18, 8)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(460)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    local bar = CreateFrame("Slider", nil, scroll, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    -2, -4)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -2,  4)
    bar:SetValueStep(16)

    EbonBuilds.Widgets.WireScroll(scroll, child, bar, 16)

    return scroll, child, bar
end

local overviewOuter
local overviewDescSmf, overviewDescMeasure, overviewDescScroll, overviewDescChild, overviewDescBar
local statsValueLabels, statsQualityLabels
local missingScroll, missingChild, missingBar
local missingRows = {}
local function RefreshOverview()
    local build = state.build
    if not build then return end
    local cc = CLASS_COLORS[build.class] or { 0.5, 0.5, 0.5 }

    SetClassIcon(overviewOuter._classIcon, build.class)
    overviewOuter._nameLabel:SetText(build.title or L.UNTITLED)
    overviewOuter._nameLabel:SetTextColor(cc[1], cc[2], cc[3], 1)

    local specs = EbonBuilds.SpecData and EbonBuilds.SpecData[build.class]
    local specName = specs and specs[build.spec or 1] and specs[build.spec or 1].name or ""
    overviewOuter._metaLabel:SetText(string.format(L.BUILD_META,
        build.author or L.UNKNOWN,
        specName,
        build.lastModified or ""))

    local publicText = build.isPublic and L.STATUS_PUBLIC or L.STATUS_PRIVATE
    local validatedText
    if build.validated then
        validatedText = L.STATUS_VALIDATED
    elseif build.isPublic then
        validatedText = L.STATUS_NOT_VALIDATED
    else
        validatedText = ""
    end
    overviewOuter._statusLabel:SetText(publicText .. validatedText)

    overviewOuter._autoToggle:SetText(build.automationEnabled and L.AUTOMATION_ON or L.AUTOMATION_OFF)

    local desc = build.comments or ""
    overviewDescSmf:Clear()
    overviewDescSmf:AddMessage(desc, 0.8, 0.8, 0.8, 1.0)
    overviewDescMeasure:SetText(desc)

    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        local btn = overviewOuter._lockedButtons[i]
        local spellId = build.lockedEchoes and build.lockedEchoes[i]
        if spellId then
            btn._icon:SetTexture(select(3, GetSpellInfo(spellId)))
            btn._spellId = spellId
            btn:Show()
            local data = EbonBuilds.Catalog.Entry(spellId)
            local quality = data and data.quality or 0
            local bc = QUALITY_BORDER_COLORS[quality] or QUALITY_BORDER_COLORS[0]
            btn._border:SetTexture(bc[1], bc[2], bc[3])
            btn._border:Show()
        else
            btn._icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
            btn._spellId = nil
            btn._border:Hide()
            btn:Show()
        end
    end

    local textHeight = overviewDescMeasure:GetStringHeight() or 0
    overviewDescSmf:SetHeight(math.max(textHeight + 4, 14))
    overviewDescChild:SetHeight(math.max(textHeight + 6, overviewDescScroll:GetHeight()))
    overviewDescBar:SetMinMaxValues(0, math.max(0, overviewDescChild:GetHeight() - overviewDescScroll:GetHeight()))
end

local QUALITY_COLORS = EbonBuilds.Const.QUALITY_RGB

local function RefreshStats()
    local build = state.build
    if not build or not statsValueLabels then return end
    local st = build.stats or {}
    for _, row in ipairs(STAT_ROWS) do
        if statsValueLabels[row.key] then
            statsValueLabels[row.key]:SetText(tostring(st[row.key] or 0))
        end
    end
    for q = 0, 3 do
        if statsQualityLabels[q] then
            local count = (st.qualityPicks or {})[q] or 0
            local total = st.picks or 0
            local pct = total > 0 and math.floor(count / total * 100) or 0
            statsQualityLabels[q]:SetText(string.format("%d (%d%%)", count, pct))
        end
    end
end

local function CreateMissingRow()
    local btn = CreateFrame("Button", nil, missingChild)
    btn:SetPoint("LEFT", missingChild, "LEFT", 4, 0)
    btn:SetPoint("RIGHT", missingChild, "RIGHT", -4, 0)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnEnter", function(self)
        if not self._spellId then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        local spellName = GetSpellInfo(self._spellId)
        if spellName then
            GameTooltip:AddLine(spellName, 1, 0.82, 0)
        end
        if utils and utils.GetSpellDescription then
            local desc = utils.GetSpellDescription(self._spellId, 500, 1)
            if desc and desc ~= "" then
                GameTooltip:AddLine(desc, 1, 1, 1, true)
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(24)
    icon:SetHeight(24)
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn._icon = icon

    local labelName = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
    labelName:SetWidth(160)
    labelName:SetJustifyH("LEFT")
    btn._labelName = labelName

    local labelSource = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelSource:SetPoint("TOPLEFT", labelName, "TOPRIGHT", 4, 0)
    labelSource:SetWidth(200)
    labelSource:SetJustifyH("LEFT")
    labelSource:SetTextColor(0.6, 0.6, 0.6, 1)
    btn._labelSource = labelSource

    local labelScore = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelScore:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -4, -2)
    labelScore:SetWidth(54)
    labelScore:SetJustifyH("RIGHT")
    btn._labelScore = labelScore

    return btn
end

local function RefreshMissing()
    local build = state.build
    if not build or not missingChild then return end
    for _, btn in ipairs(missingRows) do btn:Hide() end
    local missing = ComputeMissingEchoes(build)
    if missing == nil then
        missingChild.loadingLabel = missingChild.loadingLabel or missingChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        missingChild.loadingLabel:SetPoint("TOPLEFT", missingChild, "TOPLEFT", 4, -2)
        missingChild.loadingLabel:SetText(L.REQUESTING_DATA)
        missingChild.loadingLabel:Show()
        missingChild:SetHeight(20)
        return
    end
    if missingChild.loadingLabel then
        missingChild.loadingLabel:Hide()
    end
    local currY = 0
    for rowIdx, entry in ipairs(missing) do
        if not missingRows[rowIdx] then
            missingRows[rowIdx] = CreateMissingRow()
        end
        local btn = missingRows[rowIdx]
        btn:ClearAllPoints()
        btn._spellId = entry.spellId
        btn._icon:SetTexture(select(3, GetSpellInfo(entry.spellId)))
        local cc = QUALITY_COLORS[entry.quality] or QUALITY_COLORS[0]
        btn._labelName:SetText(entry.name)
        btn._labelName:SetTextColor(cc[1], cc[2], cc[3], 1)
        local cleanSource = (entry.dropSource or ""):gsub("^Can be found on ", "")
        btn._labelSource:SetText(cleanSource)
        btn._labelScore:SetText(string.format("%.0f", entry.score))
        local srcH = btn._labelSource:GetStringHeight() or 16
        local rowH = math.max(26, srcH + 4)
        btn:SetHeight(rowH)
        btn:SetPoint("TOPLEFT", missingChild, "TOPLEFT", 0, -currY)
        btn:SetPoint("RIGHT", missingChild, "RIGHT", -4, 0)
        btn:Show()
        currY = currY + rowH + 2
    end
    missingChild:SetHeight(math.max(1, currY))
    missingBar:SetMinMaxValues(0, math.max(0, missingChild:GetHeight() - missingScroll:GetHeight()))
end

local switchOverview, switchStats, switchMissing, switchLogbook

local function BuildViewFrame()
    local f = CreateFrame("Frame", "EbonBuildsBuildOverview", UIParent)

    local box = CreateFrame("Frame", nil, f)
    box:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -24)
    box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,  10)
    box:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    box:SetBackdropColor(0, 0, 0, 0.6)
    box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    contentArea = CreateFrame("Frame", nil, box)
    contentArea:SetPoint("TOPLEFT",     box, "TOPLEFT",     6, -6)
    contentArea:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -6,  6)

    overviewOuter, overviewDescSmf, overviewDescMeasure, overviewDescScroll, overviewDescChild, overviewDescBar = BuildOverviewTab(contentArea)

    local statsParent = CreateFrame("Frame", nil, contentArea)
    statsParent:SetAllPoints(contentArea)
    statsParent:Hide()
    statsValueLabels, statsQualityLabels = BuildStatsTab(statsParent)

    local missingParent = CreateFrame("Frame", nil, contentArea)
    missingParent:SetAllPoints(contentArea)
    missingParent:Hide()
    missingScroll, missingChild, missingBar = BuildMissingTab(missingParent)

    local logbookParent = CreateFrame("Frame", nil, contentArea)
    logbookParent:SetAllPoints(contentArea)
    logbookParent:Hide()

    local function HideAllContent()
        overviewOuter:Hide()
        statsParent:Hide()
        missingParent:Hide()
        logbookParent:Hide()
        if EbonBuilds.SessionHistory and EbonBuilds.SessionHistory.Hide then
            EbonBuilds.SessionHistory.Hide()
        end
    end

    switchOverview = function()
        HideAllContent()
        overviewOuter:Show()
        overviewOuter._deleteBtn:Show()
        PanelTemplates_SetTab(f, 1)
        PanelTemplates_EnableTab(f, 2)
        PanelTemplates_EnableTab(f, 3)
        PanelTemplates_EnableTab(f, 4)
        RefreshOverview()
    end

    switchStats = function()
        HideAllContent()
        overviewOuter._deleteBtn:Hide()
        statsParent:Show()
        PanelTemplates_SetTab(f, 2)
        PanelTemplates_EnableTab(f, 1)
        PanelTemplates_EnableTab(f, 3)
        PanelTemplates_EnableTab(f, 4)
        RefreshStats()
    end

    switchMissing = function()
        HideAllContent()
        overviewOuter._deleteBtn:Hide()
        missingParent:Show()
        PanelTemplates_SetTab(f, 3)
        PanelTemplates_EnableTab(f, 1)
        PanelTemplates_EnableTab(f, 2)
        PanelTemplates_EnableTab(f, 4)
        RefreshMissing()
    end

    switchLogbook = function()
        HideAllContent()
        overviewOuter._deleteBtn:Hide()
        logbookParent:Show()
        PanelTemplates_SetTab(f, 4)
        PanelTemplates_EnableTab(f, 1)
        PanelTemplates_EnableTab(f, 2)
        PanelTemplates_EnableTab(f, 3)
        EbonBuilds.SessionHistory.Show(logbookParent)
    end

    tab1 = CreateFrame("Button", "EbonBuildsBuildOverviewTab1", f, "OptionsFrameTabButtonTemplate")
    tab1:SetID(1)
    tab1:SetText(L.TAB_OVERVIEW)
    tab1:SetPoint("TOPLEFT", f, "TOPLEFT", 10, 0)
    PanelTemplates_TabResize(tab1, 0)
    tab1:SetScript("OnClick", function() if switchOverview then switchOverview() end end)

    tab2 = CreateFrame("Button", "EbonBuildsBuildOverviewTab2", f, "OptionsFrameTabButtonTemplate")
    tab2:SetID(2)
    tab2:SetText(L.TAB_STATS)
    tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
    PanelTemplates_TabResize(tab2, 0)
    tab2:SetScript("OnClick", function() if switchStats then switchStats() end end)

    tab3 = CreateFrame("Button", "EbonBuildsBuildOverviewTab3", f, "OptionsFrameTabButtonTemplate")
    tab3:SetID(3)
    tab3:SetText(L.TAB_MISSING)
    tab3:SetPoint("LEFT", tab2, "RIGHT", -16, 0)
    PanelTemplates_TabResize(tab3, 0)
    tab3:SetScript("OnClick", function() if switchMissing then switchMissing() end end)

    tab4 = CreateFrame("Button", "EbonBuildsBuildOverviewTab4", f, "OptionsFrameTabButtonTemplate")
    tab4:SetID(4)
    tab4:SetText(L.TAB_LOGBOOK)
    tab4:SetPoint("LEFT", tab3, "RIGHT", -16, 0)
    PanelTemplates_TabResize(tab4, 0)
    tab4:SetScript("OnClick", function() if switchLogbook then switchLogbook() end end)

    PanelTemplates_SetNumTabs(f, 4)
    PanelTemplates_SetTab(f, 1)

    return f
end

local view = {}

function view.Show(container, context)
    EbonBuilds.Widgets.Attach(viewFrame, container)

    context = context or {}
    state.build = context.build
    if switchOverview then switchOverview() end
    viewFrame:Show()
end

function view.Hide()
    if EbonBuilds.SessionHistory and EbonBuilds.SessionHistory.Hide then
        EbonBuilds.SessionHistory.Hide()
    end
    if viewFrame then viewFrame:Hide() end
end

function EbonBuilds.BuildOverview.Init()
    viewFrame = BuildViewFrame()
    viewFrame:Hide()
    EbonBuilds.ViewRouter.Register("buildOverview", view)
end
