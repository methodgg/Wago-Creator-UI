---@class WagoUICreator
local addon = select(2, ...)
---@class ModuleFunctions
addon.ModuleFunctions = {}
---@class ModuleFunctions
local ModuleFunctions = addon.ModuleFunctions
local LAP = LibStub:GetLibrary("LibAddonProfiles")

function ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
  local currentUIPack = addon:GetCurrentPack()
  tinsert(res, {
    value = 1,
    label = "|A:common-icon-redx:16:16|a|cff808080None|r",
    onclick = function(dropdown)
      dropdown:NoOptionSelected()
      currentUIPack.profileKeys[currentUIPack.resolutions.chosen][moduleName] = nil
      currentUIPack.profiles[currentUIPack.resolutions.chosen][moduleName] = nil
      addon.UpdatePackSelectedUI()
      addon:AddProfileRemoval(addon.db.chosenPack, currentUIPack.resolutions.chosen, moduleName)
    end
  })

  local orderedProfileKeys = {}
  for profileKey, _ in pairs(profileKeys) do
    local isCurrentProfile = profileKey == currentProfileKey
    tinsert(orderedProfileKeys, {
      data = {
        value = profileKey,
        label = isCurrentProfile and "|cff009ECC"..profileKey.."|r (active)" or profileKey,
        onclick = function()
          currentUIPack.profileKeys[currentUIPack.resolutions.chosen][moduleName] = profileKey
          addon.UpdatePackSelectedUI()
        end
      },
      isCurrentProfile = isCurrentProfile
    })
  end
  table.sort(orderedProfileKeys, function(a, b)
    if a.isCurrentProfile then return true end
    if b.isCurrentProfile then return false end
    return a.data.value < b.data.value
  end)
  for _, profileKey in ipairs(orderedProfileKeys) do
    tinsert(res, profileKey.data)
  end

  return res
end

local function exportFunc(moduleName, resolution, timestamp)
  local currentUIPack = addon:GetCurrentPack()
  ---@type LibAddonProfilesModule
  local lapModule = LAP:GetModule(moduleName)
  ---@type any
  local newExport = lapModule:exportProfile(currentUIPack.profileKeys[resolution][moduleName])
  ---@type any
  local oldExport = currentUIPack.profiles[resolution][moduleName]
  local tableA, tableB
  if lapModule.exportGroup then
    tableA = oldExport
    tableB = newExport
  end
  local areEqual, changedEntries, removedEntries = lapModule:areProfileStringsEqual(oldExport, newExport, tableA, tableB)
  if areEqual then return false end
  --stuff changed, we need to handle it
  --set the profile, time of export
  currentUIPack.profileMetadata[resolution][moduleName] = currentUIPack.profileMetadata[resolution]
      [moduleName] or {}
  if moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
    currentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt = currentUIPack.profileMetadata
        [resolution][moduleName].lastUpdatedAt or {}
    if changedEntries then
      for key in pairs(changedEntries) do
        currentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt[key] = timestamp
      end
    end
    currentUIPack.profiles[resolution][moduleName] = newExport
  else
    currentUIPack.profileMetadata[resolution][moduleName].lastUpdatedAt = timestamp
    currentUIPack.profiles[resolution][moduleName] = newExport
  end
  return true, changedEntries, removedEntries
end

--- probably need to rename some stuff, this is for dropdown that SETS the profile
--- @param dropdown table
--- @param lapModule LibAddonProfilesModule
local function createProfileDropdownOptions(dropdown, lapModule)
  local res = {}
  if not lapModule:isLoaded() or not lapModule.getProfileKeys then return res end
  local profileKeys = lapModule:getProfileKeys()
  for profileKey, _ in pairs(profileKeys) do
    tinsert(res, {
      value = profileKey,
      label = profileKey,
      onclick = function()
        lapModule:setProfile(profileKey)
      end
    })
  end
  return res
end

function ModuleFunctions:InsertModuleConfig(m)
  ---@type LibAddonProfilesModule
  local lapModule = m.lapModule
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
    lapModule = lapModule,
    icon = lapModule.icon,
    profileDropdownOptions = function(dropdown)
      return createProfileDropdownOptions(dropdown, lapModule)
    end,
    dropdown1Options = function()
      return m.dropdownOptions(1)
    end,
    exportFunc = function(resolution, timestamp)
      return exportFunc(m.moduleName, resolution, timestamp)
    end,
    dropdown2Options = function()
      return m.dropdownOptions(2)
    end,
    copyFuncOverride = copyFuncOverride,
    copyButtonTooltipText = m.copyButtonTooltipText,
    isLoaded = lapModule.isLoaded,
    sortIndex = m.sortIndex,
    hasGroups = m.hasGroups,
    manageFunc = manageFunc,
    onSuccessfulTestOverride = onSuccessfulTestOverride,
  })
end

function ModuleFunctions:SortModuleConfigs()
  table.sort(addon.moduleConfigs, function(a, b)
    ---@type LibAddonProfilesModule
    local aLap = a.lapModule
    ---@type LibAddonProfilesModule
    local bLap = b.lapModule
    if not aLap or not bLap then return false end

    local aLoaded = aLap:isLoaded()
    local bLoaded = bLap:isLoaded()
    local aNeedsInit = aLap:needsInitialization()
    local bNeedsInit = bLap:needsInitialization()
    local aLoadable = not aLoaded and LAP:CanEnableAddOn(aLap.moduleName)
    local bLoadable = not bLoaded and LAP:CanEnableAddOn(bLap.moduleName)
    local aSortIndex = a.sortIndex or 0
    local bSortIndex = b.sortIndex or 0
    local aIdx, bIdx = 0, 0

    if (aLoaded or aNeedsInit) then
      aIdx = 1000 - aSortIndex
    elseif aLoadable then
      aIdx = 500 - aSortIndex
    else
      aIdx = aIdx - aSortIndex
    end
    if (bLoaded or bNeedsInit) then
      bIdx = 1000 - bSortIndex
    elseif bLoadable then
      bIdx = 500 - bSortIndex
    else
      bIdx = bIdx - bSortIndex
    end

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
