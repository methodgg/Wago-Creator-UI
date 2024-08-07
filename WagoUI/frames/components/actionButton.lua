---@class WagoUI
local addon = select(2, ...)
local L = addon.L

---@param lapModule LibAddonProfilesModule
---@param profileString string
local function importProfile(lapModule, profileString, profileKey, latestVersion, entryName)
  lapModule:importProfile(profileString, profileKey, false)
  addon:StoreImportedProfileTimestamp(latestVersion, lapModule.moduleName, profileKey, entryName)
  if lapModule.needReloadOnImport then
    addon:ToggleReloadIndicator(true, L["IMPORT_RELOAD_WARNING3"])
    addon.state.needReload = true
  end
  addon:UpdateRegisteredDataConsumers()
end


function addon:CreateActionButton(parent, width, height, fontSize)
  local actionButton = addon.DF:CreateButton(parent, width, height, "", fontSize)

  function actionButton:UpdateAction(info, updateAvailable, lastUdatedAt, profileKey, latestVersion)
    ---@class LibAddonProfilesModule
    local lap = info.lap
    local loaded = lap:isLoaded()
    actionButton:SetBackdropColor(1, 1, 1, 0.7)
    local askReimport

    if loaded then
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
    else
      actionButton:SetText(L["Not loaded"])
      actionButton:Disable()
    end
    actionButton:SetClickFunction(function()
      local importCallback = function()
        addon:Async(function()
          importProfile(info.lap, info.profile, profileKey, latestVersion, info.entryName)
        end)
      end
      if askReimport then
        addon.DF:ShowPrompt(L["REIMPORT_PROMPT"], importCallback, nil, L["Re-Import"])
      else
        importCallback()
      end
    end)
  end

  return actionButton
end
