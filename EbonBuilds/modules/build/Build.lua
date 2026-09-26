EbonBuilds.Build = {}

EbonBuilds.Build.LOCKED_SLOTS = 6

EbonBuilds.Draft = {
    isEditing     = false,
    weights       = nil,
    wizardPrefill = nil,
}

local function DefaultSettings()
    return {
        qualityBonus        = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0 },
        qualityBonusMode    = { [0] = false, [1] = false, [2] = false, [3] = false, [4] = false },
        familyBonus         = { Tank = 0, Survivability = 0, Healer = 0, Caster = 0, Melee = 0, Ranged = 0, ["No family"] = 0 },
        familyBonusMode     = { Tank = false, Survivability = false, Healer = false, Caster = false, Melee = false, Ranged = false, ["No family"] = false },
        banishFamilyWhitelist = {},
        autoBanishPct    = 20,
        autoRerollPct    = 120,
        rerollGuardPct   = 90,
        autoFreezePct    = 80,
        noveltyValue     = 0,
        noveltyMode      = false,
        echoBanList      = {},
        echoBanAllMode   = "highestScore",

        scoreSource      = "matrix",

        matrixBanishBelow = -2.0,
        matrixFreezeAbove =  2.0,
        matrixRerollBelow =  0.0,
        matrixRerollGuard =  0.0,
        matrixWeightFactor = 1.0,
    }
end

EbonBuilds.Build.DefaultSettings = DefaultSettings

local function EnsureSettings(build)
    build.settings = build.settings or DefaultSettings()
    local d = DefaultSettings()
    for k, v in pairs(d) do
        if build.settings[k] == nil then
            build.settings[k] = v
        elseif type(v) == "table" then
            for sk, sv in pairs(v) do
                if build.settings[k][sk] == nil then
                    build.settings[k][sk] = sv
                end
            end
        end
    end
end

EbonBuilds.Build.EnsureSettings = EnsureSettings

local function CloneTable(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[CloneTable(k)] = CloneTable(v)
    end
    return copy
end

function EbonBuilds.Build.CopyLocked(src)
    local out = {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        out[i] = src and src[i] or nil
    end
    return out
end

function EbonBuilds.Build.CloneSettings(settings)
    return CloneTable(settings)
end

function EbonBuilds.Build.NormalizeWeights(weights)
    if type(weights) ~= "table" then return weights end
    for name, w in pairs(weights) do
        if type(w) == "table" then
            local best = nil
            for _, v in pairs(w) do
                v = tonumber(v)
                if v and (not best or v > best) then best = v end
            end
            weights[name] = best
        elseif type(w) ~= "number" then
            weights[name] = tonumber(w)
        end
    end
    return weights
end

local StableSerialize
StableSerialize = function(value)
    if type(value) ~= "table" then return tostring(value) end
    local keys = {}
    for k in pairs(value) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return ta < tb end
        if ta == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)
    local parts = {}
    for i = 1, #keys do
        local k = keys[i]
        parts[#parts + 1] = tostring(k) .. "=" .. StableSerialize(value[k])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

EbonBuilds.Build.StableSerialize = StableSerialize

function EbonBuilds.Build.Checksum(build)
    local parts = {
        build.title or "",
        build.class or "",
        tostring(build.spec or 1),
        build.comments or "",
    }
    local le = build.lockedEchoes or {}
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        parts[#parts + 1] = tostring(le[i] or "nil")
    end
    if build.echoWeights then
        local names = {}
        for name in pairs(build.echoWeights) do
            if type(build.echoWeights[name]) == "number" and build.echoWeights[name] > 0 then
                names[#names + 1] = name
            end
        end
        table.sort(names)
        for _, name in ipairs(names) do
            parts[#parts + 1] = name .. "=" .. tostring(build.echoWeights[name])
        end
    end
    parts[#parts + 1] = tostring(build.automationEnabled and 1 or 0)
    parts[#parts + 1] = StableSerialize(build.settings or DefaultSettings())
    return table.concat(parts, "|")
end

local checksums = setmetatable({}, { __mode = "k" })

function EbonBuilds.Build.Stamp(build)
    checksums[build] = EbonBuilds.Build.Checksum(build)
end

local function SameShallow(a, b)
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

function EbonBuilds.Build.CompactSettings(settings)
    if type(settings) ~= "table" then return settings end
    for k, dv in pairs(DefaultSettings()) do
        local v = settings[k]
        if v ~= nil then
            if type(dv) == "table" then
                if type(v) == "table" and SameShallow(v, dv) then settings[k] = nil end
            elseif v == dv then
                settings[k] = nil
            end
        end
    end
    return settings
end

function EbonBuilds.Build.CompactRemote(build)
    build.stats = nil
    build._checksum = nil
    EbonBuilds.Build.CompactSettings(build.settings)
    return build
end

local function EnsureStats(build)
    build.stats = build.stats or {
        echoesSeen    = 0,
        runsCompleted = 0,
        runsReset     = 0,
        picks         = 0,
        rerollsUsed   = 0,
        banishesUsed  = 0,
        freezesUsed   = 0,
        qualityPicks  = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 },
    }
    local qp = build.stats.qualityPicks
    if not qp or qp[0] == nil then
        build.stats.qualityPicks = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }
    end
    build.stats.mostPicked = nil
    build.stats.mostBanned = nil
    if build.automationEnabled == nil then build.automationEnabled = true end
    if not build.author then build.author = "Unknown" end
    if not build.lastModified then build.lastModified = date("%Y-%m-%d %H:%M:%S") end
    if build.isPublic == nil then build.isPublic = false end
    if build.validated == nil then build.validated = false end
    if build.copiedFrom == nil then build.copiedFrom = nil end
end

local activeChangeCallbacks = {}

local function Notify()
    for i = 1, #activeChangeCallbacks do
        activeChangeCallbacks[i]()
    end
end

local function Changed()
    EbonBuilds.Events.Fire("EB_BUILDS_CHANGED")
end

function EbonBuilds.Build.OnActiveChanged(fn)
    activeChangeCallbacks[#activeChangeCallbacks + 1] = fn
end

function EbonBuilds.Build.NewObjectId()
    return string.format("%08x%04x%04x%04x%04x",
        time(),
        math.random(0, 65535),
        math.random(0, 65535),
        math.random(0, 65535),
        math.random(0, 65535))
end

local function PlayerClassToken()
    return select(2, UnitClass("player"))
end

local function PlayerTopTalentTab()
    local best, bestPoints = 1, -1
    for i = 1, 3 do
        local _, _, pointsSpent = GetTalentTabInfo(i)
        pointsSpent = pointsSpent or 0
        if pointsSpent > bestPoints then
            best, bestPoints = i, pointsSpent
        end
    end
    return best
end

EbonBuilds.Build.PlayerClassToken   = PlayerClassToken
EbonBuilds.Build.PlayerTopTalentTab = PlayerTopTalentTab

function EbonBuilds.Build.Migrate()
    EbonBuildsDB.builds        = EbonBuildsDB.builds        or {}
    EbonBuildsCharDB.activeBuildId = EbonBuildsCharDB.activeBuildId or nil

    if EbonBuildsDB.activeBuildId and not EbonBuildsCharDB.activeBuildId then
        EbonBuildsCharDB.activeBuildId = EbonBuildsDB.activeBuildId
    end
    EbonBuildsDB.activeBuildId = nil

    local legacy = EbonBuildsDB.echoWeights
    if legacy and not next(EbonBuildsDB.builds) then
        local id = EbonBuilds.Build.NewObjectId()
        EbonBuildsDB.builds[id] = {
            id              = id,
            title           = "Migrated",
            class           = PlayerClassToken(),
            spec            = PlayerTopTalentTab(),
            comments        = "",
            lockedEchoes = { nil, nil, nil, nil, nil },
            echoWeights     = legacy,
            settings        = DefaultSettings(),
            version         = 1,
        }
        EbonBuildsCharDB.activeBuildId = id
    end
    EbonBuildsDB.echoWeights = nil

    EbonBuildsDB._isEditingBuild = nil
    EbonBuildsDB.pendingWeights  = nil
    EbonBuildsDB._wizardPrefill  = nil

    for _, b in pairs(EbonBuildsDB.builds) do
        EnsureSettings(b); EnsureStats(b)
        EbonBuilds.Build.NormalizeWeights(b.echoWeights)
    end
    for _, b in pairs(EbonBuildsDB.remoteBuilds or {}) do
        EbonBuilds.Build.NormalizeWeights(b.echoWeights)
        EbonBuilds.Build.CompactRemote(b)
    end

    if not EbonBuildsDB.purgedBanList then
        EbonBuildsDB.purgedBanList = true
        local cleared = 0
        for _, b in pairs(EbonBuildsDB.builds) do
            if b.settings and b.settings.echoBanList then
                for _ in pairs(b.settings.echoBanList) do cleared = cleared + 1 end
                b.settings.echoBanList = {}
            end
        end
        if cleared > 0 then
            EbonBuilds.Log.Info(string.format(EbonBuilds.L.BANLIST_PURGED, cleared))
        end
    end

    EbonBuilds.Build.MigrateIds()

    for _, b in pairs(EbonBuildsDB.builds) do
        b._checksum = nil
        EbonBuilds.Build.Stamp(b)
    end
end

function EbonBuilds.Build.MigrateIds()
    local oldIds = {}
    for id, b in pairs(EbonBuildsDB.builds) do
        if id:match("-") then oldIds[#oldIds + 1] = id end
    end

    if #oldIds == 0 then return end

    local map = {}
    for _, oldId in ipairs(oldIds) do
        map[oldId] = EbonBuilds.Build.NewObjectId()
    end

    for _, oldId in ipairs(oldIds) do
        local newId = map[oldId]
        local build = EbonBuildsDB.builds[oldId]
        build.id = newId
        EbonBuildsDB.builds[newId] = build
        EbonBuildsDB.builds[oldId] = nil
    end

    if EbonBuildsCharDB.activeBuildId and map[EbonBuildsCharDB.activeBuildId] then
        EbonBuildsCharDB.activeBuildId = map[EbonBuildsCharDB.activeBuildId]
    end

    for _, build in pairs(EbonBuildsDB.builds) do
        if build.importedFrom and map[build.importedFrom] then
            build.importedFrom = map[build.importedFrom]
        end
    end
end

function EbonBuilds.Build.List()
    local out = {}
    for _, b in pairs(EbonBuildsDB.builds) do
        out[#out + 1] = b
    end
    table.sort(out, function(a, b) return (a.title or "") < (b.title or "") end)
    return out
end

function EbonBuilds.Build.ListPublic()
    local out = {}
    for _, b in pairs(EbonBuildsDB.builds) do
        if b.isPublic then out[#out + 1] = b end
    end
    if EbonBuildsDB.remoteBuilds then
        for _, b in pairs(EbonBuildsDB.remoteBuilds) do
            out[#out + 1] = b
        end
    end
    table.sort(out, function(a, b) return (a.lastModified or "") > (b.lastModified or "") end)
    return out
end

function EbonBuilds.Build.Get(id)
    if not id then return nil end
    return EbonBuildsDB.builds[id]
end

function EbonBuilds.Build.GetActive()
    return EbonBuilds.Build.Get(EbonBuildsCharDB.activeBuildId)
end

function EbonBuilds.Build.SetActive(id)
    if EbonBuildsCharDB.activeBuildId == id then return end
    EbonBuildsCharDB.activeBuildId = id
    Notify()
end

function EbonBuilds.Build.GetActiveWeights()
    local draft = EbonBuilds.Draft
    if draft.isEditing then
        draft.weights = draft.weights or {}
        return draft.weights
    end
    local build = EbonBuilds.Build.GetActive()
    if build then
        build.echoWeights = build.echoWeights or {}
        return build.echoWeights
    end
    draft.weights = draft.weights or {}
    return draft.weights
end

function EbonBuilds.Build.NewObject(data)
    local id = EbonBuilds.Build.NewObjectId()
    local automationEnabled = data.automationEnabled
    if automationEnabled == nil then automationEnabled = true end
    local build = {
        id              = id,
        title           = data.title or "Untitled",
        class           = data.class or PlayerClassToken(),
        spec            = data.spec or PlayerTopTalentTab(),
        comments        = data.comments or "",
        lockedEchoes = data.lockedEchoes or { nil, nil, nil, nil, nil },
        echoWeights     = data.echoWeights or {},
        settings        = data.settings or DefaultSettings(),
        version         = 1,
        author          = data.author or UnitName("player") or "Unknown",
        lastModified    = data.lastModified or date("%Y-%m-%d %H:%M:%S"),
        automationEnabled = automationEnabled,
        isPublic         = data.isPublic or false,
        validated         = data.validated or false,
        copiedFrom        = data.copiedFrom or nil,
        stats            = {
            echoesSeen    = 0,
            runsCompleted = 0,
            runsReset     = 0,
            picks         = 0,
            rerollsUsed   = 0,
            banishesUsed  = 0,
            freezesUsed   = 0,
            qualityPicks  = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 },
        },
    }
    return build
end

function EbonBuilds.Build.Add(build)
    EbonBuilds.Build.Stamp(build)
    EbonBuildsDB.builds[build.id] = build
    Changed()
    return build
end

function EbonBuilds.Build.Create(data)
    local build = EbonBuilds.Build.NewObject(data)
    if not (data.echoWeights and next(data.echoWeights)) and EbonBuilds.Draft.weights then
        build.echoWeights = EbonBuilds.Draft.weights
    end
    EbonBuilds.Draft.weights = nil
    return EbonBuilds.Build.Add(build)
end

function EbonBuilds.Build.UpdateFromPublic(localBuild, publicBuild)
    localBuild.title            = publicBuild.title            or localBuild.title
    localBuild.class            = publicBuild.class            or localBuild.class
    localBuild.spec             = publicBuild.spec             or localBuild.spec
    localBuild.comments         = publicBuild.comments         or localBuild.comments
    localBuild.lockedEchoes     = { nil, nil, nil, nil, nil }
    for i = 1, EbonBuilds.Build.LOCKED_SLOTS do
        localBuild.lockedEchoes[i] = (publicBuild.lockedEchoes and publicBuild.lockedEchoes[i]) or nil
    end
    if publicBuild.settings then
        localBuild.settings = EbonBuilds.Build.CloneSettings(publicBuild.settings)
    end
    if publicBuild.automationEnabled ~= nil then
        localBuild.automationEnabled = publicBuild.automationEnabled
    end
    if publicBuild.echoWeights and next(publicBuild.echoWeights) then
        localBuild.echoWeights = {}
        for name, weight in pairs(publicBuild.echoWeights) do
            localBuild.echoWeights[name] = weight
        end
    end
    if publicBuild.copiedFrom then
        localBuild.copiedFrom = publicBuild.copiedFrom
    end
    localBuild._importedAt = publicBuild.lastModified
    localBuild.lastModified = date("%Y-%m-%d %H:%M:%S")
    localBuild.version = (localBuild.version or 1) + 1
    EnsureSettings(localBuild)
    EbonBuilds.Build.NormalizeWeights(localBuild.echoWeights)
    EbonBuilds.Build.Stamp(localBuild)
    Changed()
    return localBuild
end

function EbonBuilds.Build.Save(id, data)
    local build = EbonBuildsDB.builds[id]
    if not build then return nil end
    local oldChecksum = checksums[build]
    local classChanged = data.class and data.class ~= build.class
    build.title           = data.title           or build.title
    build.class           = data.class           or build.class
    build.spec            = data.spec            or build.spec
    build.comments        = data.comments        or build.comments
    build.lockedEchoes = data.lockedEchoes or build.lockedEchoes
    if data.settings then build.settings = data.settings end
    if data.echoWeights then build.echoWeights = data.echoWeights end
    if data.automationEnabled ~= nil then build.automationEnabled = data.automationEnabled end
    if data.isPublic ~= nil then build.isPublic = data.isPublic end
    build.version         = (build.version or 1) + 1
    local newChecksum     = EbonBuilds.Build.Checksum(build)
    checksums[build]      = newChecksum
    if newChecksum ~= oldChecksum then
        build.lastModified = date("%Y-%m-%d %H:%M:%S")
        build.validated = false
        local playerName = UnitName("player") or "Unknown"
        if build.author and build.author ~= playerName then
            build.copiedFrom = build.author
            build.author = playerName
            build.validated = false
            build.importedFrom = nil
            local newId = EbonBuilds.Build.NewObjectId()
            build.id = newId
            EbonBuildsDB.builds[newId] = build
            EbonBuildsDB.builds[id] = nil
            if EbonBuildsCharDB.activeBuildId == id then
                EbonBuildsCharDB.activeBuildId = newId
                Notify()
            end
        end
    end
    if classChanged and EbonBuildsCharDB.activeBuildId == id then
        Notify()
    end
    if EbonBuilds.Automation and EbonBuilds.Automation.ResetPeakCache then
        EbonBuilds.Automation.ResetPeakCache()
    end
    Changed()
    return build
end

function EbonBuilds.Build.Delete(id)
    if not id then return end
    EbonBuildsDB.builds[id] = nil
    Changed()
    if EbonBuildsCharDB.activeBuildId == id then
        EbonBuildsCharDB.activeBuildId = nil
        Notify()
    end
end
