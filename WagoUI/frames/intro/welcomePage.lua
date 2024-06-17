local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "WelcomePage"

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, string.format(L["Welcome to |c%sWago|rUI:"], addon.color), 38,
    "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100);

  local logo = DF:CreateImage(page, [[Interface\AddOns\]]..addonName..[[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", header, "BOTTOM", 0, 50)

  local startButton = addon.DF:CreateButton(page, 230, 50, "Full Installation", 22)
  startButton:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 140, 100);
  startButton:SetClickFunction(function()
    addon:NextPage()
  end);

  local expertButton = addon.DF:CreateButton(page, 230, 50, "Expert Mode", 22)
  expertButton:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -140, 100);
  expertButton:SetClickFunction(function()
    addon.frames.introFrame:Hide()
    addon.frames.profileFrame:Show()
  end);


  return page
end

addon:RegisterPage(createPage)
