local addonName, addon = ...
local moduleName = "Plater"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not PlaterDB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  hooksecurefunc(Plater.db, "SetProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Plater.db, "CopyProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Plater.db, "DeleteProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  hookRefresh = hookRefresh,
  copyButtonTooltipText = nil,
  sortIndex = 7,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
