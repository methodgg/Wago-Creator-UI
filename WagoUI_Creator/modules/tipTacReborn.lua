local _, addon = ...
local moduleName = "TipTac Reborn"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not TipTac_Config then return res end
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
  hookRefresh = nil, --no profiles, only global config
  copyButtonTooltipText = string.format(addon.L.noBuiltInProfileTextImport, moduleName),
  sortIndex = 19,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
