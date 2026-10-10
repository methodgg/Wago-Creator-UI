-- The creator tour: one callout at a time, pointing at the real control. A step finishes when the creator does it,
-- read from the UI Pack itself, so nothing is clicked through and undoing a step brings it back.
local addon = select(2, ...)
local UI = addon.UI
local ui = UI.view
local button, ctaButton, label, reset, widget = UI.button, UI.ctaButton, UI.label, UI.reset, UI.widget
local closeModal, modal = UI.closeModal, UI.modal
local function render() UI.render() end

local WHITE, ARROW = [[Interface\Buttons\WHITE8X8]], [[Interface\AddOns\WagoUI\media\calloutArrow]]
local CHECK, CIRCLE = [[Interface\AddOns\WagoUI\media\check]], [[Interface\AddOns\WagoUI\media\circle]]
local RED = addon.colorRGB
local BACKGROUND = { .08, .08, .08, .98 }
local WIDTH = 300
-- Callouts for a list row sit beside the control, so the rows above and below stay reachable.
local ROW_WIDTH = 250

local function alternates(pack)
  for _, rows in pairs((addon.db.creator.profileRows or {})[pack.id] or {}) do
    if #rows > 1 then return true end
  end
  return false
end

-- Cooldown Manager layouts join every new variation on their own, so only the creator's own choices count.
local function assigned(pack)
  for _, p in pairs(pack.profiles) do
    if p.kind ~= "cdm" then
      for id in pairs(p.variations) do
        if id ~= "default" then return true end
      end
    end
  end
  return false
end

local PARTS = {
  { title = "Your first save", steps = {
    { title = "Create your UI Pack", target = "create",
      text = "Start by giving your UI Pack a name. You can rename it later.",
      missing = "To create another one, choose + Add UI Pack in the UI Pack menu.",
      done = function() return true end },
    { title = "Pick your profiles", target = { "profile", "profileFirst" }, row = true,
      text = "Pick a profile for each AddOn you want in your UI Pack. AddOns without a profile are left out.",
      missing = "Open the All tab and clear the search to see your AddOns.",
      more = "Add profiles for any other AddOns, then click Next.",
      done = function(pack) return #pack.profileOrder > 0 or next(pack.additionalAddons) ~= nil end },
    { title = "Save all profiles", target = "save", above = true,
      text = "Save All Profiles stores every picked profile at once and reloads your UI. Save again whenever you "
        .. "change something in game. If the button is greyed out, hover it to see what's missing.",
      done = function(pack) return addon.db.creator.saved[pack.id] ~= nil end },
  } },
  { title = "Make it fit more players", steps = {
    { title = "Add a variation", target = "addVariation", align = "left",
      text = "A variation is a version of your UI Pack, like Healer or 1440p. Players pick one when they install, "
        .. "and a variation made for their screen resolution is picked for them.",
      done = function(pack) return #pack.variationOrder > 1 end },
    { title = "Add an alternate profile", target = "alternate", row = true, pin = true,
      text = "Click + to add an alternate profile. Use one when a variation needs a different profile for the same "
        .. "AddOn, like a healer layout for your unit frames.",
      missing = "Pick a profile for an AddOn first; + appears on its row. Open the All tab and clear the search if "
        .. "you can't see it.",
      done = alternates },
    { title = "Assign it to your variation", target = { "assignChip", "assignProfile" }, row = true,
      text = function(targets)
        if targets.assignChip then
          return "Click a variation name on this row to choose which variations use this profile. Each variation "
            .. "installs only the profiles assigned to it."
        end
        return "Pick the profile for this alternate row, like your healer layout."
      end,
      missing = "Open the All tab and clear the search to see your alternate profile row.",
      more = "Assign more if you like, then click Next.",
      done = assigned },
    { title = "Save again", target = "save", above = true,
      text = "Save again so players get your variations when they install. Saving reloads your UI.",
      done = function(pack)
        local copy = addon.db.creator.saved[pack.id]
        return copy ~= nil and copy.revision == pack.revision
      end },
  } },
}

-- One-off tips for states a first-time creator meets on their own; each shows once, after any running tour step.
local TIPS = {
  { id = "incomplete", target = "incomplete", row = true,
    text = "Orange rows are missing something, and Save waits until they're fixed. Hover the warning icon to see what." },
  { id = "cantSave", target = "cantSave", row = true,
    text = "Something on this row can't be saved right now. Hover the warning icon to see why and how to fix it." },
  { id = "emptyVariation", target = "emptyVariation", above = true,
    text = "Every variation needs at least one profile. Click a variation name on a row to add that profile to it." },
}

local OFFER = { title = "Make it fit more players", target = "guide", align = "right",
  text = "Learn how variations and alternate profiles let one UI Pack fit different roles and screens." }

local function tourState()
  local tour = addon.db.creatorTour or {}
  addon.db.creatorTour = tour
  tour.finished, tour.tips, tour.confirmed = tour.finished or {}, tour.tips or {}, tour.confirmed or {}
  return tour
end

local function isDone(step, pack) return pack ~= nil and step.done(pack) end

local function stepTarget(step)
  if type(step.target) == "string" then return ui.tourTargets[step.target] end
  for _, name in ipairs(step.target) do
    if ui.tourTargets[name] then return ui.tourTargets[name] end
  end
end

-- A step whose control is not on screen, like + before any profile is picked, points at the guide and says where it is.
local function stepView(step)
  local target = stepTarget(step)
  local text = type(step.text) == "function" and step.text(ui.tourTargets) or step.text
  if not target and step.missing then text = text .. "\n\n" .. step.missing end
  return { view = step, target = target or ui.tourTargets.guide, text = text, pin = target ~= nil and step.pin }
end

local function findStep(title)
  for _, part in ipairs(PARTS) do
    for _, step in ipairs(part.steps) do
      if step.title == title then return step end
    end
  end
end

-- The running part's first step still to do. Open-ended steps stay current until Next, so one pick does not rush
-- the creator on.
local function currentStep(tour, pack)
  local part = PARTS[tour.active]
  for index, step in ipairs(part and part.steps or {}) do
    local done = isDone(step, pack)
    if not done or step.more and not tour.confirmed[step.title] then return step, index, done end
  end
end

-- What to show now: a step the creator asked to see again, the running part, the part 2 offer, then a tip.
local function choose(pack)
  local tour = tourState()
  if ui.tourPeek then
    local shown = stepView(findStep(ui.tourPeek))
    shown.peek = true
    return shown
  end
  if not tour.active and not tour.finished[1] then
    -- Creators who saved a UI Pack before are past the first part.
    if next(addon.db.creator.saved) then tour.finished[1] = true else tour.active = 1 end
  end
  local part = PARTS[tour.active]
  if part and (pack or tour.active == 1) then
    local step, index, done = currentStep(tour, pack)
    if step then
      local shown = stepView(step)
      shown.counter = part.title .. ": step " .. index .. " of " .. #part.steps
      if done then shown.text, shown.next = shown.text .. "\n\n" .. step.more, step.title end
      return shown
    end
    tour.finished[tour.active], tour.active = true, nil
  end
  if tour.active then return nil end
  -- Offered once a UI Pack is saved and the Wago App handoff is behind the creator, unless it has variations already.
  if pack and addon.db.creator.saved[pack.id] and tour.finished[1] and not tour.finished[2] and not tour.offered
    and addon.db.appHandoff ~= "pending" and #pack.variationOrder == 1 then
    return { view = OFFER, target = ui.tourTargets.guide, text = OFFER.text, offer = true }
  end
  for _, tip in ipairs(TIPS) do
    if not tour.tips[tip.id] and ui.tourTargets[tip.target] then
      return { view = tip, target = ui.tourTargets[tip.target], text = tip.text, tip = tip.id }
    end
  end
end

-- Scrolled out of view, filtered away or hidden on hover: the callout waits instead of pointing at nothing.
local function onScreen(target)
  local region = target.region
  if not region:IsVisible() then return false end
  if not target.clipped then return true end
  local top, bottom = region:GetTop(), region:GetBottom()
  return top ~= nil and bottom ~= nil and top <= ui.scroll:GetTop() + 1 and bottom >= ui.scroll:GetBottom() - 1
end

-- An open dropdown menu is the creator acting on a step; the callout would cover it.
local function showable(target)
  local menuOpen = ui.openMenu and ui.openMenu:IsVisible()
  return target ~= nil and not addon.state.busy and not ui.modal:IsShown() and not menuOpen and onScreen(target)
end

local callout, follow
local function build()
  local parent = addon.frames.mainFrame
  callout = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  -- Above the workspace, below the busy lock and every dialog.
  callout:SetFrameLevel(parent:GetFrameLevel() + 60)
  callout:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
  callout:SetBackdropColor(unpack(BACKGROUND))
  callout:SetBackdropBorderColor(RED[1], RED[2], RED[3], 1)
  callout:EnableMouse(true)
  -- The fill triangle covers the border where the outline triangle meets it.
  callout.edge = callout:CreateTexture(nil, "OVERLAY", nil, 1)
  callout.edge:SetTexture(ARROW)
  callout.edge:SetVertexColor(RED[1], RED[2], RED[3], 1)
  callout.fill = callout:CreateTexture(nil, "OVERLAY", nil, 2)
  callout.fill:SetTexture(ARROW)
  callout.fill:SetVertexColor(unpack(BACKGROUND))
  callout:Hide()
  -- The callout cannot watch its own target while hidden, so a frame that stays shown does.
  callout.watcher = CreateFrame("Frame", nil, parent)
  callout.watcher:SetScript("OnUpdate", function() follow() end)
end

local function arrows(set)
  for index, arrow in ipairs({ callout.edge, callout.fill }) do
    arrow:ClearAllPoints()
    set(arrow, index == 2)
  end
end

-- To the right of a row's control, pointing left at it, or to its left when the window ends first.
-- Kept within the list's height.
local function placeRow(region)
  local main = addon.frames.mainFrame
  local top, bottom, left, right = region:GetTop(), region:GetBottom(), region:GetLeft(), region:GetRight()
  local listTop, listBottom = ui.scroll:GetTop(), ui.scroll:GetBottom()
  if not (top and bottom and left and right and listTop and listBottom and main:GetLeft()) then return end
  local height = callout:GetHeight()
  local boxTop = math.min(listTop, math.max(listBottom + height, (top + bottom + height) / 2))
  local onRight = right + 12 + ROW_WIDTH <= main:GetRight() - 8
  callout:ClearAllPoints()
  if onRight then callout:SetPoint("TOPLEFT", main, "BOTTOMLEFT", right + 12 - main:GetLeft(), boxTop - main:GetBottom())
  else callout:SetPoint("TOPRIGHT", main, "BOTTOMLEFT", left - 12 - main:GetLeft(), boxTop - main:GetBottom()) end
  -- The arrow texture points up; these coordinates turn it to point left or right.
  arrows(function(arrow, inner)
    local tuck = inner and 1 or 0
    arrow:SetSize(inner and 10 or 11, inner and 18 or 22)
    if onRight then
      arrow:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
      arrow:SetPoint("RIGHT", region, "RIGHT", 12 + tuck, 0)
    else
      arrow:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
      arrow:SetPoint("LEFT", region, "LEFT", -12 - tuck, 0)
    end
  end)
end

local function place(target, view)
  local region = target.region
  if view.row then placeRow(region); return end
  local above = view.above
  -- A target near the bottom of the window gets its callout above it rather than running off the edge.
  local bottom, floor = region:GetBottom(), addon.frames.mainFrame:GetBottom()
  if not above and bottom and floor and bottom - 12 - callout:GetHeight() < floor + 8 then above = true end
  local h = view.align == "left" and "LEFT" or view.align == "right" and "RIGHT" or ""
  local dx = view.align == "left" and -18 or 0
  callout:ClearAllPoints()
  if above then callout:SetPoint("BOTTOM" .. h, region, "TOP" .. h, dx, 12)
  else callout:SetPoint("TOP" .. h, region, "BOTTOM" .. h, dx, -12) end
  -- The arrow stays on the target's centre whatever the callout's alignment.
  arrows(function(arrow, inner)
    local offset = inner and 13 or 12
    arrow:SetSize(inner and 18 or 22, inner and 10 or 11)
    arrow:SetTexCoord(0, 1, above and 1 or 0, above and 0 or 1)
    if above then arrow:SetPoint("TOP", region, "TOP", 0, offset)
    else arrow:SetPoint("BOTTOM", region, "BOTTOM", 0, -offset) end
  end)
end

-- Rows scroll, so a row's callout follows its row each frame; the others are fixed to their control.
function follow()
  local target = callout.target
  local shown = showable(target)
  if shown and callout.view.row then place(target, callout.view) end
  callout:SetShown(shown)
end

local function fill(shown, width)
  reset(callout)
  local tour = tourState()
  local y = 14
  if shown.counter then
    label(callout, shown.counter, 16, y, width - 32, 11, { .6, .6, .6 })
    y = y + 18
  end
  if shown.view.title then
    label(callout, shown.view.title, 16, y, width - 32, 16, { 1, 1, 1 })
    y = y + 24
  end
  local text = label(callout, shown.text, 16, y, width - 32, 13, { .85, .85, .85 })
  text:SetWordWrap(true)
  y = y + text:GetStringHeight() + 16
  local function primary(title, onClick) ctaButton(callout, title, width - 16 - 110, y, 110, 28, onClick, "primary", 14) end
  local function secondary(title, onClick) ctaButton(callout, title, 16, y, 96, 28, onClick, "neutral", 13) end
  if shown.offer then
    secondary("Not now", function() tour.offered = true; render() end)
    primary("Show me", function() tour.offered, tour.active = true, 2; render() end)
  elseif shown.peek then
    primary("Got it", function() ui.tourPeek = nil; render() end)
  elseif shown.tip then
    primary("Got it", function() tour.tips[shown.tip] = true; render() end)
  else
    secondary("Skip tour", function() tour.finished[tour.active], tour.active = true, nil; render() end)
    if shown.next then primary("Next", function() tour.confirmed[shown.next] = true; render() end) end
  end
  callout:SetSize(width, y + 28 + 14)
end

-- Runs after every creator render; anything else hides the callout.
local function tour(pack, creating)
  if not callout then build() end
  callout.target = nil
  callout:Hide()
  if not creating then ui.tourPeek = nil; return end
  ui.tourPack = pack
  local shown = choose(pack)
  if not shown or not shown.target then return end
  -- Shown now rather than on the row's next hover check, so the callout has something to point at.
  if shown.pin then shown.target.control.pinned = true; shown.target.control:Show() end
  -- Pointing at the guide instead of the step's own control, the callout opens below it like the offer.
  local view = shown.target == ui.tourTargets.guide and OFFER or shown.view
  fill(shown, view.row and ROW_WIDTH or WIDTH)
  callout.target, callout.view = shown.target, view
  place(shown.target, view)
  follow()
end

-- The guide lists every step with its progress for the selected UI Pack, to start a part or see one step again.
local function guide()
  local width, pack, tour = 520, ui.tourPack, tourState()
  local f = modal("Creator guide", width, 524)
  f.error:Hide()
  local y = 70
  for partIndex, part in ipairs(PARTS) do
    label(f, part.title, 24, y + 6, 300, 18)
    local remaining = false
    for _, step in ipairs(part.steps) do remaining = remaining or not isDone(step, pack) end
    if tour.active == partIndex then
      label(f, "In progress", width - 24 - 110, y + 8, 110, 13, { .6, .6, .6 }):SetJustifyH("RIGHT")
    elseif remaining and (pack or partIndex == 1) then
      ctaButton(f, "Start", width - 24 - 110, y, 110, 30, function()
        tour.active, tour.finished[partIndex], ui.tourPeek = partIndex, nil, nil
        for _, step in ipairs(part.steps) do tour.confirmed[step.title] = nil end
        if partIndex == 2 then tour.offered = true end
        closeModal(); render()
      end, "outline", 14)
    else
      label(f, remaining and "Create a UI Pack first" or "Done", width - 24 - 200, y + 8, 200, 13,
        { .6, .6, .6 }):SetJustifyH("RIGHT")
    end
    y = y + 42
    for _, step in ipairs(part.steps) do
      local done = isDone(step, pack)
      local mark = widget(f, "guideMark", function() return f:CreateTexture(nil, "ARTWORK") end)
      mark:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -(y + 5))
      mark:SetSize(16, 16)
      mark:SetTexture(done and CHECK or CIRCLE)
      mark:SetVertexColor(unpack(done and { RED[1] + .2, RED[2] + .2, RED[3] + .2, 1 } or { .45, .45, .45, 1 }))
      label(f, step.title, 58, y + 6, 300, 14, done and { .6, .6, .6 } or { .92, .92, .92 })
      button(f, "Show", width - 24 - 80, y, 80, function()
        ui.tourPeek = step.title
        closeModal(); render()
      end, nil, 26, 13)
      y = y + 34
    end
    y = y + 18
  end
  f:SetHeight(y + 6)
end

-- Saving on an open-ended step that is done says the creator is done picking, as if Next was clicked.
-- Only the step on screen counts; a later step the tour has not reached waits for its own turn.
local function saving(pack)
  local tour = tourState()
  local step, _, done = currentStep(tour, pack)
  if step and step.more and done then tour.confirmed[step.title] = true end
end

UI.tour = tour
UI.tourSaving = saving
UI.tourGuide = guide
