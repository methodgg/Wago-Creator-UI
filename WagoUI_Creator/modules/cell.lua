local _, addon = ...
local moduleName = "Cell"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not Cell then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  hookRefresh = nil, --this addon doesn't have profiles at all
  copyButtonTooltipText = nil,
  sortIndex = 5,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
