local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "WeakAurasPage"

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, "WeakAuras", 38, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100);

  local profileList = addon.DF:CreateProfileList(page, page:GetWidth(), page:GetHeight())
  -- profileList.UpdateData({})
  profileList.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -80)

  return page
end

addon:RegisterPage(createPage)
