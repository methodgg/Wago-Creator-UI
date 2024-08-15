---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
---@class LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

do
  local cache = {}
  --- Checks if an addon can be enabled. AddOns that can be anabled will be enabled after a UI reload.
  ---@param addonName string
  ---@return boolean
  function private:CanEnableAddOn(addonName)
    if not addonName then return false end
    --- Check is expensive so we cache it
    if cache[addonName] then return cache[addonName].canEnable end
    for i = 1, C_AddOns.GetNumAddOns() do
      local name, _, _, loadable, reason = C_AddOns.GetAddOnInfo(i)
      if name == addonName then
        if not loadable and reason == "DISABLED" then
          cache[addonName] = {
            canEnable = true
          }
          return true
        end
      end
    end
    cache[addonName] = {
      canEnable = false
    }
    return false
  end
end
