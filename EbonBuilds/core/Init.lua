local OnAddonLoaded

OnAddonLoaded = function(addonName)
    if addonName ~= "EbonBuilds" then return end
    EbonBuilds.Events.Off("ADDON_LOADED", OnAddonLoaded)

    if not EbonAPI.Ebonhold.IsPresent() then
        return
    end

    if not EbonBuilds.api then
        EbonBuilds.Log.Warn("EbonAPI 1.1 or newer is required -- EbonBuilds did not start.")
        return
    end

    EbonBuildsDB = EbonBuildsDB or {
        builds        = {},
        minimapAngle  = 220,
        globalSettings = {
            evalDelay     = 2,
            toastDuration = 3,
        },
    }
    EbonBuildsDB.minimapAngle = EbonBuildsDB.minimapAngle or 220
    EbonBuildsDB.globalSettings = EbonBuildsDB.globalSettings or {}
    EbonBuildsDB.globalSettings.evalDelay     = EbonBuildsDB.globalSettings.evalDelay     or 2
    EbonBuildsDB.globalSettings.toastDuration = EbonBuildsDB.globalSettings.toastDuration or 3

    EbonBuildsCharDB = EbonBuildsCharDB or {
        activeBuildId = nil,
    }

    local steps = {
        { "Build.Migrate",        function() EbonBuilds.Build.Migrate()        end },
        { "Session",              function() EbonBuilds.Session.Init()         end },
        { "SessionHistory",       function() EbonBuilds.SessionHistory.Init()  end },
        { "Protocol",             function() EbonBuilds.Protocol.Init()        end },
        { "Matrix",               function() EbonBuilds.Matrix.Init()          end },
        { "Profiles",             function() EbonBuilds.Profiles.Init()        end },
        { "Toast",                function() EbonBuilds.Toast.Init()           end },
        { "MinimapButton",        function() EbonBuilds.MinimapButton.Init()   end },
        { "Automation",           function() EbonBuilds.Automation.Init()      end },
        { "EchoStars",            function() EbonBuilds.EchoStars.Init()       end },
        { "Sync",                 function() EbonBuilds.Sync.Init()            end },
        { "Version",              function() EbonBuilds.api:Version(GetAddOnMetadata("EbonBuilds", "Version"), nil) end },
    }

    local failed = {}
    for i = 1, #steps do
        local name, fn = steps[i][1], steps[i][2]
        local ok, err = pcall(fn)
        if not ok then
            failed[#failed + 1] = name
            EbonBuilds.Log.Warn(name .. " failed: " .. tostring(err))
        end
    end
    if #failed > 0 then
        EbonBuilds.Log.Warn(#failed .. " module(s) did not start: "
            .. table.concat(failed, ", ") .. ". The rest is running.")
    end
end

EbonBuilds.Events.On("ADDON_LOADED", OnAddonLoaded, "Boot")
