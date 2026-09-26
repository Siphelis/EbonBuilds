EbonBuilds.WelcomeView = {}

local L = EbonBuilds.L

local viewFrame

local function BuildViewFrame(parent)
    local f = CreateFrame("Frame", nil, parent)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(64)
    icon:SetHeight(64)
    icon:SetPoint("TOP", f, "TOP", 0, -120)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -16)
    title:SetText(L.WELCOME_TITLE)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
    sub:SetText(L.WELCOME_BODY)

    local newBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    newBtn:SetWidth(140)
    newBtn:SetHeight(28)
    newBtn:SetPoint("TOP", sub, "BOTTOM", 0, -24)
    newBtn:SetText(L.NEW_BUILD_BUTTON)
    newBtn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("buildWizard")
    end)

    local publicBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    publicBtn:SetWidth(140)
    publicBtn:SetHeight(28)
    publicBtn:SetPoint("TOP", newBtn, "BOTTOM", 0, -8)
    publicBtn:SetText(L.PUBLIC_BUILDS)
    publicBtn:SetScript("OnClick", function()
        EbonBuilds.ViewRouter.Show("publicBuilds")
    end)

    return f
end

function EbonBuilds.WelcomeView.Mount(container)
    viewFrame = viewFrame or BuildViewFrame(container)
    EbonBuilds.Widgets.Attach(viewFrame, container)
    viewFrame:Show()
end

function EbonBuilds.WelcomeView.Unmount()
    if not viewFrame then return end
    viewFrame:Hide()
end
