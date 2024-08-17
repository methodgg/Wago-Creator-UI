---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "WelcomePage"
local noPacksFound = false

local page, uiPackDropdown, uiPackLabel, header, logo, startButton, expertButton, noDataLabel

local function updatePage()
  if not page then
    return
  end
  -- label or dropdown, depending on if single or multiple ui packs available
  local dropdownData = addon:GetWagoDataForDropdown()
  if #dropdownData == 0 then
    noPacksFound = true
    noDataLabel:Show()
    startButton:Hide()
    expertButton:Hide()
    uiPackDropdown:Hide()
    uiPackLabel:Hide()
    logo:Hide()
    return
  end
  noDataLabel:Hide()
  startButton:Show()
  expertButton:Show()
  logo:Show()
  if #dropdownData > 1 then
    uiPackDropdown:Show()
    uiPackLabel:Hide()
    if not addon.db.selectedWagoData then
      uiPackDropdown:NoOptionSelected()
    else
      uiPackDropdown:Select(addon.db.selectedWagoData)
    end
  else
    uiPackDropdown:Hide()
    uiPackLabel:Show()
    uiPackLabel:SetText(dropdownData[1].label)
  end
end

local onShow = function()
  addon.db.introState.currentPage = pageName
  addon:ToggleNavigationButton("prev", false)
  addon:ToggleNavigationButton("next", false)
  updatePage()
  if noPacksFound then
    addon.db.introEnabled = false
    return
  end
  addon.state.hasSetupSplitView = false
  addon.db.introEnabled = true
  addon:ToggleStatusBar(false)
  if uiPackDropdown then
    uiPackDropdown:Select(addon.db.selectedWagoData)
  end
end

local function createPage()
  page = addon:CreatePageProtoType(pageName)
  page:SetScript("OnShow", onShow)

  header = DF:CreateLabel(page, string.format(L["Welcome to |c%sWago|rUI:"], addon.color), 38, "white")
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -75)

  local isCreator = C_AddOns.IsAddOnLoaded("WagoUI_Creator")
  local noDataText = isCreator and L["No UI Packs found Creator"] or L["No UI Packs found"]
  noDataLabel = DF:CreateLabel(page, noDataText, 26, "white")
  noDataLabel:SetJustifyH("CENTER")
  noDataLabel:SetPoint("TOP", header, "BOTTOM", 0, -70)

  logo = DF:CreateImage(page, [[Interface\AddOns\]] .. addonName .. [[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", header, "BOTTOM", 0, -20)

  local dropdownFunc = function()
    return addon:GetWagoDataForDropdown()
  end
  uiPackDropdown = LWF:CreateDropdown(page, 250, 40, 20, 1.5, dropdownFunc)
  uiPackDropdown:SetPoint("TOP", header, "BOTTOM", 0, -10)

  uiPackLabel = DF:CreateLabel(page, "", 38, "white")
  uiPackLabel:SetJustifyH("CENTER")
  uiPackLabel:SetPoint("TOP", header, "BOTTOM", 0, -10)

  startButton = LWF:CreateButton(page, 230, 50, L["Full Installation"], 22)
  startButton:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 140, 80)
  startButton:SetClickFunction(
    function()
      addon:NextPage()
    end
  )

  expertButton = LWF:CreateButton(page, 230, 50, L["Expert Mode"], 22)
  expertButton:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -140, 80)
  expertButton:SetClickFunction(
    function()
      addon.frames.introFrame:Hide()
      addon.frames.expertFrame:Show()
      addon.db.introEnabled = false
    end
  )

  return page
end

addon:RegisterDataConsumer(updatePage)
addon:RegisterPage(createPage)
