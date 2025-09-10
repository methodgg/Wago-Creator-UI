---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

local pageName = "InstallPage"
local page, installButton, header, simpleList, hasSkipped

---@param enabled boolean If there are any profiles to install
---@param needEnableAddons boolean If we need to enable some addons before we can install
---@param introImportState table<string, IntroImportState>
local setupInstallButton = function(enabled, needEnableAddons, introImportState)
  header:SetText("")
  if not enabled then
    installButton:SetEnabled(false)
    installButton:SetClickFunction(nil)
    return
  end
  if needEnableAddons then
    header:SetText(L["The following AddOns need to be enabled:"])
    installButton:SetText(L["Enable AddOns"])
    installButton:SetEnabled(true)
    installButton:SetClickFunction(
      function()
        for moduleName, data in pairs(introImportState) do
          local lap = LAP:GetModule(moduleName)
          if data.checked and not lap:isLoaded() and LAP:CanEnableAnyAddOn(lap.addonNames) then
            LAP:EnableAddOns(lap.addonNames)
          end
        end
        ReloadUI()
      end
    )
    return
  end

  installButton:SetEnabled(true)
  header:SetText(L["The following profiles will be installed:"])
  installButton:SetText(L["Install Profiles"])
  installButton:SetClickFunction(
    function()
      if InCombatLockdown() then
        addon:AddonPrintError(L["Cannot install profiles while in combat."])
        return
      end
      installButton:SetEnabled(false)
      addon.state.isImporting = true
      local countOperations = 0
      for moduleName, data in pairs(introImportState) do
        local lap = LAP:GetModule(moduleName)
        if data.checked and lap:isLoaded() and lap:isUpdated() then
          countOperations = countOperations + 1
        end
      end
      addon:StartCopyHelperProgressBar(countOperations)
      addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 0, L["Importing profiles..."])
      addon:Async(
        function()
          for moduleName, data in pairs(introImportState) do
            local lap = LAP:GetModule(moduleName)
            if data.checked and lap:isLoaded() and lap:isUpdated() then
              lap:importProfile(data.profile, data.profileKey, true)
              if lap.conflictingAddons then
                LAP:DisableConflictingAddons(lap.conflictingAddons, introImportState)
              end
              addon:AddonPrint(string.format(L["Imported %s: %s"], data.profileKey, moduleName))
              addon:StoreImportedProfileData(data.profileMetadata.lastUpdatedAt, moduleName, data.profileKey)
              if lap.needReloadOnImport then
                addon:ToggleReloadIndicator(true, L["IMPORT_RELOAD_WARNING1"])
                addon.state.needReload = true
              end
              addon:UpdateCopyHelperProgressBar()
              coroutine.yield()
            end
          end
          -- Hack to indicate that we did the setup on this character
          addon:StoreImportedProfileData(GetServerTime(), "INSTALLFLAG", "INSTALLFLAG")
          installButton:SetEnabled(true)
          addon.state.isImporting = false
          if addon.state.needReopen then
            addon.frames.mainFrame:Show()
          end
          addon.copyHelper:SmartHide()
          addon.copyHelper:SmartFadeOut(2, L["Done"], addon.frames.mainFrame, 0, 0)
          addon.db.anyInstalled = true
          addon:NextPage()
        end,
        "installProfiles"
      )
    end
  )
end

local updatePage = function(updatedData)
  if not page then
    return
  end
  local numChecked = 0
  local numNeedEnable = 0
  local res = addon.db.selectedWagoDataResolution or addon.resolutions.defaultValue
  ---@type table<string, IntroImportState>
  local introState = addon.db.introImportState[res]
  local checkedEntries = {}
  local needEnableEntries = {}
  if not introState then return end
  for moduleName, data in pairs(introState) do
    local isDataPresent
    if updatedData then
      for _, entry in ipairs(updatedData) do
        if entry.moduleName == moduleName then
          isDataPresent = true
        end
      end
    end
    local lap = LAP:GetModule(moduleName)
    if data.checked and lap:isLoaded() and lap:isUpdated() and isDataPresent then
      numChecked = numChecked + 1
      tinsert(checkedEntries, { moduleName = moduleName, profileKey = data.profileKey })
    end
    if
        data.checked and not lap:isLoaded() and LAP:CanEnableAnyAddOn(lap.addonNames) and isDataPresent and
        lap:isUpdated()
    then
      numChecked = numChecked + 1
      numNeedEnable = numNeedEnable + 1
      tinsert(needEnableEntries, { moduleName = moduleName, profileKey = L["AddOn disabled"] })
    end
  end
  setupInstallButton(numChecked > 0, numNeedEnable > 0, introState)
  local headerTwo = simpleList.header.columnHeadersCreated[2].Text
  headerTwo:SetText(numNeedEnable > 0 and L["Status"] or L["Profile to be installed"])
  if addon.db.introState.currentPage == pageName then
    addon:ToggleNavigationButton("next", not (numChecked > 0 or numNeedEnable > 0))
  end

  if (numChecked == 0 and numNeedEnable == 0) and not hasSkipped then
    if addon.db.introState.currentPage == pageName then
      hasSkipped = true
      addon:NextPage()
    end
  end
  simpleList.updateData(numNeedEnable > 0 and needEnableEntries or checkedEntries)
end

local onShow = function()
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  addon:UpdateRegisteredDataConsumers()
end

local function createPage()
  page = addon:CreatePageProtoType(pageName)
  page:SetScript("OnShow", onShow)

  header = DF:CreateLabel(page, "", 28, "white")
  header:SetWidth(page:GetWidth() - 40)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -20)
  page.header = header

  installButton = LWF:CreateButton(page, 350, 60, L["Install Profiles"], 24)
  installButton:SetPoint("BOTTOM", page, "BOTTOM", 0, 40)
  page.installButton = installButton

  simpleList = addon:SimpleProfileList(page, page:GetWidth() - 120, page:GetHeight() - 240)
  simpleList.header:SetPoint("TOP", page, "TOP", 0, -80)

  return page
end
addon:RegisterDataConsumer(updatePage)
addon:RegisterPage(createPage)
