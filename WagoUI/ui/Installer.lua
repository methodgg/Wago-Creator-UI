-- The install view: a guided flow (variation, review, install, done) and an expert list of the same profiles.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local LWF = LibStub("LibWagoFramework")
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local button, check, dropdown, label = UI.button, UI.check, UI.dropdown, UI.label
local rowBackground, widget = UI.rowBackground, UI.widget
local confirm, notice = UI.confirm, UI.notice
local resolutionText = UI.resolutionText
local layoutName = UI.layoutName
local ctaButton = UI.ctaButton
local function render() UI.render() end

local WHITE = [[Interface\Buttons\WHITE8X8]]
local RED = addon.colorRGB
-- Highlights use Wago red (a lighter tint for text), never green.
local HIGHLIGHT, AMBER, GREY = { 1, .5, .5 }, { 1, .65, .3 }, { .55, .55, .55 }
local STEPS = { "Pick a version", "Select what to Install", "Install", "Finish" }
-- The addon font has no symbol glyphs, so marks are inline game icons.
local function icon(path, size) return "|T" .. path .. ":" .. size .. ":" .. size .. "|t" end
-- Our own white marks (media/*.tga), tinted to fit the red and grey palette.
local CHECK, CROSS, CIRCLE = [[Interface\AddOns\WagoUI\media\check]], [[Interface\AddOns\WagoUI\media\cross]],
  [[Interface\AddOns\WagoUI\media\circle]]
local LIGHT, FAILED = { .9, .9, .9 }, { 1, .35, .3 }
local ALERT = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]]
local STEP_INDEX = { home = 1, review = 2, install = 3, done = 4 }

local function installable(status) return status == "Ready" or status == "Enable addon" end

local function screenMatches(variation)
  local width, height = GetPhysicalScreenSize()
  for _, size in ipairs(variation.resolutions or {}) do
    if size.width == width and size.height == height then return true end
  end
  return variation.resolutions == nil
end

-- Release notes newest first, optionally only those published after a point in time.
local function releaseNotes(pack, after)
  local notes = {}
  for timestamp, text in pairs(pack.releaseNotes or {}) do
    local at = tonumber(timestamp)
    if at and (not after or at > after) then table.insert(notes, { at = at, text = text }) end
  end
  table.sort(notes, function(a, b) return a.at > b.at end)
  return notes
end

local function addonIcon(parent, moduleName, x, y, size)
  local lap = LAP:GetModule(moduleName)
  local texture = widget(parent, "installIcon", function() return parent:CreateTexture(nil, "ARTWORK") end)
  texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  texture:SetSize(size, size)
  texture:SetTexture(lap and lap.icon and lap.icon ~= "" and lap.icon or 134400)
  texture:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
  texture:SetDesaturated(false)
  return texture
end

local function profileName(p)
  return p.kind == "cdm" and layoutName(p.name, p.classAndSpecTag) or p.name
end

-- One short state per profile, shared by every list: what installing it would do, or why it cannot.
local function badge(pack, p, status)
  if status == "Enable addon" then return "Turns the AddOn on", AMBER end
  if status == "Class incompatible" then return "Other class", GREY end
  if status == "Addon missing" then return "AddOn not installed", GREY end
  if status == "Update addon" then return "Update AddOn first", GREY end
  if status == "Not captured" then return "Not available yet", GREY end
  if status ~= "Ready" then return status, GREY end
  local state = addon:ProfileState(pack, p)
  -- Never-installed profiles need no label; on a first install every row would say the same.
  if state == "new" then return "", { .95, .95, .95 } end
  if state == "update" then return "Update available", HIGHLIGHT end
  return "Already installed", GREY
end

-- Spells out an overwrite in the row instead of hiding it in a tooltip.
local function overwriteNote(p, status)
  if status ~= "Ready" then return nil end
  local lap = LAP:GetModule(p.moduleName)
  if lap.willOverrideProfile then return "Replaces your current settings" end
  if lap.isDuplicate and lap:isDuplicate(p.sourceKey) then return "Replaces your \"" .. p.sourceKey .. "\"" end
end

local function panel(parent, x, y, width, height)
  local f = widget(parent, "installPanel", function()
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(.1, .1, .1, 1)
    frame:SetBackdropBorderColor(.22, .22, .22, 1)
    return frame
  end)
  UI.reset(f)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, height)
  return f
end

-- Numbered steps: the current one solid red, finished ones dimmed, upcoming ones outlined.
local function stepper(body, current)
  local index = STEP_INDEX[current] or 1
  local width = body:GetWidth() / #STEPS
  for i, name in ipairs(STEPS) do
    local x = (i - 1) * width
    local badge = widget(body, "stepDot", function()
      local f = CreateFrame("Frame", nil, body, "BackdropTemplate")
      f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
      f:SetSize(22, 22)
      f.text = f:CreateFontString(nil, "OVERLAY")
      f.text:SetFont(addon.FONT, 12, "")
      f.text:SetPoint("CENTER", 0, -1)
      return f
    end)
    badge:SetPoint("TOPLEFT", body, "TOPLEFT", x, -5)
    local done, active = i < index, i == index
    if active then
      badge:SetBackdropColor(RED[1], RED[2], RED[3], 1)
      badge:SetBackdropBorderColor(RED[1], RED[2], RED[3], 1)
    elseif done then
      badge:SetBackdropColor(RED[1], RED[2], RED[3], .3)
      badge:SetBackdropBorderColor(RED[1], RED[2], RED[3], .6)
    else
      badge:SetBackdropColor(0, 0, 0, 0)
      badge:SetBackdropBorderColor(.3, .3, .3, 1)
    end
    badge.text:SetText(tostring(i))
    badge.text:SetTextColor(unpack((active or done) and { 1, 1, 1, 1 } or GREY))
    local text = label(body, name, x + 32, 8, width - 40, 14,
      active and { .95, .95, .95 } or done and { .7, .7, .7 } or { .45, .45, .45 })
    if i < #STEPS then
      -- The connector starts after the label, so long step names never run into it.
      local from = x + 32 + text:GetStringWidth() + 14
      local line = widget(body, "stepLine", function() return body:CreateTexture(nil, "ARTWORK") end)
      line:SetPoint("TOPLEFT", body, "TOPLEFT", from, -16)
      line:SetSize(math.max(0, x + width - 14 - from), 1)
      line:SetColorTexture(unpack(done and { RED[1], RED[2], RED[3], .5 } or { .25, .25, .25, 1 }))
    end
  end
end

-- Starts the live install checklist for these records.
-- Reaching Finish means this character has done a full install; the next opening starts on individual profiles.
local function finishInstall(s)
  s.step = "done"
  s.openProfilesNext = true
end

-- WeakAuras asks for confirmation in its own window, so its groups are imported one at a time.
local function needsConfirmation(p) return p.moduleName == "WeakAuras" end

local function manualPending(run)
  for id in pairs(run.manual) do
    if run.results[id] == nil then return true end
  end
end

-- Starts the live install checklist: everything else imports as one batch.
local function startInstall(pack, records)
  local s = addon.dbC.selection
  local batch, manual = {}, {}
  for _, p in ipairs(records) do
    if needsConfirmation(p) then manual[p.id] = true else table.insert(batch, p) end
  end
  s.step = "install"
  ui.run = { packID = pack.id, records = records, manual = manual, results = {}, imported = 0 }
  local run = ui.run
  if #batch == 0 then run.started, run.finished = true, true; render(); return end
  render()
  addon:ImportProfiles(pack, batch, function(imported, failed)
    run.finished = true
    run.imported = run.imported + imported
    if #failed == 0 and not manualPending(run) then finishInstall(s) end
    render()
  end, {
    onRecord = function(p, ok) run.started = true; run.results[p.id] = ok; render() end,
    -- A cancelled confirmation returns to the review instead of waiting forever.
    onCancel = function() ui.run = nil; s.step = "review"; render() end,
  })
end

-- Opens one WeakAuras group in WeakAuras' own import window, docked beside WagoUI.
local function importInWeakAuras(pack, p, onDone)
  addon:ImportProfiles(pack, { p }, function(imported)
    if WeakAurasOptions and WeakAurasOptions:IsShown() then
      LWF:StartSplitView(addon.frames.mainFrame, WeakAurasOptions, false)
    end
    if onDone then onDone(imported) end
    render()
  end, { onRecord = function(record, ok) if ui.run then ui.run.results[record.id] = ok end end })
end

local CARD_WIDTH, CARD_HEIGHT, CARD_GAP = 296, 140, 15

local function variationCards(body, pack, s, y)
  local count = #pack.variationOrder
  local perRow = math.min(3, count)
  -- Rows with fewer cards stay centered instead of hugging the left edge.
  local left = (body:GetWidth() - (perRow * CARD_WIDTH + (perRow - 1) * CARD_GAP)) / 2
  for index, id in ipairs(pack.variationOrder) do
    local v = pack.variations[id]
    local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
    local card = widget(body, "variationCard", function()
      local f = CreateFrame("Button", nil, body, "BackdropTemplate")
      f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
      f.name = f:CreateFontString(nil, "OVERLAY")
      f.name:SetFont(addon.FONT, 20, "")
      f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -18)
      f.name:SetJustifyH("LEFT")
      f.name:SetWordWrap(false)
      f.size = f:CreateFontString(nil, "OVERLAY")
      f.size:SetFont(addon.FONT, 13, "")
      f.size:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -48)
      f.size:SetJustifyH("LEFT")
      f.size:SetWordWrap(false)
      f.description = f:CreateFontString(nil, "OVERLAY")
      f.description:SetFont(addon.FONT, 12, "")
      f.description:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -68)
      f.description:SetJustifyH("LEFT")
      f.description:SetJustifyV("TOP")
      f.description:SetTextColor(.6, .6, .6, 1)
      f.match = f:CreateFontString(nil, "OVERLAY")
      f.match:SetFont(addon.FONT, 12, "")
      f.match:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 16)
      f.badge = f:CreateTexture(nil, "ARTWORK")
      f.badge:SetTexture(CIRCLE)
      f.badge:SetVertexColor(RED[1], RED[2], RED[3], 1)
      f.badge:SetSize(24, 24)
      f.badge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 12)
      f.check = f:CreateTexture(nil, "OVERLAY")
      f.check:SetTexture(CHECK)
      f.check:SetSize(16, 16)
      f.check:SetPoint("CENTER", f.badge, "CENTER", 0, 0)
      f.paint = function(self)
        local hovered = self:IsMouseOver()
        self:SetBackdropColor(unpack(self.selected and { .15, .1, .1, 1 } or hovered and { .13, .13, .13, 1 } or { .1, .1, .1, 1 }))
        if self.selected then self:SetBackdropBorderColor(RED[1], RED[2], RED[3], 1)
        else self:SetBackdropBorderColor(unpack(hovered and { .5, .5, .5, 1 } or { .25, .25, .25, 1 })) end
        self.check:SetShown(self.selected)
        self.badge:SetShown(self.selected)
      end
      f:SetScript("OnEnter", function(self) self:paint() end)
      f:SetScript("OnLeave", function(self) self:paint() end)
      f:SetScript("OnClick", function(self) self.onClick() end)
      return f
    end)
    card:SetPoint("TOPLEFT", body, "TOPLEFT", left + column * (CARD_WIDTH + CARD_GAP), -(y + row * (CARD_HEIGHT + CARD_GAP)))
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card.variationID = id
    local matches = screenMatches(v)
    card.name:SetWidth(CARD_WIDTH - 36)
    card.name:SetText(v.name)
    card.size:SetWidth(CARD_WIDTH - 36)
    card.size:SetText(resolutionText(v))
    card.size:SetTextColor(.8, .8, .8, 1)
    card.description:SetSize(CARD_WIDTH - 36, 30)
    card.description:SetWordWrap(true)
    card.description:SetText(v.description or "")
    if not v.resolutions then card.match:SetText("Works on any screen")
    elseif matches then card.match:SetText(icon(CHECK, 13) .. " Made for your screen")
    else card.match:SetText(icon(ALERT, 14) .. " Made for a different screen size") end
    card.match:SetTextColor(unpack(matches and LIGHT or AMBER))
    card.selected = id == s.variationID
    card.onClick = function() s.variationID, s.variationPicked = id, true; render() end
    card:SetEnabled(not addon.state.busy)
    card:paint()
  end
  local rows = math.ceil(count / 3)
  return y + rows * CARD_HEIGHT + (rows - 1) * CARD_GAP
end

-- Full Install steps share one navigation: "<< Back" on the left, the step forward on the right.
local function primary(text, onClick, enabled)
  local f = ctaButton(ui.footer, text, 712, 0, 240, 36, onClick, "primary", 16)
  f:SetEnabled(enabled ~= false and not addon.state.busy)
  return f
end

local function back(onClick)
  local f = ctaButton(ui.footer, "<< Back", 0, 0, 140, 36, onClick, "neutral", 15)
  f:SetEnabled(not addon.state.busy)
  return f
end

local function heading(body, title, subtitle, y)
  label(body, title, 0, y, body:GetWidth() - 120, 22)
  if subtitle then label(body, subtitle, 0, y + 32, body:GetWidth(), 14, GREY):SetWordWrap(true) end
end

-- Returning users land here when the creator published changes to profiles they installed.
local function updatesHome(body, pack, s, updates)
  ui.skipUpdates = ui.skipUpdates or {}
  local chosen = {}
  for _, p in ipairs(updates) do
    if not ui.skipUpdates[p.id] then table.insert(chosen, p) end
  end
  heading(body, pack.name .. " has " .. #updates .. (#updates == 1 and " update" or " updates"),
    "The creator changed some of the settings you installed. Update them to get the latest version.", 4)
  local y = 70
  local notes = releaseNotes(pack, addon:LastInstalledAt(pack))
  if #notes > 0 then
    local box = panel(body, 0, y, body:GetWidth(), 130)
    label(box, "What changed", 16, 12, 400, 14, GREY)
    local text = label(box, notes[1].text, 16, 34, body:GetWidth() - 32, 13, { .85, .85, .85 })
    text:SetWordWrap(true)
    text:SetHeight(84)
    text:SetJustifyV("TOP")
    y = y + 146
  end
  for _, p in ipairs(updates) do
    rowBackground(body, y, 38, .06)
    check(body, "", not ui.skipUpdates[p.id], 12, y + 4, function(value) ui.skipUpdates[p.id] = not value or nil; render() end)
    addonIcon(body, p.moduleName, 44, y + 7, 24)
    label(body, p.moduleName, 76, y + 11, 220, 15)
    label(body, profileName(p), 300, y + 12, 260, 14, { .8, .8, .8 })
    local text, color = badge(pack, p, addon:ProfileStatus(p))
    label(body, text, 570, y + 12, 200, 13, color)
    y = y + 40
  end
  body:SetHeight(y)
  button(ui.footer, "See everything instead", 0, 0, 220, function()
    ui.reviewAll = ui.reviewAll or {}
    ui.reviewAll[pack.id] = true
    render()
  end)
  primary("Update " .. #chosen .. (#chosen == 1 and " AddOn" or " AddOns"), function() startInstall(pack, chosen) end,
    #chosen > 0)
end

local function home(body, pack, s)
  stepper(body, "home")
  -- Center the cards in the space below the steps, nudged slightly above the middle.
  local rows = math.ceil(#pack.variationOrder / 3)
  local block = rows * CARD_HEIGHT + (rows - 1) * CARD_GAP
  local space = ui.scroll:GetHeight() - 48
  local y = variationCards(body, pack, s, 48 + math.max(0, math.floor((space - block) / 2) - 20))
  body:SetHeight(y + 10)
  primary("Next >>", function()
    local function nextStep() s.step = "review"; render() end
    local v = pack.variations[s.variationID]
    if screenMatches(v) then nextStep(); return end
    -- A short check before installing a version made for another screen.
    local width, height = GetPhysicalScreenSize()
    confirm({
      title = "Different screen size",
      message = v.name .. " is made for " .. resolutionText(v) .. ".",
      details = "Your screen is " .. width .. " × " .. height .. ".\nSome things may need adjusting afterwards.",
      cancelText = "Go back", confirmText = "Continue anyway", onConfirm = nextStep,
    })
  end, #Packs.Profiles(pack, s.variationID) > 0)
end

-- Plain-language reason for a profile that cannot be installed right now.
local function unavailableReason(p, status)
  if status == "Addon missing" then return "Install " .. p.moduleName .. " with the Wago App first." end
  if status == "Update addon" then return "Update " .. p.moduleName .. " first." end
  if status == "Class incompatible" then
    -- A classAndSpecTag such as 61 is class 6 (Death Knight), spec 1.
    local class = C_CreatureInfo and C_CreatureInfo.GetClassInfo(math.floor(p.classAndSpecTag / 10))
    if not class or not class.className then return "Can be imported on another class." end
    local article = class.className:find("^[AEIOUaeiou]") and "an " or "a "
    return "Can be imported on " .. article .. class.className .. "."
  end
  if status == "Not captured" then return "Not available in this UI Pack yet." end
  if status == "Profile incompatible" then return "Does not work with your version of " .. p.moduleName .. "." end
  return status
end

local function sectionTitle(body, title, y)
  label(body, title:upper(), 0, y + 4, 600, 13, GREY)
  return y + 26
end

local function review(body, pack, s)
  stepper(body, "review")
  local choices = addon:InstallChoices(pack, s.variationID)
  local selection = addon:InstallSelection(pack, s.variationID)
  local profiles = Packs.Profiles(pack, s.variationID)
  local statuses, ordinary, groups, layouts, blocked = {}, {}, {}, {}, {}
  for _, p in ipairs(profiles) do
    statuses[p] = addon:ProfileStatus(p)
    if p.kind == "cdm" then
      if installable(statuses[p]) then table.insert(layouts, p) else table.insert(blocked, p) end
    elseif p.kind == "group" then
      if installable(statuses[p]) then
        groups[p.moduleName] = groups[p.moduleName] or {}
        table.insert(groups[p.moduleName], p)
      else table.insert(blocked, p) end
    elseif selection.modules[p.moduleName] then ordinary[p.moduleName] = true
    elseif not ordinary[p.moduleName] then
      -- Only list an addon as blocked once, using its first profile.
      local listed = false
      for _, other in ipairs(blocked) do listed = listed or other.moduleName == p.moduleName end
      if not listed then table.insert(blocked, p) end
    end
  end
  -- Everything selectable, so one toggle can select or clear the whole list.
  local toggles = {}
  local modules = {}
  for moduleName in pairs(ordinary) do table.insert(modules, moduleName) end
  table.sort(modules)
  for _, moduleName in ipairs(modules) do
    local module = selection.modules[moduleName]
    table.insert(toggles, { module = moduleName, chosen = module.chosen, included = module.included })
  end
  local groupModules = {}
  for moduleName in pairs(groups) do table.insert(groupModules, moduleName) end
  table.sort(groupModules)
  for _, moduleName in ipairs(groupModules) do
    for _, p in ipairs(groups[moduleName]) do table.insert(toggles, { id = p.id, included = selection.included[p.id] }) end
  end
  table.sort(layouts, function(a, b) return a.name < b.name end)
  for _, p in ipairs(layouts) do table.insert(toggles, { id = p.id, included = selection.included[p.id] }) end
  local missing = false
  for _, toggle in ipairs(toggles) do missing = missing or not toggle.included end

  if #toggles > 0 then
    -- Sits on the first section's title line, its right edge flush with the rows below (inset by 4).
    button(body, missing and "Select all" or "Select none", body:GetWidth() - 114, 46, 110, function()
      for _, toggle in ipairs(toggles) do
        if toggle.module then choices[toggle.module] = missing and (toggle.chosen and toggle.chosen.id or nil) or false
        else choices[toggle.id] = missing end
      end
      render()
    end, nil, 26, 12)
  end
  local y = 48
  local function row(p, status, included, onToggle, moduleName, module)
    -- Unchecked rows recede: a darker row and a grey icon.
    rowBackground(body, y, 38, included and .06 or .02)
    check(body, "", included, 12, y + 4, onToggle)
    addonIcon(body, p.moduleName, 44, y + 7, 24):SetDesaturated(not included)
    if moduleName then
      label(body, moduleName, 76, y + 11, 200, 15)
      if module and #module.profiles > 1 then
        local options = {}
        for _, option in ipairs(module.profiles) do
          table.insert(options, { value = option.id, label = option.name, onclick = function() choices[moduleName] = option.id; render() end })
        end
        dropdown(body, module.chosen and module.chosen.id, options, 290, y + 3, 260, "Pick one…")
      else
        label(body, p.name, 290, y + 12, 260, 14, { .8, .8, .8 })
      end
    else
      label(body, profileName(p), 76, y + 11, 480, 15)
    end
    local text, color = badge(pack, p, status)
    label(body, text, 570, y + 12, 150, 13, color)
    -- Nothing gets replaced when the row is not installed.
    local note = included and overwriteNote(p, status)
    if note then label(body, note, 724, y + 12, 194, 12, AMBER) end
    y = y + 40
  end
  if #modules > 0 then
    y = sectionTitle(body, "AddOn settings", y)
    for _, moduleName in ipairs(modules) do
      local module = selection.modules[moduleName]
      local shown = module.chosen or module.profiles[1]
      row(shown, statuses[shown], module.included, function(value)
        choices[moduleName] = value and (module.chosen and module.chosen.id) or false
        render()
      end, moduleName, module)
    end
    y = y + 14
  end
  for _, moduleName in ipairs(groupModules) do
    y = sectionTitle(body, moduleName, y)
    for _, p in ipairs(groups[moduleName]) do
      row(p, statuses[p], selection.included[p.id], function(value) choices[p.id] = value; render() end)
    end
    y = y + 14
  end
  if #layouts > 0 then
    y = sectionTitle(body, "Cooldown Manager", y)
    label(body, "Only layouts for your class can be installed on this character.", 0, y - 4, body:GetWidth(), 12, GREY)
    y = y + 18
    for _, p in ipairs(layouts) do
      row(p, statuses[p], selection.included[p.id], function(value) choices[p.id] = value; render() end)
    end
    y = y + 14
  end
  if #blocked > 0 then
    y = sectionTitle(body, "Can't be installed right now", y)
    for _, p in ipairs(blocked) do
      rowBackground(body, y, 38, .03)
      addonIcon(body, p.moduleName, 44, y + 7, 24):SetDesaturated(true)
      local name = (p.kind == "profile" or p.kind == "snapshot") and p.moduleName or profileName(p)
      label(body, name, 76, y + 11, 300, 15, GREY)
      label(body, unavailableReason(p, statuses[p]), 390, y + 12, body:GetWidth() - 400, 13, GREY)
      y = y + 40
    end
  end
  if #profiles == 0 then label(body, "This version has nothing to install yet.", 0, y + 20, body:GetWidth(), 15, GREY) end
  body:SetHeight(y + 20)
  back(function() s.step = "home"; render() end)
  label(ui.footer, selection.problem or "", 156, 11, 540, 13, AMBER)
  local count = #selection.plan
  primary(count == 0 and "Nothing selected" or ("Install (" .. count .. ") >>"),
    function() startInstall(pack, selection.plan) end, count > 0 and not selection.problem)
end

local function installing(body, pack, s)
  stepper(body, "install")
  local run = ui.run
  local records = run and run.records or {}
  local running = addon.state.busy
  local failed, done, current = {}, 0, nil
  for _, p in ipairs(records) do
    local result = run.results[p.id]
    if result ~= nil then done = done + 1 end
    if result == false and not run.manual[p.id] then table.insert(failed, p) end
    -- The first batch record without a result is the one being imported right now.
    if running and not current and result == nil and not run.manual[p.id] then current = p end
  end
  local manual = run and manualPending(run)
  local title, subtitle = "Installing your UI…", "This only takes a moment."
  if run and not running and not run.started then title, subtitle = "Waiting for confirmation…", nil
  elseif run and run.finished and #failed > 0 then title, subtitle = "Some things couldn't be installed", "You can try those again."
  elseif run and run.finished and manual then
    title, subtitle = "Almost done: your WeakAuras", "Import them one by one. Each opens in WeakAuras, where you confirm it."
  elseif run and run.finished then title, subtitle = "Everything is installed", "Click Finish to wrap up."
  end
  heading(body, title, subtitle, 48)
  local bar = widget(body, "installProgress", function()
    local f = CreateFrame("StatusBar", nil, body)
    f:SetStatusBarTexture(WHITE)
    f.track = f:CreateTexture(nil, "BACKGROUND")
    f.track:SetAllPoints(f)
    f.track:SetColorTexture(.12, .12, .12, 1)
    return f
  end)
  bar:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -104)
  bar:SetSize(body:GetWidth() - 90, 10)
  bar:SetStatusBarColor(RED[1], RED[2], RED[3], 1)
  bar:SetMinMaxValues(0, math.max(1, #records))
  bar:SetValue(done)
  label(body, done .. " of " .. #records, body:GetWidth() - 80, 101, 80, 13, GREY):SetJustifyH("RIGHT")
  local y = 130
  for _, p in ipairs(records) do
    local result = run.results[p.id]
    rowBackground(body, y, 38, .06)
    addonIcon(body, p.moduleName, 14, y + 7, 24)
    label(body, p.moduleName, 50, y + 11, 240, 15)
    label(body, profileName(p), 300, y + 12, 380, 14, { .8, .8, .8 })
    if run.manual[p.id] and result == nil then
      -- Waits for the batch so WeakAuras' window never competes with other imports.
      local open = button(body, "Import in WeakAuras", 700, y + 4, 210, function()
        importInWeakAuras(pack, p, function(imported) run.imported = run.imported + imported end)
      end, nil, 30, 13, "manualImport")
      open:SetEnabled(run.finished and not running)
    else
      local text, color = "Waiting", GREY
      if result == true then text, color = icon(CHECK, 13) .. (run.manual[p.id] and " Opened in WeakAuras" or " Installed"), LIGHT
      elseif result == false then text, color = icon(CROSS, 13) .. " Failed", FAILED
      elseif p == current then text, color = "Installing…", { .95, .95, .95 } end
      label(body, text, 700, y + 12, 210, 13, color)
    end
    y = y + 40
  end
  body:SetHeight(y + 10)
  if not running then back(function() ui.run = nil; s.step = "review"; render() end) end
  if run and run.finished and #failed > 0 then
    primary("Try again (" .. #failed .. ")", function() startInstall(pack, failed) end)
  elseif run and run.finished then
    primary("Finish >>", function() finishInstall(s); render() end)
  end
end

local function finished(body, pack, s)
  stepper(body, "done")
  local imported = ui.run and ui.run.imported
  local width = body:GetWidth()
  local circle = widget(body, "finishCircle", function() return body:CreateTexture(nil, "ARTWORK") end)
  circle:SetTexture(CIRCLE)
  circle:SetVertexColor(RED[1], RED[2], RED[3], 1)
  circle:SetSize(60, 60)
  circle:SetPoint("TOP", body, "TOP", 0, -118)
  local mark = widget(body, "finishMark", function() return body:CreateTexture(nil, "OVERLAY") end)
  mark:SetTexture(CHECK)
  mark:SetSize(38, 38)
  mark:SetPoint("CENTER", circle, "CENTER", 0, 0)
  label(body, "You're all set!", 0, 186, width, 26):SetJustifyH("CENTER")
  local detail = addon.state.needReload and "Reload your UI to see your new interface." or "Your new interface is ready."
  label(body, detail, 0, 224, width, 15, { .75, .75, .75 }):SetJustifyH("CENTER")
  if addon.state.needReload then
    ctaButton(body, "Reload UI now", (width - 240) / 2, 268, 240, 44, ReloadUI, "primary", 17)
  else
    ctaButton(body, "Close", (width - 240) / 2, 268, 240, 44, function() addon:HideFrame() end, "neutral", 17)
  end
  if imported then
    label(body, imported .. (imported == 1 and " item" or " items") .. " installed from " .. pack.name, 0, 326, width, 12,
      { .45, .45, .45 }):SetJustifyH("CENTER")
  end
  body:SetHeight(360)
end

-- One tab per variation above the individual profile list; tabs wrap and push the list down.
local function variationChips(pack, s)
  local right, x, y = ui.tabs:GetWidth(), 0, 0
  for _, id in ipairs(pack.variationOrder) do
    local name = pack.variations[id].name
    local chip = button(ui.tabs, name, 0, 0, 132, function() s.variationID, s.variationPicked = id, true; render() end,
      nil, 28, 13, "installVariation")
    chip.text_overlay:SetText(name)
    local width = math.max(100, math.min(right, chip.text_overlay:GetStringWidth() + 32))
    if x + width > right and x > 0 then x, y = 0, y + 34 end
    chip:ClearAllPoints()
    chip:SetPoint("TOPLEFT", ui.tabs, "TOPLEFT", x, -(y + 2))
    chip:SetWidth(width)
    chip:SetTextTruncated(name, width - 12)
    local active = id == s.variationID
    -- The selected tab is solid Wago red; a translucent tint turns muddy on the dark background.
    chip:SetBackdropColor(unpack(active and { RED[1], RED[2], RED[3], 1 } or { .1, .1, .1, 1 }))
    chip.text_overlay:SetTextColor(unpack(active and { 1, 1, 1, 1 } or { .7, .7, .7, 1 }))
    x = x + width + 6
  end
  local top = 134 + y + 30 + 8
  ui.tabs:SetHeight(y + 30)
  ui.scroll:ClearAllPoints()
  ui.scroll:SetPoint("TOPLEFT", addon.frames.mainFrame, "TOPLEFT", 24, -top)
  ui.scroll:SetHeight(618 - top)
end

local function enabledAfterReload(moduleName)
  local lap = LAP:GetModule(moduleName)
  for _, name in ipairs(lap and lap.addonNames or {}) do
    if addon.state.creatorEnabled and addon.state.creatorEnabled[name] then return true end
  end
end

-- After the reload WagoUI opens again on Individual Profiles.
local function reloadIntoProfiles()
  local s = addon.dbC.selection
  s.openProfilesNext, s.reopenAfterReload = true, true
  ReloadUI()
end

local function enableAddon(moduleName)
  addon:EnableCreatorAddon(moduleName)
  confirm({
    title = "Enable AddOn", message = "Reload now to turn on " .. moduleName .. "?",
    details = "WagoUI opens again afterwards, so you can import its profile.",
    cancelText = "Later", confirmText = "Reload now", onConfirm = reloadIntoProfiles,
  })
end

-- Individual profiles: the variation's profiles as one searchable list with an action per row.
local function expertList(body, pack, s)
  local query = (ui.searchText or ""):lower()
  variationChips(pack, s)
  local profiles = Packs.Profiles(pack, s.variationID)
  -- Ordered as before the rework: loaded addons alphabetically, then disabled ones, then WeakAuras by name, and
  -- Cooldown Manager layouts for other classes last.
  local statuses, ranks, otherClass = {}, {}, {}
  local tag = CooldownViewerUtil and CooldownViewerUtil.GetCurrentClassAndSpecTag()
  for _, p in ipairs(profiles) do
    statuses[p] = addon:ProfileStatus(p)
    local lap = LAP:GetModule(p.moduleName)
    local rank = lap and (lap:isLoaded() or lap:needsInitialization()) and 1 or 0
    if p.moduleName == "WeakAuras" then rank = rank - 100 end
    otherClass[p] = p.kind == "cdm" and (not tag or math.floor(tag / 10) ~= math.floor(p.classAndSpecTag / 10))
    if otherClass[p] then rank = rank - 110 end
    ranks[p] = rank
  end
  table.sort(profiles, function(a, b)
    if a.moduleName == b.moduleName then
      if otherClass[a] ~= otherClass[b] then return not otherClass[a] end
      return a.name < b.name
    end
    if ranks[a] ~= ranks[b] then return ranks[a] > ranks[b] end
    return a.moduleName < b.moduleName
  end)
  local y = 0
  for _, p in ipairs(profiles) do
    local status = statuses[p]
    if query == "" or p.moduleName:lower():find(query, 1, true) or p.name:lower():find(query, 1, true) then
      rowBackground(body, y, 42, .06)
      addonIcon(body, p.moduleName, 14, y + 9, 24)
      label(body, p.moduleName, 50, y + 13, 230, 15)
      label(body, profileName(p), 290, y + 14, 260, 14, { .8, .8, .8 })
      label(body, p.lastUpdatedAt and date("%b %d", p.lastUpdatedAt) or "", 560, y + 14, 80, 13, GREY)
      local text, color = badge(pack, p, status)
      local state = installable(status) and addon:ProfileState(pack, p)
      if state == "current" then text, color = icon(CHECK, 13) .. " Imported", LIGHT end
      -- Here enabling is its own step: it only turns the addon on, and importing comes after the reload.
      local enabled = enabledAfterReload(p.moduleName)
      if enabled then text, color = "Turns on after reload", AMBER
      elseif status == "Enable addon" then text, color = "AddOn disabled", AMBER end
      label(body, text, 640, y + 14, 126, 13, color)
      if enabled then
        button(body, "Reload", 776, y + 6, 124, reloadIntoProfiles, nil, 30, 14, "expertAction"):SetBackdropColor(1, 1, 1, .7)
      elseif status == "Enable addon" then
        button(body, "Enable AddOn", 776, y + 6, 124, function() enableAddon(p.moduleName) end, nil, 30, 14, "expertAction")
          :SetBackdropColor(1, 1, 1, .7)
      elseif installable(status) then
        local action = state == "new" and "Import" or state == "update" and "Update" or "Re-import"
        local b = button(body, action, 776, y + 6, 124, function()
          if needsConfirmation(p) then importInWeakAuras(pack, p); return end
          addon:ImportProfiles(pack, { p }, function(_, failed)
            notice(#failed > 0 and ("Not imported: " .. table.concat(failed, ", ")) or (p.name .. " imported"))
          end)
        end, nil, 30, 14, "expertAction")
        -- Updates stand out; re-importing an up-to-date profile stays quiet.
        b:SetBackdropColor(unpack(state == "update" and { RED[1], RED[2], RED[3], 1 } or state == "current" and { .13, .13, .13, 1 }
          or { 1, 1, 1, .7 }))
      end
      y = y + 44
    end
  end
  if y == 0 then
    label(body, #profiles == 0 and "This variation has no profiles yet." or "No profiles match.", 0, 40, body:GetWidth(), 15,
      GREY):SetJustifyH("CENTER")
    y = 100
  end
  body:SetHeight(y)
end

local function install(pack)
  local body = ui.content
  if not pack then
    label(body, "No installed UI Packs found.", 0, 120, body:GetWidth(), 24):SetJustifyH("CENTER")
    label(body, "Install a UI Pack through the Wago App.", 0, 162, body:GetWidth(), 14, GREY):SetJustifyH("CENTER")
    body:SetHeight(300)
    return
  end
  local s = addon.dbC.selection
  -- Preselect a variation made for this screen until the user picks one.
  if not pack.variations[s.variationID] or not s.variationPicked then
    s.variationID = "default"
    for _, id in ipairs(pack.variationOrder) do
      local v = pack.variations[id]
      if v.resolutions and screenMatches(v) then s.variationID = id; break end
    end
  end
  -- Imports interrupted by an "enable addons and reload" continue on their own.
  local pending = s.pendingInstall
  if pending and pending.packID == pack.id and not addon.state.busy then
    s.pendingInstall = nil
    local records = {}
    for _, id in ipairs(pending.ids) do
      if pack.profiles[id] then table.insert(records, pack.profiles[id]) end
    end
    if #records > 0 then
      s.expert = false
      C_Timer.After(0, function() startInstall(pack, records) end)
    end
  end
  if s.expert then expertList(body, pack, s); return end
  local step = STEP_INDEX[s.step] and s.step or "home"
  if (step == "install" or step == "done") and not (ui.run and ui.run.packID == pack.id) and not pending then
    step = "home"
  end
  s.step = step
  if step == "home" then
    local updates = addon:PackUpdates(pack)
    if #updates > 0 and not (ui.reviewAll and ui.reviewAll[pack.id]) then updatesHome(body, pack, s, updates)
    else home(body, pack, s) end
  elseif step == "review" then review(body, pack, s)
  elseif step == "install" then installing(body, pack, s)
  else finished(body, pack, s) end
end

UI.install = install
