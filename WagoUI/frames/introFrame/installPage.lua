---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

local pageName = "InstallPage"
local installButton, header, simpleList, hasSkipped

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
    installButton:SetClickFunction(function()
      for moduleName, data in pairs(introImportState) do
        local lap = LAP:GetModule(moduleName)
        if data.checked and not lap:isLoaded() and LAP:CanEnableAnyAddOn(lap.addonNames) then
          LAP:EnableAddOns(lap.addonNames)
        end
      end
      ReloadUI()
    end)
    return
  end

  installButton:SetEnabled(true)
  header:SetText(L["The following profiles will be installed:"])
  installButton:SetText(L["Install Profiles"])
  installButton:SetClickFunction(function()
    if InCombatLockdown() then
      addon:AddonPrintError(L["Cannot install profiles while in combat."])
      return
    end
    installButton:SetEnabled(false)
    addon.state.isImporting = true
    local countOperations = 0
    for moduleName, data in pairs(introImportState) do
      local lap = LAP:GetModule(moduleName)
      if data.checked and lap:isLoaded() then
        countOperations = countOperations + 1
      end
    end
    addon:StartCopyHelperProgressBar(countOperations)
    addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 0, L["Importing profiles..."])
    addon:Async(function()
      for moduleName, data in pairs(introImportState) do
        local lap = LAP:GetModule(moduleName)
        if data.checked and lap:isLoaded() then
          lap:importProfile(data.profile, data.profileKey, true)
          addon:StoreImportedProfileData(data.profileMetadata.lastUpdatedAt, moduleName, data.profileKey)
          if lap.needReloadOnImport then
            addon:ToggleReloadIndicator(true, L["IMPORT_RELOAD_WARNING1"])
            addon.state.needReload = true
          end
          addon:UpdateCopyHelperProgressBar()
          coroutine.yield()
        end
      end
      installButton:SetEnabled(true)
      addon.state.isImporting = false
      if addon.state.needReopen then
        addon.frames.mainFrame:Show()
      end
      addon.copyHelper:SmartHide()
      addon.copyHelper:SmartFadeOut(2, L["Done"], addon.frames.mainFrame, 0, 0)
      -- TODO: this is the bug that happened when Kwepp logged other char and it didn't pop up
      -- was it even a bug? maybe he didnt import anything??
      addon.db.anyInstalled = true
      addon:NextPage()
    end, "installProfiles")
  end);
end

local onShow = function()
  addon.state.currentPage = pageName
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  local numChecked = 0
  local numNeedEnable = 0
  ---@type table<string, IntroImportState>
  local introState = addon.db.introImportState
  local checkedEntries = {}
  local needEnableEntries = {}
  for moduleName, data in pairs(introState) do
    local lap = LAP:GetModule(moduleName)
    if data.checked and lap:isLoaded() then
      numChecked = numChecked + 1
      tinsert(checkedEntries, { moduleName = moduleName, profileKey = data.profileKey })
    end
    if data.checked and not lap:isLoaded() and LAP:CanEnableAnyAddOn(lap.addonNames) then
      numNeedEnable = numNeedEnable + 1
      tinsert(needEnableEntries, { moduleName = moduleName, profileKey = L["AddOn disabled"] })
    end
  end
  setupInstallButton(numChecked > 0, numNeedEnable > 0, introState)
  local headerTwo = simpleList.header.columnHeadersCreated[2].Text
  headerTwo:SetText(numNeedEnable > 0 and L["Status"] or L["Profile to be installed"])
  addon:ToggleNavigationButton("next", not (numChecked > 0 or numNeedEnable > 0))
  if (numChecked == 0 and numNeedEnable == 0) and not hasSkipped then
    hasSkipped = true
    addon:NextPage()
  end
  simpleList.updateData(numNeedEnable > 0 and needEnableEntries or checkedEntries)
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  header = DF:CreateLabel(page, "", 28, "white");
  header:SetWidth(page:GetWidth() - 40)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -20);
  page.header = header

  installButton = LWF:CreateButton(page, 350, 60, L["Install Profiles"], 24)
  installButton:SetPoint("BOTTOM", page, "BOTTOM", 0, 40)
  page.installButton = installButton

  simpleList = addon:SimpleProfileList(page, page:GetWidth() - 120, page:GetHeight() - 240)
  simpleList.header:SetPoint("TOP", page, "TOP", 0, -80)

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
