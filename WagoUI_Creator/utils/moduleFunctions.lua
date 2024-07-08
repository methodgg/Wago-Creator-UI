local addonName, addon = ...
addon.ModuleFunctions = {}
local ModuleFunctions = addon.ModuleFunctions
local LAP = LibStub:GetLibrary("LibAddonProfiles")

function ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
  local currrentUIPack = addon:GetCurrentPack()
  tinsert(res, {
    value = 1,
    label = "|A:common-icon-redx:16:16|a|cff808080None|r",
    onclick = function(dropdown)
      dropdown:NoOptionSelected()
      currrentUIPack.profileKeys[currrentUIPack.resolutions.chosen][moduleName] = nil
      currrentUIPack.profiles[currrentUIPack.resolutions.chosen][moduleName] = nil
    end
  })

  for profileKey, _ in pairs(profileKeys) do
    local coloredProfileKey = profileKey == currentProfileKey and "|cff009ECC"..profileKey.."|r (active)" or profileKey
    tinsert(res, {
      value = profileKey,
      label = coloredProfileKey,
      onclick = function()
        currrentUIPack.profileKeys[currrentUIPack.resolutions.chosen][moduleName] = profileKey
      end
    })
  end

  return res
end

local function exportFunc(moduleName, resolution, exportProfileFunc, timestamp)
  local currrentUIPack = addon:GetCurrentPack()
  local newExport = exportProfileFunc(currrentUIPack.profileKeys[resolution][moduleName])
  local oldExport = currrentUIPack.profiles[resolution][moduleName]
  ---@class LibAddonProfilesModule
  local lapModule = LAP:GetModule(moduleName)
  local areEqual, changedEntries, removedEntries = lapModule.areProfileStringsEqual(oldExport, newExport)
  if areEqual then return false end
  --stuff changed, we need to handle it
  --set the profile, time of export
  currrentUIPack.profileMetadata[resolution][moduleName] = currrentUIPack.profileMetadata[resolution]
      [moduleName] or {}
  if moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
    currrentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt = currrentUIPack.profileMetadata
        [resolution][moduleName].lastUpdatedAt or {}
    if changedEntries then
      for key in pairs(changedEntries) do
        -- TODO: IMPORTANT this is not working properly
        currrentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt[key] = timestamp
      end
    end
    currrentUIPack.profiles[resolution][moduleName] = newExport
  else
    currrentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt = timestamp
    currrentUIPack.profiles[resolution][moduleName] = newExport
  end
  return true, changedEntries, removedEntries
end

--- probably need to rename some stuff, this is for dropdown that SETS the profile
--- @param dropdown table
--- @param lapModule LibAddonProfilesModule
local function createProfileDropdownOptions(dropdown, lapModule)
  local res = {}
  if not lapModule.isLoaded() or not lapModule.getProfileKeys then return res end
  local profileKeys = lapModule.getProfileKeys()
  for profileKey, _ in pairs(profileKeys) do
    tinsert(res, {
      value = profileKey,
      label = profileKey,
      onclick = function()
        lapModule.setProfile(profileKey)
      end
    })
  end
  return res
end

function ModuleFunctions:InsertModuleConfig(m)
  local copyFuncOverride = m.copyFunc and function(...)
    m.copyFunc(...)
  end or nil
  local manageFunc = m.manageFunc and function(...)
    m.manageFunc(...)
  end or nil
  local onSuccessfulTestOverride = m.onSuccessfulTestOverride and function(...)
    m.onSuccessfulTestOverride(...)
  end or nil
  tinsert(addon.moduleConfigs, {
    name = m.moduleName,
    lapModule = m.lapModule,
    icon = m.lapModule.icon,
    profileDropdownOptions = function(dropdown)
      return createProfileDropdownOptions(dropdown, m.lapModule)
    end,
    dropdown1Options = function()
      return m.dropdownOptions(1)
    end,
    exportFunc = function(resolution, timestamp)
      return exportFunc(m.moduleName, resolution, m.lapModule.exportProfile, timestamp)
    end,
    dropdown2Options = function()
      return m.dropdownOptions(2)
    end,
    copyFuncOverride = copyFuncOverride,
    hookRefresh = m.hookRefresh,
    copyButtonTooltipText = m.copyButtonTooltipText,
    isLoaded = m.lapModule.isLoaded,
    sortIndex = m.sortIndex,
    hasGroups = m.hasGroups,
    manageFunc = manageFunc,
    onSuccessfulTestOverride = onSuccessfulTestOverride,
  })
end

function ModuleFunctions:SortModuleConfigs()
  table.sort(addon.moduleConfigs, function(a, b)
    local aIdx = (a.isLoaded() or a.lapModule.needsInitialization()) and a.sortIndex and 1000 - a.sortIndex or
        a.sortIndex or 0
    local bIdx = (b.isLoaded() or b.lapModule.needsInitialization()) and b.sortIndex and 1000 - b.sortIndex or
        b.sortIndex or 0
    return (aIdx > bIdx)
  end)
end

function ModuleFunctions:GetModuleByName(moduleName)
  for _, moduleConfig in ipairs(addon.moduleConfigs) do
    if moduleConfig.name == moduleName then
      return moduleConfig
    end
  end
end
