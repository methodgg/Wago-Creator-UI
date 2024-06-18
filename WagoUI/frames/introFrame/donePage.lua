local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "DonePage"

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, "Done", 38, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100);


  return page
end

addon:RegisterPage(createPage)
