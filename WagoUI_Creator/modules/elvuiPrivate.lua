local _, addon = ...
local moduleName = "ElvUI Private Profile"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function dropdownOptions(index)
  local res = {}
  if not ElvPrivateDB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

local function hookRefresh()
  if not lapModule.isLoaded() then return end
  local frame = CreateFrame("Frame")
  local E = unpack(ElvUI)

  local setHooks = function()
    local EDB = E.Options.args.profiles.args.private.handler.db
    hooksecurefunc(EDB, "SetProfile", function()
      addon:RefreshAllProfileDropdowns()
    end)
    hooksecurefunc(EDB, "CopyProfile", function()
      addon:RefreshAllProfileDropdowns()
    end)
    hooksecurefunc(EDB, "DeleteProfile", function()
      addon:RefreshAllProfileDropdowns()
    end)
  end

  --ElvUI Options is load on demand and might not be loaded yet when we want to hook
  if C_AddOns.IsAddOnLoaded("ElvUI_Options") then
    setHooks()
  else
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, loadedAddonName)
      if loadedAddonName == "ElvUI_Options" then
        setHooks()
        self:UnregisterEvent("ADDON_LOADED")
      end
    end)
  end
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  copyButtonTooltipText = nil,
  sortIndex = 5,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
