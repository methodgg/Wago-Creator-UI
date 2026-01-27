---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "CooldownManagerPage"
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

end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local text = L["CDM_IMPORT_INSTRUCTION"]
  local header = DF:CreateLabel(page, text, 18, "white")
  header:SetJustifyH("CENTER")
  header:SetWidth(page:GetWidth() - 10)
  header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -15)

  local profileList = addon:CreateProfileList(page, page:GetWidth(), page:GetHeight() - 105)
  local updateData = function(data)
    filtered = {}
    if data then
      for _, entry in ipairs(data) do
        if entry.moduleName == "Blizzard Cooldown Manager" then
          tinsert(filtered, entry)
        end
      end
      table.sort(
        filtered,
        function(a, b)
          local orderA = a.matchingInfo.matching and 1 or 0
          local orderB = b.matchingInfo.matching and 1 or 0
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
