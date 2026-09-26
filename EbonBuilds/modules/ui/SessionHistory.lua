EbonBuilds.SessionHistory = {}

local L = EbonBuilds.L

local QUALITY_HEX = EbonBuilds.Const.QUALITY_HEX
local ACTION_COLORS = {
    Banish         = { 1.0, 0.27, 0.27 },
    Reroll         = { 0.27, 0.67, 1.0 },
    Freeze         = { 0.27, 0.80, 1.0 },
    Select         = { 0.27, 1.0, 0.27 },
    ["Select (Locked)"] = { 1.0, 0.53, 0.0 },
}

local CARD_W     = 170
local CARD_H     = 48
local CARD_GAP   = 6
local CARD_STEP  = CARD_W + CARD_GAP
local TOP_H      = 68

local topPanel, bottomPanel
local sessionItems   = {}
local sortedSessions = {}
local logRows      = {}
local selectedSessionId = nil

local sessionChild, sessionClip, scrollOffset = nil, nil, 0
local logScroll, logChild, logBar
local durationTicker
local refreshTimer
local deferTimer

local function FormatDuration(startTime, endTime)
    local t = (endTime or time()) - startTime
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = math.floor(t % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local FormatScore = EbonBuilds.Widgets.FormatScore

local function FormatTimestamp(ts)
    return date("%H:%M:%S", ts)
end

local function ChoiceName(ch)
    return ch.name or (ch.id and GetSpellInfo(ch.id)) or "?"
end

local function ChoiceQuality(ch)
    if ch.quality then return ch.quality end
    local data = ch.id and EbonBuilds.Catalog.Entry(ch.id)
    return (data and data.quality) or 0
end

local activeSessionCard = nil

local function OnDurationTick(self, dt)
    self._elapsed = (self._elapsed or 0) + dt
    if self._elapsed < 1 then return end
    self._elapsed = 0

    if not (activeSessionCard and activeSessionCard._isActive) then
        activeSessionCard = nil
        self:Hide()
        return
    end
    activeSessionCard._durationLabel:SetText(FormatDuration(activeSessionCard._startTime, nil))
end

local function SelectSession(id)
    selectedSessionId = id
    for _, item in ipairs(sessionItems) do
        if item._id == id then
            item:SetBackdropBorderColor(1.0, 0.84, 0.0, 1)
        else
            local isActive = item._isActive
            item:SetBackdropBorderColor(isActive and 0.27 or 0.4, isActive and 1.0 or 0.4, isActive and 0.27 or 0.4, 1)
        end
    end
    EbonBuilds.SessionHistory.RefreshLogView()
end

local function BuildCard(parent)
    local item = CreateFrame("Frame", nil, parent)
    item:SetSize(CARD_W, CARD_H)

    item:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    item:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    item:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    item:EnableMouse(true)

    item._levelLabel = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item._levelLabel:SetPoint("TOPLEFT", item, "TOPLEFT", 6, -4)
    item._levelLabel:SetPoint("RIGHT", item, "RIGHT", -6, 0)
    item._levelLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    item._soulLabel = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item._soulLabel:SetPoint("TOPLEFT", item._levelLabel, "BOTTOMLEFT", 0, -2)
    item._soulLabel:SetPoint("RIGHT", item, "RIGHT", -6, 0)
    item._soulLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    item._durationLabel = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item._durationLabel:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 6, 4)
    item._durationLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    local delBtn = CreateFrame("Button", nil, item)
    delBtn:SetSize(14, 14)
    delBtn:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -6, 4)
    delBtn:SetNormalFontObject("GameFontHighlightSmall")
    delBtn:SetText("|cff888888X|r")
    delBtn:SetScript("OnClick", function()
        if item._id then
            StaticPopupDialogs["EBONBUILDS_DELETE_SESSION"] = {
                text = L.DELETE_SESSION_CONFIRM,
                button1 = L.YES, button2 = L.NO,
                OnAccept = function()
                    EbonBuilds.Session.DeleteSession(item._id)
                    selectedSessionId = nil
                    EbonBuilds.SessionHistory.RefreshSessionList()
                    EbonBuilds.SessionHistory.RefreshLogView()
                end,
                timeout = 0, whileDead = true, hideOnEscape = true,
            }
            StaticPopup_Show("EBONBUILDS_DELETE_SESSION")
        end
    end)
    item._delBtn = delBtn

    item:SetScript("OnMouseDown", function()
        if item._id then SelectSession(item._id) end
    end)

    item:Hide()
    return item
end

local function PopulateCard(item, s, index)
    local isActive = (s.endTime == nil)
    item._id        = s.id
    item._isActive  = isActive
    item._startTime = s.startTime
    item:ClearAllPoints()
    item:SetPoint("TOPLEFT", sessionChild, "TOPLEFT", 4 + (index - 1) * CARD_STEP, -2)
    item:SetSize(CARD_W, CARD_H)

    if isActive then
        item:SetBackdropBorderColor(0.27, 1.0, 0.27, 1)
        item._levelLabel:SetText(L.CARD_ACTIVE:format(s.maxLevel or UnitLevel("player")))
        item._durationLabel:SetText(FormatDuration(s.startTime, nil))
        item._delBtn:Hide()
    else
        item:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        item._levelLabel:SetText(L.CARD_LEVEL:format(s.maxLevel or UnitLevel("player")))
        item._durationLabel:SetText(FormatDuration(s.startTime, s.endTime))
        item._delBtn:Show()
    end
    item._levelLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    item._soulLabel:SetText(L.CARD_ASHES:format(isActive and "..." or tostring(s.soulAshes)))

    if s.id == selectedSessionId then
        item:SetBackdropBorderColor(1.0, 0.84, 0.0, 1)
    end
    item:Show()
end

local function RenderCards()
    if not sessionChild then return end
    local clipW = sessionClip:GetWidth() or 0
    if clipW <= 0 then clipW = 520 end
    local first   = math.floor(scrollOffset / CARD_STEP) + 1
    local visible = math.ceil(clipW / CARD_STEP) + 1

    local activeCard = nil
    for poolIdx = 1, visible do
        local index = first + poolIdx - 1
        local s = sortedSessions[index]
        local item = sessionItems[poolIdx]
        if s then
            if not item then
                item = BuildCard(sessionChild)
                sessionItems[poolIdx] = item
            end
            PopulateCard(item, s, index)
            if item._isActive then activeCard = item end
        elseif item then
            item:Hide()
        end
    end
    for i = visible + 1, #sessionItems do sessionItems[i]:Hide() end

    activeSessionCard = activeCard
    if durationTicker then
        if activeCard then
            durationTicker._elapsed = 0
            durationTicker:Show()
        else
            durationTicker:Hide()
        end
    end
end

function EbonBuilds.SessionHistory.RefreshSessionList()
    if not sessionChild then return end

    local sessions = EbonBuilds.Session.GetSessions()
    local activeSession = EbonBuilds.Session.GetActiveSession()

    for i = #sortedSessions, 1, -1 do sortedSessions[i] = nil end
    for i = 1, #sessions do sortedSessions[i] = sessions[i] end
    table.sort(sortedSessions, function(a, b)
        if a == b then return false end
        if a == activeSession then return true end
        if b == activeSession then return false end
        return (a.startTime or 0) > (b.startTime or 0)
    end)

    if not selectedSessionId and activeSession then
        selectedSessionId = activeSession.id
    end

    local width = 4 + #sortedSessions * CARD_STEP
    sessionChild:SetWidth(math.max(width, 1))
    local maxScroll = math.max(0, width - (sessionClip:GetWidth() or 0))
    if scrollOffset > maxScroll then scrollOffset = maxScroll end
    sessionChild:SetPoint("TOPLEFT", sessionClip, "TOPLEFT", -scrollOffset, -2)

    RenderCards()
end

local function ClearLogRows()
    for _, row in ipairs(logRows) do
        row:Hide()
    end
    if logChild and logChild._noticeFs then logChild._noticeFs:Hide() end
end

local function SummaryText(session)
    local sum = session.logSummary
    if not sum then return nil end
    local order = { "Select", "Freeze", "Banish", "Reroll", "Select (Locked)" }
    local parts = {}
    for _, action in ipairs(order) do
        local n = sum.actions and sum.actions[action]
        if n then parts[#parts + 1] = string.format("%s %d", L.ACTION[action] or action, n) end
    end
    for action, n in pairs(sum.actions or {}) do
        local known = false
        for _, a in ipairs(order) do if a == action then known = true end end
        if not known then parts[#parts + 1] = string.format("%s %d", L.ACTION[action] or action, n) end
    end
    local out = {
        L.LOG_NO_DETAIL,
        string.format(L.LOG_DECISIONS, sum.decisions or 0,
            table.concat(parts, ", ")),
        string.format(L.LOG_CHARGES_END,
            sum.ban or 0, sum.reroll or 0, sum.freeze or 0),
    }
    return table.concat(out, "\n")
end

local TIME_W    = 46
local ACTION_W  = 52
local ECHO_W    = 94
local SCORE_W   = 32
local CHARGES_W = 66
local MAX_ECHO_COLS = 4

local function BuildLogRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(16)

    local timeFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeFs:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -1)
    timeFs:SetWidth(TIME_W)
    row._timeFs = timeFs

    local actionFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    actionFs:SetPoint("LEFT", timeFs, "RIGHT", 3, 0)
    actionFs:SetWidth(ACTION_W)
    row._actionFs = actionFs

    row._echoFrames = {}
    row._echoNameFonts  = {}
    row._echoScoreFonts = {}
    local echoAnchor = actionFs
    for i = 1, MAX_ECHO_COLS do
        local echoFrame = CreateFrame("Frame", nil, row)
        echoFrame:SetHeight(14)
        echoFrame:SetWidth(ECHO_W)
        echoFrame:SetPoint("LEFT", echoAnchor, "RIGHT", 3, 0)
        echoFrame:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        echoFrame:SetBackdropBorderColor(0, 0, 0, 0)
        echoFrame:EnableMouse(true)

        local scoreFont = echoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        scoreFont:SetPoint("TOPRIGHT", echoFrame, "TOPRIGHT", -4, -2)
        scoreFont:SetPoint("BOTTOMRIGHT", echoFrame, "BOTTOMRIGHT", -4, 2)
        scoreFont:SetWidth(SCORE_W)
        scoreFont:SetJustifyH("RIGHT")

        local nameFont = echoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameFont:SetPoint("TOPLEFT", echoFrame, "TOPLEFT", 4, -2)
        nameFont:SetPoint("RIGHT", scoreFont, "LEFT", -2, 0)
        nameFont:SetJustifyH("LEFT")

        echoFrame:SetScript("OnEnter", function(self)
            if self._echoName then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self._echoName, 1, 1, 1)
                if self._echoScore then
                    GameTooltip:AddLine(string.format(L.SCORE, FormatScore(self._echoScore)), 0.7, 0.7, 0.7)
                end
                GameTooltip:Show()
            end
        end)
        echoFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row._echoFrames[i]      = echoFrame
        row._echoNameFonts[i]   = nameFont
        row._echoScoreFonts[i]  = scoreFont
        echoAnchor = echoFrame
    end

    local chargesFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chargesFs:SetPoint("LEFT", echoAnchor, "RIGHT", 3, 0)
    chargesFs:SetWidth(CHARGES_W)
    chargesFs:SetJustifyH("LEFT")
    row._chargesFs = chargesFs

    row:Hide()
    return row
end

local ROW_H = 18

local logEntries = {}

local function VisibleLogRows()
    local h = logScroll and logScroll:GetHeight() or 0
    if h <= 0 then h = 200 end
    return math.ceil(h / ROW_H) + 2
end

local function PopulateLogRow(row, listIdx, entry)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", logChild, "TOPLEFT", 0, -(listIdx - 1) * ROW_H)
    row:SetPoint("RIGHT",   logChild, "RIGHT",   0, 0)
    row:SetHeight(ROW_H)

    row._timeFs:SetText(("|cff888888%s|r"):format(FormatTimestamp(entry.timestamp)))

    local ac = ACTION_COLORS[entry.action] or { 1, 1, 1 }
    local acHex = string.format("%02x%02x%02x",
        math.floor(ac[1] * 255), math.floor(ac[2] * 255), math.floor(ac[3] * 255))
    row._actionFs:SetText(("|cff%s%s|r"):format(acHex, L.ACTION[entry.action] or entry.action))

    local choices = entry.choices or {}
    for j = 1, MAX_ECHO_COLS do
        local ch         = choices[j]
        local echoFrame  = row._echoFrames[j]
        local nameFont   = row._echoNameFonts[j]
        local scoreFont  = row._echoScoreFonts[j]

        if ch then
            local hex = QUALITY_HEX[ChoiceQuality(ch)] or "ffffff"
            local name = ChoiceName(ch)
            nameFont:SetText(("|cff%s%s|r"):format(hex, name))
            scoreFont:SetText(("|cff%s(%s)|r"):format(hex, FormatScore(ch.score)))
            echoFrame._echoName  = name
            echoFrame._echoScore = ch.score
            if j == entry.targetIndex then
                echoFrame:SetBackdropBorderColor(ac[1], ac[2], ac[3], 1)
            else
                echoFrame:SetBackdropBorderColor(0, 0, 0, 0)
            end
        else
            nameFont:SetText("")
            scoreFont:SetText("")
            echoFrame._echoName  = nil
            echoFrame._echoScore = nil
            echoFrame:SetBackdropBorderColor(0, 0, 0, 0)
        end
        echoFrame:Show()
    end

    local ch = entry.charges or {}
    row._chargesFs:SetText(("|cff888888B:%d R:%d F:%d|r"):format(
        ch.ban or 0, ch.reroll or 0, ch.freeze or 0))

    row:Show()
end

local function RenderLogRows()
    if not logChild then return end
    local offset  = math.floor((logBar and logBar:GetValue() or 0) / ROW_H)
    local visible = VisibleLogRows()

    for poolIdx = 1, visible do
        local listIdx = offset + poolIdx
        local entry   = logEntries[listIdx]
        if entry then
            if not logRows[poolIdx] then logRows[poolIdx] = BuildLogRow(logChild) end
            PopulateLogRow(logRows[poolIdx], listIdx, entry)
        elseif logRows[poolIdx] then
            logRows[poolIdx]:Hide()
        end
    end
    for i = visible + 1, #logRows do logRows[i]:Hide() end
end

EbonBuilds.SessionHistory._RenderLogRows = RenderLogRows

function EbonBuilds.SessionHistory.RefreshLogView()
    ClearLogRows()
    logEntries = {}

    if not logScroll or not logChild then return end
    logChild:SetWidth(math.max(logScroll:GetWidth() or 0, 450))

    local prevSessionId = logChild._sessionId
    local sessionSwitched = (selectedSessionId ~= prevSessionId)

    local function ShowNothing()
        logChild:SetHeight(1)
        logChild._sessionId = nil
        if logBar then logBar:SetMinMaxValues(0, 0) end
    end

    if not selectedSessionId then return ShowNothing() end

    local sessions = EbonBuilds.Session.GetSessions()
    local session
    for _, s in ipairs(sessions) do
        if s.id == selectedSessionId then session = s; break end
    end
    if not session then return ShowNothing() end

    logChild._sessionId = selectedSessionId

    local savedScroll = logBar and logBar:GetValue() or 0
    if sessionSwitched and logBar then
        savedScroll = 0
        logBar:SetValue(0)
    end

    logEntries = session.logs or {}

    if not logChild._noticeFs then
        local fs = logChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", logChild, "TOPLEFT", 6, -6)
        fs:SetJustifyH("LEFT")
        logChild._noticeFs = fs
    end
    local notice = (#logEntries == 0) and SummaryText(session) or nil
    if notice then
        logChild._noticeFs:SetText(notice)
        logChild._noticeFs:Show()
    else
        logChild._noticeFs:Hide()
    end

    local totalH = math.max(#logEntries * ROW_H + 4, logScroll:GetHeight())
    if notice then
        totalH = math.max(totalH, logChild._noticeFs:GetStringHeight() + 16)
    end
    logChild:SetHeight(totalH)
    if logBar then
        local mx = math.max(0, totalH - logScroll:GetHeight())
        logBar:SetMinMaxValues(0, mx)
        if not sessionSwitched then
            logBar:SetValue(math.min(savedScroll, mx))
        end
    end

    RenderLogRows()
end

local exportDialog

local function BuildExportDialog()
    local f = CreateFrame("Frame", "EbonBuildsExportDialog", UIParent)
    f:SetSize(800, 550)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnHide", function(self) self:StopMovingOrSizing() end)
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -12)
    title:SetText(L.EXPORT_SESSION_TITLE)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -8)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 10)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetTextInsets(6, 6, 4, 4)
    editBox:SetAutoFocus(false)
    scroll:SetScrollChild(editBox)

    local bar = CreateFrame("Slider", nil, scroll, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -2, -4)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -2, 4)
    bar:SetValueStep(18)

    EbonBuilds.Widgets.WireScroll(scroll, editBox, bar, 18)

    f._editBox = editBox
    f._scroll  = scroll
    f._bar     = bar

    return f
end

function EbonBuilds.SessionHistory.ExportSession()
    if not exportDialog then
        exportDialog = BuildExportDialog()
    end

    local session
    if selectedSessionId then
        for _, s in ipairs(EbonBuilds.Session.GetSessions()) do
            if s.id == selectedSessionId then session = s; break end
        end
    end

    if not session then
        exportDialog._editBox:SetText(L.NO_SESSION_SELECTED)
        exportDialog._editBox:SetWidth(exportDialog._scroll:GetWidth() - 12)
        exportDialog._editBox:SetHeight(40)
    else
        local lines = {}
        lines[#lines + 1] = string.format(L.EXPORT_SESSION_HEADER,
            session.maxLevel or UnitLevel("player"),
            FormatDuration(session.startTime, session.endTime),
            session.soulAshes or 0)
        lines[#lines + 1] = ""

        local logs = session.logs or {}
        if #logs == 0 and session.logSummary then
            local sum = session.logSummary
            lines[#lines + 1] = string.format(
                L.EXPORT_NO_DETAIL, sum.decisions or 0)
            for action, n in pairs(sum.actions or {}) do
                lines[#lines + 1] = string.format("  %-16s %d", L.ACTION[action] or action, n)
            end
            lines[#lines + 1] = string.format(L.EXPORT_CHARGES_END,
                sum.ban or 0, sum.reroll or 0, sum.freeze or 0)
        end
        for _, entry in ipairs(logs) do
            local parts = {}
            parts[#parts + 1] = FormatTimestamp(entry.timestamp)
            parts[#parts + 1] = string.format("%-16s", L.ACTION[entry.action] or entry.action)

            for j, ch in ipairs(entry.choices) do
                local text = string.format("%s (%s)", ChoiceName(ch), FormatScore(ch.score))
                if j == entry.targetIndex then
                    text = ">>" .. text .. "<<"
                end
                parts[#parts + 1] = string.format("%-34s", text)
            end

            local ch = entry.charges or {}
            parts[#parts + 1] = string.format("B:%d  R:%d  F:%d",
                ch.ban or 0, ch.reroll or 0, ch.freeze or 0)

            lines[#lines + 1] = table.concat(parts, "")
        end

        local text = table.concat(lines, "\n")
        exportDialog._editBox:SetText(text)

        local editW = exportDialog._scroll:GetWidth() - 12
        exportDialog._editBox:SetWidth(editW)
        local lineCount = #lines + 1
        local estH = math.max(lineCount * 14 + 12, exportDialog._scroll:GetHeight())
        exportDialog._editBox:SetHeight(estH)
        exportDialog._bar:SetMinMaxValues(0, math.max(0, estH - exportDialog._scroll:GetHeight()))
    end

    exportDialog:Show()
end

local function ScrollCards(delta)
    local childW = sessionChild:GetWidth() or 0
    local clipW  = sessionClip:GetWidth() or 1
    local maxScroll = childW - clipW
    if maxScroll <= 0 then
        scrollOffset = 0
    else
        scrollOffset = math.max(0, math.min(maxScroll, scrollOffset + delta * 30))
    end
    sessionChild:SetPoint("TOPLEFT", sessionClip, "TOPLEFT", -scrollOffset, -2)
    RenderCards()
end

local function RefreshAll()
    logChild:SetWidth(math.max(logScroll:GetWidth() or 0, 450))
    EbonBuilds.SessionHistory.RefreshSessionList()
    EbonBuilds.SessionHistory.RefreshLogView()
end

local function BuildUI(container)
    topPanel = CreateFrame("Frame", nil, container)
    topPanel:SetPoint("TOPLEFT",     container, "TOPLEFT",  0, -4)
    topPanel:SetPoint("TOPRIGHT",    container, "TOPRIGHT", 0,  0)
    topPanel:SetHeight(TOP_H)

    durationTicker = CreateFrame("Frame", nil, topPanel)
    if EbonBuilds.api then EbonBuilds.api:Track("Logbook duration", durationTicker) end
    durationTicker:SetScript("OnUpdate", OnDurationTick)
    durationTicker:Hide()

    local topHeader = topPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    topHeader:SetPoint("TOPLEFT", topPanel, "TOPLEFT", 4, -2)
    topHeader:SetText(L.LOGBOOK_HINT)

    local exportBtn = CreateFrame("Button", nil, topPanel)
    exportBtn:SetSize(60, 18)
    exportBtn:SetPoint("TOPRIGHT", topPanel, "TOPRIGHT", -110, -2)
    exportBtn:SetNormalFontObject("GameFontHighlightSmall")
    exportBtn:SetText(L.EXPORT)
    exportBtn:SetScript("OnClick", function()
        EbonBuilds.SessionHistory.ExportSession()
    end)

    local clearBtn = CreateFrame("Button", nil, topPanel)
    clearBtn:SetSize(100, 18)
    clearBtn:SetPoint("TOPRIGHT", topPanel, "TOPRIGHT", -4, -2)
    clearBtn:SetNormalFontObject("GameFontHighlightSmall")
    clearBtn:SetText(L.CLEAR_ALL)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("EBONBUILDS_CLEAR_SESSIONS")
    end)

    local scrollLeft = CreateFrame("Button", nil, topPanel)
    scrollLeft:SetSize(16, CARD_H)
    scrollLeft:SetPoint("BOTTOMLEFT", topPanel, "BOTTOMLEFT", 2, 0)
    scrollLeft:SetNormalFontObject("GameFontNormal")
    scrollLeft:SetText("|cff888888<|r")
    scrollLeft:SetScript("OnMouseDown", function() ScrollCards(-1) end)

    local scrollRight = CreateFrame("Button", nil, topPanel)
    scrollRight:SetSize(16, CARD_H)
    scrollRight:SetPoint("BOTTOMRIGHT", topPanel, "BOTTOMRIGHT", -2, 0)
    scrollRight:SetNormalFontObject("GameFontNormal")
    scrollRight:SetText("|cff888888>|r")
    scrollRight:SetScript("OnMouseDown", function() ScrollCards(1) end)

    sessionClip = CreateFrame("ScrollFrame", nil, topPanel)
    sessionClip:SetPoint("TOP",    topHeader,   "BOTTOM",   0, -4)
    sessionClip:SetPoint("BOTTOM", topPanel,    "BOTTOM",   0,  2)
    sessionClip:SetPoint("LEFT",   scrollLeft,  "RIGHT",    2,  0)
    sessionClip:SetPoint("RIGHT",  scrollRight, "LEFT",    -2,  0)
    sessionClip:EnableMouse(true)
    sessionClip:EnableMouseWheel(true)
    sessionClip:SetScript("OnMouseWheel", function(self, delta) ScrollCards(delta) end)

    sessionChild = CreateFrame("Frame", nil, sessionClip)
    sessionChild:SetPoint("TOPLEFT", sessionClip, "TOPLEFT", 0, -2)
    sessionChild:SetHeight(CARD_H)
    sessionClip:SetScrollChild(sessionChild)

    bottomPanel = CreateFrame("Frame", nil, container)
    bottomPanel:SetPoint("TOPLEFT",     topPanel, "BOTTOMLEFT", 0, -6)
    bottomPanel:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 4)

    local logHeader = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    logHeader:SetPoint("TOPLEFT", bottomPanel, "TOPLEFT", 4, -2)
    logHeader:SetText(L.LOGBOOK_HEADER)

    logScroll = CreateFrame("ScrollFrame", nil, bottomPanel)
    logScroll:SetPoint("TOPLEFT",     logHeader, "BOTTOMLEFT", 0, -4)
    logScroll:SetPoint("BOTTOMRIGHT", bottomPanel, "BOTTOMRIGHT", -2, 2)

    logChild = CreateFrame("Frame", nil, logScroll)
    logScroll:SetScrollChild(logChild)

    logBar = CreateFrame("Slider", nil, logScroll, "UIPanelScrollBarTemplate")
    logBar:SetPoint("TOPLEFT",    logScroll, "TOPRIGHT",    -2, -4)
    logBar:SetPoint("BOTTOMLEFT", logScroll, "BOTTOMRIGHT", -2,  4)
    logBar:SetValueStep(20)
    EbonBuilds.Widgets.WireScroll(logScroll, logChild, logBar, 20, RenderLogRows)
    logScroll:SetScript("OnSizeChanged", function()
        logChild:SetWidth(math.max(logScroll:GetWidth() or 0, 450))
        RenderLogRows()
    end)

    refreshTimer = EbonBuilds.Timer.New("Logbook refresh")
    deferTimer   = EbonBuilds.Timer.New("Logbook first draw")
end

function EbonBuilds.SessionHistory.Show(container)
    local firstBuild = not topPanel
    if firstBuild then BuildUI(container) end

    topPanel:SetParent(container)
    bottomPanel:SetParent(container)
    topPanel:Show()
    bottomPanel:Show()

    if firstBuild then
        EbonBuilds.Timer.Arm(deferTimer, 0, RefreshAll)
    else
        RefreshAll()
    end
end

function EbonBuilds.SessionHistory.Hide()
    if topPanel    then topPanel:Hide()    end
    if bottomPanel then bottomPanel:Hide() end
    if exportDialog then exportDialog:Hide() end
    activeSessionCard = nil
    if deferTimer   then EbonBuilds.Timer.Cancel(deferTimer)   end
    if refreshTimer then EbonBuilds.Timer.Cancel(refreshTimer) end
end

local function OnSessionChanged()
    if refreshTimer and topPanel and topPanel:IsVisible() then
        EbonBuilds.Timer.Arm(refreshTimer, 0.2, RefreshAll)
    end
end

function EbonBuilds.SessionHistory.Init()
    EbonBuilds.Events.On("EB_SESSION_CHANGED", OnSessionChanged, "Logbook")

    StaticPopupDialogs["EBONBUILDS_CLEAR_SESSIONS"] = {
        text = L.CLEAR_SESSIONS_CONFIRM,
        button1 = L.YES, button2 = L.NO,
        OnAccept = function()
            EbonBuilds.Session.ClearAllSessions()
            selectedSessionId = nil
            EbonBuilds.SessionHistory.RefreshSessionList()
            EbonBuilds.SessionHistory.RefreshLogView()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end
