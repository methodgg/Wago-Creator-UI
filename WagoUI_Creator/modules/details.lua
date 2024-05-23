local addonName, addon = ...
local moduleName = "Details"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not _detalhes_global then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  hooksecurefunc(Details, "ApplyProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Details, "EraseProfile", function()
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
  sortIndex = 6,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
