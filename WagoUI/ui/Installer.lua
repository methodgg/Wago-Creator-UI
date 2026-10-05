-- The install view: variation wizard and expert profile list.
local addon = select(2, ...)
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local addonRow, button, check, dropdown, label = UI.addonRow, UI.button, UI.check, UI.dropdown, UI.label
local rowBackground = UI.rowBackground
local closeModal, modal, notice = UI.closeModal, UI.modal, UI.notice
local resolutionText = UI.resolutionText
local function render() UI.render() end

local function installResult(imported, failed)
  addon.dbC.selection.step = #failed == 0 and "done" or "profiles"
  notice(#failed > 0 and ("Not imported: " .. table.concat(failed, ", ")) or (imported .. " imported"))
end

local function install(pack)
  local body = ui.content
  if not pack then
    label(body, "No installed UI Packs found.", 0, 120, body:GetWidth(), 24):SetJustifyH("CENTER")
    label(body, "Install a UI Pack through the Wago App.", 0, 162, body:GetWidth(), 14,
      { 0.65, 0.65, 0.65 }):SetJustifyH("CENTER")
    body:SetHeight(300)
    return
  end
  local s = addon.dbC.selection
  s.variationID = pack.variations[s.variationID] and s.variationID or "default"
  local expert = s.expert
  local entries = {}
  for _, id in ipairs(pack.variationOrder) do
    table.insert(entries, { value = id, label = pack.variations[id].name, onclick = function() s.variationID = id; render() end })
  end
  dropdown(ui.header, s.variationID, entries, 380, 0, 220)
  button(ui.header, expert and "Wizard" or "Expert", 614, 0, 100, function() s.expert = not expert; render() end)
  button(ui.header, "Alt setup", 728, 0, 100, function()
    local f = modal("Alt setup")
    local characters, options, selected = addon:AltCharacters(), {}, addon.dbC.pendingAlt
    for _, character in ipairs(characters) do
      table.insert(options, { value = character, label = character, onclick = function() selected = character end })
    end
    dropdown(f, selected, options, 28, 80, 535, "Choose character…")
    button(f, "Apply", 424, 476, 150, function()
      if not selected then f.error:SetText("Choose a character."); return end
      closeModal()
      addon:ApplyAlt(selected, function(failed) notice(#failed > 0 and table.concat(failed, ", ") or "Profiles applied") end)
    end)
  end)
  local step = s.step or "variations"
  if not expert and step == "done" then
    label(body, "Done", 360, 120, 300, 30)
    if addon.state.needReload then button(body, "Reload UI", 330, 180, 230, ReloadUI, nil, 44) end
    button(ui.footer, "Back", 0, 0, 100, function() s.step = "profiles"; render() end)
    body:SetHeight(300)
    return
  end
  if not expert and step == "variations" then
    local y = 0
    for _, id in ipairs(pack.variationOrder) do
      local v = pack.variations[id]
      button(body, (id == s.variationID and "|TInterface\\Buttons\\UI-CheckBox-Check:20:20|t " or "") .. v.name,
        12, y + 8, 310, function() s.variationID = id; render() end, nil, 44)
      label(body, resolutionText(v), 350, y + 14, 500, 15)
      if v.description and v.description ~= "" then label(body, v.description, 350, y + 40, 500, 13) end
      y = y + 100
    end
    body:SetHeight(math.max(1, y))
    button(ui.footer, "Next", 664, 0, 120, function()
      local size = pack.variations[s.variationID].resolution
      local function nextStep() s.step = "profiles"; render() end
      local w, h = GetPhysicalScreenSize()
      if size and (size.width ~= w or size.height ~= h) then
        addon:ShowPrompt("Designed for " .. resolutionText(pack.variations[s.variationID]) .. ". Continue?", nextStep, nil, "Continue")
      else nextStep() end
    end)
    return
  end
  local choices = addon:InstallChoices(pack, s.variationID)
  local profiles = Packs.Profiles(pack, s.variationID)
  table.sort(profiles, function(a, b)
    if a.moduleName == b.moduleName then return a.name < b.name end
    return a.moduleName < b.moduleName
  end)
  local y, current = 0, nil
  for _, p in ipairs(profiles) do
    local status = addon:ProfileStatus(p)
    if current ~= p.moduleName then
      current = p.moduleName
      addonRow(body, current, y)
      if not expert and p.kind ~= "group" then
        local options, eligible = { { value = "skip", label = "Skip", onclick = function() choices[p.moduleName] = false; render() end } }, {}
        for _, other in ipairs(profiles) do
          local otherStatus = addon:ProfileStatus(other)
          if other.moduleName == p.moduleName and (otherStatus == "Ready" or otherStatus == "Enable addon") then
            table.insert(eligible, other)
            table.insert(options, { value = other.id, label = other.name, onclick = function() choices[p.moduleName] = other.id; render() end })
          end
        end
        local chosen = choices[p.moduleName]
        if chosen == nil and #eligible == 1 then chosen = eligible[1].id end
        dropdown(body, chosen == false and "skip" or chosen, options, 554, y + 10, 348, "Choose profile…")
      end
      y = y + 56
    end
    rowBackground(body, y, 38, 0.06)
    if not expert and p.kind == "group" then
      check(body, p.name, choices[p.id] ~= false, 18, y, function(value) choices[p.id] = value; render() end)
    else label(body, p.name, 28, y + 8, 500, 15) end
    local history = addon:GetProfileHistory(pack.id, p.id)
    local action = not history and "Import" or (history.lastUpdatedAt or 0) < (p.lastUpdatedAt or 0) and "Update" or "Re-import"
    label(body, status == "Ready" and (history and "Imported" or "") or status, 550, y + 8, 175, 13)
    if expert then
      local b = button(body, status == "Enable addon" and "Enable" or action, 740, y, 124, function()
        addon:ImportProfiles(pack, { p }, function(count, failed)
          notice(#failed > 0 and table.concat(failed, ", ") or "Imported")
        end)
      end)
      b:SetEnabled(not addon.state.busy and (status == "Ready" or status == "Enable addon"))
    end
    y = y + 40
  end
  if #profiles == 0 then label(body, "No profiles", 24, 28, 600, 18) end
  body:SetHeight(math.max(1, y))
  if not expert then
    button(ui.footer, "Back", 0, 0, 100, function() s.step = "variations"; render() end)
    local plan, problem = addon:BuildInstallPlan(pack, s.variationID)
    label(ui.footer, problem or "", 120, 8, 520, 14)
    local b = button(ui.footer, "Install", 664, 0, 120, function() addon:ImportProfiles(pack, plan, installResult) end)
    b:SetEnabled(not addon.state.busy and plan and #plan > 0)
  end
end

UI.install = install
