EbonBuilds.WeightsView = {}

local L = EbonBuilds.L

local viewFrame

local function BuildViewFrame(parent)
    local f = CreateFrame("Frame", nil, parent)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    header:SetText(L.ECHO_WEIGHTS)
    f._header = header
    return f
end

local function RefreshHeader()
    if not viewFrame then return end
    local build = EbonBuilds.Build.GetActive()
    if build then
        viewFrame._header:SetText(string.format(L.ECHO_WEIGHTS_FOR, build.title or ""))
    else
        viewFrame._header:SetText(L.ECHO_WEIGHTS)
    end
end

function EbonBuilds.WeightsView.Mount(container)
    if not viewFrame then
        viewFrame = BuildViewFrame(container)
        EbonBuilds.Filters.Init(viewFrame)
        EbonBuilds.EchoTable.Init(viewFrame)
    end
    EbonBuilds.Widgets.Attach(viewFrame, container)
    RefreshHeader()
    viewFrame:Show()
    EbonBuilds.Filters.FocusSearch()
end

function EbonBuilds.WeightsView.Unmount()
    if viewFrame then viewFrame:Hide() end
end

function EbonBuilds.WeightsView.Init()
    if EbonBuilds.Build and EbonBuilds.Build.OnActiveChanged then
        EbonBuilds.Build.OnActiveChanged(RefreshHeader)
    end
end
