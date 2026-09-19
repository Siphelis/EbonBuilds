------------------------------------------------------------
-- EBON ORB REROLL -- WISHLIST
------------------------------------------------------------
-- The set of Echoes the player is hunting for, and the graft that lets them say
-- so from the game's own Echo journal.
--
-- Ctrl+click an icon in ProjectEbonholdEchoJournal to arm or disarm it. No panel
-- of our own: the journal already draws every Echo, greys the ones never
-- discovered, and filters by name and class. Rebuilding that beside it would be
-- a second, worse copy of a list the player already knows how to read.
--
-- Both of the journal's grids are wired, and they have to be. The catalog on the
-- right removes an Echo as soon as the player owns it, and it turns up in the run
-- panel on the left. Wiring only the catalog would make the one case that needs
-- this most -- wanting another stack of something already held -- the one case
-- that could not be asked for.
--
-- The set is volatile on purpose. It lives for one hunt and dies with the
-- session -- no SavedVariables, nothing to migrate, nothing stale to explain
-- away three patches from now.
--
-- Identity is the spellId the journal cell carries, and nothing else. The grid
-- recycles its buttons: the same cell held spellId 200228 before a search and
-- 200932 after, with the pool unchanged at 63. A mark bound to a cell would
-- follow the cell; bound to the id, it follows the Echo.

local _, ns = ...

-- The shared string table, defined in EbonOrbReroll.lua, which the .toc loads first so that this
-- is already there. Every player-visible sentence in the addon lives in one place.
local L = ns.L
-- Shortest gap between two error reports, matching the core's driver.
local ERROR_COOLDOWN = 30

------------------------------------------------------------
-- THE SET
------------------------------------------------------------

local wanted     = {}   -- [spellId] = true
local count      = 0
-- Bumped on every change. The grid repaints a cell only when its spellId or this
-- number moved, which turns the steady state into a pair of integer compares per
-- button and no texture calls at all.
local generation = 0

local Wishlist = {}
ns.Wishlist = Wishlist

function Wishlist.Has(spellId)
  return (spellId and wanted[spellId]) and true or false
end

function Wishlist.Count() return count end

--- One place to bump the counter and tell the core, so the two can never drift
--- apart. The core's hunt button carries the count of armed Echoes and greys out
--- while the count is zero, and the journal can be open over a live draw: without
--- this, arming an Echo would leave that button reading the number it had before.
--- It is the one thing the core cannot learn from a hook of ProjectEbonhold's,
--- because ProjectEbonhold does not know this list exists.
local function Touch()
  generation = generation + 1
  local notify = ns.OnWishlistChanged
  if notify then notify() end
end

function Wishlist.Toggle(spellId)
  if not spellId then return false end
  if wanted[spellId] then
    wanted[spellId] = nil
    count = count - 1
  else
    wanted[spellId] = true
    count = count + 1
  end
  Touch()
  return wanted[spellId] and true or false
end

--- Emptied wholesale when a hunt finds something: the reason the list existed is
--- gone. Kept when a hunt merely runs out of orbs -- there the intent still
--- stands and only the fuel ran out.
function Wishlist.Clear()
  if count == 0 then return false end
  for id in pairs(wanted) do wanted[id] = nil end
  count = 0
  Touch()
  return true
end

------------------------------------------------------------
-- THE JOURNAL GRAFT
------------------------------------------------------------
-- ProjectEbonholdEchoJournalScroll is a named global, so the grid is reachable
-- without guessing: its scroll child holds one Button per Echo, and each button
-- carries spellId, ownedStacks, isLocked and perkData as plain Lua fields.

-- Both grids of the journal, because an Echo lives in exactly one of them at a
-- time. The catalog on the right drops an Echo the moment the player owns it,
-- and it reappears in the run panel on the left -- so hunting for a second stack
-- of something already held would be impossible if only the catalog were wired.
--
-- Same treatment for both: they are built by the same cell factory, so a cell is
-- a Button carrying a spellId wherever it sits.
local SCROLL_NAMES = {
  "ProjectEbonholdEchoJournalScroll",       -- the catalog, right panel
  "ProjectEbonholdEchoJournalMyRunScroll",  -- what this run already holds, left panel
}

-- The journal exposes no "grid changed" callback, so the cells are polled -- but
-- only while the player is looking at them. See the driver at the foot of this
-- file for how that is arranged. A sixth of a second is invisible to a human
-- moving a mouse, and the guarded repaint below makes a tick cost two integer
-- compares per cell and one C call for the whole grid.
local POLL = 0.15

-- How often to look for the two scroll frames by name while they do not exist
-- yet. They are built the first time the journal opens, and until then there is
-- nothing to hook and nothing to wait on but the names, so this is the one thing
-- in the addon that genuinely has to be asked for rather than told. It stops for
-- good once both are found.
local DISCOVERY_POLL = 1.0

local MARK_TEXTURE = "Interface\\Buttons\\CheckButtonHilight"

-- One record per grid. Kept side by side rather than merged into a single array:
-- each scroll frame grows and rebinds its own pool on its own schedule, and a
-- shared array would have to be rebuilt whenever either of them moved.
--
--   n     - how many of `buttons` are live
--   rawN  - what GetNumChildren said when that list was built, which is what
--           decides whether it has to be built again. Not the same number as n
--           unless every child is a Button, and comparing the two would have
--           rebuilt the list on every single tick of any grid where they differ.
--   probe - the rotating cell whose OnClick is verified this tick
local grids = {}
for i = 1, #SCROLL_NAMES do
  grids[i] = {
    name = SCROLL_NAMES[i], scroll = nil, child = nil,
    buttons = {}, n = 0, rawN = -1, probe = 0,
  }
end

--- While the orb is armed the base UI owns the left button: the player is
--- marking Echoes to forget. Ours steps aside rather than fighting for the click.
local function OrbArmed()
  local orb = ProjectEbonhold and ProjectEbonhold.OrbService
  return (orb and orb.IsArmed and orb.IsArmed()) and true or false
end

--- Created on first arming, never before. A player who marks four Echoes pays
--- for four textures, not for the whole grid.
local function EnsureMark(button)
  local mark = button._eorMark
  if mark then return mark end

  -- Anchored to the icon rather than the button: the button is 46x64 and the
  -- lower third is the name label, so covering it would ring the text too.
  local anchor = button.icon or button
  mark = button:CreateTexture(nil, "OVERLAY")
  mark:SetTexture(MARK_TEXTURE)
  mark:SetBlendMode("ADD")
  mark:SetVertexColor(1, 0.82, 0, 0.9)
  mark:SetPoint("TOPLEFT", anchor, "TOPLEFT", -2, 2)
  mark:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 2, -2)
  mark:Hide()

  button._eorMark = mark
  return mark
end

--- Replaces OnClick rather than post-hooking it, because Ctrl+click has to be
--- swallowed: relaying it would let the journal act on a click the player meant
--- for us. Every other click goes straight through to the original.
---
--- Identity is checked rather than a "hooked once" flag. The journal is free to
--- reassign OnClick when it rebinds a cell, and a flag would let that silently
--- unhook us -- leaving Ctrl+click dead with nothing to show why. Comparing
--- against the wrapper we installed makes the graft repair itself instead.
local function HookClick(button)
  if button._eorWrapper and button:GetScript("OnClick") == button._eorWrapper then
    return
  end

  local original = button:GetScript("OnClick")
  -- Guard against wrapping our own wrapper if one is somehow still in the chain.
  if original == button._eorWrapper then original = button._eorOriginal end
  button._eorOriginal = original

  local wrapper = function(self, mouseButton, down)
    if mouseButton == "LeftButton" and IsControlKeyDown() and not OrbArmed() then
      local id = self.spellId
      if id then
        Wishlist.Toggle(id)
        return
      end
    end
    local passthrough = self._eorOriginal
    if passthrough then return passthrough(self, mouseButton, down) end
  end

  button._eorWrapper = wrapper
  button:SetScript("OnClick", wrapper)
end

--- Re-reads a grid only when it actually changed shape. Building the child list
--- allocates, so it is done on a new scroll child or a grown pool and not on the
--- several ticks a second where neither moved.
local function Rebuild(grid)
  local child = grid.scroll:GetScrollChild()
  if not child then
    grid.child, grid.n, grid.rawN = nil, 0, -1
    return
  end

  local n = child:GetNumChildren()
  if child == grid.child and n == grid.rawN then return end
  grid.child, grid.rawN = child, n

  local kids = { child:GetChildren() }
  local buttons, count = grid.buttons, 0
  for i = 1, #kids do
    local b = kids[i]
    if b.GetObjectType and b:GetObjectType() == "Button" then
      count = count + 1
      buttons[count] = b
    end
  end
  -- Drop stale references past the new end so a shrunken grid cannot keep
  -- buttons alive, and so the paint loop never reads beyond grid.n.
  for i = count + 1, #buttons do buttons[i] = nil end
  grid.n = count
end

--- The steady state is two integer compares per cell and one C call for the whole
--- grid. Nothing is drawn, allocated or written unless the grid rebound a cell or
--- the set changed under it.
---
--- The graft still repairs itself, but it no longer interrogates every cell to do
--- it. A cell whose spellId moved has just been rebound, and a rebind is when the
--- journal reassigns OnClick, so that is where the check belongs and it is free
--- there. The case it cannot see is a rebind that kept the same id, which the
--- rotating probe covers: one extra cell verified per tick walks a grid of sixty
--- in nine seconds. The old code asked all sixty every tick, four hundred C calls
--- a second, to close a hole that has never been observed to open.
local function Paint(grid)
  local buttons, n = grid.buttons, grid.n
  if n == 0 then return end

  grid.probe = (grid.probe % n) + 1
  HookClick(buttons[grid.probe])

  for i = 1, n do
    local b = buttons[i]
    local id = b.spellId
    if b._eorId ~= id then
      b._eorId = id
      HookClick(b)
      -- Force the mark below to be decided again for the Echo that just arrived,
      -- rather than trusting a verdict reached about the one that left.
      b._eorGen = nil
    end
    if b._eorGen ~= generation then
      b._eorGen = generation
      if id and wanted[id] then
        EnsureMark(b):Show()
      elseif b._eorMark then
        b._eorMark:Hide()
      end
    end
  end
end

------------------------------------------------------------
-- DRIVER
------------------------------------------------------------
-- Two layers, and neither of them runs while the journal is shut.
--
-- The sweep is one frame per grid, parented to that grid's own scroll frame. A
-- frame whose parent is hidden is not visible, and a frame that is not visible
-- is never handed an OnUpdate, so the parenting IS the visibility test: the
-- client stops calling us the moment the journal closes and starts again when it
-- opens, and no IsVisible of ours has to ask. That also keeps the two panels
-- independent for free, which they have to be -- the left one is hidden on its
-- own while a loadout is being edited.
--
-- Discovery is the one poll left in the addon, because the scroll frames are
-- built the first time the journal opens and there is nothing to hook until they
-- exist. It costs two hash lookups a second until then, and nothing at all
-- afterwards: the frame hides itself for good once both are wired.

--- Throttled, not reported once. An error here would fire several times a second
--- while the journal is open, so it cannot be printed raw; but silencing every
--- later failure after the first would hide the bug that explains it. Same
--- reasoning, and the same cooldown, as the core.
local lastReport = 0
local function Report(err)
  local now = GetTime()
  if now - lastReport < ERROR_COOLDOWN then return end
  lastReport = now
  DEFAULT_CHAT_FRAME:AddMessage(L.PREFIX .. string.format(L.WISHLIST_ERROR, tostring(err)))
end

local function Sweep(grid)
  Rebuild(grid)
  Paint(grid)
end

--- The sweeper is a child of the grid it sweeps, which is the whole trick: it is
--- shown once, here, and never shown or hidden again. Everything after that is
--- the client's own visibility rule doing the scheduling.
local function AttachSweeper(grid)
  local f = CreateFrame("Frame", nil, grid.scroll)
  f.elapsed = 0
  f:SetScript("OnUpdate", function(self, delta)
    self.elapsed = self.elapsed + delta
    if self.elapsed < POLL then return end
    self.elapsed = 0
    local ok, err = pcall(Sweep, grid)
    if not ok then Report(err) end
  end)
  grid.sweeper = f
end

local discovery = CreateFrame("Frame")
discovery.elapsed = 0
discovery:SetScript("OnUpdate", function(f, delta)
  f.elapsed = f.elapsed + delta
  if f.elapsed < DISCOVERY_POLL then return end
  f.elapsed = 0

  local wired = 0
  for i = 1, #grids do
    local grid = grids[i]
    if not grid.sweeper then
      local scroll = _G[grid.name]
      if scroll then
        grid.scroll = scroll
        AttachSweeper(grid)
      end
    end
    if grid.sweeper then wired = wired + 1 end
  end

  -- Both panels are wired, so there is nothing left to look for. This is the last
  -- Lua this file runs until the player opens the journal.
  --
  -- It assumes each scroll frame is built once and kept, which is the same thing
  -- the previous version assumed when it resolved the name once and cached it for
  -- the session. A journal that rebuilt its grids under the same names would have
  -- gone unnoticed there too.
  if wired >= #grids then f:Hide() end
end)
