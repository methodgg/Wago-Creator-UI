---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if private then
  for moduleName, m in pairs(private.modules) do
    if m.flavors and not tContains(m.flavors, private.gameFlavor) then private.modules[moduleName] = nil end
  end
end
loadingAddonNamespace.GetLibAddonProfilesInternal = nil
