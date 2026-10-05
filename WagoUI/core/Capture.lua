local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local LibAsync = LibStub("LibAsync")
local CDM = "Blizzard Cooldown Manager"

-- Keep the creator's established order within loaded, disabled and missing addons.
local creatorOrder = {
  "Blizzard Edit Mode", "Blizzard Cooldown Manager", "ElvUI", "ElvUI Private Profile",
  "ElvUI Account Settings", "ElvUI Style Filters", "ElvUI Aura Filters", "EllesmereUI",
  "Details", "Plater", "Kui Nameplates", "BigWigs", "BigWigs Boss Options", "Bartender4",
  "Cell", "Cell Unit Frames", "Unhalted Unit Frames", "BetterCooldownManager", "Grid2",
  "ShadowedUnitFrames", "WeakAuras", "Echo Raid Tools", "Method Raid Tools", "EXBoss",
  "BliZzi Party Tools", "OmniCC", "NameplateSCT", "SexyMap", "TipTac Reborn", "BugSack",
  "WarpDeplete", "Quartz", "OmniCD", "OmniCD Spell Editor", "BlizzHUDTweaks", "OmniBar",
  "HidingBar", "NameplateAuras", "MinimapStats", "MPlusTimer", "TargetedSpells",
  "Advanced Focus Cast Bar", "AzortharionUI", "BetterBlizzFrames", "BetterBlizzPlates",
  "sArenaReloaded", "SenseiClassResourceBar", "CooldownManager", "Cooldown Manager Centered",
  "Enhance QoL", "Enhance QoL Unit Frames", "Enhance QoL Resource Bars", "DandersFrames",
  "Prat3", "Midnight Simple Unit Frames", "Skyriding Falcon", "BuffReminders",
  "CooldownCursorManager", "Ayije_CDM", "NaowhQOL", "atrocityEssentials", "NorskenUI",
}
local creatorRank = {}
for index, name in ipairs(creatorOrder) do creatorRank[name] = index end

function addon:CreatorAddons()
  local result = {}
  for name, lap in pairs(LAP:GetAllModules()) do
    if lap.getProfileKeys or name == "WeakAuras" or name == "Echo Raid Tools" then
      local loaded = lap:isLoaded()
      local initialize = not loaded and lap:needsInitialization()
      local canEnable = not loaded and LAP:CanEnableAnyAddOn(lap.addonNames)
      local pending = false
      for _, addonName in ipairs(lap.addonNames or {}) do
        if self.state.creatorEnabled and self.state.creatorEnabled[addonName] then pending = true end
      end
      local status
      if loaded then status = lap:isUpdated() and "Ready" or "Outdated - update required"
      elseif pending then status = "Enabled after reload"
      elseif initialize then status = "Needs setup"
      elseif canEnable then status = "Addon disabled"
      else status = "Not installed" end
      table.insert(result, { name = name, status = status, group = loaded and 1 or (canEnable or initialize) and 2 or 3 })
    end
  end
  table.sort(result, function(a, b)
    if a.group ~= b.group then return a.group < b.group end
    local aRank, bRank = creatorRank[a.name] or 1000, creatorRank[b.name] or 1000
    if aRank ~= bRank then return aRank < bRank end
    return a.name < b.name
  end)
  return result
end

function addon:EnableCreatorAddon(moduleName)
  local lap = LAP:GetModule(moduleName)
  if not lap or not LAP:CanEnableAnyAddOn(lap.addonNames) then return end
  LAP:EnableAddOns(lap.addonNames)
  self.state.creatorEnabled = self.state.creatorEnabled or {}
  for _, name in ipairs(lap.addonNames) do self.state.creatorEnabled[name] = true end
  self.state.needReload = true
  self:ToggleReloadIndicator(true)
  self:RefreshWorkspace()
end

function addon:CharacterKey()
  return UnitName("player") .. " - " .. GetRealmName()
end

function addon:InitializePacks()
  self.db.creator = self.db.creator or { packs = {}, saved = {}, cdmCache = {} }
  self.db.profileHistory = self.db.profileHistory or {}
  self.dbC.selection = self.dbC.selection or { choices = {} }
  self.dbC.selection.choices = self.dbC.selection.choices or {}
  for _, packs in ipairs({ self.db.creator.packs, self.db.creator.saved }) do
    for _, pack in pairs(packs) do self.Packs.Upgrade(pack) end
  end
end

function addon:NewPack(label)
  self.db.creator.sequence = (self.db.creator.sequence or 0) + 1
  local id = "local-" .. UnitGUID("player") .. "-" .. GetServerTime() .. "-" .. self.db.creator.sequence
  local pack = self.Packs.New(id, label)
  self.db.creator.packs[id] = pack
  self.db.creator.selected = id
  return pack
end

function addon:GetPack(id)
  return self.db.creator.packs[id] or (WagoUI_Storage and WagoUI_Storage[id])
end

function addon:GetPacks(ownedOnly)
  local result = {}
  if not ownedOnly then
    for id, pack in pairs(WagoUI_Storage or {}) do
      result[id] = pack
    end
  end
  for id, pack in pairs(self.db.creator.packs) do result[id] = pack end
  return result
end

function addon:EnsureIntegration(moduleName)
  local lap = LAP:GetModule(moduleName)
  if not lap then return nil, "Unsupported addon" end
  if moduleName == CDM and not CooldownViewerSettings then C_AddOns.LoadAddOn("Blizzard_CooldownViewer") end
  if moduleName == CDM and not CooldownViewerSettings then return nil, "Cooldown Manager unavailable" end
  if lap:needsInitialization() then
    lap:openConfig()
    if lap.closeConfig then lap:closeConfig() end
  end
  return lap
end

function addon:CacheCooldownProfiles()
  local lap = self:EnsureIntegration(CDM)
  if not lap then return end
  local profiles = {}
  for key, info in pairs(lap:getProfileKeys()) do
    local data = lap:exportProfile(key)
    if data then
      profiles[key] = { data = data, classAndSpecTag = info.classAndSpecTag, updatedAt = GetServerTime() }
    end
  end
  self.db.creator.cdmCache[self:CharacterKey()] = profiles
end

function addon:ProfileSources(moduleName)
  local lap, problem = self:EnsureIntegration(moduleName)
  local result = {}
  if not lap then return result, problem end
  if moduleName == CDM then
    self:CacheCooldownProfiles()
    for character, profiles in pairs(self.db.creator.cdmCache) do
      for key, info in pairs(profiles) do
        table.insert(result, { key = key, label = key .. " · " .. character, kind = "cdm",
          character = character, classAndSpecTag = info.classAndSpecTag })
      end
    end
  elseif not lap:isLoaded() or not lap:isUpdated() then
    return result, "Enable or update this addon first."
  elseif moduleName == "WeakAuras" then
    for key in pairs(WeakAurasSaved.displays) do table.insert(result, { key = key, label = key, kind = "group" }) end
  elseif moduleName == "Echo Raid Tools" then
    for _, group in pairs(EchoRaidToolsDB.Cooldowns.groups) do
      table.insert(result, { key = group.name, label = group.name, kind = "group" })
    end
  elseif lap.getProfileKeys then
    for key in pairs(lap:getProfileKeys()) do
      table.insert(result, { key = key, label = key, kind = lap.preventRename and "snapshot" or "profile" })
    end
  end
  local current = lap:isLoaded() and lap.getCurrentProfileKey and lap:getCurrentProfileKey()
  for _, source in ipairs(result) do
    source.active = source.key == current and (not source.character or source.character == self:CharacterKey())
    if source.active then source.label = source.label .. " (active)" end
  end
  table.sort(result, function(a, b)
    if a.active ~= b.active then return a.active end
    return a.label < b.label
  end)
  return result
end

local function exportRecord(pack, profile)
  local lap, problem = addon:EnsureIntegration(profile.moduleName)
  if not lap then return nil, problem end
  if profile.kind == "cdm" then
    local cache = addon.db.creator.cdmCache[profile.sourceCharacter]
    local cached = cache and cache[profile.sourceKey]
    if cached and cached.classAndSpecTag == profile.classAndSpecTag then return cached.data end
    return nil, "Source layout unavailable; previous capture kept."
  end
  if not lap:isLoaded() or not lap:isUpdated() then return nil, "Addon unavailable; previous capture kept." end
  if lap.setExportOptions then lap:setExportOptions(pack.exportOptions and pack.exportOptions[profile.moduleName] or {}) end
  if profile.kind == "group" then
    if profile.moduleName == "WeakAuras" then
      if not WeakAuras.GetData(profile.sourceKey) then return nil, "Source aura missing." end
      local selected = { [profile.sourceKey] = { export = true } }
      for id in pairs(pack.blockedAuras or {}) do
        if id ~= profile.sourceKey then selected[id] = { blocked = true } end
      end
      local groups = lap:exportProfile(selected)
      profile.collectedWagoIds = CopyTable(lap:getCollectedWagoIds())
      return groups and groups[profile.sourceKey]
    end
    local groups = lap:exportProfile({ [profile.sourceKey] = true })
    return groups and groups[profile.sourceKey], "Source group missing."
  end
  local keys = lap.getProfileKeys and lap:getProfileKeys()
  if not keys or not keys[profile.sourceKey] then return nil, "Source profile missing; previous capture kept." end
  local data, success = lap:exportProfile(profile.sourceKey)
  if success == false then return nil, "Export failed; previous capture kept." end
  return data
end

-- Capture into a copy. A failed export never clears the previous successful payload.
function addon:CapturePack(pack, onlyProfileID, callback, progress)
  if self.state.busy then return end
  if InCombatLockdown() then self:AddonPrintError("Cannot capture in combat."); return end
  self.state.busy = true
  self:RefreshWorkspace()
  if progress then progress(0, #pack.profileOrder) end
  self:Async(function()
    -- A plain yield can resume in this same frame; let the progress UI render.
    if progress then LibAsync:Await(function(done) C_Timer.After(0, done) end) end
    self:CacheCooldownProfiles()
    local captured = CopyTable(pack)
    local timestamp, changes, issues = GetServerTime(), {}, {}
    for index, id in ipairs(captured.profileOrder) do
      if InCombatLockdown() then error("Capture stopped: combat. Previous captures kept.") end
      local p = captured.profiles[id]
      -- Snapshots, and Cooldown Manager layouts while their exports are frozen, keep their capture unless asked.
      local keep = (p.kind == "snapshot" or p.kind == "cdm" and captured.cdmExportsFrozen) and p.data and onlyProfileID ~= id
      if (not onlyProfileID or onlyProfileID == id) and not keep then
        local data, problem = exportRecord(captured, p)
        if type(data) == "string" and #data > 0 then
          p.lastSavedAt = timestamp
          local lap = LAP:GetModule(p.moduleName)
          local equal = p.data == data
          if p.data and not equal and lap.areProfileStringsEqual then
            local a, b
            if p.kind == "group" then a, b = { [p.sourceKey] = p.data }, { [p.sourceKey] = data } end
            local succeeded
            equal, _, _, succeeded = lap:areProfileStringsEqual(p.data, data, a, b)
            if succeeded == false then error("Could not compare " .. p.name .. "; capture cancelled.") end
          end
          if not equal then
            p.data, p.lastUpdatedAt = data, math.max(timestamp, (p.lastUpdatedAt or 0) + 1)
            table.insert(changes, p.moduleName .. ": " .. p.name)
          end
        else
          table.insert(issues, p.moduleName .. " / " .. p.name .. ": " .. (problem or "Export failed."))
        end
      end
      if progress then progress(index, #captured.profileOrder) end
      if progress then LibAsync:Await(function(done) C_Timer.After(0, done) end)
      else coroutine.yield() end
    end
    local saved = self.db.creator.saved[pack.id]
    if not saved or saved.revision ~= captured.revision then table.insert(changes, "Pack settings") end
    captured.gameVersion = select(4, GetBuildInfo())
    local version = captured.gameVersion
    captured.gameFlavor = version >= 120000 and "retail" or version >= 50500 and "mop"
      or version >= 40400 and "cata" or version >= 20505 and "bc" or "classic"
    captured.createdBy = self:CharacterKey()
    captured.includedAddons = {}
    captured.collectedWagoIds = {}
    for id, name in pairs(captured.additionalAddons) do captured.includedAddons[name] = id end
    for _, p in pairs(captured.profiles) do
      local lap = LAP:GetModule(p.moduleName)
      if next(p.variations) and lap then
        for id, label in pairs(p.collectedWagoIds or {}) do captured.collectedWagoIds[id] = label end
        if lap.wagoId then captured.includedAddons[lap.moduleName] = lap.wagoId end
        for key, value in pairs(lap.additionalWagoIds or {}) do captured.includedAddons[key] = value end
      end
    end
    captured.updatedAt = #changes > 0 and math.max(timestamp, (captured.updatedAt or 0) + 1) or captured.updatedAt
    self.db.creator.packs[pack.id] = captured
    self.state.busy = false
    self:RefreshWorkspace()
    callback(captured, changes, issues)
  end, "CapturePack")
end

-- Compares a variation's resolution list by value.
local function sizesKey(v)
  local parts = {}
  for _, size in ipairs(v.resolutions or {}) do parts[#parts + 1] = size.width .. "x" .. size.height end
  return table.concat(parts, ",")
end

function addon:BuildReleaseNotes(pack)
  local previous = self.db.creator.saved[pack.id]
  local added, removed = {}, {}
  local function profileName(p) return p.moduleName .. ": " .. p.name end
  for _, variationID in ipairs(pack.variationOrder) do
    local lines = {}
    for _, p in ipairs(self.Packs.Profiles(pack, variationID)) do
      local old = previous and previous.profiles[p.id]
      if not old or not old.variations[variationID] or p.lastUpdatedAt ~= old.lastUpdatedAt
        or p.name ~= old.name or p.sourceKey ~= old.sourceKey or p.sourceCharacter ~= old.sourceCharacter then
        lines[#lines + 1] = "- " .. profileName(p)
      end
    end
    if #lines > 0 then added[#added + 1] = "### " .. pack.variations[variationID].name .. "\n" .. table.concat(lines, "\n") end
  end
  for _, variationID in ipairs(previous and previous.variationOrder or {}) do
    local lines = {}
    for _, old in ipairs(self.Packs.Profiles(previous, variationID)) do
      local p = pack.profiles[old.id]
      if not p or not p.variations[variationID] then lines[#lines + 1] = "- " .. profileName(old) end
    end
    if #lines > 0 then removed[#removed + 1] = "### " .. previous.variations[variationID].name .. "\n" .. table.concat(lines, "\n") end
  end
  local settings, deleted = {}, {}
  for _, id in ipairs(pack.profileOrder) do
    local p, old = pack.profiles[id], previous and previous.profiles[id]
    if not next(p.variations) and (not old or p.lastUpdatedAt ~= old.lastUpdatedAt
      or p.name ~= old.name or p.sourceKey ~= old.sourceKey or p.sourceCharacter ~= old.sourceCharacter) then
      settings[#settings + 1] = "- " .. profileName(p) .. " (unassigned)"
    end
  end
  for _, id in ipairs(previous and previous.profileOrder or {}) do
    local old = previous.profiles[id]
    if not next(old.variations) and not pack.profiles[id] then deleted[#deleted + 1] = "- " .. profileName(old) end
  end
  if not previous or previous.name ~= pack.name then settings[#settings + 1] = "- UI Pack: " .. pack.name end
  for _, id in ipairs(pack.variationOrder) do
    local v, old = pack.variations[id], previous and previous.variations[id]
    if not old or old.name ~= v.name or old.description ~= v.description or sizesKey(old) ~= sizesKey(v) then
      settings[#settings + 1] = "- Variation: " .. v.name
    end
  end
  for _, id in ipairs(previous and previous.variationOrder or {}) do
    if not pack.variations[id] then deleted[#deleted + 1] = "- Variation: " .. previous.variations[id].name end
  end
  for id, name in pairs(pack.additionalAddons) do
    if not previous or previous.additionalAddons[id] ~= name then settings[#settings + 1] = "- Additional addon: " .. name end
  end
  for id, name in pairs(previous and previous.additionalAddons or {}) do
    if not pack.additionalAddons[id] then deleted[#deleted + 1] = "- Additional addon: " .. name end
  end
  if #added == 0 and #removed == 0 and #settings == 0 and #deleted == 0
    and previous and previous.revision ~= pack.revision then settings[1] = "- Pack settings" end
  table.sort(settings); table.sort(deleted)
  if #settings > 0 then added[#added + 1] = "### UI Pack\n" .. table.concat(settings, "\n") end
  if #deleted > 0 then removed[#removed + 1] = "### UI Pack\n" .. table.concat(deleted, "\n") end
  local lines = { "# " .. date("%y/%m/%d", pack.updatedAt or GetServerTime()) }
  if #added > 0 then lines[#lines + 1] = "## Updated / Added:\n" .. table.concat(added, "\n") end
  if #removed > 0 then lines[#lines + 1] = "## Removed:\n" .. table.concat(removed, "\n") end
  return table.concat(lines, "\n") .. "\n", #added > 0 or #removed > 0
end

function addon:SaveCapturedPack(pack, notes)
  local ok, problem = self.Packs.Validate(pack)
  assert(ok, problem)
  assert(notes == nil or (type(notes) == "string" and #notes <= 100000), "Release notes exceed 100,000 characters.")
  if notes and notes ~= "" then pack.releaseNotes[tostring(pack.updatedAt or GetServerTime())] = notes end
  self.db.creator.saved[pack.id] = CopyTable(pack)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
  if addon.db and addon.db.creator then addon:CacheCooldownProfiles() end
end)
