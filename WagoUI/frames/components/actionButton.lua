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

local function setupWagoWeakAuraSplitView()
  if addon.state.hasSetupSplitView then return end
  if not WeakAurasOptions then return end
  WeakAurasOptions:ClearAllPoints()
  WeakAurasOptions:SetPoint("RIGHT", UIParent, "CENTER", -10, 0)
  addon.frames.mainFrame:ClearAllPoints()
  addon.frames.mainFrame:SetPoint("LEFT", UIParent, "CENTER", 10, 0)
  addon.state.hasSetupSplitView = true
end

function addon:EndWeakAuraSplitView()
  WeakAurasOptions:Hide()
  addon:ResetFramePosition()
  addon.state.hasSetupSplitView = false
end

function addon:CreateActionButton(parent, width, height, fontSize)
  local actionButton = LWF:CreateButton(parent, width, height, "", fontSize)

  function actionButton:UpdateAction(info, updateAvailable, lastUdatedAt, profileKey, latestVersion)
    ---@type LibAddonProfilesModule
    local lap = info.lap
    local loaded = lap:isLoaded()
    local canEnable = LAP:CanEnableAnyAddOn(lap.addonNames)
    local askReimport
    actionButton:SetBackdropColor(1, 1, 1, 0.7)

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
    elseif canEnable then
      actionButton:SetText(L["Enable AddOn"])
      actionButton:Enable()
      actionButton:SetClickFunction(function()
        LAP:EnableAddOns(lap.addonNames)
        ReloadUI()
      end)
      return
    else
      actionButton:SetText(L["AddOn not installed"])
      actionButton:Disable()
    end
    actionButton:SetClickFunction(function()
      local importCallback = function()
        addon:Async(function()
          importProfile(lap, info.profile, profileKey, latestVersion, info.entryName)
          if lap.moduleName == "WeakAuras" then
            setupWagoWeakAuraSplitView()
          end
        end)
      end
      if askReimport then
        addon:ShowPrompt(L["REIMPORT_PROMPT"], importCallback, nil, L["Re-Import"])
      else
        importCallback()
      end
    end)
  end

  return actionButton
end
