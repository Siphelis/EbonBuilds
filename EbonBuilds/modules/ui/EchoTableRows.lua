EbonBuilds.EchoTableRows = {}

local COL_ICON   = 40
local COL_WEIGHT = 80
local COL_SCORE  = 140
local ROW_HEIGHT = 36

local QUALITY_COLORS = EbonBuilds.Const.QUALITY_HEX

local function UpdateScores(row, entry)
    if not row.scoreLabel then return end
    local weight = EbonBuilds.Weights.Get(entry.name) or 0
    local form = EbonBuilds.BuildForm
    local settings = form.GetEditingSettings()
    local parts = {}
    for q = 0, 4 do
        if entry.qualities[q] then
            local spellId = entry.spellIds and entry.spellIds[q]
            if spellId and form.IsLocked(spellId) then
                parts[#parts + 1] = string.format("|cff%s%s|r", QUALITY_COLORS[q], EbonBuilds.L.LOCKED)
            elseif spellId and form.IsBanned(spellId) then
                parts[#parts + 1] = string.format("|cff%s%s|r", QUALITY_COLORS[q], EbonBuilds.L.BANNED)
            else
                local score = EbonBuilds.Scoring.ScorePerQuality(entry, weight, settings, q)
                parts[#parts + 1] = string.format("|cff%s%d|r", QUALITY_COLORS[q], score)
            end
        end
    end
    row.scoreLabel:SetText(table.concat(parts, " - "))
end

local function CreateIconFrame(row)
    local frame = CreateFrame("Frame", nil, row)
    frame:SetWidth(COL_ICON)
    frame:SetHeight(ROW_HEIGHT)
    frame:SetPoint("LEFT", row, "LEFT", 4, 0)
    frame:EnableMouse(true)
    frame.spellId = 0

    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetWidth(28)
    tex:SetHeight(28)
    tex:SetPoint("CENTER", frame, "CENTER")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = tex
    return frame
end

local function WireIconTooltip(iconFrame)
    iconFrame:SetScript("OnEnter", function(self)
        if not self.spellId then return end
        local spellName = GetSpellInfo(self.spellId)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if spellName then
            GameTooltip:AddLine(spellName, 1, 0.82, 0)
        end
        if utils and utils.GetSpellDescription then
            local description = utils.GetSpellDescription(self.spellId, 500, 1)
            if description and description ~= "" then
                GameTooltip:AddLine(description, 1, 1, 1, true)
            end
        end
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
EbonBuilds.EchoTableRows.WireIconTooltip = WireIconTooltip

local function ApplyWeight(editBox, raw)
    local num = tonumber(raw)
    if num and math.floor(num) == num and num >= 0 then
        EbonBuilds.Weights.Set(editBox.echoName, num)
    end
    editBox:SetText(tostring(EbonBuilds.Weights.Get(editBox.echoName)))
    if editBox._row and editBox._row.scoreLabel then
        local row = editBox._row
        local entry = { name = editBox.echoName, qualities = row._qualities, families = row._families, spellIds = row._spellIds }
        UpdateScores(row, entry)
    end
end

local function WireWeightBox(editBox)
    editBox:SetScript("OnChar", function(self, char)
        if not char:match("%d") then
            local pos  = self:GetCursorPosition()
            local text = self:GetText()
            self:SetText(text:sub(1, pos - 1) .. text:sub(pos + 1))
            self:SetCursorPosition(pos - 1)
        end
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        ApplyWeight(self, self:GetText())
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        ApplyWeight(self, self:GetText())
    end)
    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
end

local function CreateWeightBox(parentRow)
    local editContainer = CreateFrame("Frame", nil, parentRow)
    editContainer:SetSize(58, 22)
    editContainer:SetPoint("RIGHT", parentRow, "RIGHT", -8, 0)
    EbonBuilds.Widgets.InputBackdrop(editContainer)

    local box = CreateFrame("EditBox", nil, editContainer)
    box:SetSize(52, 18)
    box:SetPoint("CENTER", editContainer, "CENTER", 0, 0)
    box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    box:SetTextColor(1, 1, 1, 1)
    box:SetJustifyH("CENTER")
    box:SetAutoFocus(false)
    box:SetMaxLetters(6)
    box._row = parentRow
    WireWeightBox(box)
    return box
end

local function AddBackground(row, index)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetTexture(0, 0, 0, (index % 2 == 0) and 0.15 or 0.05)
end

function EbonBuilds.EchoTableRows.CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("LEFT",  parent, "LEFT",  0, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    AddBackground(row, index)

    local iconFrame = CreateIconFrame(row)
    WireIconTooltip(iconFrame)

    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT",  iconFrame, "RIGHT", 4, 0)
    nameLabel:SetPoint("RIGHT", row,       "RIGHT", -(COL_WEIGHT + COL_SCORE + 24), 0)
    nameLabel:SetJustifyH("LEFT")

    local scoreLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scoreLabel:SetPoint("RIGHT", row, "RIGHT", -(COL_WEIGHT + 16), 0)
    scoreLabel:SetWidth(COL_SCORE)
    scoreLabel:SetJustifyH("RIGHT")

    local weightBox = CreateWeightBox(row)

    row.iconFrame  = iconFrame
    row.nameLabel  = nameLabel
    row.scoreLabel = scoreLabel
    row.weightBox  = weightBox
    row:Hide()
    return row
end

function EbonBuilds.EchoTableRows.Populate(row, yOffset, entry)
    row:SetPoint("TOP", row:GetParent(), "TOP", 0, yOffset)
    row.iconFrame.spellId = entry.spellId
    row.iconFrame.icon:SetTexture(select(3, GetSpellInfo(entry.spellId)))
    row.nameLabel:SetText(entry.name)
    row.weightBox.echoName = entry.name
    row.weightBox:SetText(tostring(EbonBuilds.Weights.Get(entry.name)))
    row._qualities = entry.qualities
    row._families  = entry.families
    row._spellIds  = entry.spellIds
    UpdateScores(row, entry)
    row:Show()
end
