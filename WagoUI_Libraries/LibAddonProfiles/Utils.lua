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
