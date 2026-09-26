local _, ns = ...

local Log = {}
ns.Log = Log

local WARN_PREFIX    = "|cffff4444[EbonBuilds]|r "
local ERROR_COOLDOWN = 30

local prefixes = {}

local function Prefix(tag)
    local key = tag or ""
    local p = prefixes[key]
    if not p then
        p = "|cff33ccff[EbonBuilds" .. (tag and (" " .. tag) or "") .. "]|r "
        prefixes[key] = p
    end
    return p
end

function Log.Info(msg, tag)
    DEFAULT_CHAT_FRAME:AddMessage(Prefix(tag) .. tostring(msg))
end

function Log.Warn(msg)
    DEFAULT_CHAT_FRAME:AddMessage(WARN_PREFIX .. tostring(msg))
end

local lastError = {}

function Log.Error(where, err)
    local now = GetTime()
    local last = lastError[where]
    if last and now - last < ERROR_COOLDOWN then return end
    lastError[where] = now
    DEFAULT_CHAT_FRAME:AddMessage(WARN_PREFIX .. "error in " .. tostring(where)
        .. ": " .. tostring(err))
end

function Log.Guard(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        Log.Error(where, a)
        return nil
    end
    return a, b, c
end
