local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "DonePage"

local onShow = function()
  addon.state.currentPage = pageName
  addon:ToggleNavgiationButton("prev", true)
  addon:ToggleNavgiationButton("next", false)
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, "Done", 38, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100);

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
