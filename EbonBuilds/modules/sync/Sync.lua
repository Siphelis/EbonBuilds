EbonBuilds.Sync = {}

local api = EbonBuilds.api

local SYNC_VERSION = 2
local VALIDATION_REQUIRED = true
local MAX_REMOTE_BUILDS = 300
local MAX_TITLE_LEN = 80
local MAX_AUTHOR_LEN = 32
local MAX_COMMENTS_LEN = 4000
local REQ_COOLDOWN = 30

local lastRequestTime = 0

local function Now()
    return GetTime()
end

local function SanitizeMarkup(text)
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|H(.-)|h(.-)|h", function(link, label)
        if link:find("^echo:") then
            return "|H" .. link .. "|h" .. label .. "|h"
        end
        return label
    end)
    return text
end

local function SanitizeText(value, maxLen, allowMarkup)
    if type(value) ~= "string" then return nil end
    if #value > maxLen then value = value:sub(1, maxLen) end
    if allowMarkup then return SanitizeMarkup(value) end
    return (value:gsub("|", "||"))
end

local function CountRemoteBuilds()
    local count = 0
    for _ in pairs(EbonBuildsDB.remoteBuilds or {}) do count = count + 1 end
    return count
end

local function SortableNow()
    return date("%Y-%m-%d %H:%M:%S")
end

local function IsoToEpoch(iso)
    if not iso or iso == "" then return 0 end
    local y, m, d, h, min, s = iso:match("^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)$")
    if not y then return 0 end
    local ok, result = pcall(time, {
        year = tonumber(y), month = tonumber(m), day = tonumber(d),
        hour = tonumber(h), min = tonumber(min), sec = tonumber(s),
    })
    return ok and result or 0
end

local function DateToEpoch(d)
    if not d or d == "" then return 0 end
    local epoch = IsoToEpoch(d)
    if epoch > 0 then return epoch end
    local m, day, y, h, min, s = d:match("^(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)$")
    if not m then return 0 end
    local year = tonumber(y)
    if year < 100 then year = year + 2000 end
    local ok, result = pcall(time, {
        year = year, month = tonumber(m), day = tonumber(day),
        hour = tonumber(h), min = tonumber(min), sec = tonumber(s),
    })
    return ok and result or 0
end

function EbonBuilds.Sync.Epoch(build)
    return DateToEpoch(build and build.lastModified)
end

local function Published()
    if type(EbonBuildsDB.published) ~= "table" then
        EbonBuildsDB.published = {}
    end
    return EbonBuildsDB.published
end

local function Eligible(build)
    return build.isPublic == true and (not VALIDATION_REQUIRED or build.validated == true)
end

function EbonBuilds.Sync.Refresh()
    if not api then return false end

    local published = Published()
    local changed = false

    for id, build in pairs(EbonBuildsDB.builds) do
        if Eligible(build) then
            local epoch = DateToEpoch(build.lastModified)
            if published[id] ~= epoch then
                local b64 = EbonBuilds.ExportImport.ExportBuild(build)
                if b64 and api:Share(id, epoch, b64) then
                    changed = true
                end
                published[id] = epoch
            end
        end
    end

    for id in pairs(published) do
        local build = EbonBuildsDB.builds[id]
        if not build or not Eligible(build) then
            api:Unshare(id)
            published[id] = nil
            changed = true
        end
    end

    return changed
end

local function AssembleBuild(buildId, base64)
    local imported = EbonBuilds.ExportImport.DecodeBuild(base64)
    if not imported then return end

    imported.title    = SanitizeText(imported.title,    MAX_TITLE_LEN)          or "Untitled"
    imported.author   = SanitizeText(imported.author,   MAX_AUTHOR_LEN)         or "Unknown"
    imported.comments = SanitizeText(imported.comments, MAX_COMMENTS_LEN, true) or ""

    EbonBuildsDB.remoteBuilds = EbonBuildsDB.remoteBuilds or {}

    local incomingEpoch = DateToEpoch(imported.lastModified)

    local existing = EbonBuildsDB.builds[buildId]
    if existing then
        if incomingEpoch > DateToEpoch(existing.lastModified) then
            EbonBuilds.Build.UpdateFromPublic(existing, imported)
        end
        return
    end

    EbonBuilds.Build.CompactRemote(imported)
    local rb = EbonBuildsDB.remoteBuilds[buildId]
    if rb then
        if incomingEpoch > DateToEpoch(rb.lastModified) then
            imported.id = buildId
            EbonBuildsDB.remoteBuilds[buildId] = imported
        end
    else
        if CountRemoteBuilds() >= MAX_REMOTE_BUILDS then
            return
        end
        imported.id = buildId
        EbonBuildsDB.remoteBuilds[buildId] = imported
    end

    if EbonBuilds.Matrix and EbonBuilds.Matrix.InvalidateBanVotes then
        EbonBuilds.Matrix.InvalidateBanVotes()
    end

    if EbonBuilds.PublicBuildsView and EbonBuilds.PublicBuildsView.RefreshIfMounted then
        EbonBuilds.PublicBuildsView.RefreshIfMounted()
    end
end

local function Adopt(name)
    local b64 = api:GetShared(name)
    if not b64 then return false end
    local ok, err = pcall(AssembleBuild, name, b64)
    if not ok then
        EbonBuilds.Log.Info("Error assembling build " .. tostring(name) .. ": " .. tostring(err), "Sync")
        return false
    end
    return true
end

local function OnReceived(_, addon, name)
    if addon ~= "EbonBuilds" then return end
    if Adopt(name) then
        EbonBuildsDB.lastSyncDate = SortableNow()
    end
end

local function OnBuildsChanged()
    EbonBuilds.Sync.Refresh()
end

function EbonBuilds.Sync.GetCooldownRemaining()
    local elapsed = Now() - lastRequestTime
    if elapsed >= REQ_COOLDOWN then return 0 end
    return math.ceil(REQ_COOLDOWN - elapsed)
end

function EbonBuilds.Sync.RequestSync()
    local remaining = EbonBuilds.Sync.GetCooldownRemaining()
    if remaining > 0 then
        EbonBuilds.Log.Info(string.format(EbonBuilds.L.SYNC_COOLDOWN, remaining), "Sync")
        return false
    end

    EbonBuilds.Sync.Refresh()

    if not api:SyncShares() then
        EbonBuilds.Log.Info(EbonBuilds.L.SYNC_NO_CHANNEL, "Sync")
        return false
    end

    lastRequestTime = Now()
    EbonBuilds.Log.Info(EbonBuilds.L.SYNC_REQUESTING, "Sync")
    return true
end

function EbonBuilds.Sync.Init()
    api:On("SHARE_RECEIVED", OnReceived)
    EbonBuilds.Events.On("EB_BUILDS_CHANGED", OnBuildsChanged, "Sync")

    EbonBuildsDB.lastSyncDate = EbonBuildsDB.lastSyncDate or nil
    EbonBuildsDB.syncPeers = nil

    local storedVersion = EbonBuildsDB.syncVersion or 0
    if storedVersion < SYNC_VERSION then
        if EbonBuildsDB.remoteBuilds and next(EbonBuildsDB.remoteBuilds) then
            EbonBuildsDB.remoteBuilds = {}
        end
        EbonBuildsDB.syncVersion = SYNC_VERSION
    end

    local remote = EbonBuildsDB.remoteBuilds or {}
    for _, name in ipairs(api:SharedNames()) do
        if not EbonBuildsDB.builds[name] and not remote[name] then
            Adopt(name)
        end
    end

    EbonBuilds.Sync.Refresh()
end
