local addonName, addon = ...
local moduleName = "BigWigs"
local ModuleFunctions = addon.ModuleFunctions
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not BigWigs3DB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  hooksecurefunc(BigWigs.db, "SetProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(BigWigs.db, "DeleteProfile", function()
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
  sortIndex = 15,
}

ModuleFunctions:InsertModuleConfig(moduleConfig)
