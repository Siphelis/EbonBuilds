EbonBuilds.MinimapButton = {}

local BUTTON_NAME   = "EbonBuildsMinimapButton"
local ICON_FALLBACK = "Interface\\Icons\\INV_Misc_Gear_01"
local RADIUS        = 80

local function UpdatePosition(button, angle)
    local rad = math.rad(angle)
    button:SetPoint("CENTER", Minimap, "CENTER",
        RADIUS * math.cos(rad),
        RADIUS * math.sin(rad))
end

local function GetCursorAngle()
    local cx, cy   = Minimap:GetCenter()
    local mx, my   = GetCursorPosition()
    local scale    = UIParent:GetEffectiveScale()
    mx, my         = mx / scale, my / scale
    return math.deg(math.atan2(my - cy, mx - cx))
end

local function CreateButton()
    local button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture(ICON_FALLBACK)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(54)
    border:SetHeight(54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    return button
end

local function AttachTooltip(button)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("EbonBuilds")
        GameTooltip:AddLine(EbonBuilds.L.MINIMAP_TIP, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function AttachDrag(button)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local angle = GetCursorAngle()
            EbonBuildsDB.minimapAngle = angle
            UpdatePosition(self, angle)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
end

local function AttachClick(button)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            EbonBuilds.MainWindow.Toggle()
        end
    end)
end

function EbonBuilds.MinimapButton.Init()
    local button = CreateButton()
    AttachTooltip(button)
    AttachDrag(button)
    AttachClick(button)
    UpdatePosition(button, EbonBuildsDB.minimapAngle)
end
