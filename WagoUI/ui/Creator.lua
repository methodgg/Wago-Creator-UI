-- The creator view: one row group per addon with profile selectors and variation chips.
local addon = select(2, ...)
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local PROFILE_WIDTH, PROFILE_X, VARIATIONS_RIGHT = UI.PROFILE_WIDTH, UI.PROFILE_X, UI.VARIATIONS_RIGHT
local VARIATIONS_X, addonRow, button, dropdown, label = UI.VARIATIONS_X, UI.addonRow, UI.button, UI.dropdown, UI.label
local profileConnector, rowBackground, widget = UI.profileConnector, UI.rowBackground, UI.widget
local safely = UI.safely
local variationTabs, variationToggle = UI.variationTabs, UI.variationToggle
local additionalAddons, exportOptions, saveCapture = UI.additionalAddons, UI.exportOptions, UI.saveCapture
local wagoAddons = UI.wagoAddons
local CDM, cooldownManager, includedLayouts = UI.CDM, UI.cooldownManager, UI.includedLayouts
local ctaButton, startSetup = UI.ctaButton, UI.startSetup
local function render() UI.render() end

-- Empty row slots are creator state, never installable profiles in published packs.
local function creatorRows(pack, moduleName)
  addon.db.creator.profileRows = addon.db.creator.profileRows or {}
  local stored = addon.db.creator.profileRows
  if not addon.db.creator.emptyRowsUnseeded then
    -- Unused main rows used to be pre-seeded with Default, which now reads as a half-done row.
    for _, modules in pairs(stored) do
      for _, rows in pairs(modules) do
        if rows[1] and not rows[1].profileID then rows[1].variations = {} end
      end
    end
    addon.db.creator.emptyRowsUnseeded = true
  end
  stored[pack.id] = stored[pack.id] or {}
  local rows = stored[pack.id][moduleName] or { { variations = {} } }
  stored[pack.id][moduleName] = rows
  local seen = {}
  for index = #rows, 1, -1 do
    local row = rows[index]
    if row.profileID and not pack.profiles[row.profileID] then
      if index == 1 then row.profileID, row.variations = nil, {}
      else table.remove(rows, index) end
    elseif row.profileID then seen[row.profileID] = true end
  end
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == moduleName and not seen[p.id] then
      if not rows[1].profileID and not rows[1].cleared then rows[1].profileID = p.id
      else table.insert(rows, { profileID = p.id }) end
    end
  end
  return rows
end

local function rowAction(parent, texture, x, y, tooltip, callback)
  local icon = widget(parent, "rowAction", function() return LWF:CreateIconButton(parent, 28, "") end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -(y + 8))
  icon:SetBackdrop(nil)
  icon.disabled_overlay:SetTexture(nil)
  icon:SetTexture(texture or "", true, true, true)
  if not texture then
    for _, region in ipairs({ icon:GetNormalTexture(), icon:GetPushedTexture(), icon:GetHighlightTexture(), icon:GetDisabledTexture() }) do
      region:SetAtlas("communities-icon-addgroupplus")
    end
  end
  icon:GetDisabledTexture():SetDesaturated(true)
  icon:SetTooltip(tooltip)
  addon:UseWidgetTooltip(icon)
  icon:SetEnabled(not addon.state.busy)
  icon:SetClickFunction(callback)
  return icon
end

-- Explains why a row is incomplete; an untouched main row is simply unused.
local function rowWarning(index, p, tags)
  if p and not next(tags) then return "No variation assigned.\nClick a variation to include this profile in it." end
  if not p and next(tags) then return "No profile selected.\nChoose a profile for the assigned variations." end
  if not p and index > 1 then return "Empty alternate profile.\nChoose a profile and a variation, or remove this row." end
end

local function emptyRow(parent, y, height)
  local shade = widget(parent, "emptyShade", function() return parent:CreateTexture(nil, "BACKGROUND", nil, 2) end)
  shade:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  shade:SetSize(parent:GetWidth() - 8, height)
  shade:SetColorTexture(0, 0, 0, .3)
end

local function unassignedRow(parent, y, height, tooltip)
  local tint = widget(parent, "unassignedTint", function() return parent:CreateTexture(nil, "BACKGROUND", nil, 2) end)
  tint:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  tint:SetSize(parent:GetWidth() - 8, height)
  tint:SetColorTexture(.95, .6, .1, .12)
  local stripe = widget(parent, "unassignedStripe", function() return parent:CreateTexture(nil, "BORDER") end)
  stripe:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  stripe:SetSize(3, height)
  stripe:SetColorTexture(.95, .62, .15, 1)
  local icon = widget(parent, "unassignedIcon", function()
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(22, 22)
    f:EnableMouse(true)
    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetAllPoints(f)
    f.texture:SetTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
    f:SetScript("OnEnter", function(self) addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) addon.HideWidgetTooltip(self) end)
    return f
  end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", PROFILE_X - 26, -(y + 11))
  icon:SetFrameLevel(parent:GetFrameLevel() + 5)
  icon.tooltip = tooltip
end

-- Disables Save All and explains why; disabled buttons do not reliably report hover, so a frame above them does.
local function blockSave(saveAll, reason)
  saveAll:SetEnabled(not addon.state.busy and reason == nil)
  local blocker = widget(ui.footer, "saveBlocker", function()
    local f = CreateFrame("Frame", nil, ui.footer)
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self) addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) addon.HideWidgetTooltip(self) end)
    return f
  end)
  local saveFrame = saveAll.widget or saveAll.button or saveAll
  blocker:SetAllPoints(saveFrame)
  blocker:SetFrameLevel(saveFrame:GetFrameLevel() + 5)
  blocker.tooltip = reason
  blocker:SetShown(reason ~= nil)
end

-- Without a UI Pack the creator keeps its layout but locks it; the only action creates the first pack.
local function lockedCreator(body)
  variationTabs(Packs.New("locked", "UI Pack"), nil, true)
  blockSave(button(ui.footer, "Save All Profiles", (ui.footer:GetWidth() - 300) / 2, -14, 300, nil, nil, 50, 20),
    "Create your UI Pack first.")
  local height = ui.scroll:GetHeight()
  ctaButton(body, "Create your UI Pack", (body:GetWidth() - 320) / 2, (height - 56) / 2, 320, 56, startSetup, "primary", 20)
  body:SetHeight(height)
end

local function creator(pack)
  local body = ui.content
  if not pack then lockedCreator(body); return end
  ui.variationTabs = ui.variationTabs or {}
  local filter = ui.variationTabs[pack.id]
  if filter and not pack.variations[filter] then filter, ui.variationTabs[pack.id] = nil, nil end
  -- Variation tabs are a read-only view of what installs; every edit happens in "All".
  local locked = filter ~= nil
  variationTabs(pack, filter)

  local infos = addon:CreatorAddons()
  local saved = addon.db.creator.saved[pack.id]
  local y = 0
  local query = (ui.searchText or ""):lower()
  local function found(text) return text:lower():find(query, 1, true) end
  local function variationFound(tags)
    for id in pairs(tags) do
      if pack.variations[id] and found(pack.variations[id].name) then return true end
    end
  end
  local hasNotInstalled, listed, unassigned, profilesListed = false, false, {}, false
  -- Pack-wide extras are not tied to a variation, so previews leave them out.
  local extrasPending = not filter and found("Additional Addons")
  local function additionalRow()
    extrasPending = false
    listed = true
    local known, extras = wagoAddons(), {}
    for id, name in pairs(pack.additionalAddons) do
      table.insert(extras, { name = name, icon = known[id] and known[id].icon })
    end
    table.sort(extras, function(a, b) return a.name:lower() < b.name:lower() end)
    local groupStart = y
    local icon = addonRow(body, "Additional Addons", y, { .95, .95, .95 }, nil, nil, true)
    icon:SetEnabled(not addon.state.busy)
    icon:SetTooltip("Choose additional addons to include")
    icon:SetClickFunction(function() additionalAddons(pack) end)
    button(body, #extras > 0 and ("Manage (" .. #extras .. ")") or "Manage", PROFILE_X, y + 6, PROFILE_WIDTH,
      function() additionalAddons(pack) end, "Choose additional addons to include", 32)
    y = y + 44
    if #extras > 0 then
      -- Branch the included addons below Manage, like an alternate profile, wrapping as needed.
      local left = PROFILE_X + 16
      local x, lineY = left, y
      for _, item in ipairs(extras) do
        local name = label(body, item.name, 0, 0, 400, 14)
        local width = math.min(VARIATIONS_RIGHT - left - 26, name:GetStringWidth() + 2)
        if x + 26 + width > VARIATIONS_RIGHT and x > left then x, lineY = left, lineY + 26 end
        local texture = widget(body, "extraAddonIcon", function() return body:CreateTexture(nil, "ARTWORK") end)
        texture:SetPoint("TOPLEFT", body, "TOPLEFT", x, -(lineY + 12))
        texture:SetSize(20, 20)
        texture:SetTexture(tonumber(item.icon) or item.icon or 134400)
        texture:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
        name:SetPoint("TOPLEFT", body, "TOPLEFT", x + 26, -(lineY + 15))
        name:SetWidth(width)
        x = x + 26 + width + 18
      end
      profileConnector(body, PROFILE_X + 8, groupStart + 38, 1, y + 22 - groupStart - 38 + 1)
      profileConnector(body, PROFILE_X + 8, y + 22, 6, 1)
      y = lineY + 44
    end
    rowBackground(body, groupStart, y - groupStart - 1, .18)
    -- Like an unused addon row, an empty extras row recedes until addons are chosen.
    if #extras == 0 then emptyRow(body, groupStart, y - groupStart - 1) end
  end
  for _, info in ipairs(infos) do
    -- Sits below the last loaded addon, ahead of disabled and missing ones.
    if extrasPending and info.group ~= 1 then additionalRow() end
    if info.status == "Not installed" then hasNotInstalled = true end
    local moduleName, ready = info.name, info.status == "Ready"
    -- Cooldown Manager layouts are picked in their own manager and ship with every variation: one manage row.
    local cdm = moduleName == CDM
    local rows = cdm and { { manage = true } } or creatorRows(pack, moduleName)
    local layouts = cdm and includedLayouts(pack) or {}
    local addonFound, shown = found(moduleName), {}
    for index, row in ipairs(rows) do
      local p = row.profileID and pack.profiles[row.profileID]
      local tags = p and p.variations or row.variations or {}
      if rowWarning(index, p, tags) then unassigned[moduleName] = true end
      if (not filter or tags[filter]) and (addonFound or p and found(p.name) or variationFound(tags)) then
        table.insert(shown, index)
      end
    end
    if cdm then
      -- Listed when it or a layout matches; previews show it whenever layouts are included.
      local match = addonFound
      for _, p in ipairs(layouts) do match = match or found(p.name) end
      shown = match and (not filter or #layouts > 0) and { 1 } or {}
    end
    -- Previews list everything the variation installs, so missing addons are never collapsed there.
    if #shown > 0 and (info.status ~= "Not installed" or ui.showNotInstalled or query ~= "" or filter) then
      listed, profilesListed = true, true
      local lap = LAP:GetModule(moduleName)
      local groupStart, lastBranch = y, nil
      for position, index in ipairs(shown) do
        local row = rows[index]
        row.moduleName = moduleName
        local p = row.profileID and pack.profiles[row.profileID]
        local tags = p and p.variations or row.variations or {}
        local function toggle(id)
          safely(function()
            local changed = CopyTable(tags)
            changed[id] = not tags[id] or nil
            if p then Packs.SetMembership(pack, p.id, changed) else row.variations = changed end
          end)
          render()
        end
        local chipX, chipY = VARIATIONS_X, y + 9
        for _, id in ipairs(row.manage and {} or pack.variationOrder) do
          -- A variation tab shows only what is assigned; "All" offers every toggle.
          if tags[id] or not filter then
            local chip, width = variationToggle(body, pack.variations[id].name, id, tags[id],
              not locked and function() toggle(id) end or nil, locked)
            if chipX + width > VARIATIONS_RIGHT and chipX > VARIATIONS_X then chipX, chipY = VARIATIONS_X, chipY + 30 end
            chip:SetPoint("TOPLEFT", body, "TOPLEFT", chipX, -chipY)
            chipX = chipX + width + 4
          end
        end
        local height = math.max(44, chipY - y + 35)
        local warning, rowHeight = rowWarning(index, p, tags), position == #shown and height - 1 or height
        if warning then unassignedRow(body, y, rowHeight, warning)
        elseif not p and not (row.manage and #layouts > 0) then emptyRow(body, y, rowHeight) end
        if position == 1 then
          local status = info.status ~= "Ready" and info.status or nil
          if info.status == "Addon disabled" then status = "AddOn disabled - click to enable" end
          addonRow(body, moduleName, y, lap:isLoaded() and { .95, .95, .95 } or { .5, .5, .5 }, status, nil, true)
          if info.status == "Addon disabled" or info.status == "Enabled after reload" or info.status == "Needs setup" then
            -- Keep the old row click action without rendering a styled status button.
            local hit = widget(body, "statusAction", function() return CreateFrame("Button", nil, body) end)
            hit:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
            hit:SetSize(PROFILE_X - 12, height)
            hit:SetEnabled(not addon.state.busy)
            hit:SetScript("OnClick", function()
              if info.status == "Addon disabled" then addon:EnableCreatorAddon(moduleName)
              elseif info.status == "Enabled after reload" then ReloadUI()
              else addon:EnsureIntegration(moduleName); render() end
            end)
          end
        else
          lastBranch = y + 22
          profileConnector(body, PROFILE_X + 8, lastBranch, 8, 1)
        end

        local function clear()
          if row.profileID then Packs.RemoveProfile(pack, row.profileID) end
          -- The main row keeps its variations so the next profile picked inherits them.
          if index == 1 then row.profileID, row.cleared = nil, true; row.variations = CopyTable(tags)
          else table.remove(rows, index) end
          render()
        end
        if row.manage then
          local manage = button(body, #layouts > 0 and ("Manage (" .. #layouts .. ")") or "Manage", PROFILE_X, y + 6,
            PROFILE_WIDTH, function() cooldownManager(pack) end, "Choose Cooldown Manager profiles to include", 32)
          manage:SetEnabled(ready and not locked and not addon.state.busy)
        else
          local current = ready and lap.getCurrentProfileKey and lap:getCurrentProfileKey()
          local entries = {}
          if p then entries[1] = { value = p.id, label = current == p.sourceKey and ("|cff009ECC" .. p.name .. "|r (active)") or p.name } end
          -- DF needs an initial option to open; enumerate profiles only when opened.
          entries[#entries + 1] = { value = "none", label = "Not selected", onclick = clear }
          local indent = position == 1 and 0 or 16
          local selector = dropdown(body, p and p.id or "none", entries, PROFILE_X + indent, y + 6, PROFILE_WIDTH - indent)
          selector.moduleName, selector.profileRow = moduleName, row
          local prior = p and p.data and saved and saved.profiles[p.id]
          if prior and (prior.sourceKey ~= p.sourceKey or prior.sourceCharacter ~= p.sourceCharacter) then prior = nil end
          local timestamp = prior and (prior.lastSavedAt or prior.lastUpdatedAt)
          local savedText = timestamp and ("Last save: " .. date("%b %d, %H:%M", timestamp)) or "Not saved yet"
          selector:SetTooltip(p and (position == 1 and savedText or (moduleName .. "\n" .. savedText)) or nil)
          addon:UseWidgetTooltip(selector)
          selector.OnMouseDownHook = function(_, _, options)
            for i = #options, 1, -1 do options[i] = nil end
            options[1] = { value = "none", label = "Not selected", font = addon.FONT, onclick = clear }
            local sources = addon:ProfileSources(moduleName)
            for sourceIndex, source in ipairs(sources) do
              options[#options + 1] = { value = sourceIndex, label = source.active and ("|cff009ECC" .. source.key .. "|r (active)") or source.label,
                font = addon.FONT, onclick = function()
                safely(function()
                  if row.profileID then Packs.SetSource(pack, row.profileID, source)
                  else
                    -- Chips picked beforehand win; otherwise an addon's first profile joins Default.
                    local tags = row.variations and next(row.variations) and row.variations or (index == 1 and { default = true } or {})
                    row.profileID = Packs.AddProfile(pack, moduleName, source.key, source.key,
                      tags, source.kind, source.character, source.classAndSpecTag)
                  end
                  addon.state.notice = nil
                end)
                render()
              end }
            end
          end
          if locked or not ready or addon.state.busy then selector:Disable() end
        end
        if not locked and not row.manage then
          local add = rowAction(body, nil, 838, y, "Add alternate profile", function()
            -- New alternates start unassigned until a variation chip is chosen.
            table.insert(rows, { variations = {}, moduleName = moduleName })
            render()
          end)
          add:SetEnabled(ready and not addon.state.busy)
          local remove = rowAction(body, [[Interface\Buttons\UI-GroupLoot-Pass-Up]], 870, y,
            index == 1 and "Clear selected profile" or "Remove alternate profile", clear)
          local hover = widget(body, "profileHover", function()
            local frame = CreateFrame("Frame", nil, body)
            frame:EnableMouse(false)
            frame:SetScript("OnUpdate", function(self)
              -- Test row bounds so hovering its dropdown, chips or icons also counts.
              local shown = self.addonLoaded and not addon.state.busy and not ui.modal:IsShown()
                and ui.scroll:IsMouseOver() and self:IsMouseOver()
              for _, action in ipairs(self.actions) do action:SetShown(shown) end
            end)
            return frame
          end)
          hover:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
          hover:SetSize(body:GetWidth() - 8, height)
          hover.actions = { add, remove }
          hover.addonLoaded = lap:isLoaded()
          add:Hide(); remove:Hide()
        end
        y = y + height
      end
      -- One shared addon cell/background; branches connect its indented profiles.
      rowBackground(body, groupStart, y - groupStart - 1, ready and .18 or .06)
      if lastBranch then profileConnector(body, PROFILE_X + 8, groupStart + 38, 1, lastBranch - groupStart - 38 + 1) end
      if lap.exportOptions or moduleName == "WeakAuras" then
        local icon = body.pools.addonIcon[body.used.addonIcon]
        icon:SetTooltip("Left-click: addon settings\nRight-click: export options")
        icon:SetEnabled(ready and not addon.state.busy)
        icon:SetClickFunction(function() exportOptions(pack, moduleName) end, nil, nil, "RightButton")
      end
    end
  end
  if extrasPending then additionalRow() end
  local saveAll = button(ui.footer, "Save All Profiles", (ui.footer:GetWidth() - 300) / 2, -14, 300,
    function()
      addon:CapturePack(pack, nil, saveCapture, function(current, total)
        if current == 0 then
          ui.captureProgress.fade = 0; ui.captureProgress:SetAlpha(1)
          ui.captureBar:SetMinMaxSmoothedValue(0, math.max(1, total))
        end
        ui.captureBar:SetSmoothedValue(current)
        ui.captureCounter:SetText(current .. "/" .. total)
        ui.captureText:SetText("Saving all profiles...")
        ui.captureProgress:Show()
        ui.capturePopup:Show()
      end)
    end, nil, 50, 20)
  local blocked = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if not next(p.variations) then unassigned[p.moduleName] = true end
  end
  for moduleName in pairs(unassigned) do table.insert(blocked, moduleName) end
  table.sort(blocked)
  local reason
  if #blocked > 0 then
    reason = "Fix the rows marked with a warning before saving.\nIncomplete: " .. table.concat(blocked, ", ")
  elseif #pack.profileOrder == 0 and not next(pack.additionalAddons) and not saved then
    -- A previously saved pack may still save an emptied draft; a fresh one needs something to export.
    reason = "Select a profile for at least one AddOn before saving."
  end
  blockSave(saveAll, reason)
  if filter and query == "" and not profilesListed then
    label(body, "No profiles are assigned to " .. pack.variations[filter].name .. " yet.", 0, y + 40, body:GetWidth(), 16,
      { .65, .65, .65 }):SetJustifyH("CENTER")
    y = y + 90
  elseif not listed then
    label(body, "Nothing matches \"" .. ui.searchText .. "\"", 0, 40, body:GetWidth(), 16, { .65, .65, .65 }):SetJustifyH("CENTER")
    y = 100
  end
  if hasNotInstalled and query == "" and not filter then
    local row = widget(body, "missingAddonsRow", function()
      local f = CreateFrame("Button", nil, body)
      f.line = f:CreateTexture(nil, "BACKGROUND")
      f.line:SetPoint("CENTER")
      f.line:SetHeight(1)
      f.line:SetColorTexture(.25, .25, .25, 1)
      f.plate = CreateFrame("Frame", nil, f, "BackdropTemplate")
      f.plate:EnableMouse(false)
      f.plate:SetPoint("CENTER")
      f.plate:SetHeight(28)
      f.plate:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
      f.plate:SetBackdropColor(.1, .1, .1, 1)
      f.plate:SetBackdropBorderColor(.25, .25, .25, 1)
      f.label = f.plate:CreateFontString(nil, "OVERLAY")
      f.label:SetFont(addon.FONT, 14, "")
      f.label:SetPoint("CENTER")
      f.label:SetTextColor(.85, .85, .85, 1)
      f:SetScript("OnEnter", function(self)
        self.plate:SetBackdropColor(.18, .18, .18, 1)
        self.plate:SetBackdropBorderColor(.45, .45, .45, 1)
        self.label:SetTextColor(1, 1, 1, 1)
      end)
      f:SetScript("OnLeave", function(self)
        self.plate:SetBackdropColor(.1, .1, .1, 1)
        self.plate:SetBackdropBorderColor(.25, .25, .25, 1)
        self.label:SetTextColor(.85, .85, .85, 1)
      end)
      return f
    end)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
    row:SetSize(body:GetWidth() - 8, 44)
    row.line:SetWidth(row:GetWidth())
    row.label:SetText(ui.showNotInstalled and "-  Hide AddOns that are not installed" or "+  Show AddOns that are not installed")
    row.plate:SetWidth(row.label:GetStringWidth() + 28)
    row:SetEnabled(not addon.state.busy)
    row:SetScript("OnClick", function()
      ui.showNotInstalled = not ui.showNotInstalled
      render()
    end)
    y = y + 44
  end
  body:SetHeight(math.max(1, y))
end

UI.creator = creator
