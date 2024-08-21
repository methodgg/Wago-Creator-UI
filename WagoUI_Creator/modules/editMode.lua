if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
  return
end

---@class WagoUICreator
local addon = select(2, ...)
local moduleName = "Blizzard Edit Mode"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
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
  sortIndex = 1
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
