---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
---@class LibAddonProfilesPrivate
local private =
  loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then
  return
end

do
  local cache = {}
  --- Checks if any addon from the list can enabled.
  ---@param addonNames table<number, string> | nil
  ---@return boolean
  function private:CanEnableAnyAddOn(addonNames)
    if not addonNames then
      return false
    end
    --- Check is expensive so we cache it
    for _, module in pairs(addonNames) do
      if cache[module] then
        if cache[module].canEnable == true then
          return true
        end
      else
        for i = 1, C_AddOns.GetNumAddOns() do
          local name, _, _, loadable, reason = C_AddOns.GetAddOnInfo(i)
          if name == module then
            if loadable then
              cache[module] = {
                canEnable = true
              }
              return true
            end
            if not loadable and (reason == "DISABLED" or reason == "DEP_DISABLED" or reason == "DEMAND_LOADED") then
              cache[module] = {
                canEnable = true
              }
              return true
            end
          end
        end
        cache[module] = {
          canEnable = false
        }
      end
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

---@param a string Sanitized semver string - no "v" prefix etc
---@param b string Sanitized semver string - no "v" prefix etc
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
  local currentVersionString = C_AddOns.GetAddOnMetadata(lapModule.addonNames[1], "Version")
  if not currentVersionString then
    return false
  end
  return private:IsSemverSameOrHigher(currentVersionString, lapModule.oldestSupported)
end
