---@class WagoUICreator
local addon = select(2, ...)
local moduleName = "WarpDeplete"
local ModuleFunctions = addon.ModuleFunctions
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not lapModule:isLoaded() then
    return res
  end
  local profileKeys = lapModule:getProfileKeys()
  local currentProfileKey = lapModule:getCurrentProfileKey()
  return ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  sortIndex = 23
}

ModuleFunctions:InsertModuleConfig(moduleConfig)
