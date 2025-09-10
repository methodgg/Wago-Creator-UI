---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "DonePage"
local reloadButton

local onShow = function()
  addon.db.introState.currentPage = pageName
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", false)
  if addon.state.needReload then
    reloadButton:SetText(L["Reload UI"])
  else
    reloadButton:SetText(L["Close"])
  end
  addon.db.introEnabled = false
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, L["INSTALLATION_END_TEXT"], 38, "white")
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100)

  reloadButton = LWF:CreateButton(page, 250, 70, "", 24)
  reloadButton:SetClickFunction(
    function()
      if addon.state.needReload then
        ReloadUI()
      else
        addon.frames.introFrame:Hide()
        addon.frames.expertFrame:Show()
        addon.frames.mainFrame:Hide()
      end
    end
  )
  reloadButton:SetPoint("BOTTOM", page, "BOTTOM", 0, 180)

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
