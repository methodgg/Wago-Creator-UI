---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "DirectProfilesPage"
local filtered

local onShow = function()
  addon.state.currentPage = pageName
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", true)
  addon:UpdateRegisteredDataConsumers()
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local text = L["Choose the profiles you would like to install."]
  local header = DF:CreateLabel(page, text, 22, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -15);

  local list = addon:CreateProfileSelectionList(page, page:GetWidth(), page:GetHeight() - 120)
  local updateData = function(data)
    filtered = {}
    if data then
      for _, entry in ipairs(data) do
        if entry.moduleName ~= "WeakAuras" and entry.moduleName ~= "Echo Raid Tools" then
          tinsert(filtered, entry)
        end
      end
      --sort disabled modules to bottom, alphabetically afterwards
      table.sort(filtered, function(a, b)
        local orderA = (a.lap:isLoaded() or a.lap:needsInitialization()) and 1 or 0
        local orderB = (b.lap:isLoaded() or b.lap:needsInitialization()) and 1 or 0
        if orderA == orderB then
          return a.moduleName < b.moduleName
        end
        return orderA > orderB
      end)
    end
    list.updateData(filtered)
  end

  function addon:GetFilteredProfileInstallData()
    return filtered
  end

  addon:RegisterDataConsumer(updateData)
  list.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -60)

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
