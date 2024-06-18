local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

---@param lapModule LibAddonProfilesModule
---@param profileString string
local function importProfile(lapModule, profileString, profileKey)
  local genericPKey, genericProfile, genericRaw = LAP:GenericDecode(profileString)
  if lapModule.testImport then
    local successful = lapModule.testImport(profileString, genericPKey, genericProfile, genericRaw)
    if successful then
      local isDuplicate = lapModule.isDuplicate and lapModule.isDuplicate(profileKey)
      --TODO: this is pretty raw and might need to be adjusted for certain addons
      --TODO: set last imported to timestamp from metadata (not the time when we imported)
      --TODO: update the profileTable list and reflect the status in the actionButton
      lapModule.importProfile(profileString, profileKey, isDuplicate)
    end
  end
end


function addon:CreateActionButton(parent)
  local actionButton = addon.DF:CreateButton(parent, 180, 30, L["Import"], 16)

  --TODO: Check if profile is uptodate, use timestamp from metadata to verify
  function actionButton:UpdateAction(info)
    ---@class LibAddonProfilesModule
    local lap = info.lap
    local loaded = lap.isLoaded()
    if loaded then
      actionButton:SetText(L["Import"])
      actionButton:Enable()
    else
      actionButton:SetText(L["Not loaded"])
      actionButton:Disable()
    end
    actionButton:SetClickFunction(function()
      --TODO: Implement Import
      addon:Async(function()
        -- vdt(info)
        importProfile(info.lap, info.profile, info.profileKey)
      end)
    end)
  end

  return actionButton
end
