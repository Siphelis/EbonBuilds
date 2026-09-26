local _, ns = ...

local CONSUME_DELAY = 0.4
local PICK_TIMEOUT = 8.0
local TICK = 0.1
local SETTLE_WINDOW = 1.0
local CHARGE_PROBE_INTERVAL = 3.0

local HUNT_CYCLE = 0.5
local DEFAULT_BUDGET = 10

local BUTTON_WIDTH = 190
local HUNT_BUTTON_WIDTH = 150
local SLIDER_WIDTH = 180
local RARITY_WIDTH = 28
local BUTTON_GAP = 8
local BUTTON_HEIGHT = 32
local ROW_WIDTH = BUTTON_WIDTH + BUTTON_GAP + HUNT_BUTTON_WIDTH + BUTTON_GAP
                  + RARITY_WIDTH + BUTTON_GAP + SLIDER_WIDTH
local PANEL_HEIGHT = BUTTON_HEIGHT
local BUTTON_Y = -8

local TOGGLE_W, TOGGLE_H = 34, 14
local KNOB = 10
local KNOB_INSET = 2
local KNOB_TRAVEL = TOGGLE_W - KNOB - KNOB_INSET
local SLIDE_TIME = 0.12
local TOGGLE_X = 0.040
local TOGGLE_Y = 0.062

local TRACK_OFF = { 0.12, 0.12, 0.12 }
local TRACK_ON  = { 0.45, 0.25, 0.70 }
local KNOB_OFF  = { 0.45, 0.45, 0.45 }
local KNOB_ON   = { 1.00, 0.82, 0.00 }

local QUALITY_COLORS = {}
for q, hex in pairs(EbonBuilds.Const.QUALITY_HEX) do QUALITY_COLORS[q] = "|cff" .. hex end

local L = ns.L
local R = ns.C.R

local function S(n)
  return n == 1 and "" or L.PLURAL
end

local function Fmt(fmt, a, b)
  if not fmt or a == nil then return fmt end
  return string.format(fmt, a, b)
end

local PE = nil
local container = nil
local button = nil
local huntButton = nil
local slider = nil
local uiParent = nil
local orbHooksInstalled = false

local state = "idle"
local pickSpellId = nil
local pickName = nil

local hunt = {
  armed  = false,
  active = false,
  budget = 0,
  spent  = 0,
  nextAt = 0,
}
ns.hunt = hunt

EbonBuilds.Reroll = EbonBuilds.Reroll or {}
function EbonBuilds.Reroll.IsHunting()
  return (hunt.armed or hunt.active) and true or false
end

local lastJudged = nil

local huntCycleInFlight = false

local orbMultiplier = 1
ns.selfCall = false

local function Multiplier()
  local n = orbMultiplier
  if type(n) ~= "number" or n < 1 then return 1 end
  return math.floor(n)
end

local function Notify(msg, r, g, b)
  UIErrorsFrame:AddMessage(msg, r or 1, g or 0.82, b or 0)
end

local function Report(err)
  EbonBuilds.Log.Error("hunt", err)
end

local Refresh

local Timer = EbonBuilds.Timer
local Arm, Cancel = Timer.Arm, Timer.Cancel

local stateTimer  = Timer.New("Hunt: pick then spend")
local probeTimer  = Timer.New("Hunt: orb count probe")
local huntTimer   = Timer.New("Hunt: cycle floor")
local unfoldTimer = Timer.New("Hunt: unfold")

local settle = CreateFrame("Frame")
if EbonBuilds.api then EbonBuilds.api:Track("Hunt: orb offer settle", settle) end
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

local function ChargesKnown()
  local orb = Orb()
  if not orb or not orb.IsStateKnown then return true end
  return orb.IsStateKnown()
end

local OnProbeExpired

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

function OnProbeExpired()
  if ChargesKnown() then Refresh() else ProbeCharges() end
end

local function ColoredName(spellId, quality)
  local name = GetSpellInfo(spellId) or ("Echo " .. tostring(spellId))
  return (QUALITY_COLORS[quality or 0] or "|cffFFFFFF") .. name .. "|r"
end

local function QualityName(q)
  local name = _G["ITEM_QUALITY" .. (q + 1) .. "_DESC"] or tostring(q)
  return (QUALITY_COLORS[q] or "") .. name .. R
end

local function Wanted(spellId)
  local wl = ns.Wishlist
  return (wl and wl.Has(spellId)) and true or false
end

local function WantedCount()
  local wl = ns.Wishlist
  return (wl and wl.Count()) or 0
end

local function AutoAcceptOn()
  local svc = EbonAPI.Ebonhold.OptionsService()
  if not svc or not svc.GetSetting then return false end
  local ok, value = pcall(svc.GetSetting, svc, "autoAcceptLoadoutEchoes")
  return (ok and value) and true or false
end

local function FindWanted(choices)
  if not choices or WantedCount() == 0 then return nil end
  for i = 1, #choices do
    local c = choices[i]
    if c.spellId and Wanted(c.spellId) then return c end
  end
  return nil
end

local function IsPermanent(spellId)
  local svc = Svc()
  local locked = svc and svc.GetLockedPerks and svc.GetLockedPerks()
  if not locked then return false end
  for _, p in ipairs(locked) do
    if p.spellId == spellId then return true end
  end
  return false
end

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

local function CanReroll()
  if not PE or not Orb() or not Svc() then return nil, L.NO_ADDON end
  if state ~= "idle" then return nil, L.BUSY end

  local svc = Svc()
  local choices = svc.GetCurrentChoice and svc.GetCurrentChoice()
  if not choices or #choices == 0 then return nil, L.NO_CHOICE end

  if PE.Perks and PE.Perks.pendingSelectSpellId then
    return nil, L.PICK_IN_FLIGHT
  end

  local pick = ChooseSacrifice(choices)
  if not pick then
    return nil, L.NONE_FORGETTABLE, true
  end

  if not ChargesKnown() then return nil, L.CHARGES_UNKNOWN end
  local cost = Multiplier()
  if Charges() < cost then
    if cost == 1 then return nil, L.NO_ORBS end
    return nil, L.NOT_ENOUGH_ORBS, false, cost, Charges()
  end

  return pick
end

local MARK_OPEN  = "|cffffff00>> |r"
local MARK_CLOSE = " |cffffff00<<|r"
local CARD_GAP   = "    "

local liveLine = nil
local liveWanted = nil
local cardParts = {}

local function CardsLine(choices, markedId)
  if not choices then return "" end
  local n = #choices
  for i = 1, n do
    local c = choices[i]
    local text = ColoredName(c.spellId, c.quality)
    if c.spellId == markedId or Wanted(c.spellId) then
      text = MARK_OPEN .. text .. MARK_CLOSE
    end
    cardParts[i] = text
  end
  return table.concat(cardParts, CARD_GAP, 1, n)
end

local function WantedLine()
  local wl = ns.Wishlist
  if not wl or wl.Count() == 0 then return nil end
  local rows = wl.Armed()
  local names = {}
  for i = 1, #rows do
    local row = rows[i]
    if row.floor ~= row.qualities[1] then
      names[i] = string.format(L.LIVE_WANTED_MIN, row.name, QualityName(row.floor))
    else
      names[i] = row.name
    end
  end
  return string.format(L.LIVE_WANTED, table.concat(names, ", "))
end

local function Live(title, line)
  liveLine = line
  local toast = EbonBuilds.Toast
  if toast and toast.ShowLive and toast.ShowLive(title, line, liveWanted) then return end
  Notify(title)
end

local function LiveTitle()
  return string.format(L.LIVE_TITLE, hunt.spent, hunt.budget, S(hunt.budget))
end

local function HuntStop(reason, clearList, line)
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
    Live(reason .. string.format(L.HUNT_SPENT, spent, S(spent)), line or liveLine)
  end
  Refresh()
end

local function FailHuntCycle(reason, detail)
  if not huntCycleInFlight then return end
  huntCycleInFlight = false
  HuntStop(reason, false, detail)
end

local function Fail(detail, huntReason)
  if huntCycleInFlight then
    FailHuntCycle(huntReason, detail)
  elseif detail then
    Notify(detail, 1, 0.3, 0.3)
  end
end

local function Abort(reason)
  state = "idle"
  pickSpellId, pickName = nil, nil
  Cancel(stateTimer)
  Fail(reason, L.HUNT_INTERRUPTED)
  Refresh()
end

local function OnPickTimeout()
  Abort(L.PICK_TIMED_OUT)
end

local function Spend()
  local orb, spellId, name = Orb(), pickSpellId, pickName
  state = "idle"
  pickSpellId, pickName = nil, nil

  if not orb or not spellId then
    FailHuntCycle(L.HUNT_BEFORE_SPEND)
    return
  end

  if IsPermanent(spellId) then
    Fail(string.format(L.WENT_PERMANENT, name or L.THAT_ECHO), L.HUNT_WENT_PERMANENT)
    return
  end

  local cost = Multiplier()
  if Charges() < cost then
    Fail(string.format(L.SHORT_ON_ORBS, cost, Charges(), name or L.THAT_ECHO),
      string.format(L.HUNT_NO_ORBS, cost))
    return
  end

  ns.selfCall = true
  local sent, err = pcall(orb.ConfirmSpend, spellId, cost)
  ns.selfCall = false

  if not sent then
    Fail(string.format(L.SPEND_FAILED, tostring(err)), L.HUNT_SPEND_FAILED)
    return
  end

  if huntCycleInFlight then
    huntCycleInFlight = false
    hunt.spent = hunt.spent + cost
    Live(LiveTitle(), CardsLine(lastJudged, spellId))
  end

end

local function SpendOrb()
  Spend()
  Refresh()
end

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

  ns.selfCall = true
  local sent = Svc().SelectPerk(pick.spellId)
  ns.selfCall = false

  if not sent then
    Abort(L.PICK_REFUSED)
    return false
  end
  Refresh()
  return true
end

local budgetWanted = DEFAULT_BUDGET

local function CanHunt()
  if hunt.active then return nil, L.HUNT_RUNNING_ALREADY end
  if WantedCount() == 0 then return nil, L.NOTHING_ARMED end
  if AutoAcceptOn() then return nil, L.AUTO_ACCEPT_ON end
  if not ChargesKnown() then return nil, L.CHARGES_UNKNOWN end

  local cost = Multiplier()
  if Charges() < cost then
    return nil, L.NOT_ENOUGH_ORBS, cost, Charges()
  end
  if math.min(budgetWanted, Charges()) < cost then
    return nil, L.BUDGET_TOO_LOW, cost
  end
  return true
end

local function HuntBegin()
  hunt.active = true
  hunt.budget = math.min(budgetWanted, Charges())
  hunt.spent  = 0
  hunt.nextAt = 0
  lastJudged = nil
  huntCycleInFlight = false

  local cost  = Multiplier()
  local draws = math.floor(hunt.budget / cost)
  liveWanted = WantedLine()
  Live(LiveTitle(), string.format(L.HUNT_STARTED, WantedCount(),
    hunt.budget, S(hunt.budget), draws, S(draws), cost))

  Refresh()
end

local function HuntStart()
  local ok, fmt, a, b = CanHunt()
  if not ok then
    UIErrorsFrame:AddMessage(Fmt(fmt, a, b) or L.HUNT_CANNOT, 1, 0.2, 0.2)
    return
  end

  HuntBegin()
end

local function ToggleHunt()
  if hunt.active then
    HuntStop(L.HUNT_STOPPED, false)
  else
    HuntStart()
  end
end

local function ToggleGuard()
  hunt.armed = not hunt.armed
  Refresh()
end

local function Unfold()
  local parent, choose = EbonAPI.Ebonhold.PerkFrame(), _G.PerkChooseButton
  if parent and parent.perksHidden and choose and choose:IsShown() then
    choose:Click()
  end
end

local function HuntTick(choices)
  if not hunt.active then return end
  if state ~= "idle" then return end
  if not choices or #choices == 0 then return end
  if choices == lastJudged then return end

  local now = GetTime()
  if now < hunt.nextAt then
    Arm(huntTimer, hunt.nextAt - now, Refresh)
    return
  end

  lastJudged = choices

  local found = FindWanted(choices)
  if found then
    HuntStop(string.format(L.HUNT_FOUND, ColoredName(found.spellId, found.quality)), true,
      CardsLine(choices))
    Arm(unfoldTimer, 0, Unfold)
    return
  end

  local cost = Multiplier()

  if hunt.spent + cost > hunt.budget then
    HuntStop(L.HUNT_BUDGET_DONE, false, CardsLine(choices))
    return
  end
  if Charges() < cost then
    HuntStop(string.format(L.HUNT_NO_ORBS, cost), false, CardsLine(choices))
    return
  end

  local pick, fmt, impossible, a, b = CanReroll()
  if not pick then
    HuntStop(impossible and L.HUNT_DEAD_END
      or string.format(L.HUNT_CANNOT_REASON, Fmt(fmt, a, b) or L.REROLL_CANNOT), false,
      CardsLine(choices))
    return
  end

  hunt.nextAt = GetTime() + HUNT_CYCLE
  huntCycleInFlight = true
  if not Reroll() then
    FailHuntCycle(L.HUNT_REROLL_REFUSED)
  end
end

local function InstallPerkHooks()
  local draw = EbonBuilds.DrawHook
  draw.Install()

  draw.After("Show", function()
    ArmSettle()
    Refresh()
  end)

  draw.After("Hide", Refresh)

  draw.After("UpdateSinglePerk", Refresh)

  draw.After("ResetSelection", function()
    if state == "picking" and not (PE.Perks and PE.Perks.pendingSelectSpellId) then
      Abort(L.PICK_REFUSED_SERVER)
    end
  end)
end

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
      Arm(stateTimer, CONSUME_DELAY, SpendOrb)
    elseif hunt.active then
      HuntStop(L.HUNT_STOPPED_CLICK, false)
    end
    Refresh()
  end

  local originalConfirmSpend = orb.ConfirmSpend
  if originalConfirmSpend then
    orb.ConfirmSpend = function(spellId, count, ...)
      if not ns.selfCall and type(count) == "number" and count >= 1 then
        orbMultiplier = math.floor(count)
      end
      return originalConfirmSpend(spellId, count, ...)
    end
  end
end

local TOGGLE_BUTTONS = { "PerkHideButton", "PerkChooseButton" }
local togglesHooked = 0

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

local function ShowTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(L.REROLL_TITLE, 1, 0.82, 0)

  local pick, fmt, _, a, b = CanReroll()
  if pick then
    local cost = Multiplier()
    GameTooltip:AddLine(string.format(L.REROLL_BODY, ColoredName(pick.spellId, pick.quality)),
      1, 1, 1, true)
    GameTooltip:AddLine(string.format(L.REROLL_COST, cost, S(cost), Charges()), 1, 1, 1)
  else
    GameTooltip:AddLine(Fmt(fmt, a, b) or L.REROLL_CANNOT, 1, 0.3, 0.3, true)
  end
  GameTooltip:Show()
end

local function StyleButton(b)
  local options = EbonAPI.Ebonhold.OptionsService()
  local transparent = options and options:GetSetting("transparentDesign")
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
    if cost == 1 then
      GameTooltip:AddLine(L.HUNT_BODY_HINT, 0.5, 0.5, 0.5, true)
    end
  else
    GameTooltip:AddLine(Fmt(fmt, a, b) or L.HUNT_CANNOT, 1, 0.3, 0.3, true)
  end
  GameTooltip:Show()
end

local rarityButton = nil
local rarityMenu = nil
local rarityRows = nil

local function QualityRGB(q)
  local const = EbonBuilds and EbonBuilds.Const
  local rgb = const and const.QUALITY_RGB and const.QUALITY_RGB[q]
  if rgb then return rgb[1], rgb[2], rgb[3] end
  return 1, 1, 1
end

local function RarityMenuInit(_, level, menuList)
  local wl = ns.Wishlist
  if not level or not wl then return end

  if level == 1 then
    rarityRows = wl.Armed()
    if #rarityRows == 0 then
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.notCheckable, info.disabled = L.NOTHING_ARMED, true, true
      UIDropDownMenu_AddButton(info, level)
      return
    end
    for i = 1, #rarityRows do
      local info = UIDropDownMenu_CreateInfo()
      info.text = rarityRows[i].name
      info.notCheckable = true
      info.hasArrow = true
      info.menuList = i
      UIDropDownMenu_AddButton(info, level)
    end
    return
  end

  local row = rarityRows and rarityRows[tonumber(menuList)]
  if not row then return end
  for i = 1, #row.qualities do
    local q = row.qualities[i]
    local info = UIDropDownMenu_CreateInfo()
    info.text = (i == 1) and L.RARITY_ANY or string.format(L.RARITY_MIN, QualityName(q))
    info.checked = (row.floor == q)
    info.func = function()
      wl.SetFloor(row.key, q)
      CloseDropDownMenus()
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

local function OpenRarityMenu(self)
  if not rarityMenu then
    rarityMenu = CreateFrame("Frame", "EbonBuildsRarityMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(rarityMenu, RarityMenuInit, "MENU")
  end
  ToggleDropDownMenu(1, nil, rarityMenu, self, 0, 0)
end

local function ShowRarityTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(L.RARITY_TITLE, 1, 0.82, 0)
  if WantedCount() == 0 then
    GameTooltip:AddLine(L.NOTHING_ARMED, 1, 0.3, 0.3, true)
  else
    GameTooltip:AddLine(L.RARITY_BODY, 1, 1, 1, true)
    GameTooltip:AddLine(L.RARITY_HINT, 0.6, 0.6, 0.6, true)
  end
  GameTooltip:Show()
end

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
  b:ClearAllPoints()
  return b
end

local function MakeSlider(parent)
  local s = CreateFrame("Slider", "EbonBuildsRerollBudget", parent, "OptionsSliderTemplate")
  s:SetWidth(SLIDER_WIDTH)
  s:SetMinMaxValues(1, math.max(1, DEFAULT_BUDGET))
  s:SetValueStep(1)

  local name = s:GetName()
  s._low   = _G[name .. "Low"]
  s._high  = _G[name .. "High"]
  s._label = _G[name .. "Text"]

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

  if s._low then s._low:Hide() end
  if s._high then s._high:Hide() end

  s:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    budgetWanted = value
    Relabel(value)
    Refresh()
  end)

  s:SetValue(DEFAULT_BUDGET)
  Relabel(DEFAULT_BUDGET)
  return s
end

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
  container:SetPoint("TOP", parent, "BOTTOM", 0, BUTTON_Y)
  uiParent = parent

  button = MakeButton(container, "Reroll (Orb)", BUTTON_WIDTH, Reroll, ShowTooltip)
  button:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

  huntButton = MakeButton(container, "Chercher", HUNT_BUTTON_WIDTH, ToggleHunt, ShowHuntTooltip)
  huntButton:SetPoint("TOPLEFT", button, "TOPRIGHT", BUTTON_GAP, 0)

  rarityButton = MakeButton(container, "", RARITY_WIDTH, OpenRarityMenu, ShowRarityTooltip)
  rarityButton:SetPoint("TOPLEFT", huntButton, "TOPRIGHT", BUTTON_GAP, 0)
  local swatch = rarityButton:CreateTexture(nil, "OVERLAY")
  swatch:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  swatch:SetWidth(RARITY_WIDTH - 14)
  swatch:SetHeight(BUTTON_HEIGHT - 18)
  swatch:SetPoint("CENTER")
  rarityButton.swatch = swatch

  slider = MakeSlider(container)
  slider:SetPoint("LEFT", rarityButton, "RIGHT", BUTTON_GAP, 0)

  SetShown(container, false)
  return container
end

local function RefreshSliderBounds()
  local maxOrbs = math.max(1, Charges())
  if slider._eorMax == maxOrbs then return end
  slider._eorMax = maxOrbs
  slider:SetMinMaxValues(1, maxOrbs)
  if budgetWanted > maxOrbs then slider:SetValue(maxOrbs) end
end

local function RefreshSliderLabel()
  if not slider or not slider._relabel then return end
  local value = math.floor(slider:GetValue() + 0.5)
  if slider._lblValue == value and slider._lblCost == Multiplier() then return end
  slider._relabel(value)
end

local function RefreshRarity()
  if not rarityButton then return end
  local wl = ns.Wishlist
  local n = (wl and wl.Count()) or 0
  local floor = (n > 0 and wl.CommonFloor()) or nil

  if rarityButton._floor == floor and rarityButton._armed == n then return end
  rarityButton._floor, rarityButton._armed = floor, n

  if floor then
    rarityButton.swatch:SetVertexColor(QualityRGB(floor))
  else
    rarityButton.swatch:SetVertexColor(0.55, 0.55, 0.55)
  end
end

local function SetButtonText(b, label, enabled)
  if not b.text then return end
  b.text:SetText(label)
  local shade = enabled and 1 or 0.5
  b.text:SetTextColor(shade, shade, shade)
end

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
    SetButtonText(b, string.format(L.HUNT_MULT, count, cost), enabled)
  else
    SetButtonText(b, string.format(L.HUNT, count), enabled)
  end
end

local toggle = nil

local function ShowGuardTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(L.TOGGLE, 1, 0.82, 0)
  GameTooltip:AddLine(L.GUARD_BODY, 1, 1, 1, true)
  GameTooltip:AddLine(hunt.armed and L.GUARD_ON or L.GUARD_OFF, 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

local function Place(x)
  local k = (x - KNOB_INSET) / (KNOB_TRAVEL - KNOB_INSET)
  toggle._x = x
  toggle.knob:SetPoint("LEFT", toggle, "LEFT", x, 0)
  toggle:SetBackdropColor(
    TRACK_OFF[1] + (TRACK_ON[1] - TRACK_OFF[1]) * k,
    TRACK_OFF[2] + (TRACK_ON[2] - TRACK_OFF[2]) * k,
    TRACK_OFF[3] + (TRACK_ON[3] - TRACK_OFF[3]) * k, 0.95)
  toggle.knob:SetVertexColor(
    KNOB_OFF[1] + (KNOB_ON[1] - KNOB_OFF[1]) * k,
    KNOB_OFF[2] + (KNOB_ON[2] - KNOB_OFF[2]) * k,
    KNOB_OFF[3] + (KNOB_ON[3] - KNOB_OFF[3]) * k)
end

local slide = CreateFrame("Frame")
if EbonBuilds.api then EbonBuilds.api:Track("Hunt: switch slide", slide) end
slide:Hide()
slide:SetScript("OnUpdate", function(f, delta)
  f.elapsed = f.elapsed + delta
  local p = f.elapsed / SLIDE_TIME
  if p >= 1 then
    f:Hide()
    Place(f.to)
    return
  end
  Place(f.from + (f.to - f.from) * p * p * (3 - 2 * p))
end)

local function PaintToggle(on)
  if not toggle or toggle._on == on then return end
  toggle._on = on
  slide.from = toggle._x or KNOB_INSET
  slide.to = on and KNOB_TRAVEL or KNOB_INSET
  slide.elapsed = 0
  slide:Show()
end

local function BuildToggle(root)
  if toggle or not root or not PE then return end

  local t = CreateFrame("Button", nil, root)
  t:SetSize(TOGGLE_W, TOGGLE_H)
  t:SetFrameLevel(root:GetFrameLevel() + 10)
  t:SetPoint("TOPRIGHT", root, "TOPRIGHT",
    -root:GetWidth() * TOGGLE_X, -root:GetHeight() * TOGGLE_Y)
  t:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    edgeSize = 2,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  t:SetBackdropBorderColor(0, 0, 0, 1)

  local knob = t:CreateTexture(nil, "OVERLAY")
  knob:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  knob:SetWidth(KNOB)
  knob:SetHeight(TOGGLE_H - 4)
  t.knob = knob

  local label = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("BOTTOM", t, "TOP", 0, 3)
  label:SetText(L.TOGGLE)

  t:SetScript("OnClick", ToggleGuard)
  t:SetScript("OnEnter", ShowGuardTooltip)
  t:SetScript("OnLeave", function() GameTooltip:Hide() end)

  toggle = t
  toggle._on = hunt.armed
  Place(hunt.armed and KNOB_TRAVEL or KNOB_INSET)
end

local function Evaluate()
  PaintToggle(hunt.armed)

  local parent = EbonAPI.Ebonhold.PerkFrame()
  if not parent then
    if container then SetShown(container, false) end
    return
  end

  InstallOrbHooks()
  InstallToggleHooks()

  local svc = Svc()
  local orb = Orb()
  local choices = svc and svc.GetCurrentChoice and svc.GetCurrentChoice()
  local offerPending = orb and orb.IsOfferPending and orb.IsOfferPending() or false

  if offerPending then
    settle:Hide()
    ProbeCharges()
    HuntTick(choices)
  end

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
    SetShown(panel, false)
    return
  end

  local canReroll = (pick ~= nil) and not hunt.active
  SetEnabled(button, canReroll)
  SetLabel(button, canReroll)

  local canHunt = hunt.active or (CanHunt() ~= nil)
  SetEnabled(huntButton, canHunt)
  SetHuntLabel(huntButton, canHunt)

  SetEnabled(rarityButton, WantedCount() > 0)
  RefreshRarity()

  SetEnabled(slider, not hunt.active)

  SetShown(panel, true)
end

local refreshing = false
function Refresh()
  if refreshing then return end
  refreshing = true
  local ok, err = pcall(Evaluate)
  refreshing = false
  if not ok then Report(err) end
end

local function OnWishlistChanged()
  if hunt.active then liveWanted = WantedLine() end
  Refresh()
end

local Boot
Boot = function()
  EbonBuilds.Events.Off("PLAYER_LOGIN", Boot)

  PE = EbonAPI.Ebonhold.Raw()
  local ui = PE and PE.PerkUI
  if not PE or not PE.PerkService or not ui
      or not ui.Show or not ui.Hide or not ui.ResetSelection then
    PE = nil
    EbonBuilds.Log.Warn(L.NO_PERK_SYSTEM)
    return
  end

  InstallPerkHooks()

  ns.OnWishlistChanged = OnWishlistChanged

  ns.OnJournalFound = BuildToggle
end

EbonBuilds.Events.On("PLAYER_LOGIN", Boot, "Hunt boot")
