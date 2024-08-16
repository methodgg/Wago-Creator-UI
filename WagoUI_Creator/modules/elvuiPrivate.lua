---@class WagoUICreator
local addon = select(2, ...)
local moduleName = "ElvUI Private Profile"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not ElvPrivateDB then
    return res
  end
  local profileKeys = lapModule:getProfileKeys()
  local currentProfileKey = lapModule:getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  copyButtonTooltipText = nil,
  sortIndex = 5
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
