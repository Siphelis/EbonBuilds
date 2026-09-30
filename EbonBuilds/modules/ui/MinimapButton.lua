EbonBuilds.MinimapButton = {}

local ICON = "Interface\\Icons\\INV_Misc_Gear_01"

function EbonBuilds.MinimapButton.Init()
    EbonBuilds.api:MinimapButton({
        icon   = ICON,
        angle  = EbonBuildsDB.minimapAngle,
        text   = "EbonBuilds",
        tipKey = "MINIMAP_TIP",
        onClick = function(_, mouseButton)
            if mouseButton == "LeftButton" then
                EbonBuilds.MainWindow.Toggle()
            end
        end,
    })
end
