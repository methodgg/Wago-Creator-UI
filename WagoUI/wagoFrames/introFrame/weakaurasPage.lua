---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "WeakAurasPage"
local hasSkipped = false
local filtered

local onShow = function()
  if not hasSkipped and #filtered == 0 then
    addon:NextPage()
    hasSkipped = true
    return
  end
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", true)
end

local onHide = function()
  addon.state.hasSetupSplitView = false
  LWF:EndSplitView(WeakAurasOptions, addon.ResetFramePosition)
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local text = L["Install the WeakAuras you would like to use."]
  local header = DF:CreateLabel(page, text, 22, "white")
  header:SetJustifyH("CENTER")
  header:SetWidth(page:GetWidth() - 10)
  header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -15)

  local profileList = addon:CreateProfileList(page, page:GetWidth(), page:GetHeight() - 105)
  local updateData = function(data)
    filtered = {}
    if data then
      for _, entry in ipairs(data) do
        if entry.moduleName == "WeakAuras" or entry.moduleName == "Echo Raid Tools" then
          tinsert(filtered, entry)
        end
      end
      --sort weakauras on top
      table.sort(
        filtered,
        function(a, b)
          local orderA = a.moduleName == "WeakAuras" and 1 or 0
          local orderB = b.moduleName == "WeakAuras" and 1 or 0
          return orderA > orderB
        end
      )
    end
    profileList.updateData(filtered)
  end
  addon:RegisterDataConsumer(updateData)
  addon:UpdateRegisteredDataConsumers()
  profileList.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -80)

  page:SetScript("OnShow", onShow)
  page:SetScript("OnHide", onHide)
  return page
end

addon:RegisterPage(createPage)
