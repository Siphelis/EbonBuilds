EbonBuilds.EchoPicker = {}

local QUALITY_COLOR = EbonBuilds.Const.QUALITY_HEX

local ROW_HEIGHT = 24

local frame, searchBox, scrollFrame, scrollChild, scrollBar
local allEntries   = {}
local filtered     = {}
local rowPool      = {}
local onPick
local searchText   = ""

local function BuildEntries()
    local best = EbonBuilds.Catalog.BestByName()
    local list = {}
    for name, entry in pairs(best) do
        list[#list + 1] = {
            spellId = entry.spellId,
            name    = name,
            quality = entry.quality,
        }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local function ApplySearch()
    filtered = {}
    if searchText == "" then
        for i = 1, #allEntries do filtered[i] = allEntries[i] end
        return
    end
    for i = 1, #allEntries do
        local e = allEntries[i]
        local lname = e.lname
        if not lname then
            lname = e.name:lower()
            e.lname = lname
        end
        if lname:find(searchText, 1, true) then
            filtered[#filtered + 1] = e
        end
    end
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetTexture(1, 1, 1, 0.1)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row._icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT",  icon, "RIGHT", 6, 0)
    label:SetPoint("RIGHT", row,  "RIGHT", -4, 0)
    label:SetJustifyH("LEFT")
    row._label = label
    return row
end

local function PopulateRow(row, index, entry)
    row:ClearAllPoints()
    row:SetPoint("LEFT",  scrollChild, "LEFT",  0, 0)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row:SetPoint("TOP",   scrollChild, "TOP",   0, -(index - 1) * ROW_HEIGHT)
    row._icon:SetTexture(select(3, GetSpellInfo(entry.spellId)))
    local color = QUALITY_COLOR[entry.quality] or "ffffff"
    row._label:SetText("|cff" .. color .. entry.name .. "|r")
    row:SetScript("OnClick", function()
        if onPick then onPick(entry.spellId, entry.quality, entry.name) end
        frame:Hide()
    end)
    row:Show()
end

local function VisibleRowCount()
    local h = scrollFrame and scrollFrame:GetHeight() or 0
    if h <= 0 then h = 420 end
    return math.ceil(h / ROW_HEIGHT) + 2
end

local function Render()
    scrollChild:SetHeight(math.max(1, #filtered * ROW_HEIGHT))

    local offset  = math.floor((scrollFrame:GetVerticalScroll() or 0) / ROW_HEIGHT)
    local visible = VisibleRowCount()

    for poolIdx = 1, visible do
        local listIdx = offset + poolIdx
        local entry   = filtered[listIdx]
        if entry then
            if not rowPool[poolIdx] then
                rowPool[poolIdx] = CreateRow(scrollChild, poolIdx)
            end
            PopulateRow(rowPool[poolIdx], listIdx, entry)
        elseif rowPool[poolIdx] then
            rowPool[poolIdx]:Hide()
        end
    end
    for i = visible + 1, #rowPool do rowPool[i]:Hide() end
end

local function ApplyBackdrop(f)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

local function CreateSearchBox(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(360, 22)
    container:SetPoint("TOP", parent, "TOP", 0, -36)
    EbonBuilds.Widgets.InputBackdrop(container)

    local box = CreateFrame("EditBox", nil, container)
    box:SetSize(354, 18)
    box:SetPoint("CENTER", container, "CENTER", 0, 0)
    box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    box:SetTextColor(1, 1, 1, 1)
    box:SetAutoFocus(false)
    box:SetMaxLetters(60)
    box:SetScript("OnTextChanged", function(self)
        searchText = self:GetText():lower()
        ApplySearch()
        scrollFrame:SetVerticalScroll(0)
        Render()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function BuildFrame()
    local f = CreateFrame("Frame", "EbonBuildsEchoPicker", UIParent)
    f:SetWidth(400)
    f:SetHeight(500)
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    ApplyBackdrop(f)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText(EbonBuilds.L.PICK_ECHO)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)

    searchBox = CreateSearchBox(f)

    scrollFrame = CreateFrame("ScrollFrame", "EbonBuildsEchoPickerSF", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",      16, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -36,  16)
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(340)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:HookScript("OnVerticalScroll", function() Render() end)
    scrollFrame:HookScript("OnSizeChanged", function() Render() end)

    f:Hide()
    return f
end

function EbonBuilds.EchoPicker.Show(callback, dataSource)
    if not frame then
        frame = BuildFrame()
    end
    if type(dataSource) == "table" then
        allEntries = dataSource
    elseif dataSource then
        allEntries = EbonBuilds.Catalog.AllQualities()
    else
        allEntries = BuildEntries()
    end
    onPick = callback
    searchBox:SetText("")
    searchText = ""
    ApplySearch()
    frame:Show()
    scrollFrame:SetVerticalScroll(0)
    Render()
    searchBox:SetFocus()
end
