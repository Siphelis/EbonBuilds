------------------------------------------------------------
-- EBON ORB REROLL
------------------------------------------------------------
-- A "Reroll (Orb)" button under the three Echo cards, for the draw an Orb of Lost Memories
-- hands back.
--
-- The server refuses reroll, banish and freeze on an Orb offer, which is why ProjectEbonhold
-- hides its own Reroll button there (perks.lua, ShowRerollButton). Nothing in the protocol
-- rerolls such a draw, so this addon does not try to: it performs the two ordinary actions a
-- player would perform by hand, back to back.
--
--   1. Take one card off the table (REQUEST_PLAYER_PERK_SELECTION). The stack is granted.
--   2. Spend one orb to forget that same stack again (REQUEST_ORB_CONSUME), which is what
--      pushes a fresh Echo choice.
--
-- Net effect: three new cards, one orb gone, the same echoes owned as before. Nothing new is
-- sent and nothing is decided locally - the server validates ownership, lock state and the
-- charge on step 2 as it always does.
--
-- The one way this differs from a real reroll: between the two steps the player genuinely owns
-- the sacrificed echo. If the server refuses step 2 the echo stays. The card is therefore chosen
-- to be the cheapest thing to be stuck with, and the tooltip names it before the click.
--
-- THE HUNT
--
-- On top of that single reroll sits a supervisor. The player arms a set of Echoes from the game's
-- own journal (see EbonOrbWishlist.lua), sets how many Orbs they are willing to spend, and the
-- addon repeats the reroll until one of the armed Echoes is dealt. It never picks the card: two
-- wanted Echoes can land together, and choosing between them is the player's business. It stops
-- and says so.
--
-- WHAT DRIVES IT
--
-- Nothing, until something happens. There is no loop: every path into this file is a hook on a
-- function ProjectEbonhold already calls at the moment its state changes, a click, a hover, or a
-- timer that armed itself and will disarm itself. Between two draws the addon executes no Lua.
--
--   PerkUI.Show / Hide          a draw arrived, or left
--   PerkUI.UpdateSinglePerk     one card was rewritten in place, by a banish
--   PerkUI.ResetSelection       the server refused our pick
--   OrbService.ClearOffer       the server took our pick
--   PerkHideButton / PerkChooseButton   the cards were collapsed or unfolded
--
-- The timers are hidden frames. A hidden frame gets no OnUpdate at all, so an idle timer is not a
-- cheap loop - it is no loop. Show is the enable bit, Hide is the disable bit.
--
-- One thing has no event: whether the offer now on the table came from an orb rather than a
-- level-up. `settle` below is the bounded watcher that covers it, and the only code here that can
-- tick more than once for one draw.

local _, ns = ...

-- How long to wait after a successful pick before spending the orb. The selection handler sends
-- REQUEST_PLAYER_PERK_CHOICE and REQUEST_PLAYER_GRANTED_PERKS of its own; letting those land
-- first keeps the consume from racing the grant it depends on.
local CONSUME_DELAY = 0.4
-- Give up on a pick that never comes back, so a dropped packet cannot leave the button dead.
local PICK_TIMEOUT = 8.0
-- The settle watcher's period, and the only interval in the addon that repeats. See `settle`.
local TICK = 0.1
-- How long that watcher waits for the orb flag before accepting that this draw is not an orb
-- draw. Generous next to a flag that is normally already set when the cards are dealt, and it
-- only ever runs out on a level-up draw, where nothing is waiting on it.
local SETTLE_WINDOW = 1.0
-- How often to re-ask for the orb count while the server has not answered.
local CHARGE_PROBE_INTERVAL = 3.0
-- Shortest gap between two error reports. See Report.
local ERROR_COOLDOWN = 30

-- Seconds between two hunt cycles. The floor exists so a hunt paced by server round trips cannot
-- degenerate into a tight loop when they come back fast; it is not what makes the addon wait for
-- the draw, which is the choice-table identity check in HuntTick.
local HUNT_CYCLE = 0.5
-- What the budget slider starts on. Deliberately not "everything": the point of the slider is
-- that spending the pool is a decision, and a default that spends it is not a decision.
local DEFAULT_BUDGET = 10

local BUTTON_WIDTH = 190
local HUNT_BUTTON_WIDTH = 150
local SLIDER_WIDTH = 180
local BUTTON_GAP = 8
local BUTTON_HEIGHT = 32
-- Everything on one row, and deliberately so. ProjectEbonholdPerkFrame measures 624x280 and
-- carries a 200x100 PerkHideButton under the cards; a second row of controls would land inside
-- it. One row of 536 fits the frame's width with room to spare and clears that button entirely.
local ROW_WIDTH = BUTTON_WIDTH + BUTTON_GAP + HUNT_BUTTON_WIDTH + BUTTON_GAP + SLIDER_WIDTH
local PANEL_HEIGHT = BUTTON_HEIGHT
-- Cards are anchored at CENTER +100 inside that 280-tall frame, so their bottom edge sits 40px
-- above the frame's own bottom. Hanging the panel off that bottom edge puts it clear of both the
-- "Auto Show Echoes" checkbox under the middle card and the Show/Hide toggle below.
local BUTTON_Y = -8

local QUALITY_COLORS = {
  [0] = "|cffFFFFFF",
  [1] = "|cff1AFF1A",
  [2] = "|cff0066FF",
  [3] = "|cffCC66FF",
  [4] = "|cffFF8000",
}

local GOLD, RED, GREEN, GREY = "|cffFFD100", "|cffff5555", "|cff19ff19", "|cff888888"
local R = "|r"

------------------------------------------------------------
-- STRINGS
------------------------------------------------------------
-- Every sentence the player can read, in one place. Gathered here for two reasons: so that
-- translating the addon is editing one table rather than hunting through nine hundred lines, and
-- so that a message can never again be half in one language and half in another.
--
-- Anything with a runtime value goes through string.format, so word order stays the translator's
-- to choose rather than being frozen by concatenation.

local L = {
  PREFIX             = "|cff9966ff[Orb Reroll]|r ",

  -- Reroll button
  REROLL             = "Reroll (Orb: %s)",
  REROLL_BUSY        = "Rerolling...",
  REROLL_TITLE       = "Reroll with an Orb",
  REROLL_BODY        = "Takes %s and forgets it again for a fresh draw.",
  REROLL_COST        = "Cost: " .. GOLD .. "%d Orb%s" .. R .. "   Held: " .. GOLD .. "%d" .. R,
  REROLL_CANNOT      = "Cannot reroll.",

  -- Hunt button
  HUNT               = "Hunt (%d)",
  HUNT_MULT          = "Hunt (%d) x%d",
  HUNT_STOP          = "Stop (%d/%d)",
  HUNT_TITLE         = "Hunt for Echoes",
  HUNT_RUNNING       = "Hunt in progress",
  HUNT_PROGRESS      = "%d of %d orbs spent, %d per draw.",
  HUNT_CLICK_STOP    = "Click to stop.",
  HUNT_BODY          = "Rerolls until one of your %d armed Echo(es) is dealt.",
  HUNT_BODY_COST     = "Cost: " .. GOLD .. "%d orb(s)" .. R .. " per draw - %d draw(s) for "
                       .. GOLD .. "%d orb(s)" .. R .. ".",
  HUNT_BODY_MANUAL   = "The Echo it finds is never taken for you.",
  HUNT_BODY_HINT     = "The cost follows the game's own quality slider, read from your last orb spend.",
  HUNT_CANNOT        = "Cannot hunt.",

  -- Budget slider
  BUDGET             = "Orbs to spend: " .. GOLD .. "%d" .. R,
  BUDGET_DRAWS       = "Orbs to spend: " .. GOLD .. "%d" .. R .. "  " .. GREY .. "(%d draw%s at %d)" .. R,

  -- Refusals, shown in the tooltip and on the error frame
  NO_ADDON           = "Project Ebonhold is not loaded.",
  BUSY               = "A reroll is already in progress.",
  NO_CHOICE          = "No Echo choice on the table.",
  PICK_IN_FLIGHT     = "A pick is already in flight.",
  NONE_FORGETTABLE   = "None of these cards can be forgotten again.",
  CHARGES_UNKNOWN    = "Still waiting on your Orb count.",
  NO_ORBS            = "You have no Orbs of Lost Memories.",
  NOT_ENOUGH_ORBS    = "A draw costs %d orbs and you hold %d.",
  HUNT_RUNNING_ALREADY = "A hunt is already running.",
  NOTHING_ARMED      = "No Echo armed. Ctrl+click one in the Echoes journal.",
  AUTO_ACCEPT_ON     = "Turn Ebonhold's \"auto-accept loadout echoes\" off before hunting.",
  BUDGET_TOO_LOW     = "Budget too low: one draw costs %d orbs, raise the slider.",

  -- Chat
  HUNT_STARTED       = "Hunt started: %d Echo(es) wanted, up to " .. GOLD .. "%d orb%s" .. R
                       .. " - %d draw%s at " .. GOLD .. "%d" .. R .. " each.",
  HUNT_SPENT         = " " .. GREY .. "(%d orb%s spent)" .. R,
  HUNT_FOUND         = GREEN .. "Found:" .. R .. " %s " .. GREY .. "- yours to pick." .. R,
  HUNT_BUDGET_DONE   = "Budget spent, hunt finished.",
  HUNT_NO_ORBS       = RED .. "Not enough orbs left (%d per draw), hunt finished." .. R,
  HUNT_STOPPED       = "Hunt stopped.",
  HUNT_INTERRUPTED   = RED .. "Hunt interrupted." .. R,
  HUNT_BEFORE_SPEND  = RED .. "Hunt interrupted before the spend." .. R,
  HUNT_WENT_PERMANENT = RED .. "Hunt stopped: the Echo taken came back permanent." .. R,
  HUNT_SPEND_FAILED  = RED .. "Hunt stopped: the spend failed." .. R,
  HUNT_REROLL_REFUSED = RED .. "Hunt stopped: the reroll was refused." .. R,
  HUNT_DEAD_END      = RED .. "Hunt stopped: " .. R .. "no card in this draw can be forgotten.",
  HUNT_CANNOT_REASON = RED .. "Hunt stopped: " .. R .. "%s",

  PICK_REFUSED       = "The pick was refused - nothing was spent.",
  PICK_REFUSED_SERVER = "The server refused the pick - no orb was spent.",
  PICK_TIMED_OUT     = "The pick timed out - no orb was spent.",
  WENT_PERMANENT     = RED .. "%s came back permanent, so it cannot be forgotten - no orb was "
                       .. "spent. It is yours to keep." .. R,
  SHORT_ON_ORBS      = RED .. "Not enough orbs for the second step (%d needed, %d held) - %s stays "
                       .. "with you." .. R,
  SPEND_FAILED       = RED .. "The spend failed: %s" .. R,
  FORGOTTEN          = "Forgot %s again - " .. GOLD .. "%d orb%s" .. R .. " spent, fresh draw incoming.",
  THAT_ECHO          = "That Echo",
  ERROR              = RED .. "Error: %s" .. R,
  NO_PERK_SYSTEM     = "Project Ebonhold's perk system was not found - the panel stays hidden.",
  WISHLIST_ERROR     = RED .. "Wishlist: %s" .. R,
}

-- Shared with EbonOrbWishlist.lua, which the .toc loads after this file for exactly that reason.
ns.L = L

--- English plurals are a single trailing "s", so the whole rule fits here. A locale that needs
--- more can replace this along with the table above.
local function S(n)
  return n == 1 and "" or "s"
end

--- Refusals travel as the constant plus its arguments, and are only assembled where one is going
--- to be read. Refresh asks CanReroll and CanHunt whether the buttons may light up and throws the
--- reason away every time; formatting there would be building a sentence for nobody and handing
--- it to the collector.
local function Fmt(fmt, a, b)
  if not fmt or a == nil then return fmt end
  return string.format(fmt, a, b)
end

local PE = nil -- ProjectEbonhold, resolved at login
local container = nil   -- holds the two buttons and the slider, anchored under the cards
local button = nil      -- "Reroll (Orb: N)", the single reroll
local huntButton = nil  -- "Chercher (N)", start and stop
local slider = nil      -- how many orbs the hunt may spend
-- What `container` is currently parented to, tracked here rather than read back with GetParent:
-- ProjectEbonholdPerkFrame is built once and only shown and hidden thereafter, so this is a
-- comparison that is always equal, and a Lua compare is the cheapest way to stay defensive about
-- a version that might one day rebuild it.
local uiParent = nil
local orbHooksInstalled = false

-- "idle" -> "picking" (selection in flight) -> "consuming" (orb spend scheduled) -> "idle"
-- The deadline of whichever of those two waits is running lives in `stateTimer`, not here: the
-- states are consecutive, so one armed frame covers both and nothing has to compare clocks.
local state = "idle"
local pickSpellId = nil
local pickName = nil

-- The supervisor above that machine. `spent` counts orbs actually handed to the server, not
-- cycles attempted: a pick the server refuses costs nothing and must not eat the budget.
local hunt = {
  active = false,
  budget = 0,
  spent  = 0,
  nextAt = 0,
}

-- The choice table last judged, held by reference. ProjectEbonhold replaces Perks.currentChoice
-- wholesale on every SEND_PLAYER_PERK_CHOICE, so identity is an exact, allocation-free answer to
-- "is this a new draw or the one I already rejected". Comparing spell ids instead would be both
-- slower and wrong: a fresh draw can legitimately repeat the previous three cards.
local lastJudged = nil

-- Set when a hunt cycle is in flight, so the reroll's own failure paths can stop the hunt with the
-- reason the player needs rather than leaving the supervisor waiting on a draw that never comes.
local huntCycleInFlight = false

-- How many orbs one forget costs. This is the game's own quality multiplier -- the slider inside
-- Ebonhold's orb dialog -- and it is read rather than offered again here: the player already has a
-- control for it, and a second one beside it would be a second answer to the same question.
--
-- Captured by watching the player's own ConfirmSpend, which carries it as its second argument.
-- Confirmed on the wire: ConfirmSpend(200421, 100) sent "1221 100|200421" and the balance went
-- 483 -> 383. One is the game's own default, so there is always a sane value to read.
local orbMultiplier = 1
-- Raised around our own ConfirmSpend so the hook below does not mistake the addon's spend for the
-- player choosing a new multiplier, which would just echo the last value back at itself.
local spendingOurselves = false

local function Multiplier()
  local n = orbMultiplier
  if type(n) ~= "number" or n < 1 then return 1 end
  return math.floor(n)
end

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(L.PREFIX .. msg)
end

--- Throttled rather than reported once and then never again. A hook can fire many times a second
--- while a hunt runs, so an error cannot be printed raw; but a single report that silences every
--- later failure hides the second bug behind the first, and the second is usually the one that
--- explains the first.
local lastReport = 0
local function Report(err)
  local now = GetTime()
  if now - lastReport < ERROR_COOLDOWN then return end
  lastReport = now
  Print(string.format(L.ERROR, tostring(err)))
end

--- Our hook bodies run inside ProjectEbonhold's own pcall around its opcode handlers, so an error
--- of ours would be printed as one of theirs and sent to the wrong author. Caught here instead.
local function Guard(fn)
  local ok, err = pcall(fn)
  if not ok then Report(err) end
end

--- Forward declaration. Every hook, every timer, every click and every hover ends in this one
--- function, and all of them are written above it.
local Refresh

------------------------------------------------------------
-- TIMERS
------------------------------------------------------------
-- A frame that is hidden receives no OnUpdate, so an idle timer here is not a loop comparing
-- clocks ten times a second - it is a frame the client skips entirely. Show is the enable bit,
-- Hide is the disable bit, and a delay that is not running costs nothing at all.

local function MakeTimer()
  local t = CreateFrame("Frame")
  t:Hide()
  t:SetScript("OnUpdate", function(f, delta)
    f.left = f.left - delta
    if f.left > 0 then return end
    -- Disarmed before the callback runs, so a callback that arms this same timer again wins
    -- instead of being cancelled by the expiry it was called from.
    f:Hide()
    local fn = f.fn
    f.fn = nil
    Guard(fn)
  end)
  return t
end

local function Arm(t, delay, fn)
  t.left, t.fn = delay, fn
  t:Show()
end

local function Cancel(t)
  t.fn = nil
  t:Hide()
end

-- One timer per concern. A hidden frame costs nothing, so sharing them would buy nothing and
-- would mean proving that no two delays can ever overlap.
--   state - the pick timeout, then the gap before the orb is spent. Those two are consecutive
--           states of one machine and genuinely cannot overlap, so they do share.
--   probe - re-asking for the orb count while the server has not answered.
--   hunt  - the floor between two hunt cycles, on the rare draw that arrives under it.
local stateTimer = MakeTimer()
local probeTimer = MakeTimer()
local huntTimer  = MakeTimer()

-- The one transition nothing announces: whether the choice now on the table came from an orb.
-- The offer flag is normally already set by the time the cards are dealt, in which case this
-- stops on its first tick. It exists for the ordering where it is not, so that a flag arriving a
-- beat late cannot leave the panel missing for the whole draw. Bounded, so a level-up draw, where
-- the flag never comes at all, costs SETTLE_WINDOW of ticks and then silence.
local settle = CreateFrame("Frame")
settle:Hide()
settle:SetScript("OnUpdate", function(f, delta)
  f.left = f.left - delta
  if f.left <= 0 then
    f:Hide()
    return
  end
  f.acc = f.acc + delta
  if f.acc < TICK then return end
  f.acc = 0
  Refresh()
end)

--- Armed only from the events that can bring a draw in. Refresh never arms it and only ever
--- disarms it, so a settling tick cannot renew the window it is running inside.
local function ArmSettle()
  settle.left, settle.acc = SETTLE_WINDOW, 0
  settle:Show()
end

local function Orb()
  return PE and PE.OrbService
end

local function Svc()
  return PE and PE.PerkService
end

local function Charges()
  local orb = Orb()
  return (orb and orb.GetCharges and orb.GetCharges()) or 0
end

--- The count is only ever written from SEND_ORB_CHARGES, and GetCharges reports an unanswered
--- server as 0. "None" and "not told yet" have to stay apart: reporting the second as the first
--- greys the button out and tells the player they own no orbs, which may be false.
local function ChargesKnown()
  local orb = Orb()
  if not orb or not orb.IsStateKnown then return true end
  return orb.IsStateKnown()
end

local OnProbeExpired

--- Nudges the server for a count while it is unknown, and keeps nudging: a single dropped request
--- would otherwise leave the button dead for the rest of the session.
---
--- The timer is both the rate limit and the retry. While it is armed an answer is outstanding, so
--- a second caller costs one IsShown and returns, and once the count is in the frame goes back to
--- being a frame nobody visits.
local function ProbeCharges()
  if ChargesKnown() then
    Cancel(probeTimer)
    return
  end
  if probeTimer:IsShown() then return end
  local orb = Orb()
  if orb and orb.RequestCharges then orb.RequestCharges() end
  Arm(probeTimer, CHARGE_PROBE_INTERVAL, OnProbeExpired)
end

--- The answer lands on a handler we do not own and cannot take over, so the next expiry is the
--- first moment we can notice it. Noticing is what closes the loop: the label reads "?" until
--- something repaints it.
function OnProbeExpired()
  if ChargesKnown() then Refresh() else ProbeCharges() end
end

local function ColoredName(spellId, quality)
  local name = GetSpellInfo(spellId) or ("Echo " .. tostring(spellId))
  return (QUALITY_COLORS[quality or 0] or "|cffFFFFFF") .. name .. "|r"
end

--- Read through the shared table at call time rather than cached at load: the two files are
--- independent and either may be the one that finished loading first.
local function Wanted(spellId)
  local wl = ns.Wishlist
  return (wl and wl.Has(spellId)) and true or false
end

local function WantedCount()
  local wl = ns.Wishlist
  return (wl and wl.Count()) or 0
end

--- With Ebonhold's auto-accept on, the server's answer to a reroll can be taken before the player
--- sees it. One draw taken from under you is a nuisance; a hunt of eighty is a run rewritten while
--- you watch, so a hunt refuses to start rather than warning and proceeding.
local function AutoAcceptOn()
  local svc = _G.ProjectEbonholdOptionsService
  if not svc or not svc.GetSetting then return false end
  local ok, value = pcall(svc.GetSetting, svc, "autoAcceptLoadoutEchoes")
  return (ok and value) and true or false
end

--- The first armed Echo on the table, or nil. Returned rather than a boolean so the message can
--- name what was found.
local function FindWanted(choices)
  if not choices or WantedCount() == 0 then return nil end
  for i = 1, #choices do
    local c = choices[i]
    if c.spellId and Wanted(c.spellId) then return c end
  end
  return nil
end

--- Permanent echoes are refused by the server's ConsumeOrbOnPerk, so a card that would land in
--- that pile is not a legal sacrifice - step 2 would bounce and the player would keep it.
---
--- Matched by exact spell id, which is the granularity the lock actually has. Each rarity of an
--- echo is its own spell id and SEND_PLAYER_PERK_GRANTED sends one line per id carrying its own
--- locked flag, so an id is wholly locked or wholly unlocked - a Common stays a legal target
--- while the Rare of the same echo is permanent. echo_journal reads it the same way: it picks
--- the cheapest UNLOCKED rarity as the orb's target and only refuses the click when no unlocked
--- copy exists at all. Matching by name instead would skip cards the server would have accepted.
local function IsPermanent(spellId)
  local svc = Svc()
  local locked = svc and svc.GetLockedPerks and svc.GetLockedPerks()
  if not locked then return false end
  for _, p in ipairs(locked) do
    if p.spellId == spellId then return true end
  end
  return false
end

--- Owned stacks of one exact spell id, plus its ceiling. grantedPerks is keyed by spell NAME
--- with one entry per stack, so both rarities of an echo share a bucket and only ids compare.
local function OwnedStacks(spellId)
  local svc = Svc()
  local granted = svc and svc.GetGrantedPerks and svc.GetGrantedPerks()
  local name = GetSpellInfo(spellId)
  if not granted or not name or not granted[name] then return 0, nil end

  local owned, maxStack = 0, nil
  for _, entry in ipairs(granted[name]) do
    if entry.spellId == spellId then
      owned = owned + 1
      maxStack = entry.maxStack or maxStack
    end
  end
  return owned, maxStack
end

--- Picks the card to take and immediately forget. Skips anything the round trip would choke on:
--- a permanent echo (step 2 refused) and a full stack (step 1 refused). Lowest quality wins, so
--- a refused step 2 leaves the player with the cheapest card on the table; the build-slot
--- guaranteed card and frozen or carried cards are last resorts, having been held for a purpose.
--- An armed Echo is never a candidate. Taking one to pay for a reroll would spend an orb to throw
--- away the very card the hunt exists to find, and on a table holding one wanted card and two
--- others it would pick the wanted one whenever it was also the cheapest.
---
--- Tests are ordered by cost, cheapest first: a hash lookup, then a walk of at most six locked
--- entries, then the stack count, which costs a GetSpellInfo and a walk of every stack owned under
--- that name. On a hunt this runs on every draw, so the ordering is not cosmetic.
local function ChooseSacrifice(choices)
  if not choices then return nil end

  local best, bestScore
  for _, c in ipairs(choices) do
    local spellId = c.spellId
    local eligible = spellId and not Wanted(spellId) and not IsPermanent(spellId)
    if eligible then
      local owned, maxStack = OwnedStacks(spellId)
      eligible = not (maxStack and owned >= maxStack)
    end
    if eligible then
      local score = c.quality or 0
      if c.isGuaranteed then score = score + 1000 end
      if c.isFrozen then score = score + 500 end
      if c.isCarried then score = score + 250 end
      if not bestScore or score < bestScore then
        best, bestScore = c, score
      end
    end
  end
  return best
end

--- Everything that must hold before the button will do anything. Returns the chosen card, or
--- nil plus the reason, which doubles as the tooltip's explanation of a greyed-out button.
---
--- The reason comes back as `fmt, impossible, a, b` rather than as a finished sentence, because
--- most callers are asking whether the button lights up and never read it. Fmt assembles it at
--- the one place that does.
---
--- The second return separates the two kinds of no. A missing resource (no orbs, count not in
--- yet) is a state the player can leave, so the button greys and says how. But when not one card
--- on the table can be forgotten again, no orb count and no waiting changes that - the draw is
--- simply not rerollable, and the button is removed rather than greyed. ProjectEbonhold draws
--- the same line with its own Reroll button on an orb offer: a disabled "Reroll (0)" would read
--- as "you are out of rerolls", which is a different and misleading statement.
local function CanReroll()
  if not PE or not Orb() or not Svc() then return nil, L.NO_ADDON end
  if state ~= "idle" then return nil, L.BUSY end

  local svc = Svc()
  local choices = svc.GetCurrentChoice and svc.GetCurrentChoice()
  if not choices or #choices == 0 then return nil, L.NO_CHOICE end

  if PE.Perks and PE.Perks.pendingSelectSpellId then
    return nil, L.PICK_IN_FLIGHT
  end

  -- Structural first, resources second. "Nothing here can be forgotten" holds however many orbs
  -- the player has, so it must not sit behind a charge check - otherwise a rerollable-in-
  -- principle draw and an impossible one both show the same greyed button at zero orbs.
  local pick = ChooseSacrifice(choices)
  if not pick then
    return nil, L.NONE_FORGETTABLE, true
  end

  if not ChargesKnown() then return nil, L.CHARGES_UNKNOWN end
  -- Against the multiplier, not against one. A reroll at 100 orbs a draw is refused at 99 held,
  -- and saying "you have no Orbs" there would be a lie the player could not act on.
  local cost = Multiplier()
  if Charges() < cost then
    if cost == 1 then return nil, L.NO_ORBS end
    return nil, L.NOT_ENOUGH_ORBS, false, cost, Charges()
  end

  return pick
end

------------------------------------------------------------
-- THE TWO STEPS
------------------------------------------------------------

--- Ends a hunt and says why. `clearList` separates the two kinds of ending: a find has consumed
--- the reason the list existed, so the list goes with it, while running out of orbs or being
--- stopped by hand leaves the intent intact and only empties the budget. The budget is zeroed
--- either way, so nothing can resume without the player moving the slider again.
local function HuntStop(reason, clearList)
  if not hunt.active then return end
  hunt.active = false
  hunt.budget = 0
  huntCycleInFlight = false
  lastJudged = nil

  local spent = hunt.spent
  hunt.spent = 0

  Cancel(huntTimer)

  if clearList and ns.Wishlist then ns.Wishlist.Clear() end
  if reason then
    Print(reason .. string.format(L.HUNT_SPENT, spent, S(spent)))
  end
  -- The hunt button says "Stop (n/N)" while it runs and has to stop saying it. Nothing else is
  -- going to come along and notice, since ending a hunt is the one transition the server is not
  -- party to.
  Refresh()
end

--- A cycle that dies mid-flight leaves the supervisor waiting on a draw the server will never
--- push, so every failure path in the two steps ends here. Written once because it was written
--- five times: the flag has to be cleared before HuntStop, or the stop would recurse through the
--- same failure it is reporting.
local function FailHuntCycle(reason)
  if not huntCycleInFlight then return end
  huntCycleInFlight = false
  HuntStop(reason, false)
end

local function Abort(reason)
  state = "idle"
  pickSpellId, pickName = nil, nil
  -- Whichever of the two waits was running is over. Left armed, a pick timeout would fire into an
  -- idle machine and a consume delay would spend an orb on a pick that was refused.
  Cancel(stateTimer)
  if reason then Print(RED .. reason .. R) end
  FailHuntCycle(L.HUNT_INTERRUPTED)
  Refresh()
end

--- Named rather than built as a closure at each reroll, because a hunt would build one per cycle
--- for a function that never varies.
local function OnPickTimeout()
  Abort(L.PICK_TIMED_OUT)
end

--- Step 2. Called a beat after the pick is confirmed, never before: the orb can only forget a
--- stack the server has already granted.
local function Spend()
  local orb, spellId, name = Orb(), pickSpellId, pickName
  state = "idle"
  pickSpellId, pickName = nil, nil

  if not orb or not spellId then
    FailHuntCycle(L.HUNT_BEFORE_SPEND)
    return
  end

  -- Last look before the charge goes. The pick's own handler asks for a fresh granted list, so
  -- by now the stack we just took may have shown up as permanent after all - in which case the
  -- server would refuse the spend and eat nothing, leaving the player wondering what happened.
  if IsPermanent(spellId) then
    Print(string.format(L.WENT_PERMANENT, name or L.THAT_ECHO))
    FailHuntCycle(L.HUNT_WENT_PERMANENT)
    return
  end

  -- The whole cost, not a single orb. Charges were checked when the button was clicked, not now,
  -- and a batch spend from the journal can empty the pool inside the gap between the two steps -
  -- sending a consume with nothing to spend would just lose the Echo we took.
  local cost = Multiplier()
  if Charges() < cost then
    Print(string.format(L.SHORT_ON_ORBS, cost, Charges(), name or L.THAT_ECHO))
    FailHuntCycle(string.format(L.HUNT_NO_ORBS, cost))
    return
  end

  -- The multiplier the player set in the game's own dialog. It reaches the server as
  -- "1221 <cost>|<spellId>" and buys quality on the draw this spend pushes.
  --
  -- This runs after the pick cleared the offer, never with a choice still on the table -- which is
  -- the state a multi-orb spend was observed working in. The two are not independent: were the
  -- order ever to change, this line would be spending into an untested state.
  spendingOurselves = true
  local sent, err = pcall(orb.ConfirmSpend, spellId, cost)
  spendingOurselves = false

  if not sent then
    Print(string.format(L.SPEND_FAILED, tostring(err)))
    FailHuntCycle(L.HUNT_SPEND_FAILED)
    return
  end

  -- Billed here and nowhere else. This is the only line in the addon that actually costs the
  -- player charges, so it is the only honest place to bill the budget: every earlier failure
  -- path returns above without spending anything.
  if huntCycleInFlight then
    huntCycleInFlight = false
    hunt.spent = hunt.spent + cost
  end

  Print(string.format(L.FORGOTTEN, name or L.THAT_ECHO, cost, S(cost)))
end

--- Every way out of the spend leaves the machine idle and the button saying "Rerolling...", and
--- on the failing ones no fresh draw is coming to correct it. Wrapped once rather than repeated
--- at each of the five returns above.
local function SpendOrb()
  Spend()
  Refresh()
end

--- Step 1. Returns true only once the selection is genuinely in flight, so the hunt can tell a
--- cycle that started from one that never left the client.
local function Reroll()
  local pick, fmt, _, a, b = CanReroll()
  if not pick then
    UIErrorsFrame:AddMessage(Fmt(fmt, a, b) or L.REROLL_CANNOT, 1, 0.2, 0.2)
    return false
  end

  pickSpellId = pick.spellId
  pickName = ColoredName(pick.spellId, pick.quality)
  state = "picking"
  Arm(stateTimer, PICK_TIMEOUT, OnPickTimeout)

  if not Svc().SelectPerk(pick.spellId) then
    Abort(L.PICK_REFUSED)
    return false
  end
  Refresh()
  return true
end

------------------------------------------------------------
-- THE HUNT
------------------------------------------------------------
-- The supervisor. It owns no protocol of its own: every cycle is the same two ordinary steps a
-- player could perform by hand, and the only thing added is the decision to perform them again.

-- What the slider is set to, which is not what the running hunt is spending. Copied into
-- hunt.budget at the moment the hunt starts so that dragging the slider mid-hunt cannot silently
-- extend a spend the player already authorised.
local budgetWanted = DEFAULT_BUDGET

--- Everything that must hold before a hunt may begin. Returns nil plus the reason, which the
--- button's tooltip shows verbatim.
local function CanHunt()
  if hunt.active then return nil, L.HUNT_RUNNING_ALREADY end
  if WantedCount() == 0 then return nil, L.NOTHING_ARMED end
  if AutoAcceptOn() then return nil, L.AUTO_ACCEPT_ON end
  if not ChargesKnown() then return nil, L.CHARGES_UNKNOWN end

  local cost = Multiplier()
  if Charges() < cost then
    return nil, L.NOT_ENOUGH_ORBS, cost, Charges()
  end
  -- A budget that cannot pay for a single draw would start a hunt and stop it on the same tick.
  -- Refusing here, naming the number that has to move, is the version the player can act on.
  if math.min(budgetWanted, Charges()) < cost then
    return nil, L.BUDGET_TOO_LOW, cost
  end
  return true
end

local function HuntStart()
  local ok, fmt, a, b = CanHunt()
  if not ok then
    UIErrorsFrame:AddMessage(Fmt(fmt, a, b) or L.HUNT_CANNOT, 1, 0.2, 0.2)
    return
  end

  hunt.active = true
  hunt.budget = math.min(budgetWanted, Charges())
  hunt.spent  = 0
  hunt.nextAt = 0
  -- Nil rather than the table on screen: the draw already dealt has never been judged against the
  -- list, and it may well be holding what the player is looking for.
  lastJudged = nil
  huntCycleInFlight = false

  local cost  = Multiplier()
  local draws = math.floor(hunt.budget / cost)
  Print(string.format(L.HUNT_STARTED, WantedCount(),
    hunt.budget, S(hunt.budget), draws, S(draws), cost))

  -- The first cycle runs against the cards already on the table, which have never been judged
  -- against the list. Nothing else would bring us back: the draw that starts a hunt arrived
  -- before the hunt existed.
  Refresh()
end

--- One decision per draw. Everything here is guarded on the choice table being one this function
--- has not already judged, which is what keeps a hunt in step with the server instead of racing
--- ahead of it: after a spend, GetCurrentChoice still returns the old cards until the new draw
--- lands, and acting on that stale view would burn orbs against a table that no longer exists.
local function HuntTick(choices)
  if not hunt.active then return end
  -- A cycle is mid-flight. The reroll's own paths will either finish it or abort it, and either
  -- way this draw has already been decided.
  if state ~= "idle" then return end
  if not choices or #choices == 0 then return end
  if choices == lastJudged then return end

  -- Deferred, not dropped. The draw that would have triggered the next evaluation is the one
  -- being held back, so returning here without arming anything would stall the hunt on a table it
  -- never judged. The old code could return because a poll was always coming round again.
  local now = GetTime()
  if now < hunt.nextAt then
    Arm(huntTimer, hunt.nextAt - now, Refresh)
    return
  end

  lastJudged = choices

  local found = FindWanted(choices)
  if found then
    HuntStop(string.format(L.HUNT_FOUND, ColoredName(found.spellId, found.quality)), true)
    return
  end

  -- Read once and used for every test below, so a multiplier changed mid-hunt cannot make the
  -- budget check and the spend disagree about what this cycle costs.
  local cost = Multiplier()

  -- Stop before overspending, never after. At 100 an orb a draw on a budget of 250 that is two
  -- cycles, not two and a half, and the third must not be started to discover it.
  if hunt.spent + cost > hunt.budget then
    HuntStop(L.HUNT_BUDGET_DONE, false)
    return
  end
  if Charges() < cost then
    HuntStop(string.format(L.HUNT_NO_ORBS, cost), false)
    return
  end

  local pick, fmt, impossible, a, b = CanReroll()
  if not pick then
    HuntStop(impossible and L.HUNT_DEAD_END
      or string.format(L.HUNT_CANNOT_REASON, Fmt(fmt, a, b) or L.REROLL_CANNOT), false)
    return
  end

  hunt.nextAt = GetTime() + HUNT_CYCLE
  huntCycleInFlight = true
  -- Reroll refused before anything left the client. FailHuntCycle is a no-op when Abort already
  -- spoke, so the two paths cannot both report the same failure.
  if not Reroll() then
    FailHuntCycle(L.HUNT_REROLL_REFUSED)
  end
end

------------------------------------------------------------
-- HOOKS
------------------------------------------------------------
-- ProjectEbonhold keeps ONE handler per opcode (ServerHandlers[id] = fn), so registering for
-- SEND_PLAYER_PERK_SELECTION_RESULT would silently replace theirs. Both outcomes of a pick are
-- reachable as plain table fields instead, and both are looked up at call time:
--   success -> OrbService.ClearOffer()      (its only call site is the success branch)
--   failure -> PerkUI.ResetSelection()      (the failure branch, and the banish handler)
--
-- ResetSelection is shared with banish replies, so it is only read as our failure once the
-- selection has actually resolved: the result handler nils pendingSelectSpellId before taking
-- either branch, while a banish reply arriving mid-pick leaves it set.
--
-- The same table fields are also what wakes the addon up. PerkUI.Show and PerkUI.Hide are called
-- on every transition the panel cares about, from the same handler that assigns currentChoice, so
-- hooking them replaces the sweep that used to look for those transitions ten times a second.

--- The perk side, and the only hooks the addon cannot run without. PerkUI is assigned at file
--- scope by ProjectEbonhold, and the .toc declares the dependency, so these are in place before
--- our PLAYER_LOGIN. Installed once, never retried: if they are missing there is no perk system
--- to graft onto, and boot has already said so.
local function InstallPerkHooks()
  local ui = PE.PerkUI

  local originalShow = ui.Show
  ui.Show = function(...)
    originalShow(...)
    -- Cards are on the table. Whether they came from an orb is the one thing no hook says, so the
    -- watcher goes up with them and Refresh takes it down as soon as the flag is in.
    ArmSettle()
    Refresh()
  end

  local originalHide = ui.Hide
  ui.Hide = function(...)
    originalHide(...)
    Refresh()
  end

  -- A banish rewrites one card in place: currentChoice keeps its identity and only the entry
  -- underneath it moves. That makes this the single change to the table that an identity check
  -- cannot see, which is why it is hooked rather than inferred.
  local originalUpdateSingle = ui.UpdateSinglePerk
  if originalUpdateSingle then
    ui.UpdateSinglePerk = function(...)
      originalUpdateSingle(...)
      Refresh()
    end
  end

  local originalResetSelection = ui.ResetSelection
  ui.ResetSelection = function(...)
    originalResetSelection(...)
    if state == "picking" and not (PE.Perks and PE.Perks.pendingSelectSpellId) then
      Abort(L.PICK_REFUSED_SERVER)
    end
  end
end

--- The orb side. OrbService is a module of ProjectEbonhold's and this addon does not get to say
--- when it is built, so unlike the perk hooks these are retried until they take.
local function InstallOrbHooks()
  if orbHooksInstalled then return end
  local orb = Orb()
  if not orb or not orb.ClearOffer then return end
  orbHooksInstalled = true

  local originalClearOffer = orb.ClearOffer
  orb.ClearOffer = function(...)
    originalClearOffer(...)
    if state == "picking" then
      state = "consuming"
      -- Armed at the instant the pick is confirmed, rather than noticed by the next sweep. A hunt
      -- cycle now waits CONSUME_DELAY and not CONSUME_DELAY plus whatever was left of a tick.
      Arm(stateTimer, CONSUME_DELAY, SpendOrb)
    end
    Refresh()
  end

  -- Reading the multiplier off the player's own spend, rather than off the dialog that carries the
  -- slider. The dialog only exists during a manual spend; the number does not, and it arrives here
  -- in the clear. Nothing is altered on the way through, and nothing is repainted from here
  -- either: a manual spend is a forget, and a forget deals a draw, so PerkUI.Show is already on
  -- its way with the new multiplier in place by the time it arrives.
  local originalConfirmSpend = orb.ConfirmSpend
  if originalConfirmSpend then
    orb.ConfirmSpend = function(spellId, count, ...)
      if not spendingOurselves and type(count) == "number" and count >= 1 then
        orbMultiplier = math.floor(count)
      end
      return originalConfirmSpend(spellId, count, ...)
    end
  end
end

-- perksHidden is a plain field on the frame, toggled by two buttons and announced to nobody.
-- Both of them are named globals, which is what makes the last poll unnecessary: HookScript
-- appends to the existing handler, so ours runs after theirs with the field already flipped.
local TOGGLE_BUTTONS = { "PerkHideButton", "PerkChooseButton" }
local togglesHooked = 0

--- Built by ProjectEbonhold on PLAYER_ENTERING_WORLD, so this is retried like the orb hooks.
--- Once both are in it costs one integer compare and returns.
local function InstallToggleHooks()
  if togglesHooked >= #TOGGLE_BUTTONS then return end
  for i = 1, #TOGGLE_BUTTONS do
    local b = _G[TOGGLE_BUTTONS[i]]
    if b and not b._eorHooked and b.HookScript then
      b._eorHooked = true
      togglesHooked = togglesHooked + 1
      b:HookScript("OnClick", Refresh)
    end
  end
end

------------------------------------------------------------
-- BUTTON
------------------------------------------------------------

local function ShowTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(L.REROLL_TITLE, 1, 0.82, 0)

  local pick, fmt, _, a, b = CanReroll()
  if pick then
    -- The cost is the multiplier, not one. This line said "1 Orb" from the version that could only
    -- ever spend one, and kept saying it after the multiplier arrived - quietly quoting a price
    -- the click would not charge.
    local cost = Multiplier()
    GameTooltip:AddLine(string.format(L.REROLL_BODY, ColoredName(pick.spellId, pick.quality)),
      1, 1, 1, true)
    GameTooltip:AddLine(string.format(L.REROLL_COST, cost, S(cost), Charges()), 1, 1, 1)
  else
    GameTooltip:AddLine(Fmt(fmt, a, b) or L.REROLL_CANNOT, 1, 0.3, 0.3, true)
  end
  GameTooltip:Show()
end

--- Match the frame's own Reroll button when Transparent Design is on, so the two read as one
--- control set rather than a native button and a bolted-on one.
local function StyleButton(b)
  local transparent = ProjectEbonholdOptionsService
      and ProjectEbonholdOptionsService:GetSetting("transparentDesign")
  if not transparent or not b.SetBackdrop then return end

  local function hideTex(t)
    if t then
      t:Hide()
      t:SetTexture(nil)
    end
  end
  hideTex(b:GetNormalTexture())
  hideTex(b:GetPushedTexture())
  hideTex(b:GetHighlightTexture())
  hideTex(b:GetDisabledTexture())

  b:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  b:SetBackdropColor(0.16, 0.08, 0.24, 0.95)
  b:SetBackdropBorderColor(0, 0, 0, 1)
  if b.text then b.text:SetFontObject("GameFontNormalSmall") end
  b._transparent = true
end

local function ShowHuntTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:ClearLines()

  local cost = Multiplier()

  if hunt.active then
    GameTooltip:AddLine(L.HUNT_RUNNING, 1, 0.82, 0)
    GameTooltip:AddLine(string.format(L.HUNT_PROGRESS, hunt.spent, hunt.budget, cost), 1, 1, 1)
    GameTooltip:AddLine(L.HUNT_CLICK_STOP, 0.6, 0.6, 0.6)
    GameTooltip:Show()
    return
  end

  GameTooltip:AddLine(L.HUNT_TITLE, 1, 0.82, 0)
  local ok, fmt, a, b = CanHunt()
  if ok then
    local budget = math.min(budgetWanted, Charges())
    local draws  = math.floor(budget / cost)
    GameTooltip:AddLine(string.format(L.HUNT_BODY, WantedCount()), 1, 1, 1, true)
    GameTooltip:AddLine(string.format(L.HUNT_BODY_COST, cost, draws, budget), 1, 1, 1, true)
    GameTooltip:AddLine(L.HUNT_BODY_MANUAL, 0.6, 0.6, 0.6, true)
    -- Only worth saying while the cost still looks like a default. Once the player has raised it
    -- the number speaks for itself, and the line becomes noise on a tooltip they read often.
    if cost == 1 then
      GameTooltip:AddLine(L.HUNT_BODY_HINT, 0.5, 0.5, 0.5, true)
    end
  else
    GameTooltip:AddLine(Fmt(fmt, a, b) or L.HUNT_CANNOT, 1, 0.3, 0.3, true)
  end
  GameTooltip:Show()
end

--- Both buttons are built the same way, through ProjectEbonhold's own factory when it is there so
--- they inherit the frame's skin, and through a plain template when it is not.
local function MakeButton(parent, label, width, onClick, onTooltip)
  local b
  local utils = _G.utils
  if utils and utils.CreateSimpleCustomButton then
    b = utils.CreateSimpleCustomButton(parent, label, nil, width, BUTTON_HEIGHT)
  else
    b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, BUTTON_HEIGHT)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
  end
  StyleButton(b)

  local glow = b:CreateTexture(nil, "OVERLAY")
  glow:SetAllPoints(b)
  glow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(0.45, 0.25, 0.7, 0.4)
  glow:Hide()
  b._glow = glow

  b:SetScript("OnEnter", function(self)
    -- The orb count is the one number that can move with no event of ours attached to it: the
    -- server pushes a new balance whenever the player loots or buys one. Re-evaluating on the way
    -- into the tooltip is free, happens exactly when somebody is about to read the number, and
    -- costs nothing on all the frames where nobody is.
    Refresh()
    if self:IsEnabled() and self._transparent then
      self:SetBackdropBorderColor(0.7, 0.4, 1, 1)
      self:SetBackdropColor(0.32, 0.16, 0.46, 0.98)
    end
    if self:IsEnabled() then self._glow:Show() end
    onTooltip(self)
  end)
  b:SetScript("OnLeave", function(self)
    if self._transparent then
      self:SetBackdropBorderColor(0, 0, 0, 1)
      self:SetBackdropColor(0.16, 0.08, 0.24, 0.95)
    end
    self._glow:Hide()
    GameTooltip:Hide()
  end)
  b:SetScript("OnClick", onClick)
  -- ProjectEbonhold's factory anchors what it builds. Cleared here so the caller's single SetPoint
  -- is the only thing positioning the button, rather than fighting a point we never asked for.
  b:ClearAllPoints()
  return b
end

--- The budget, in whole orbs, from one to however many the player is actually holding. Never a
--- percentage: "spend 24 of my 962" is the sentence the player has in mind, and a percentage would
--- make them do arithmetic to say it.
local function MakeSlider(parent)
  local s = CreateFrame("Slider", "EbonOrbRerollBudget", parent, "OptionsSliderTemplate")
  s:SetWidth(SLIDER_WIDTH)
  s:SetMinMaxValues(1, math.max(1, DEFAULT_BUDGET))
  s:SetValueStep(1)

  -- The template builds these three under predictable names. Held by reference rather than looked
  -- up on every change, and each use guarded: a skin that ships its own OptionsSliderTemplate
  -- could leave one of them out, and a missing label is not worth killing the panel over.
  local name = s:GetName()
  s._low   = _G[name .. "Low"]
  s._high  = _G[name .. "High"]
  s._label = _G[name .. "Text"]

  -- The budget stays in orbs, which is the currency the player counts in. What the multiplier adds
  -- is the translation to draws, shown beside it rather than replacing it: 250 orbs at 100 apiece
  -- is two draws, and both halves of that sentence are worth reading.
  local function Relabel(value)
    if not s._label then return end
    local cost = Multiplier()
    if cost > 1 then
      local draws = math.floor(value / cost)
      s._label:SetText(string.format(L.BUDGET_DRAWS, value, draws, S(draws), cost))
    else
      s._label:SetText(string.format(L.BUDGET, value))
    end
    s._lblValue, s._lblCost = value, cost
  end
  s._relabel = Relabel

  -- The end labels are hidden rather than filled in. They hang below the track, which is where
  -- PerkHideButton starts, and the value the player actually needs is already spelled out in the
  -- label above and in the button's tooltip.
  if s._low then s._low:Hide() end
  if s._high then s._high:Hide() end

  s:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    budgetWanted = value
    Relabel(value)
    -- The label is already written above; this is for the hunt button, which greys out when the
    -- budget drops under one draw's worth and has to come back when it rises again.
    Refresh()
  end)

  -- Set the value last, then label by hand: SetValue only fires the handler when the value really
  -- moves, and here it does not.
  s:SetValue(DEFAULT_BUDGET)
  Relabel(DEFAULT_BUDGET)
  return s
end

--- Enable, Disable, Show and Hide are C calls that already early-out on a no-op, but Refresh runs
--- several times for one draw - once on the hook, once or twice while the offer flag settles,
--- again on every hover - and each of those would repeat all four. Holding the answer in Lua
--- makes a repeated Refresh genuinely free rather than merely cheap, which is what lets the rest
--- of the file call it as freely as it does.
local function SetEnabled(w, on)
  if w._eorEnabled == on then return end
  w._eorEnabled = on
  if on then w:Enable() else w:Disable() end
end

local function SetShown(f, on)
  if f._eorShown == on then return end
  f._eorShown = on
  if on then f:Show() else f:Hide() end
end

local function EnsureUI(parent)
  if container then return container end

  container = CreateFrame("Frame", nil, parent)
  container:SetSize(ROW_WIDTH, PANEL_HEIGHT)
  container:SetFrameLevel(parent:GetFrameLevel() + 20)
  -- Anchored here rather than in Refresh, which re-anchors only if the frame this hangs from is
  -- ever rebuilt. On the first pass it has not changed, so nothing there would fire.
  container:SetPoint("TOP", parent, "BOTTOM", 0, BUTTON_Y)
  uiParent = parent

  button = MakeButton(container, "Reroll (Orb)", BUTTON_WIDTH, Reroll, ShowTooltip)
  button:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

  huntButton = MakeButton(container, "Chercher", HUNT_BUTTON_WIDTH, function()
    if hunt.active then
      HuntStop(L.HUNT_STOPPED, false)
    else
      HuntStart()
    end
  end, ShowHuntTooltip)
  huntButton:SetPoint("TOPLEFT", button, "TOPRIGHT", BUTTON_GAP, 0)

  slider = MakeSlider(container)
  slider:SetPoint("LEFT", huntButton, "RIGHT", BUTTON_GAP, 0)

  SetShown(container, false)
  return container
end

--- Keeps the slider's ceiling honest without fighting the player's hand: the bounds are only
--- rewritten when the orb count actually moved, so dragging is never interrupted by a rebuild.
local function RefreshSliderBounds()
  local maxOrbs = math.max(1, Charges())
  if slider._eorMax == maxOrbs then return end
  slider._eorMax = maxOrbs
  slider:SetMinMaxValues(1, maxOrbs)
  -- Only ever clamps downwards. Raising the ceiling must not raise what the player asked for.
  if budgetWanted > maxOrbs then slider:SetValue(maxOrbs) end
end

--- The multiplier is read from the player's own spends, so it can change while the panel is on
--- screen and without the slider moving. Repainted only when the pair actually differs, since
--- several Refreshes can land on one draw and none of them knows what the others found.
local function RefreshSliderLabel()
  if not slider or not slider._relabel then return end
  local value = math.floor(slider:GetValue() + 0.5)
  if slider._lblValue == value and slider._lblCost == Multiplier() then return end
  slider._relabel(value)
end

--- Writes a label unconditionally. The decision not to write is taken by the two callers below,
--- which know what the label is made of and can tell when none of it moved.
local function SetButtonText(b, label, enabled)
  if not b.text then return end
  b.text:SetText(label)
  local shade = enabled and 1 or 0.5
  b.text:SetTextColor(shade, shade, shade)
end

--- Both labels are rebuilt only when one of the values they are made of has actually moved.
---
--- The guard used to sit on the finished string: it skipped the SetText but paid for the
--- concatenation anyway, handing the collector short-lived strings for nothing. Comparing the
--- inputs instead costs three integer compares and allocates only when something changed. That
--- mattered under a driver running ten times a second, and it still earns its place now that
--- several Refreshes can land on a single draw.
local function SetLabel(b, enabled)
  local charges = ChargesKnown() and Charges() or nil
  if b._enabled == enabled and b._state == state and b._charges == charges then return end
  b._enabled, b._state, b._charges = enabled, state, charges

  if state ~= "idle" then
    SetButtonText(b, L.REROLL_BUSY, enabled)
  else
    SetButtonText(b, string.format(L.REROLL, charges or "?"), enabled)
  end
end

local function SetHuntLabel(b, enabled)
  local cost, count = Multiplier(), WantedCount()
  if b._enabled == enabled and b._active == hunt.active and b._spent == hunt.spent
      and b._budget == hunt.budget and b._count == count and b._cost == cost then
    return
  end
  b._enabled, b._active, b._spent = enabled, hunt.active, hunt.spent
  b._budget, b._count, b._cost = hunt.budget, count, cost

  if hunt.active then
    SetButtonText(b, string.format(L.HUNT_STOP, hunt.spent, hunt.budget), enabled)
  elseif cost > 1 then
    -- The multiplier belongs on the button, not in the tooltip. It is the difference between a
    -- hunt that costs ten orbs and one that costs a thousand, and that is not a detail to make
    -- the player hover for.
    SetButtonText(b, string.format(L.HUNT_MULT, count, cost), enabled)
  else
    SetButtonText(b, string.format(L.HUNT, count), enabled)
  end
end

------------------------------------------------------------
-- REFRESH
------------------------------------------------------------
-- What used to be a tick. Nothing polls it now: it runs when a hook fires, when a timer expires,
-- when the player clicks, drags or hovers, and at no other time. Between two draws this function
-- is not called at all, and the addon executes no Lua.
--
-- Because it is called from a dozen places rather than one, it has to be safe to call twice in a
-- row with nothing having changed. Every write it makes is behind a guard that compares what it
-- is about to write with what is already there.

local function Evaluate()
  local parent = _G.ProjectEbonholdPerkFrame
  if not parent then
    if container then SetShown(container, false) end
    return
  end

  -- Retried here rather than on a schedule of their own. OrbService and the two toggle buttons
  -- are built by ProjectEbonhold on its own timetable, and this is the function every path goes
  -- through; once they are in, both calls are an integer compare and a return.
  InstallOrbHooks()
  InstallToggleHooks()

  local svc = Svc()
  local orb = Orb()
  local choices = svc and svc.GetCurrentChoice and svc.GetCurrentChoice()
  local offerPending = orb and orb.IsOfferPending and orb.IsOfferPending() or false

  -- The hunt is driven before the panel's visibility is settled, so a cycle keeps its pace through
  -- the moment between two draws when the frame has nothing to show. It is gated on the offer
  -- being an orb draw: a level-up draw has a real Reroll button of its own and must never be
  -- touched from here, and CanReroll does not know the difference.
  if offerPending then
    -- The flag is in, which is the whole question the watcher was asking. It comes down here
    -- rather than running its window out.
    settle:Hide()
    ProbeCharges()
    HuntTick(choices)
  end

  -- Mirrors the native Reroll button: gone while the frame is down and gone while the cards are
  -- collapsed behind "Select an Echo" / "Show". Only Orb offers get the panel, since an
  -- ordinary draw already has a real Reroll button of its own.
  local relevant = parent:IsShown()
      and not parent.perksHidden
      and choices and #choices > 0
      and offerPending

  if not relevant then
    if container then SetShown(container, false) end
    return
  end

  local panel = EnsureUI(parent)
  if uiParent ~= parent then
    uiParent = parent
    panel:SetParent(parent)
    panel:SetFrameLevel(parent:GetFrameLevel() + 20)
    panel:ClearAllPoints()
    panel:SetPoint("TOP", parent, "BOTTOM", 0, BUTTON_Y)
  end

  RefreshSliderBounds()
  RefreshSliderLabel()

  local pick, _, impossible = CanReroll()
  if impossible then
    -- Nothing here can be sacrificed, so there is no reroll to offer at any price, and no hunt
    -- either. Removed rather than greyed, for the reason CanReroll's second return exists.
    SetShown(panel, false)
    return
  end

  -- The single reroll is the hunt's own engine; letting the player fire it by hand mid-hunt would
  -- put two cycles on the same table.
  local canReroll = (pick ~= nil) and not hunt.active
  SetEnabled(button, canReroll)
  SetLabel(button, canReroll)

  local canHunt = hunt.active or (CanHunt() ~= nil)
  SetEnabled(huntButton, canHunt)
  SetHuntLabel(huntButton, canHunt)

  -- Dragging the budget while a hunt is spending it would move a number the hunt already copied,
  -- which reads as an authorisation it is not.
  SetEnabled(slider, not hunt.active)

  SetShown(panel, true)
end

-- Re-entrancy is real here rather than theoretical: Refresh drives HuntTick, HuntTick starts a
-- reroll, and a reroll asks for the labels it just invalidated to be repainted. The inner call
-- would paint a half-applied state and the outer one would overwrite it a moment later, so the
-- inner call is dropped and the outer one, which finishes last and sees everything, is the one
-- that paints.
--
-- The pcall lives here rather than at each of the dozen call sites, since all of them end up in
-- this one function.
local refreshing = false
function Refresh()
  if refreshing then return end
  refreshing = true
  local ok, err = pcall(Evaluate)
  refreshing = false
  if not ok then Report(err) end
end

------------------------------------------------------------
-- BOOT
------------------------------------------------------------
-- Registers one event, handles it once, and unregisters. After that this frame does nothing and
-- the addon owns no loop of any kind.

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_LOGIN")

  PE = _G.ProjectEbonhold
  local ui = PE and PE.PerkUI
  if not PE or not PE.PerkService or not ui
      or not ui.Show or not ui.Hide or not ui.ResetSelection then
    -- Left nil so every helper that reads it keeps returning the safe answer.
    PE = nil
    Print(RED .. L.NO_PERK_SYSTEM .. R)
    return
  end

  -- The only hooks that have to be in before anything can happen, because they are what wakes the
  -- addon. The orb and toggle hooks graft themselves later, from Refresh, since ProjectEbonhold
  -- builds those parts after login.
  InstallPerkHooks()

  -- The journal is a window of its own and can be open over a draw, so arming an Echo has to
  -- reach the hunt button that counts them. This is the one edge the old sweep covered for free
  -- and the only place the two files need to know about each other beyond the string table.
  ns.OnWishlistChanged = Refresh
end)
