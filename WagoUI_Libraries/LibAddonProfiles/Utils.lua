---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
---@class LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

do
  local cache
  --- Checks if any addon from the list can enabled.
  ---@param addonNames table<number, string> | nil
  ---@return boolean
  function private:CanEnableAnyAddOn(addonNames)
    if not addonNames or not next(addonNames) then
      return false
    end
    -- Build one inventory per session, instead of rescanning it for every missing addon.
    if not cache then
      cache = {}
      for i = 1, C_AddOns.GetNumAddOns() do
        local name, _, _, loadable, reason = C_AddOns.GetAddOnInfo(i)
        if name then cache[name] = loadable or reason == "DISABLED" or reason == "DEP_DISABLED" or reason == "DEMAND_LOADED" end
      end
    end
    for _, module in pairs(addonNames) do
      if cache[module] then return true end
    end
    return false
  end

  ---Enables a list of AddOns. AddOns that can be enabled will be enabled after a UI reload.
  ---@param addonNames table<number, string>
  function private:EnableAddOns(addonNames)
    if not addonNames then
      return
    end
    for _, module in ipairs(addonNames) do
      C_AddOns.EnableAddOn(module)
    end
  end
end

---Disables a list of AddOns.
---If the Addon is in selectedModules and has field checked set to true, it will not be disabled
---@param addonNames table<number, string>
---@param selectedModules table<string, {checked: boolean}>
function private:DisableConflictingAddons(addonNames, selectedModules)
  if not addonNames or not selectedModules then return end
  local doNotDisable = {}
  for moduleName, state in pairs(selectedModules) do
    ---@type LibAddonProfilesModule
    local lap = private.modules[moduleName]
    if lap and lap.addonNames and state.checked then
      for _, addon in ipairs(lap.addonNames) do
        doNotDisable[addon] = true
      end
    end
  end
  for _, addon in ipairs(addonNames) do
    if not doNotDisable[addon] then
      C_AddOns.DisableAddOn(addon)
    end
  end
end

---Checks if the version of the addon is the same or higher than the provided version.
---Version format is semver but it can be any string that has numbers separated by dots.
---@param a string
---@param b string
function private:IsSemverSameOrHigher(a, b)
  local aMajor, aMinor, aPatch, aBuild = string.match(a, "(%d+)%.*(%d*)%.*(%d*)%.*(%d*)")
  local bMajor, bMinor, bPatch, bBuild = string.match(b, "(%d+)%.*(%d*)%.*(%d*)%.*(%d*)")
  aMajor = aMajor and tonumber(aMajor) or 0
  aMinor = aMinor and tonumber(aMinor) or 0
  aPatch = aPatch and tonumber(aPatch) or 0
  aBuild = aBuild and tonumber(aBuild) or 0
  bMajor = bMajor and tonumber(bMajor) or 0
  bMinor = bMinor and tonumber(bMinor) or 0
  bPatch = bPatch and tonumber(bPatch) or 0
  bBuild = bBuild and tonumber(bBuild) or 0

  if aMajor > bMajor then
    return true
  end
  if aMajor < bMajor then
    return false
  end
  if aMinor > bMinor then
    return true
  end
  if aMinor < bMinor then
    return false
  end
  if aPatch > bPatch then
    return true
  end
  if aPatch < bPatch then
    return false
  end
  if aBuild > bBuild then
    return true
  end
  if aBuild < bBuild then
    return false
  end
  return true
end

---@param lapModule LibAddonProfilesModule
---@return boolean
function private:GenericVersionCheck(lapModule)
  local currentVersionString = private:GetAddonVersionCached(lapModule.addonNames[1])
  if currentVersionString == "@project-version@" or currentVersionString == "#@project-version@" then
    return true
  end
  if not currentVersionString then
    return false
  end
  return private:IsSemverSameOrHigher(currentVersionString, lapModule.oldestSupported)
end

do
  local versionCache = {}
  ---@param addonName string
  ---@return string
  function private:GetAddonVersionCached(addonName)
    if versionCache[addonName] then
      return versionCache[addonName]
    end
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    versionCache[addonName] = version
    return version
  end
end
