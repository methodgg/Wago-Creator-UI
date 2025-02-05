---@class WagoUICreator
local addon = select(2, ...)
---@class ModuleFunctions
addon.ModuleFunctions = {}
---@class ModuleFunctions
local ModuleFunctions = addon.ModuleFunctions
local LAP = LibStub:GetLibrary("LibAddonProfiles")

ModuleFunctions.specialModules = {}

function ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
  local currentUIPack = addon:GetCurrentPackStashed()
  tinsert(
    res,
    {
      value = 1,
      label = "|A:common-icon-redx:16:16|a|cff808080None|r",
      onclick = function(dropdown)
        dropdown:NoOptionSelected()
        currentUIPack.profileKeys[currentUIPack.resolutions.chosen][moduleName] = nil
        currentUIPack.profiles[currentUIPack.resolutions.chosen][moduleName] = nil
        addon.UpdatePackSelectedUI()
        -- only mark for removal if it was previously set
        if addon.db.creatorUI[addon.db.chosenPack].profiles[currentUIPack.resolutions.chosen][moduleName] then
          addon:AddProfileRemoval(addon.db.chosenPack, currentUIPack.resolutions.chosen, moduleName)
        end
      end
    }
  )

  local orderedProfileKeys = {}
  for profileKey, _ in pairs(profileKeys) do
    local isCurrentProfile = profileKey == currentProfileKey
    tinsert(
      orderedProfileKeys,
      {
        data = {
          value = profileKey,
          label = isCurrentProfile and "|cff009ECC"..profileKey.."|r (active)" or profileKey,
          onclick = function()
            currentUIPack.profileKeys[currentUIPack.resolutions.chosen][moduleName] = profileKey
            addon.UpdatePackSelectedUI()
          end
        },
        isCurrentProfile = isCurrentProfile
      }
    )
  end
  table.sort(
    orderedProfileKeys,
    function(a, b)
      if a.isCurrentProfile then
        return true
      end
      if b.isCurrentProfile then
        return false
      end
      return a.data.value < b.data.value
    end
  )
  for _, profileKey in ipairs(orderedProfileKeys) do
    tinsert(res, profileKey.data)
  end

  return res
end

local function exportFunc(moduleName, resolution, timestamp)
  local packFromDb = addon.db.creatorUI[addon.db.chosenPack]
  local stashed = addon:GetCurrentPackStashed()
  ---@type LibAddonProfilesModule
  local lapModule = LAP:GetModule(moduleName)
  ---@type any
  local newExport = lapModule:exportProfile(stashed.profileKeys[resolution][moduleName])
  ---@type any
  local oldExport = packFromDb.profiles[resolution][moduleName]
  local tableA, tableB
  if lapModule.exportGroup then
    tableA = oldExport
    tableB = newExport
  end
  local areEqual, changedEntries, removedEntries =
      lapModule:areProfileStringsEqual(oldExport, newExport, tableA, tableB)

  --check for old keys for which the data is now nonexistent here
  if moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
    -- don't clean up blocked entries
    for key, info in pairs(stashed.profileKeys[resolution][moduleName]) do
      if not info.blocked and not newExport[key] then
        removedEntries = removedEntries or {}
        removedEntries[key] = true
        areEqual = false
        stashed.profileKeys[resolution][moduleName][key] = nil
      end
    end
  end

  if areEqual then
    return false
  end
  --stuff changed, we need to handle it
  --set the profile, time of export
  stashed.profileMetadata[resolution][moduleName] = stashed.profileMetadata[resolution][moduleName] or {}
  if moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
    stashed.profileMetadata[resolution][moduleName].lastUpdatedAt =
        stashed.profileMetadata[resolution][moduleName].lastUpdatedAt or {}
    if changedEntries then
      for key in pairs(changedEntries) do
        stashed.profileMetadata[resolution][moduleName].lastUpdatedAt[key] = timestamp
      end
    end
    stashed.profiles[resolution][moduleName] = newExport
  else
    stashed.profileMetadata[resolution][moduleName].lastUpdatedAt = timestamp
    stashed.profiles[resolution][moduleName] = newExport
  end
  return true, changedEntries, removedEntries
end

--- probably need to rename some stuff, this is for dropdown that SETS the profile
--- @param dropdown table
--- @param lapModule LibAddonProfilesModule
local function createProfileDropdownOptions(dropdown, lapModule)
  local res = {}
  if not lapModule:isLoaded() or not lapModule.getProfileKeys then
    return res
  end
  local profileKeys = lapModule:getProfileKeys()
  for profileKey, _ in pairs(profileKeys) do
    tinsert(
      res,
      {
        value = profileKey,
        label = profileKey,
        onclick = function()
          lapModule:setProfile(profileKey)
        end
      }
    )
  end
  return res
end

function ModuleFunctions:InsertModuleConfig(m)
  ---@type LibAddonProfilesModule
  local lapModule = m.lapModule
  local manageFunc = m.manageFunc and function(...)
    m.manageFunc(...)
  end or nil
  local onSuccessfulTestOverride = m.onSuccessfulTestOverride and function(...)
    m.onSuccessfulTestOverride(...)
  end or nil
  tinsert(
    addon.moduleConfigs,
    {
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
      sortIndex = m.sortIndex,
      hasGroups = m.hasGroups,
      manageFunc = manageFunc,
      onSuccessfulTestOverride = onSuccessfulTestOverride
    }
  )
end

function ModuleFunctions:SortModuleConfigs()
  table.sort(
    addon.moduleConfigs,
    function(a, b)
      ---@type LibAddonProfilesModule
      local aLap = a.lapModule
      ---@type LibAddonProfilesModule
      local bLap = b.lapModule
      if not aLap or not bLap then
        return false
      end

      local aLoaded = aLap:isLoaded()
      local bLoaded = bLap:isLoaded()
      local aLoadable = not aLoaded and LAP:CanEnableAnyAddOn(aLap.addonNames)
      local bLoadable = not bLoaded and LAP:CanEnableAnyAddOn(bLap.addonNames)
      local aSortIndex = a.sortIndex or 0
      local bSortIndex = b.sortIndex or 0
      local aIdx, bIdx = 0, 0

      if (aLoaded) then
        aIdx = 1000 - aSortIndex
      elseif aLoadable then
        aIdx = 500 - aSortIndex
      else
        aIdx = aIdx - aSortIndex
      end
      if (bLoaded) then
        bIdx = 1000 - bSortIndex
      elseif bLoadable then
        bIdx = 500 - bSortIndex
      else
        bIdx = bIdx - bSortIndex
      end

      return (aIdx > bIdx)
    end
  )
end

function ModuleFunctions:GetModuleByName(moduleName)
  for _, moduleConfig in ipairs(addon.moduleConfigs) do
    if moduleConfig.name == moduleName then
      return moduleConfig
    end
  end
end
