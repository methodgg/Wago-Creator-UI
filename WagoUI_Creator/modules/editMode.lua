local addonName, addon = ...
local moduleName = "EditMode"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  --new, rename, copy, delete, import layout
  hooksecurefunc(EditModeManagerFrame, "SaveLayouts", function()
    C_Timer.After(0.1, function()
      addon:RefreshAllProfileDropdowns()
    end)
  end)
  --chose layout
  hooksecurefunc(EditModeManagerFrame, "Layout", function()
    C_Timer.After(0.1, function()
      addon:RefreshAllProfileDropdowns()
    end)
  end)
  --select layout
  hooksecurefunc(EditModeManagerFrame, "SelectLayout", function()
    C_Timer.After(0.1, function()
      addon:RefreshAllProfileDropdowns()
    end)
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
  sortIndex = 1,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
