EbonBuilds.SavedBuildsView = {}

local L = EbonBuilds.L

local SLOT_LIST_W  = 210
local SLOT_HEIGHT  = 22
local ICON_SIZE    = 28
local ICON_GAP     = 4
local ICONS_PER_ROW = 10

local QUALITY_BORDER = EbonBuilds.Const.QUALITY_RGB

local STAR_SIZE = 9

local viewFrame
local slotRows, iconPool = {}, {}
local state = { slot = nil }

local function CreateSlotRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(SLOT_HEIGHT)
    row:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -(index - 1) * SLOT_HEIGHT)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(index - 1) * SLOT_HEIGHT)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetTexture(1, 1, 1, 0.08)

    local sel = row:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints(row)
    sel:SetTexture(0.2, 0.5, 0.9, 0.20)
    sel:Hide()
    row._sel = sel

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT",  row, "LEFT", 6, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -34, 0)
    label:SetJustifyH("LEFT")
    row._label = label

    local count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row._count = count

    row:Hide()
    return row
end

local function CreateIcon(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(ICON_SIZE)
    btn:SetHeight(ICON_SIZE)

    local border = btn:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  1, -1)
    btn._border = border

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn._icon = icon

    local lock = btn:CreateTexture(nil, "OVERLAY")
    lock:SetWidth(12)
    lock:SetHeight(12)
    lock:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
    lock:SetTexture("Interface\\Buttons\\LockButton-Locked")
    lock:Hide()
    btn._lock = lock

    local stars = EbonBuilds.Stars.Create(btn, STAR_SIZE, 0, "OVERLAY")
    EbonBuilds.Stars.Place(stars, "TOP", btn, "BOTTOM", 0, -1)
    btn._stars = stars

    local stacks = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stacks:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, 0)
    stacks:SetTextColor(1, 0.82, 0)
    stacks:Hide()
    btn._stacks = stacks

    btn:SetScript("OnEnter", function(self)
        if not self._spellId then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local name = GetSpellInfo(self._spellId)
        if name then GameTooltip:AddLine(name, 1, 0.82, 0) end
        if utils and utils.GetSpellDescription then
            local desc = utils.GetSpellDescription(self._spellId, 500, 1)
            if desc and desc ~= "" then GameTooltip:AddLine(desc, 1, 1, 1, true) end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:Hide()
    return btn
end

local function RenderComposition(build)
    local grid = viewFrame._grid
    if not build then
        for i = 1, #iconPool do iconPool[i]:Hide() end
        viewFrame._compLabel:SetText("")
        return
    end

    local echoes = EbonAPI.State.BuildEchoes(build)
    viewFrame._compLabel:SetText(string.format(L.COMPOSITION,
        build.name or "?", #echoes))

    for i = 1, #echoes do
        local e = echoes[i]
        if not iconPool[i] then iconPool[i] = CreateIcon(grid) end
        local btn = iconPool[i]

        local col = (i - 1) % ICONS_PER_ROW
        local row = math.floor((i - 1) / ICONS_PER_ROW)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", grid, "TOPLEFT",
            col * (ICON_SIZE + ICON_GAP), -row * (ICON_SIZE + ICON_GAP + 10))

        btn._spellId = e.spellId
        btn._icon:SetTexture(select(3, GetSpellInfo(e.spellId)))

        local data = EbonBuilds.Catalog.Entry(e.spellId)
        local quality = data and data.quality or 0
        local bc = QUALITY_BORDER[quality] or QUALITY_BORDER[0]
        btn._border:SetTexture(bc[1], bc[2], bc[3])

        if e.locked then btn._lock:Show() else btn._lock:Hide() end
        if (e.stacks or 1) > 1 then
            btn._stacks:SetText("x" .. e.stacks)
            btn._stacks:Show()
        else
            btn._stacks:Hide()
        end

        EbonBuilds.Stars.Set(btn._stars, EbonBuilds.Rating.Stars(e.spellId, false))

        btn:Show()
    end
    for i = #echoes + 1, #iconPool do iconPool[i]:Hide() end
end

local Refresh

local function OrderedSlots()
    local slots = EbonAPI.State.GetBuilds()
    local out = {}
    if not slots or not slots.slots then return out, nil end
    for slot in pairs(slots.slots) do out[#out + 1] = slot end
    table.sort(out)
    return out, slots
end

Refresh = function()
    if not viewFrame then return end
    local ordered, server = OrderedSlots()

    if #ordered == 0 then
        viewFrame._empty:Show()
        viewFrame._subtitle:SetText("")
        for i = 1, #slotRows do slotRows[i]:Hide() end
        RenderComposition(nil)
        return
    end
    viewFrame._empty:Hide()

    if not state.slot or not server.slots[state.slot] then
        state.slot = server.active and server.slots[server.active] and server.active
                     or ordered[1]
    end

    for i = 1, #ordered do
        local slot  = ordered[i]
        local build = server.slots[slot]
        if not slotRows[i] then slotRows[i] = CreateSlotRow(viewFrame._slotList, i) end
        local row = slotRows[i]

        row._slot = slot
        local marker = (slot == server.active) and "|cff19ff19>|r " or "  "
        row._label:SetText(string.format("%s%d. %s", marker, slot, build.name or "?"))
        row._count:SetText(tostring(#EbonAPI.State.BuildEchoes(build)))

        if slot == state.slot then row._sel:Show() else row._sel:Hide() end

        row:SetScript("OnClick", function(self)
            state.slot = self._slot
            Refresh()
        end)

        row:Show()
    end
    for i = #ordered + 1, #slotRows do slotRows[i]:Hide() end

    viewFrame._subtitle:SetText(string.format(
        L.SAVED_SUBTITLE,
        #ordered, server.active or 0, server.unlocked or 0, server.maxSlots or 0))

    RenderComposition(server.slots[state.slot])
end

EbonBuilds.SavedBuildsView.Refresh = Refresh

local function BuildViewFrame()
    local f = CreateFrame("Frame", nil, UIParent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.SAVED_BUILDS)

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    subtitle:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    subtitle:SetJustifyH("LEFT")
    f._subtitle = subtitle

    local slotList = CreateFrame("Frame", nil, f)
    slotList:SetPoint("TOPLEFT",    f, "TOPLEFT",    10, -62)
    slotList:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    slotList:SetWidth(SLOT_LIST_W)
    f._slotList = slotList

    local compLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    compLabel:SetPoint("TOPLEFT", f, "TOPLEFT", SLOT_LIST_W + 22, -62)
    f._compLabel = compLabel

    local grid = CreateFrame("Frame", nil, f)
    grid:SetPoint("TOPLEFT",     f, "TOPLEFT",     SLOT_LIST_W + 22, -84)
    grid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    f._grid = grid

    local empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", f, "CENTER", 0, 0)
    empty:SetText(L.SAVED_NONE)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    f._empty = empty

    f:Hide()
    return f
end

local view = {}

function view.Show(container)
    EbonBuilds.Widgets.Attach(viewFrame, container)
    Refresh()
    viewFrame:Show()
end

function view.Hide()
    if viewFrame then viewFrame:Hide() end
end

function EbonBuilds.SavedBuildsView.Init()
    viewFrame = BuildViewFrame()
    EbonBuilds.ViewRouter.Register("savedBuilds", view)

    EbonBuilds.api:On("SERVER_BUILDS", function()
        if viewFrame and viewFrame:IsVisible() then Refresh() end
    end)
end
