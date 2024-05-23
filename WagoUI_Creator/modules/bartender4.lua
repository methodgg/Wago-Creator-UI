local addonName, addon = ...
local moduleName = "Bartender4"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not Bartender4DB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  hooksecurefunc(Bartender4.db, "SetProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Bartender4.db, "CopyProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Bartender4.db, "DeleteProfile", function()
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
  copyButtonTooltipText = string.format(addon.L.noBuiltInProfileTextImport, moduleName),
  sortIndex = 8,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
