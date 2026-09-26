local _, ns = ...

local Profiles = {}
ns.Profiles = Profiles

local api = ns.api
local Codec = EbonAPI.Profile
local Key = ns.Catalog.Key

local db = nil

local function Players()
    return db.account.players
end

local function Index(class)
    if type(class) == "number" then return class end
    return Codec.ClassIndex(class)
end

local folds = {}

local EMPTY_FOLD = { sum = {}, people = 0, builds = 0, version = 0 }

local function Contribute(fold, player, sign)
    local total, hits = 0, nil
    for _, text in pairs(player.e) do
        if text ~= "" then
            local ids, _, n = Codec.DecodeBuild(text)
            if ids then
                total = total + 1
                hits = hits or {}
                local seen = {}
                for i = 1, n do
                    local id = Key(ids[i])
                    if not seen[id] then
                        seen[id] = true
                        hits[id] = (hits[id] or 0) + 1
                    end
                end
            end
        end
    end
    if total == 0 then return end

    fold.people = fold.people + sign
    fold.builds = fold.builds + sign * total
    local sum = fold.sum
    for id, n in pairs(hits) do
        local value = (sum[id] or 0) + sign * n / total
        if value < 1e-9 and value > -1e-9 then value = nil end
        sum[id] = value
    end
    fold.version = fold.version + 1
end

local function BuildFold(class)
    local fold = { sum = {}, people = 0, builds = 0, version = 0 }
    for _, player in pairs(Players()) do
        if player.c == class then Contribute(fold, player, 1) end
    end
    folds[class] = fold
    return fold
end

function Profiles.Fold(class)
    class = Index(class)
    if not class then return EMPTY_FOLD end
    return folds[class] or BuildFold(class)
end

local function Player(name, class)
    local players = Players()
    local player = players[name]
    if not player then
        player = { c = class, t = 0, h = {}, e = {} }
        players[name] = player
    end
    return player
end

local function Reshape(player, class, change)
    local before = folds[player.c]
    if before then Contribute(before, player, -1) end
    change(player)
    player.c = class
    player.t = time()
    local after = folds[class]
    if after then Contribute(after, player, 1) end
    ns.Matrix.Touch()
end

local function OnSlots(_, sender, class, slots)
    local player = Player(sender, class)
    local keep = {}
    for i = 1, #slots do keep[slots[i]] = true end

    local stale = false
    for slot in pairs(player.h) do
        if not keep[slot] then stale = true; break end
    end
    if not stale and player.c == class then
        player.t = time()
        return
    end

    Reshape(player, class, function(p)
        for slot in pairs(p.h) do
            if not keep[slot] then
                p.h[slot] = nil
                p.e[slot] = nil
            end
        end
    end)
end

local function OnBuild(_, sender, class, slot, hash, text)
    local player = Player(sender, class)
    if player.h[slot] == hash and player.c == class then
        player.t = time()
        return
    end

    Reshape(player, class, function(p)
        p.h[slot] = hash
        p.e[slot] = text
    end)
end

local function OnBans(_, sender, class, hash, text)
    local player = Player(sender, class)
    if player.xh == hash and player.c == class then
        player.t = time()
        return
    end

    Reshape(player, class, function(p)
        p.xh = hash
        p.x = text
    end)

    if ns.Matrix and ns.Matrix.InvalidateBanVotes then
        ns.Matrix.InvalidateBanVotes()
    end
end

function Profiles.EachBuild(class, fn)
    class = Index(class)
    if not class then return end
    for name, player in pairs(Players()) do
        if player.c == class then
            for _, text in pairs(player.e) do
                if text ~= "" then fn(name, text) end
            end
        end
    end
end

function Profiles.EachBanList(class, fn)
    class = Index(class)
    if not class then return end
    for name, player in pairs(Players()) do
        if player.c == class and player.x and player.x ~= "" then
            local lists = Codec.DecodeBans(player.x)
            if lists then
                for i = 1, #lists do fn(name, lists[i]) end
            end
        end
    end
end

function Profiles.HasBans(name)
    local player = name and Players()[name]
    return player ~= nil and player.x ~= nil and player.x ~= ""
end

function Profiles.Count(class)
    class = Index(class)
    local n = 0
    for _, player in pairs(Players()) do
        if class == nil or player.c == class then n = n + 1 end
    end
    return n
end

function Profiles.Wipe()
    db.account.players = {}
    folds = {}
    if ns.Matrix and ns.Matrix.InvalidateBanVotes then
        ns.Matrix.InvalidateBanVotes()
    end
end

function Profiles.SendBans()
    local class = ns.Build.PlayerClassToken()
    if not class then return false end

    local lists = {}
    for _, build in pairs(EbonBuildsDB.builds or {}) do
        local list = build.class == class and build.settings and build.settings.echoBanList
        if list and next(list) then
            local ids = {}
            for spellId in pairs(list) do
                local id = tonumber(spellId)
                if id then ids[#ids + 1] = id end
            end
            if #ids > 0 then lists[#lists + 1] = ids end
        end
    end

    return api:SetProfileBans(lists)
end

function Profiles.Init()
    db = api:DB({ account = { players = {} } })

    api:On("PROFILE_SLOTS", OnSlots)
    api:On("PROFILE_BUILD", OnBuild)
    api:On("PROFILE_BANS", OnBans)

    ns.Events.On("EB_BUILDS_CHANGED", Profiles.SendBans, "Profiles bans")
    Profiles.SendBans()
end
