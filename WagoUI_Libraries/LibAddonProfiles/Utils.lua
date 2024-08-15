---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
---@class LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

do
  local cache = {}
  --- Checks if an addon can be enabled. AddOns that can be enabled will be enabled after a UI reload.
  --- Checks the first entry in the list of supplied AddOn names
  ---@param addonNames table<number, string> | nil Only first entry is checked
  ---@return boolean
  function private:CanEnableAddOn(addonNames)
    if not addonNames then return false end
    --- Check is expensive so we cache it
    local first = addonNames[1]
    if not first then return false end
    if cache[first] then return cache[first].canEnable end
    for i = 1, C_AddOns.GetNumAddOns() do
      local name, _, _, loadable, reason = C_AddOns.GetAddOnInfo(i)
      if name == first then
        if not loadable and reason == "DISABLED" or reason == "DEP_DISABLED" then
          cache[first] = {
            canEnable = true
          }
          return true
        end
      end
    end
    cache[first] = {
      canEnable = false
    }
    return false
  end

  ---Enables a list of AddOns. AddOns that can be enabled will be enabled after a UI reload.
  ---@param addonNames table<number, string>
  function private:EnableAddOns(addonNames)
    if not addonNames then return end
    for _, module in ipairs(addonNames) do
      C_AddOns.EnableAddOn(module)
    end
  end
end
