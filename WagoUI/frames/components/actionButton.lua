---@class WagoUI
local addon = select(2, ...)
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

---@param lapModule LibAddonProfilesModule
---@param profileString string
local function importProfile(lapModule, profileString, profileKey, latestVersion, entryName)
  lapModule:importProfile(profileString, profileKey, false)
  addon:StoreImportedProfileData(latestVersion, lapModule.moduleName, profileKey, entryName)
  if lapModule.needReloadOnImport then
    addon:ToggleReloadIndicator(true, L["IMPORT_RELOAD_WARNING3"])
    addon.state.needReload = true
  end
  addon:UpdateRegisteredDataConsumers()
end

function addon:CreateActionButton(parent, width, height, fontSize)
  local actionButton = LWF:CreateButton(parent, width, height, "", fontSize)

  function actionButton:UpdateAction(info, updateAvailable, lastUdatedAt, profileKey, latestVersion)
    ---@type LibAddonProfilesModule
    local lap = info.lap
    local loaded = lap:isLoaded()
    local updated = lap:isUpdated()
    local canEnable = LAP:CanEnableAnyAddOn(lap.addonNames)
    local askReimport
    actionButton:SetBackdropColor(1, 1, 1, 0.7)

    if loaded and updated then
      if not lastUdatedAt then
        actionButton:SetText(L["Import"])
      elseif updateAvailable then
        actionButton:SetText(L["Update"])
        actionButton:SetBackdropColor(0, 0.8, 0, 1)
      else
        actionButton:SetBackdropColor(0, 0, 0, 0.3)
        actionButton:SetText(L["Up to date"])
        askReimport = true
      end
      actionButton:Enable()
    elseif (canEnable or loaded) and not updated then
      actionButton:SetText(L["Addon out of date"])
      actionButton:Disable()
    elseif canEnable then
      actionButton:SetText(L["Enable AddOn"])
      actionButton:Enable()
      actionButton:SetClickFunction(
        function()
          LAP:EnableAddOns(lap.addonNames)
          ReloadUI()
        end
      )
      return
    else
      actionButton:SetText(L["AddOn not installed"])
      actionButton:Disable()
    end
    actionButton:SetClickFunction(
      function()
        local importCallback = function()
          addon:Async(
            function()
              importProfile(lap, info.profile, profileKey, latestVersion, info.entryName)
              if lap.moduleName == "WeakAuras" then
                if not addon.state.hasSetupSplitView then
                  LWF:StartSplitView(addon.frames.mainFrame, WeakAurasOptions, false)
                  addon.state.hasSetupSplitView = true
                end
              end
            end
          )
        end
        if askReimport then
          addon:ShowPrompt(L["REIMPORT_PROMPT"], importCallback, nil, L["Re-Import"])
        else
          importCallback()
        end
      end
    )
  end

  return actionButton
end
