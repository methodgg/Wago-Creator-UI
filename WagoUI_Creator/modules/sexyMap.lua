local _, addon = ...
local moduleName = "SexyMap"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not SexyMap2DB then return res end
  -- we cannot hook refresh because the addon is not using AceDB
  -- this way we only show the key of the current character, other profiles are not shown
  -- this is a limitation but it still covers most use cases
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
  hookRefresh = nil, --only global or character specific profile that requires reload to change
  copyButtonTooltipText = string.format(addon.L.noBuiltInProfileTextImport, moduleName),
  sortIndex = 18,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
