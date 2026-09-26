EbonBuilds.Toast = {}

local L = EbonBuilds.L

local TOAST_W  = 520
local TOAST_H  = 72
local LIVE_PAD = 26
local function GetToastDuration()
    return (EbonBuildsDB.globalSettings and EbonBuildsDB.globalSettings.toastDuration) or 3
end
local QUALITY_HEX = EbonBuilds.Const.QUALITY_HEX

local queue   = {}
local frame
local elapsed = 0
local hovered = false
local header, echoLine, footerLine

local function GetRunInfo()
    local level = 0
    local perks = EbonAPI.Ebonhold.Perks()
    if perks and perks.GetRollsDebugInfo then
        local choiceLevel = perks.GetRollsDebugInfo()
        if choiceLevel then level = choiceLevel end
    end
    if level == 0 then
        level = UnitLevel("player") or 0
    end

    local rd = EbonAPI.State.GetRun()
    local banRemain    = (rd and rd.remainingBanishes) or 0
    local totalRerolls = (rd and rd.totalRerolls) or 0
    local usedRerolls  = (rd and rd.usedRerolls) or 0
    local totalFreezes = (rd and rd.totalFreezes) or 0
    local usedFreezes  = (rd and rd.usedFreezes) or 0
    return level, banRemain, totalRerolls - usedRerolls, totalFreezes - usedFreezes
end

local FormatScore = EbonBuilds.Widgets.FormatScore

local function ClearLines()
    header:SetText("")
    echoLine:SetText("")
    footerLine:SetText("")
end

local function ShowNext()
    ClearLines()
    if #queue == 0 then
        frame:Hide()
        return
    end

    local entry = table.remove(queue, 1)
    if entry.action then
        local actionColors = {
            Banish = "|cffff4444", Reroll = "|cff44aaff",
            Freeze = "|cff44ccff", Select  = "|cff44ff44",
        }
        local colorKey = entry.action:match("^(%a+)") or entry.action
        local ac = actionColors[colorKey] or "|cffffffff"
        header:SetText(ac .. string.format(L.TOAST_AUTOMATION, L.ACTION[entry.action] or entry.action) .. "|r")

        local parts = {}
        for i, ch in ipairs(entry.choices) do
            if i > 1 then
                parts[#parts + 1] = "    "
            end
            local hex = QUALITY_HEX[ch.quality] or "ffffff"
            local isTarget = (ch.index == entry.targetIndex)
            if isTarget then
                parts[#parts + 1] = "|cffffff00>> |r"
            end
            parts[#parts + 1] = string.format("|cff%s%s (%s)|r", hex, ch.name, FormatScore(ch.score))
            if isTarget then
                parts[#parts + 1] = " |cffffff00<<|r"
            end
        end
        echoLine:SetText(table.concat(parts))

        local level, banRemain, rerollRemain, freezeRemain = GetRunInfo()
        footerLine:SetText(string.format(
            L.TOAST_CHARGES,
            banRemain, rerollRemain, freezeRemain))

        frame:SetHeight(TOAST_H)
    else
        header:SetText(entry.text or "")
        frame:SetHeight(32)
    end

    frame:Show()
    elapsed  = 0
    hovered  = false
end

local function DismissCurrent()
    frame:Hide()
    ShowNext()
end

function EbonBuilds.Toast.ShowAutomationResult(scored, action, targetIndex)
    local entry = { action = action, targetIndex = targetIndex, choices = {} }
    for _, s in ipairs(scored) do
        entry.choices[#entry.choices + 1] = {
            index   = s.index,
            name    = s.name,
            quality = s.quality,
            score   = s.score,
        }
    end
    table.insert(queue, entry)
    if not frame:IsShown() then ShowNext() end
end

function EbonBuilds.Toast.ShowLive(title, line, footer)
    if not frame then return false end
    header:SetText(title or "")
    echoLine:SetText(line or "")
    footerLine:SetText(footer or "")
    frame:SetHeight(math.max(TOAST_H, LIVE_PAD + header:GetHeight()
        + echoLine:GetHeight() + footerLine:GetHeight()))
    frame:Show()
    elapsed = 0
    return true
end

local function BuildFrame()
    local f = CreateFrame("Frame", "EbonBuildsToastFrame", UIParent)
    if EbonBuilds.api then EbonBuilds.api:Track("Toast", f) end
    f:SetSize(TOAST_W, TOAST_H)
    f:SetPoint("TOP", UIParent, "TOP", 0, -20)
    f:SetFrameStrata("TOOLTIP")
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function() DismissCurrent() end)

    f:SetScript("OnEnter", function() hovered = true end)
    f:SetScript("OnLeave", function() hovered = false; elapsed = 0 end)

    header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
    header:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    header:SetJustifyH("CENTER")

    echoLine = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    echoLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    echoLine:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    echoLine:SetJustifyH("CENTER")
    echoLine:SetTextColor(1, 1, 1, 1)

    footerLine = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerLine:SetPoint("TOPLEFT", echoLine, "BOTTOMLEFT", 0, -4)
    footerLine:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    footerLine:SetJustifyH("CENTER")
    footerLine:SetTextColor(1, 1, 1, 1)

    f:SetScript("OnUpdate", function(self, dt)
        if hovered then
            elapsed = 0
            return
        end
        elapsed = elapsed + dt
        if elapsed >= GetToastDuration() then
            DismissCurrent()
        end
    end)

    return f
end

function EbonBuilds.Toast.Init()
    frame = BuildFrame()
end
