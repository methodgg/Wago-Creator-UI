local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")

function addon:SetActivePack(id)
  local pack = self:GetPack(id)
  local ok, problem = self.Packs.Validate(pack)
  if ok and pack.id ~= id then ok, problem = false, "Pack ID does not match its storage key." end
  if not ok then self.state.packError = problem; self:RefreshWorkspace(); return false end
  self.state.packError = nil
  local selection = self.dbC.selection
  selection.packID = id
  selection.variationID = pack.variations[selection.variationID] and selection.variationID or "default"
  selection.step = "variations"
  self:RefreshWorkspace()
  return true
end

function addon:CurrentInstallPack()
  local pack = self:GetPack(self.dbC.selection.packID)
  if pack and self.Packs.Validate(pack) and pack.id == self.dbC.selection.packID then return pack end
end

function addon:ProfileStatus(p)
  if not p.data then return "Not captured" end
  local lap = self:EnsureIntegration(p.moduleName)
  if not lap then return "Unsupported addon" end
  if p.kind == "cdm" then
    local tag = CooldownViewerUtil and CooldownViewerUtil.GetCurrentClassAndSpecTag()
    if not tag or math.floor(tag / 10) ~= math.floor(p.classAndSpecTag / 10) then return "Class incompatible" end
  end
  if not lap:isLoaded() then
    return LAP:CanEnableAnyAddOn(lap.addonNames) and "Enable addon" or "Addon missing"
  end
  if not lap:isUpdated() then return "Update addon" end
  if lap.isProfileStringCompatible and not lap:isProfileStringCompatible(p.data) then return "Profile incompatible" end
  return "Ready"
end

function addon:InstallChoices(pack, variationID)
  local choices = self.dbC.selection.choices
  choices[pack.id] = choices[pack.id] or {}
  choices[pack.id][variationID] = choices[pack.id][variationID] or {}
  return choices[pack.id][variationID]
end

function addon:BuildInstallPlan(pack, variationID)
  if not pack.variations[variationID] then return nil, "Choose a variation." end
  local groups, order, plan = {}, {}, {}
  local choices = self:InstallChoices(pack, variationID)
  for _, p in ipairs(self.Packs.Profiles(pack, variationID)) do
    local status = self:ProfileStatus(p)
    if status == "Ready" or status == "Enable addon" then
      if p.kind == "group" then
        if choices[p.id] ~= false then table.insert(plan, p) end
      else
        if not groups[p.moduleName] then groups[p.moduleName] = {}; table.insert(order, p.moduleName) end
        table.insert(groups[p.moduleName], p)
      end
    end
  end
  for _, moduleName in ipairs(order) do
    local profiles = groups[moduleName]
    local chosen = choices[moduleName]
    if chosen ~= false then
      if not chosen and #profiles == 1 then chosen = profiles[1].id end
      local match
      for _, p in ipairs(profiles) do if p.id == chosen then match = p end end
      if not match then return nil, "Choose a profile for " .. moduleName .. "." end
      table.insert(plan, match)
    end
  end
  return plan
end

function addon:GetProfileHistory(packID, profileID)
  local history = self.db.profileHistory[self:CharacterKey()]
  return history and history[packID] and history[packID][profileID]
end

function addon:RecordImport(pack, p, profileKey)
  local character = self:CharacterKey()
  local history = self.db.profileHistory
  history[character] = history[character] or {}
  history[character][pack.id] = history[character][pack.id] or {}
  history[character][pack.id][p.id] = {
    moduleName = p.moduleName, profileKey = profileKey, lastUpdatedAt = p.lastUpdatedAt,
    importedAt = GetServerTime(), kind = p.kind, variationID = self.dbC.selection.variationID,
  }
  self.db.anyInstalled = true
end

function addon:ImportProfiles(pack, records, callback)
  if self.state.busy then return end
  if InCombatLockdown() then self:AddonPrintError("Cannot install profiles in combat."); return end
  local valid, problem = self.Packs.Validate(pack)
  if not valid then self:AddonPrintError(problem); return end
  if #records == 0 then self:AddonPrintError("No profiles selected."); return end
  local warnings, enable, checked = {}, false, {}
  for _, p in ipairs(records) do
    if pack.profiles[p.id] ~= p then self:AddonPrintError("Profile changed. Select it again."); return end
    local status = self:ProfileStatus(p)
    if status == "Enable addon" then enable = true
    elseif status ~= "Ready" then self:AddonPrintError(p.name .. ": " .. status); return end
    checked[p.moduleName] = { checked = true }
    local lap = LAP:GetModule(p.moduleName)
    if status == "Ready" then
      if lap.willOverrideProfile or (lap.isDuplicate and lap:isDuplicate(p.sourceKey)) then
        table.insert(warnings, p.moduleName .. ": " .. p.sourceKey)
      end
    end
    if lap.conflictingAddons then
      for _, addonName in ipairs(lap.conflictingAddons) do
        if C_AddOns.IsAddOnLoaded(addonName) then table.insert(warnings, "Disable conflicting addon: " .. addonName) end
      end
    end
  end
  if enable then
    self:ShowPrompt("Enable required addons and reload?", function()
      for _, p in ipairs(records) do
        local lap = LAP:GetModule(p.moduleName)
        if not lap:isLoaded() then LAP:EnableAddOns(lap.addonNames) end
      end
      self.dbC.selection.step = "profiles"
      ReloadUI()
    end)
    return
  end
  local function run()
    if InCombatLockdown() or self.state.busy then return end
    self.state.busy, self.state.isImporting = true, true
    self:RefreshWorkspace()
    self:Async(function()
      self:SuppressAddOnSpam()
      local failed, imported = {}, 0
      for _, p in ipairs(records) do
        if InCombatLockdown() then table.insert(failed, "Installation stopped: combat."); break end
        local lap = LAP:GetModule(p.moduleName)
        if self:ProfileStatus(p) ~= "Ready" then error(p.name .. ": addon is no longer ready.") end
        local compatible = not lap.isProfileStringCompatible or lap:isProfileStringCompatible(p.data)
        local accepted = false
        if compatible then accepted = lap:importProfile(p.data, p.sourceKey, true) end
        if accepted == false then
          table.insert(failed, p.moduleName .. ": " .. p.name)
        else
          self:RecordImport(pack, p, p.sourceKey)
          imported = imported + 1
          if lap.conflictingAddons then LAP:DisableConflictingAddons(lap.conflictingAddons, checked) end
          if lap.needReloadOnImport then self.state.needReload = true end
        end
        coroutine.yield()
      end
      self.state.busy, self.state.isImporting = false, false
      self:ToggleReloadIndicator(self.state.needReload)
      if self.state.needReopen then self.frames.mainFrame:Show(); self.state.needReopen = nil end
      self:RefreshWorkspace()
      callback(imported, failed)
    end, "ImportProfiles")
  end
  if #warnings > 0 then self:ShowPrompt("Replace existing settings?\n" .. table.concat(warnings, "\n"), run, nil, "Import")
  else run() end
end

function addon:AltCharacters()
  local characters = {}
  for character in pairs(self.db.profileHistory) do characters[character] = true end
  for _, lap in pairs(LAP:GetAllModules()) do
    if lap:isLoaded() and lap:isUpdated() and lap.getProfileAssignments then
      for character in pairs(lap:getProfileAssignments() or {}) do characters[character] = true end
    end
  end
  characters[self:CharacterKey()] = nil
  local result = {}
  for character in pairs(characters) do table.insert(result, character) end
  table.sort(result)
  return result
end

function addon:ApplyAlt(character, callback)
  if InCombatLockdown() or self.state.busy then return end
  local latest = {}
  for _, profiles in pairs(self.db.profileHistory[character] or {}) do
    for _, info in pairs(profiles) do
      if info.kind ~= "group" and (not latest[info.moduleName] or info.importedAt > latest[info.moduleName].importedAt) then
        latest[info.moduleName] = info
      end
    end
  end
  local pending, failed = {}, {}
  self.state.busy = true
  self:RefreshWorkspace()
  self:Async(function()
    self:SuppressAddOnSpam()
    for moduleName, lap in pairs(LAP:GetAllModules()) do
      lap = self:EnsureIntegration(moduleName)
      if lap and lap.setProfile then
        local old = latest[moduleName]
        if lap:isLoaded() and lap:isUpdated() then
          local assignments = lap.getProfileAssignments and lap:getProfileAssignments()
          local key = assignments and assignments[character] or old and old.profileKey
          if key then
            local keys = lap.getProfileKeys and lap:getProfileKeys()
            local eligible = keys and keys[key]
            if moduleName == "Blizzard Cooldown Manager" and eligible then
              eligible = math.floor(eligible.classAndSpecTag / 10) == math.floor(CooldownViewerUtil.GetCurrentClassAndSpecTag() / 10)
            end
            if eligible then
              if InCombatLockdown() then error("Alt setup stopped: combat.") end
              lap:setProfile(key)
              if lap.getCurrentProfileKey and lap:getCurrentProfileKey() ~= key then
                table.insert(failed, moduleName)
              else
                self.state.needReload = true
                self.db.profileHistory[self:CharacterKey()] = self.db.profileHistory[self:CharacterKey()] or {}
                local target = self.db.profileHistory[self:CharacterKey()]
                target.alt = target.alt or {}
                target.alt[moduleName] = { moduleName = moduleName, profileKey = key, importedAt = GetServerTime(), kind = "profile" }
              end
            else table.insert(failed, moduleName .. ": profile missing") end
          end
        elseif old and not lap:isLoaded() and LAP:CanEnableAnyAddOn(lap.addonNames) then
          table.insert(pending, lap)
        elseif old then
          table.insert(failed, moduleName .. ": update required")
        end
      end
      coroutine.yield()
    end
    self.state.busy = false
    self:ToggleReloadIndicator(self.state.needReload)
    self:RefreshWorkspace()
    if #pending > 0 then
      self:ShowPrompt("Enable remaining addons and reload?", function()
        self.dbC.pendingAlt = character
        for _, lap in ipairs(pending) do LAP:EnableAddOns(lap.addonNames) end
        ReloadUI()
      end)
    else self.dbC.pendingAlt = nil end
    callback(failed)
  end, "ApplyAlt")
end
