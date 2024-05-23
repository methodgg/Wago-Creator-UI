local _, addon = ...
local moduleName = "Grid2"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not Grid2DB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  hooksecurefunc(Grid2.db, "SetProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Grid2.db, "CopyProfile", function()
    addon:RefreshAllProfileDropdowns()
  end)
  hooksecurefunc(Grid2.db, "DeleteProfile", function()
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
  sortIndex = 9,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
